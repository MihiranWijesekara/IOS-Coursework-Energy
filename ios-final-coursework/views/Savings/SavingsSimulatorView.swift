//
//  SavingsSimulatorView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct SavingsSimulatorView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    @Query(sort: \SavingsScenario.createdAt, order: .reverse) private var savedScenarios: [SavingsScenario]
    
    @State private var dailyHours: Double = 4.0
    
    private var currencySymbol: String {
        let raw = pdfSavedBills.first?.currency ?? savedBills.first?.currency ?? "LKR"
        return (raw.uppercased() == "USD" || raw == "$") ? "$" : "Rs."
    }
    
    private var effectiveTariffRate: Double {
        if let pdf = pdfSavedBills.first, pdf.totalKWh > 0, pdf.totalAmount > 0 {
            return pdf.totalAmount / pdf.totalKWh
        }
        if let bill = savedBills.first, bill.consumptionKwh > 0, bill.billAmount > 0 {
            return bill.billAmount / bill.consumptionKwh
        }
        return currencySymbol == "$" ? 0.288 : 30.0
    }
    
    // Active simulated appliance
    private var activeAppliance: Appliance? {
        if let id = navState.selectedApplianceID ?? navState.selectedApplianceId {
            return savedAppliances.first(where: { $0.id == id })
        }
        return savedAppliances.first(where: { $0.name.lowercased() == navState.selectedAppliance.lowercased() })
    }
    
    private var baselineHours: Double {
        return activeAppliance?.hoursPerDay ?? navState.currentAcHours
    }
    
    private var simulationMetrics: (kwhSaved: Double, lkrSaved: Double, oldKwh: Double, newKwh: Double) {
        let billKwh = pdfSavedBills.first?.totalKWh ?? savedBills.first?.consumptionKwh ?? savedAppliances.reduce(0.0) { $0 + $1.estimatedMonthlyKwh }
        
        let oldCalibratedKwh: Double
        if let app = activeAppliance {
            let item = ApplianceCalibrationService.shared.calibrateSingleAppliance(
                appliance: app,
                allAppliances: savedAppliances,
                targetBillKwh: billKwh
            )
            oldCalibratedKwh = item.calibratedKwh
        } else {
            // Default 40% of 180 = 72 kWh
            oldCalibratedKwh = billKwh * 0.40
        }
        
        let safeBaseHours = max(baselineHours, 1.0)
        let kwhPerHour = oldCalibratedKwh / safeBaseHours
        let newCalibratedKwh = kwhPerHour * dailyHours
        let savedKwh = max(0.0, oldCalibratedKwh - newCalibratedKwh)
        let savedCost = savedKwh * effectiveTariffRate
        
        return (savedKwh, savedCost, oldCalibratedKwh, newCalibratedKwh)
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Top Bar
                    Text("ENERGYLENS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .tracking(0.8)
                        .padding(.top, 12)
                    
                    // Headings
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Savings")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Energy Saving Simulator")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Explore how small changes can reduce your\nenergy use.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                    }
                    
                    // Selected Appliance Row (Tapping opens appliance list)
                    Button(action: {
                        navState.navigate(to: .appliances)
                    }) {
                        HStack(spacing: 14) {
                            let appName = activeAppliance?.name ?? navState.selectedAppliance
                            let iconName = ApplianceCalibrationService.shared.iconForCategory(activeAppliance?.category ?? appName)
                            Image(systemName: iconName)
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.45))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Current · \(String(format: "%.0f", baselineHours)) h/day")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // New Daily Usage Controls Card
                    VStack(spacing: 12) {
                        Text("NEW DAILY USAGE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .tracking(0.6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Stepper row
                        HStack {
                            Button(action: {
                                if dailyHours > 0 { dailyHours -= 1 }
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                                    .frame(width: 44, height: 44)
                                    .background(Color(red: 0.94, green: 0.96, blue: 0.98))
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(dailyHours)) h/day")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                if dailyHours < 24 { dailyHours += 1 }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                                    .frame(width: 44, height: 44)
                                    .background(Color(red: 0.94, green: 0.96, blue: 0.98))
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Slider
                        Slider(value: $dailyHours, in: 0...max(12, baselineHours + 2), step: 1)
                            .tint(EnergyLensTheme.accentGreen)
                            .padding(.top, 4)
                        
                        HStack {
                            Text("0 h")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text("\(Int(max(12, baselineHours + 2))) h")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Result Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Estimated monthly saving")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", simulationMetrics.kwhSaved))
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh/month")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(String(format: "≈ \(currencySymbol) %.0f/month", simulationMetrics.lkrSaved))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        let targetName = activeAppliance?.name ?? navState.selectedAppliance
                        Text("Calibrated \(targetName) contribution: \(Int(round(simulationMetrics.oldKwh))) → \(Int(round(simulationMetrics.newKwh))) kWh. Estimates use your bill and profile, not nameplate power × hours.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Saved Scenarios Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Saved Scenarios")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(savedScenarios.count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(EnergyLensTheme.mintHighlight)
                                .clipShape(Capsule())
                        }
                        
                        if savedScenarios.isEmpty {
                            // Clean Empty State
                            VStack(spacing: 12) {
                                Image(systemName: "lightbulb.slash")
                                    .font(.system(size: 32))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                    .padding(.top, 8)
                                
                                Text("No Saved Scenarios")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Tap 'Add Scenario' below to model custom appliance reductions and calculate your monthly bill savings.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                            )
                        } else {
                            ForEach(savedScenarios) { scenario in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scenario.scenarioTitle)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(EnergyLensTheme.textPrimary)
                                        
                                        Text("\(scenario.applianceName) · \(String(format: "%.0f", scenario.originalHoursPerDay))h → \(String(format: "%.0f", scenario.targetHoursPerDay))h/day")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(EnergyLensTheme.textSecondary)
                                        
                                        Text("Save \(String(format: "%.0f", scenario.estimatedKwhSaved)) kWh · ≈ \(currencySymbol) \(String(format: "%.0f", scenario.estimatedLkrSaved))/mo")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(EnergyLensTheme.accentGreen)
                                    }
                                    
                                    Spacer()
                                    
                                    // Delete Scenario Button
                                    Button(action: {
                                        withAnimation {
                                            modelContext.delete(scenario)
                                            try? modelContext.save()
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color.red.opacity(0.8))
                                            .frame(width: 36, height: 36)
                                            .background(Color.red.opacity(0.08))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.top, 4)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        GradientButton(title: "Run Simulation") {
                            navState.simulationHours = dailyHours
                            navState.navigate(to: .simulationResult)
                        }
                        
                        Button(action: {
                            navState.navigate(to: .addScenarioModal)
                        }) {
                            Text("Add Scenario")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.42))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.88, green: 0.95, blue: 0.97))
                                .cornerRadius(14)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            
            // Bottom Tab Bar
            CustomTabBar(selectedTab: $navState.selectedTab) { tab in
                switch tab {
                case .home:
                    navState.navigate(to: .home)
                case .analysis:
                    navState.navigate(to: .analysis)
                case .savings:
                    navState.navigate(to: .savingsSimulator)
                case .profile:
                    navState.navigate(to: .profile)
                }
            }
        }
        .background(EnergyLensTheme.screenBackground.ignoresSafeArea())
        .onAppear {
            if navState.simulationHours > 0 {
                dailyHours = navState.simulationHours
            }
        }
    }
}
