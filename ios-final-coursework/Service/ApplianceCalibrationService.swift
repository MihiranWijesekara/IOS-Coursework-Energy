//
//  ApplianceCalibrationService.swift
//  ios-final-coursework
//
//  Created for calculating appliance consumption and calibrating against actual electricity bills
//

import Foundation
import SwiftUI
import SwiftData

public struct CalibratedApplianceItem: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var rawKwh: Double
    public var calibratedKwh: Double
    public var percentage: Double // 0.0 to 1.0 (e.g. 0.40 = 40%)
    public var icon: String
    public var color: Color
    
    public init(
        id: UUID = UUID(),
        name: String,
        rawKwh: Double,
        calibratedKwh: Double,
        percentage: Double,
        icon: String,
        color: Color
    ) {
        self.id = id
        self.name = name
        self.rawKwh = rawKwh
        self.calibratedKwh = calibratedKwh
        self.percentage = percentage
        self.icon = icon
        self.color = color
    }
}

public final class ApplianceCalibrationService {
    public static let shared = ApplianceCalibrationService()
    
    private init() {}
    
    /// Calibrates saved appliances against an electricity bill's total kWh.
    /// If actual bill kWh is provided (e.g. 78 kWh or 180 kWh), the raw appliance estimates
    /// are proportionally scaled to match the true meter reading.
    public func calibrateAppliances(
        appliances: [Appliance],
        targetBillKwh: Double?
    ) -> (items: [CalibratedApplianceItem], totalKwh: Double, highestConsumer: CalibratedApplianceItem?) {
        
        guard !appliances.isEmpty else {
            return ([], targetBillKwh ?? 0, nil)
        }
        
        // 1. Calculate uncalibrated theoretical kWh for each appliance
        let uncalibrated = appliances.map { app -> (appliance: Appliance, rawKwh: Double) in
            return (app, app.estimatedMonthlyKwh)
        }
        
        let sumRawKwh = uncalibrated.reduce(0.0) { $0 + $1.rawKwh }
        
        // 2. Determine target total: use bill kWh if available and valid (> 0), else theoretical sum
        let totalTarget = (targetBillKwh != nil && targetBillKwh! > 0) ? targetBillKwh! : max(sumRawKwh, 1.0)
        
        // 3. Compute calibrated values and percentages
        var resultItems: [CalibratedApplianceItem] = []
        
        for entry in uncalibrated {
            let app = entry.appliance
            let rawKwh = entry.rawKwh
            
            let proportion: Double
            if sumRawKwh > 0 {
                proportion = rawKwh / sumRawKwh
            } else {
                proportion = 1.0 / Double(appliances.count)
            }
            
            let calibratedKwh = proportion * totalTarget
            let icon = iconForCategory(app.category ?? app.name)
            let color = colorForIndex(resultItems.count)
            
            let item = CalibratedApplianceItem(
                id: app.id,
                name: app.name,
                rawKwh: rawKwh,
                calibratedKwh: calibratedKwh,
                percentage: proportion,
                icon: icon,
                color: color
            )
            resultItems.append(item)
        }
        
        // 4. Sort descending by highest consumption
        resultItems.sort { $0.calibratedKwh > $1.calibratedKwh }
        
        let highest = resultItems.first
        return (resultItems, totalTarget, highest)
    }
    
    /// Fallback default calibrated profiles matching coursework specifications when no custom appliances exist
    public static func defaultCalibratedItems(totalBillKwh: Double = 180.0) -> [CalibratedApplianceItem] {
        return [
            CalibratedApplianceItem(name: "Air Conditioner", rawKwh: 72, calibratedKwh: totalBillKwh * 0.40, percentage: 0.40, icon: "air.conditioner.horizontal", color: Color(red: 0.12, green: 0.55, blue: 0.32)),
            CalibratedApplianceItem(name: "Refrigerator", rawKwh: 45, calibratedKwh: totalBillKwh * 0.25, percentage: 0.25, icon: "refrigerator", color: Color(red: 0.95, green: 0.60, blue: 0.10)),
            CalibratedApplianceItem(name: "Fans", rawKwh: 21.6, calibratedKwh: totalBillKwh * 0.12, percentage: 0.12, icon: "fanblades", color: Color(red: 0.55, green: 0.35, blue: 0.85)),
            CalibratedApplianceItem(name: "Lights", rawKwh: 14.4, calibratedKwh: totalBillKwh * 0.08, percentage: 0.08, icon: "lightbulb", color: Color(red: 0.90, green: 0.30, blue: 0.55)),
            CalibratedApplianceItem(name: "Others", rawKwh: 14.4, calibratedKwh: totalBillKwh * 0.08, percentage: 0.08, icon: "powerplug", color: Color(red: 0.25, green: 0.50, blue: 0.90)),
            CalibratedApplianceItem(name: "TV", rawKwh: 12.6, calibratedKwh: totalBillKwh * 0.07, percentage: 0.07, icon: "tv", color: Color(red: 0.95, green: 0.45, blue: 0.20))
        ]
    }
    
    /// Calibrate a single appliance against the current household profile and bill
    public func calibrateSingleAppliance(
        appliance: Appliance,
        allAppliances: [Appliance],
        targetBillKwh: Double?
    ) -> CalibratedApplianceItem {
        let (items, totalKwh, _) = calibrateAppliances(appliances: allAppliances, targetBillKwh: targetBillKwh)
        if let match = items.first(where: { $0.id == appliance.id || $0.name.lowercased() == appliance.name.lowercased() }) {
            return match
        }
        
        // Fallback if not found in list
        let raw = appliance.estimatedMonthlyKwh
        let total = targetBillKwh ?? 180.0
        let prop = min(1.0, max(0.05, raw / max(total, 1.0)))
        return CalibratedApplianceItem(
            id: appliance.id,
            name: appliance.name,
            rawKwh: raw,
            calibratedKwh: prop * total,
            percentage: prop,
            icon: iconForCategory(appliance.category ?? appliance.name),
            color: Color(red: 0.12, green: 0.55, blue: 0.32)
        )
    }
    
    /// Estimated tariff rate per kWh in LKR.
    /// Uses actual imported bill rate (e.g. 7850 / 180 = ~43.6 LKR/kWh) or standard CEB domestic rate (~43.75 LKR/kWh).
    public func effectiveTariffRate(bill: ElectricityBill?) -> Double {
        if let b = bill, b.consumptionKwh > 0, b.billAmount > 0 {
            return b.billAmount / b.consumptionKwh
        }
        return 43.75 // Standard CEB domestic tier average rate
    }
    
    /// Estimate monthly expenditure in LKR for an appliance's calibrated kWh
    public func estimateMonthlyCost(calibratedKwh: Double, bill: ElectricityBill?) -> Double {
        return calibratedKwh * effectiveTariffRate(bill: bill)
    }

    public func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "cooling", "air conditioner", "ac": return "air.conditioner.horizontal"
        case "refrigeration", "fridge", "refrigerator": return "refrigerator"
        case "ventilation", "fan", "fans": return "fanblades"
        case "entertainment", "tv", "television": return "tv"
        case "cleaning", "washing machine": return "sparkles"
        case "lighting", "light", "lights": return "lightbulb"
        case "cooking", "microwave", "oven", "stove": return "stove"
        default: return "powerplug"
        }
    }
    
    public func colorForIndex(_ index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.12, green: 0.55, blue: 0.32), // Emerald Green
            Color(red: 0.95, green: 0.60, blue: 0.10), // Warm Orange
            Color(red: 0.55, green: 0.35, blue: 0.85), // Purple
            Color(red: 0.90, green: 0.30, blue: 0.55), // Rose
            Color(red: 0.25, green: 0.50, blue: 0.90), // Ocean Blue
            Color(red: 0.95, green: 0.45, blue: 0.20), // Amber
            Color(red: 0.15, green: 0.65, blue: 0.60)  // Teal
        ]
        return palette[index % palette.count]
    }
}
