//
//  EnergyPredictionService.swift
//  ios-final-coursework
//
//  Next-month kWh / bill prediction. Uses the on-device Core ML model
//  (EnergyBillPredictor.mlmodelc) when bundled, otherwise a multivariate
//  linear regression trained on the same dataset (ML/energy_training_data.csv).
//

import Foundation
import CoreML

public struct EnergyPrediction: Sendable {
    public let predictedKWh: Double
    public let predictedCost: Double
    public let currency: String            
    public let usedCoreML: Bool
    public let billsAnalyzed: Int
    public let historicalAvgKWh: Double
    public let calibratedApplianceCount: Int
    public let applianceMonthlyKWh: Double
    public let temperatureC: Double
    public let humidityPercent: Double
    public let occupants: Int
    public let coolingLoadImpactPercent: Double
    public let effectiveRatePerKWh: Double
}

public final class EnergyPredictionService: @unchecked Sendable {
    public static let shared = EnergyPredictionService()
    public var lastModelError: String? = nil

    private init() {}

    private lazy var coreMLModel: MLModel? = {
        for name in ["EnergyBillPredictor", "EnergyBillPredictor 1", "EnergyBillPredictor_1"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc"),
               let model = try? MLModel(contentsOf: url) {
                return model
            }
        }
        return nil
    }()

    private static let trainingRows: [[Double]] = [
        [90, 55, 28, 75, 3, 94], [120, 80, 29, 78, 4, 128], [150, 95, 30, 80, 4, 155],
        [180, 110, 31, 82, 5, 186], [210, 130, 31, 80, 5, 212], [75, 45, 27, 72, 2, 74],
        [240, 150, 32, 84, 6, 245], [300, 190, 32, 85, 6, 297], [60, 35, 26, 70, 2, 58],
        [135, 85, 29, 76, 3, 136], [165, 100, 30, 79, 4, 165], [195, 120, 31, 81, 5, 199],
        [225, 140, 32, 83, 5, 228], [105, 65, 28, 74, 3, 106], [255, 160, 33, 86, 6, 260],
        [85, 50, 27, 73, 2, 83], [145, 90, 29, 77, 4, 146], [170, 105, 30, 78, 4, 172],
        [200, 125, 31, 82, 5, 202], [270, 170, 33, 87, 6, 274], [110, 70, 28, 75, 3, 112],
        [320, 200, 34, 88, 7, 322], [130, 75, 28, 74, 3, 127], [190, 115, 30, 80, 5, 191],
        [160, 95, 29, 77, 4, 160]
    ]

    private lazy var regressionWeights: [Double] = Self.trainRegression(rows: Self.trainingRows)

    private static func trainRegression(rows: [[Double]]) -> [Double] {
        let n = 6
        var xtx = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        var xty = [Double](repeating: 0, count: n)
        for row in rows {
            let x = [1.0] + Array(row[0..<5])
            let y = row[5]
            for i in 0..<n {
                xty[i] += x[i] * y
                for j in 0..<n { xtx[i][j] += x[i] * x[j] }
            }
        }
        for i in 1..<n { xtx[i][i] += 0.01 }   

        var a = xtx
        var b = xty
        for col in 0..<n {
            var pivot = col
            for r in (col + 1)..<n where abs(a[r][col]) > abs(a[pivot][col]) { pivot = r }
            if abs(a[pivot][col]) < 1e-12 { continue }
            a.swapAt(col, pivot); b.swapAt(col, pivot)
            let d = a[col][col]
            for j in 0..<n { a[col][j] /= d }
            b[col] /= d
            for r in 0..<n where r != col {
                let f = a[r][col]
                if f == 0 { continue }
                for j in 0..<n { a[r][j] -= f * a[col][j] }
                b[r] -= f * b[col]
            }
        }
        return b
    }

    private func regressionPredict(_ f: [Double]) -> Double {
        let w = regressionWeights
        var y = w[0]
        for i in 0..<5 { y += w[i + 1] * f[i] }
        return y
    }

    private static let featureNames = ["historicalAvgKWh", "applianceMonthlyKWh", "temperatureC", "humidityPercent", "occupants"]

    private func coreMLPredict(_ f: [Double]) -> Double? {
        guard let model = coreMLModel else {
            lastModelError = "Core ML model 'EnergyBillPredictor' is not loaded or bundled."
            return nil
        }
        let inputDescriptions = model.modelDescription.inputDescriptionsByName
        var input: [String: MLFeatureValue] = [:]
        for (i, name) in Self.featureNames.enumerated() {
            // Create ML may export numeric columns as Int64 or Double; match the model's declared type.
            if inputDescriptions[name]?.type == .int64 {
                input[name] = MLFeatureValue(int64: Int64(f[i].rounded()))
            } else {
                input[name] = MLFeatureValue(double: f[i])
            }
        }
        do {
            let provider = try MLDictionaryFeatureProvider(dictionary: input)
            let output = try model.prediction(from: provider)
            guard let outValue = output.featureValue(for: "nextMonthKWh") else {
                lastModelError = "Output feature 'nextMonthKWh' missing from model prediction."
                return nil
            }
            let value = outValue.type == .int64 ? Double(outValue.int64Value) : outValue.doubleValue
            guard value.isFinite, value > 0 else {
                lastModelError = "Model output was non-finite or non-positive: \(value)"
                return nil
            }
            lastModelError = nil
            return value
        } catch {
            lastModelError = "Core ML prediction error: \(error.localizedDescription)"
            return nil
        }
    }

    /// Sri Lankan CEB domestic tiered tariff estimation (Domestic Purpose D-1/D-2)
    public static func estimateCEBDomesticCost(kwh: Double) -> Double {
        let units = max(0.0, kwh)
        var energyCharge: Double = 0.0
        var fixedCharge: Double = 0.0

        if units <= 60 {
            // Low-consumption tier
            if units <= 30 {
                energyCharge = units * 8.0
                fixedCharge = 150.0
            } else {
                energyCharge = (30 * 8.0) + ((units - 30) * 20.0)
                fixedCharge = 300.0
            }
        } else {
            // General domestic tier
            if units <= 90 {
                energyCharge = (60 * 16.0) + ((units - 60) * 25.0)
                fixedCharge = 400.0
            } else if units <= 180 {
                energyCharge = (60 * 16.0) + (30 * 25.0) + ((units - 90) * 45.0)
                fixedCharge = 1000.0
            } else {
                energyCharge = (60 * 16.0) + (30 * 25.0) + (90 * 45.0) + ((units - 180) * 65.0)
                fixedCharge = 1500.0
            }
        }
        let subtotal = energyCharge + fixedCharge
        let sscLevy = subtotal * 0.025 // 2.5% SSCL
        return subtotal + sscLevy
    }

    // MARK: - Public API

    /// Predicts next month's consumption and cost. Returns nil when there are no saved bills.
    public func predictNextMonth(
        bills: [SavedBill],
        appliances: [Appliance] = [],
        user: User? = nil,
        temperatureC: Double? = 31.0,
        humidityPercent: Double? = 75.0,
        occupants: Int = 3
    ) -> EnergyPrediction? {
        guard !bills.isEmpty else { return nil }

        // Phase 5: Read resolved occupants from user model or parameter
        let resolvedOccupants = max(1, user?.occupants ?? occupants)

        // Phase 5: Sort bills chronologically by actualBillingDate descending
        let sorted = bills.sorted { $0.actualBillingDate > $1.actualBillingDate }
        guard let latest = sorted.first else { return nil }

        let temp = temperatureC ?? 31.0
        let hum = humidityPercent ?? 75.0

        let historicalAvg = bills.map(\.totalKWh).reduce(0, +) / Double(bills.count)
        let applianceKWh = appliances.map(\.estimatedMonthlyKwh).reduce(0, +)
        let features = [historicalAvg, applianceKWh, temp, hum, Double(resolvedOccupants)]

        let mlValue = coreMLPredict(features)
        let kwh = max(1.0, mlValue ?? regressionPredict(features))

        // Phase 5: Calculate next-month cost using Sri Lankan CEB tiered tariff or effective rate
        let billAmount = latest.monthlyBill > 0 ? latest.monthlyBill : latest.totalAmount
        let userEffectiveRate = latest.totalKWh > 0 ? (billAmount / latest.totalKWh) : 0.0
        let raw = latest.currency.uppercased()
        let isLKR = (raw != "USD" && raw != "$")
        let currency = isLKR ? "Rs." : "$"

        let predictedCost: Double
        let effectiveRate: Double

        if isLKR {
            let cebEstimatedCost = Self.estimateCEBDomesticCost(kwh: kwh)
            if userEffectiveRate > 5.0 {
                // Calibrate with user's historical rate
                let userBasedCost = kwh * userEffectiveRate
                predictedCost = (cebEstimatedCost * 0.6) + (userBasedCost * 0.4)
                effectiveRate = kwh > 0 ? (predictedCost / kwh) : userEffectiveRate
            } else {
                predictedCost = cebEstimatedCost
                effectiveRate = kwh > 0 ? (predictedCost / kwh) : 25.0
            }
        } else {
            effectiveRate = userEffectiveRate > 0 ? userEffectiveRate : 0.22
            predictedCost = kwh * effectiveRate
        }

        let tempExcess = max(0.0, temp - 24.0)
        let humidityExcess = max(0.0, hum - 60.0)
        let cooling = min(40.0, max(0.0, tempExcess * 3.5 + humidityExcess * 0.2))

        return EnergyPrediction(
            predictedKWh: kwh,
            predictedCost: predictedCost,
            currency: currency,
            usedCoreML: mlValue != nil,
            billsAnalyzed: bills.count,
            historicalAvgKWh: historicalAvg,
            calibratedApplianceCount: appliances.count,
            applianceMonthlyKWh: applianceKWh,
            temperatureC: temp,
            humidityPercent: hum,
            occupants: resolvedOccupants,
            coolingLoadImpactPercent: cooling,
            effectiveRatePerKWh: effectiveRate
        )
    }
}
