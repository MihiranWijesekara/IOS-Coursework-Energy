//
//  WidgetDataStore.swift
//  ios-final-coursework
//
//  Shared App Group & Standard UserDefaults Store for WidgetKit Home Screen Widgets.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Widget Snapshot Model
public struct EnergyWidgetSnapshot: Codable, Equatable, Sendable {
    public var billingMonth: String
    public var currentKWh: Double
    public var currentBillAmount: Double
    public var currency: String
    public var predictedNextKWh: Double
    public var predictedNextCost: Double
    public var usedCoreML: Bool
    public var town: String
    public var temperatureC: Double
    public var updatedAt: Date

    public init(
        billingMonth: String = "SEPTEMBER 2026",
        currentKWh: Double = 78.0,
        currentBillAmount: Double = 1628.72,
        currency: String = "Rs.",
        predictedNextKWh: Double = 115.0,
        predictedNextCost: Double = 2405.0,
        usedCoreML: Bool = true,
        town: String = "Colombo",
        temperatureC: Double = 31.0,
        updatedAt: Date = Date()
    ) {
        self.billingMonth = billingMonth
        self.currentKWh = currentKWh
        self.currentBillAmount = currentBillAmount
        self.currency = currency
        self.predictedNextKWh = predictedNextKWh
        self.predictedNextCost = predictedNextCost
        self.usedCoreML = usedCoreML
        self.town = town
        self.temperatureC = temperatureC
        self.updatedAt = updatedAt
    }

    public static let sample = EnergyWidgetSnapshot(
        billingMonth: "SEPTEMBER 2026",
        currentKWh: 78.0,
        currentBillAmount: 1628.72,
        currency: "Rs.",
        predictedNextKWh: 115.0,
        predictedNextCost: 2405.0,
        usedCoreML: true,
        town: "Colombo",
        temperatureC: 31.0,
        updatedAt: Date()
    )
}

// MARK: - Widget Data Store
public final class WidgetDataStore: @unchecked Sendable {
    public static let shared = WidgetDataStore()
    public static let appGroupID = "group.Achintha.ios-final-coursework"
    private static let snapshotKey = "energy_lens_widget_snapshot"

    private init() {}

    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }

    public func saveSnapshot(_ snapshot: EnergyWidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            // 1. Write to App Group container for Widget Extension
            appGroupDefaults?.set(data, forKey: Self.snapshotKey)
            // 2. Mirror to standard UserDefaults so it works in Simulator without paid provisioning
            UserDefaults.standard.set(data, forKey: Self.snapshotKey)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    public func loadSnapshot() -> EnergyWidgetSnapshot {
        // Priority 1: App Group
        if let data = appGroupDefaults?.data(forKey: Self.snapshotKey),
           let snapshot = try? JSONDecoder().decode(EnergyWidgetSnapshot.self, from: data) {
            return snapshot
        }
        // Priority 2: Standard defaults (Simulator fallback)
        if let data = UserDefaults.standard.data(forKey: Self.snapshotKey),
           let snapshot = try? JSONDecoder().decode(EnergyWidgetSnapshot.self, from: data) {
            return snapshot
        }
        // Priority 3: Built-in coursework sample
        return .sample
    }

    /// Convenience method to sync latest snapshot from SwiftData models and prediction engine
    public func syncFrom(
        bills: [SavedBill],
        appliances: [Appliance] = [],
        user: User? = nil,
        temperatureC: Double? = nil,
        humidityPercent: Double? = nil
    ) {
        let latestBill = bills.sorted { $0.actualBillingDate > $1.actualBillingDate }.first
        let prediction = EnergyPredictionService.shared.predictNextMonth(
            bills: bills,
            appliances: appliances,
            user: user,
            temperatureC: temperatureC,
            humidityPercent: humidityPercent
        )

        let month: String
        if let b = latestBill, !b.billingMonth.isEmpty {
            month = b.billingMonth.uppercased()
        } else {
            month = "SEPTEMBER 2026"
        }

        let kwh = latestBill?.totalKWh ?? 78.0
        let amount: Double
        if let b = latestBill {
            amount = b.monthlyBill > 0 ? b.monthlyBill : b.totalAmount
        } else {
            amount = 1628.72
        }

        let cur = (latestBill?.currency.uppercased() == "USD" || latestBill?.currency == "$") ? "$" : (prediction?.currency ?? "Rs.")
        let nextKWh = prediction?.predictedKWh ?? 115.0
        let nextCost = prediction?.predictedCost ?? 2405.0
        let coreML = prediction?.usedCoreML ?? true
        let userTown = user?.town ?? "Colombo"
        let temp = temperatureC ?? 31.0

        let snapshot = EnergyWidgetSnapshot(
            billingMonth: month,
            currentKWh: kwh,
            currentBillAmount: amount,
            currency: cur,
            predictedNextKWh: nextKWh,
            predictedNextCost: nextCost,
            usedCoreML: coreML,
            town: userTown,
            temperatureC: temp,
            updatedAt: Date()
        )
        saveSnapshot(snapshot)
    }
}
