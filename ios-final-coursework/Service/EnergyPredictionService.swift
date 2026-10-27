//
//  EnergyPredictionService.swift
//  ios-final-coursework
//
//  Next-month kWh / bill prediction. Uses the on-device Core ML model
//  (EnergyBillPredictor.mlmodelc / EnergyBillPredictor.mlmodel).
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
        let candidateNames = ["EnergyBillPredictor", "EnergyBillPredictor 1", "EnergyBillPredictor_1"]
        for name in candidateNames {
            if let compiledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc"),
               let model = try? MLModel(contentsOf: compiledURL) {
                return model
            }
        }
        for name in candidateNames {
            if let sourceURL = Bundle.main.url(forResource: name, withExtension: "mlmodel"),
               let compiledURL = try? MLModel.compileModel(at: sourceURL),
               let model = try? MLModel(contentsOf: compiledURL) {
                return model
            }
        }
        return nil
    }()

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

        guard let mlValue = coreMLPredict(features) else {
            return nil
        }
        let kwh = max(1.0, mlValue)

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
            usedCoreML: true,
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
