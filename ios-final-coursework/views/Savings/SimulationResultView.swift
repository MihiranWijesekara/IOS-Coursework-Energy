//
//  SimulationResultView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//


import SwiftUI
import SwiftData

public struct SimulationResultView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    
    // Active simulated appliance
    private var activeAppliance: Appliance? {
        if let id = navState.selectedApplianceId {
            return savedAppliances.first(where: { $0.id == id })
        }
        return savedAppliances.first(where: { $0.name.lowercased() == navState.selectedAppliance.lowercased() })
    }
    
    private var baselineHours: Double {
        return activeAppliance?.hoursPerDay ?? navState.currentAcHours
    }
    
    private var simulatedHours: Double {
        return navState.simulationHours
    }
    
    private var metrics: (savedKwh: Double, savedLkr: Double, beforeKwh: Double, afterKwh: Double, appName: String, monthName: String) {
        let latestBill = savedBills.first
        let billKwh = latestBill?.consumptionKwh ?? 180.0
        let tariffRate = ApplianceCalibrationService.shared.effectiveTariffRate(bill: latestBill)
        
        let beforeKwh: Double
        if let app = activeAppliance {
            let item = ApplianceCalibrationService.shared.calibrateSingleAppliance(
                appliance: app,
                allAppliances: savedAppliances,
                targetBillKwh: billKwh
            )
            beforeKwh = item.calibratedKwh
        } else {
            beforeKwh = billKwh * 0.40
        }
        
        let safeBaseHours = max(baselineHours, 1.0)
        let kwhPerHour = beforeKwh / safeBaseHours
        let afterKwh = kwhPerHour * simulatedHours
        let savedKwh = max(0.0, beforeKwh - afterKwh)
        let savedLkr = savedKwh * tariffRate
        
        let name = activeAppliance?.name ?? navState.selectedAppliance
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let month = latestBill != nil ? monthFormatter.string(from: latestBill!.periodEnd) : "August"
        
        return (savedKwh, savedLkr, beforeKwh, afterKwh, name, month)
    }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Savings") {
                navState.navigate(to: .savingsSimulator)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Title
                    Text("Simulation Result")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // You can save badge
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(EnergyLensTheme.accentGreen)
                        
                        Text("You can save")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.12, green: 0.45, blue: 0.28))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.88, green: 0.96, blue: 0.90))
                    .clipShape(Capsule())
                    
                    // Main Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Estimated monthly saving")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", metrics.savedKwh))
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh/month")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(String(format: "≈ LKR %.0f/month", metrics.savedLkr))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Comparison Card (Active Appliance)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(metrics.appName)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        // Before
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Before · \(String(format: "%.0f", baselineHours)) h/day")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                Spacer()
                                Text(String(format: "%.0f kWh", metrics.beforeKwh))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            
                            // Dark bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(EnergyLensTheme.darkNavyCard)
                                .frame(height: 6)
                        }
                        
                        // After
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("After · \(String(format: "%.0f", simulatedHours)) h/day")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                Spacer()
                                Text(String(format: "%.0f kWh", metrics.afterKwh))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            
                            // Green bar proportional to before
                            let ratio = metrics.beforeKwh > 0 ? CGFloat(metrics.afterKwh / metrics.beforeKwh) : 0.66
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.90, green: 0.92, blue: 0.95))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(EnergyLensTheme.accentGreen)
                                        .frame(width: max(geo.size.width * min(1.0, ratio), 6), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Saving row
                        HStack {
                            Text("Saving")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.0f kWh/month", metrics.savedKwh))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.92, green: 0.96, blue: 0.98))
                    .cornerRadius(18)
                    
                    // Footnote
                    Text("A calibrated scenario based on your \(metrics.monthName) bill. Actual savings depend on settings, weather and usage.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    Spacer(minLength: 30)
                    
                    // Try Another Scenario Button
                    GradientButton(title: "Try Another Scenario") {
                        navState.navigate(to: .savingsSimulator)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
