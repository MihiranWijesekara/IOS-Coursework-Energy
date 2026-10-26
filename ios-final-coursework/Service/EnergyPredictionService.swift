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

public struct EnergyPrediction {
    public let predictedKWh: Double
    public let predictedCost: Double
    public let currency: String            // "Rs." or "$"
    public let usedCoreML: Bool
    public let billsAnalyzed: Int
    public let historicalAvgKWh: Double
    public let calibratedApplianceCount: Int
    public let applianceMonthlyKWh: Double
    public let temperatureC: Double
    public let humidityPercent: Double
    public let occupants: Int
    public let coolingLoadImpactPercent: Double
}

public final class EnergyPredictionService {
    public static let shared = EnergyPredictionService()
    private init() {}

    // MARK: - Core ML model

    private lazy var coreMLModel: MLModel? = {
        guard let url = Bundle.main.url(forResource: "EnergyBillPredictor", withExtension: "mlmodelc") else {
            return nil
        }
        return try? MLModel(contentsOf: url)
    }()

    // MARK: - Fallback regression (trained on the same 25-row dataset as the CSV)

    private static let trainingRows: [[Double]] = [
        // historicalAvgKWh, applianceMonthlyKWh, temperatureC, humidityPercent, occupants, nextMonthKWh
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

    /// Ridge-regularised least squares weights: [intercept, 5 feature weights]
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
        for i in 1..<n { xtx[i][i] += 0.01 }   // small ridge term for stability

        // Gauss-Jordan elimination with partial pivoting
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

    private func coreMLPredict(_ f: [Double]) -> Double? {
        guard let model = coreMLModel else { return nil }
        let input: [String: MLFeatureValue] = [
            "historicalAvgKWh": MLFeatureValue(double: f[0]),
            "applianceMonthlyKWh": MLFeatureValue(double: f[1]),
            "temperatureC": MLFeatureValue(double: f[2]),
            "humidityPercent": MLFeatureValue(double: f[3]),
            "occupants": MLFeatureValue(double: f[4])
        ]
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: input),
              let output = try? model.prediction(from: provider),
              let value = output.featureValue(for: "nextMonthKWh")?.doubleValue,
              value.isFinite, value > 0 else {
            return nil
        }
        return value
    }

    // MARK: - Public API

    /// Predicts next month's consumption and cost. Returns nil when there are no saved bills.
    public func predictNextMonth(
        bills: [SavedBill],
        appliances: [Appliance],
        user: User?,
        temperatureC: Double,
        humidityPercent: Double,
        occupants: Int = 3
    ) -> EnergyPrediction? {
        guard !bills.isEmpty else { return nil }

        let sorted = bills.sorted { $0.scannedDate > $1.scannedDate }
        guard let latest = sorted.first else { return nil }

        let historicalAvg = bills.map(\.totalKWh).reduce(0, +) / Double(bills.count)
        let applianceKWh = appliances.map(\.estimatedMonthlyKwh).reduce(0, +)
        let features = [historicalAvg, applianceKWh, temperatureC, humidityPercent, Double(occupants)]

        let mlValue = coreMLPredict(features)
        let kwh = max(1.0, mlValue ?? regressionPredict(features))

        // Effective tariff from the latest bill
        let billAmount = latest.monthlyBill > 0 ? latest.monthlyBill : latest.totalAmount
        let rate = latest.totalKWh > 0 ? billAmount / latest.totalKWh : 0
        let raw = latest.currency.uppercased()
        let currency = (raw == "USD" || raw == "$") ? "$" : "Rs."

        let tempExcess = max(0.0, temperatureC - 24.0)
        let humidityExcess = max(0.0, humidityPercent - 60.0)
        let cooling = min(40.0, max(0.0, tempExcess * 3.5 + humidityExcess * 0.2))

        return EnergyPrediction(
            predictedKWh: kwh,
            predictedCost: kwh * rate,
            currency: currency,
            usedCoreML: mlValue != nil,
            billsAnalyzed: bills.count,
            historicalAvgKWh: historicalAvg,
            calibratedApplianceCount: appliances.count,
            applianceMonthlyKWh: applianceKWh,
            temperatureC: temperatureC,
            humidityPercent: humidityPercent,
            occupants: occupants,
            coolingLoadImpactPercent: cooling
        )
    }
}
