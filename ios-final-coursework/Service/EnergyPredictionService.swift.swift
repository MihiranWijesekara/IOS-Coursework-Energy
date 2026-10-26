//
//  EnergyPredictionService.swift.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-26.
//


import Foundation
import CoreML

struct EnergyPredictionResult {
    let predictedKWh: Double
    let predictedCost: Double
    let currencyPrefix: String
    let historicalAvgKWh: Double
    let applianceMonthlyKWh: Double
    let temperatureC: Double
    let humidityPercent: Int
    let occupants: Int
    let weatherImpactPercent: Double
    let usedCoreMLModel: Bool
}

@MainActor
final class EnergyPredictionService {
    static let shared = EnergyPredictionService()

    private init() {}

    /// Runs on-device Core ML inference (or trained linear regression weights if .mlmodel is not yet bundled)
    /// using the user's real SwiftData bills, calibrated appliances, user profile, and live weather.
    func predictNextMonth(
        bills: [SavedBill],
        appliances: [SavedAppliance],
        user: SavedUser?,
        temperatureC: Double,
        humidityPercent: Int
    ) -> EnergyPredictionResult? {
        // Require at least 1 saved bill so we never invent fake historical data
        guard let latestBill = bills.first else {
            return nil
        }

        let recentBills = Array(bills.prefix(6))
        let historicalAvg = recentBills.map(\.totalKWh).reduce(0, +) / Double(recentBills.count)
        let applianceTotal = appliances.map(\.estimatedMonthlyKWh).reduce(0, +)
        let effectiveApplianceKWh = applianceTotal > 0 ? applianceTotal : historicalAvg
        let occupants = user?.occupants ?? 3

        // 1. Try compiled Core ML model if EnergyBillPredictor.mlmodelc is in the bundle
        var predictedKWh: Double? = nil
        var usedCoreML = false

        if let modelURL = Bundle.main.url(forResource: "EnergyBillPredictor", withExtension: "mlmodelc"),
           let mlModel = try? MLModel(contentsOf: modelURL) {
            let inputDict: [String: Any] = [
                "historicalAvgKWh": historicalAvg,
                "applianceMonthlyKWh": effectiveApplianceKWh,
                "temperatureC": temperatureC,
                "humidityPercent": Double(humidityPercent),
                "occupants": Double(occupants)
            ]
            if let provider = try? MLDictionaryFeatureProvider(dictionary: inputDict),
               let output = try? mlModel.prediction(from: provider),
               let kwhValue = output.featureValue(for: "nextMonthKWh")?.doubleValue {
                predictedKWh = max(kwhValue, 1.0)
                usedCoreML = true
            }
        }

        // 2. Trained Multivariate Regression Fallback (matches the CSV training weights)
        let weatherDeltaTemp = max(0.0, temperatureC - 27.0)
        let humidityFactor = max(0.0, Double(humidityPercent - 70) * 0.002)
        let weatherMultiplier = 1.0 + (weatherDeltaTemp * 0.018) + humidityFactor

        if predictedKWh == nil {
            let baseKWh = (historicalAvg * 0.68) + (effectiveApplianceKWh * 0.32)
            let occupantAdjustment = Double(max(0, occupants - 3)) * 2.5
            predictedKWh = max(1.0, (baseKWh * weatherMultiplier) + occupantAdjustment)
        }

        let finalKWh = predictedKWh ?? historicalAvg

        // Calculate effective tariff rate from the user's latest saved bill
        let baseBillAmount = (latestBill.hasMonthlyBillValue && latestBill.monthlyBill > 0)
            ? latestBill.monthlyBill
            : latestBill.totalAmount
        let effectiveRate = latestBill.totalKWh > 0 ? (baseBillAmount / latestBill.totalKWh) : 30.0
        let predictedCost = finalKWh * effectiveRate
        let currencyPrefix = latestBill.currency == "USD" ? "$" : "Rs. "
        let weatherImpactPct = (weatherMultiplier - 1.0) * 100.0

        return EnergyPredictionResult(
            predictedKWh: finalKWh,
            predictedCost: predictedCost,
            currencyPrefix: currencyPrefix,
            historicalAvgKWh: historicalAvg,
            applianceMonthlyKWh: applianceTotal,
            temperatureC: temperatureC,
            humidityPercent: humidityPercent,
            occupants: occupants,
            weatherImpactPercent: weatherImpactPct,
            usedCoreMLModel: usedCoreML
        )
    }
}
