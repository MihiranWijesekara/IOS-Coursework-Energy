//
//  AddScenarioModalView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct AddScenarioModalView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    
    @State private var selectedAppliance: String = "Air Conditioner"
    @State private var savingAdjustment: String = "Reduce hours per day"
    @State private var newUsageHours: Double = 4.0
    
    let appliances = ["Air Conditioner", "Refrigerator", "Fan", "TV", "Washing Machine"]
    let adjustments = ["Reduce hours per day", "Turn off on peak hours", "Upgrade to Inverter"]
    
    public init() {}
    
    private var currencySymbol: String {
        let raw = pdfSavedBills.first?.currency ?? savedBills.first?.currency ?? "LKR"
        return (raw.uppercased() == "USD" || raw == "$") ? "$" : "Rs."
    }
    
    private var effectiveTariffRate: Double {
        if let latestBill = pdfSavedBills.first, latestBill.totalKWh > 0 {
            let monthly = (latestBill.hasMonthlyBillValue && latestBill.monthlyBill > 0) ? latestBill.monthlyBill : latestBill.totalAmount
            if monthly > 0 {
                return monthly / latestBill.totalKWh
            }
        }
        if let bill = savedBills.first, bill.consumptionKwh > 0, bill.billAmount > 0 {
            return bill.billAmount / bill.consumptionKwh
        }
        return currencySymbol == "$" ? 0.288 : 30.0
    }
    
    public var body: some View {
        ZStack {
            // Dark Teal / Deep Forest dim backdrop
            Color(red: 0.08, green: 0.22, blue: 0.22)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Bottom Sheet Container
                VStack(spacing: 16) {
                    // Grabber handle
                    Capsule()
                        .fill(Color(red: 0.85, green: 0.88, blue: 0.90))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)
                    
                    // Header Bar (Navy capsule buttons)
                    HStack {
                        Button(action: {
                            navState.navigate(to: .savingsSimulator)
                        }) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.08, green: 0.22, blue: 0.35))
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Text("Add Scenario")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            navState.selectedAppliance = selectedAppliance
                            navState.simulationHours = newUsageHours
                            
                            let kwhSaved = max(0.0, (navState.currentAcHours - newUsageHours) * 12.0)
                            let dollarSavedPerMonth = kwhSaved * effectiveTariffRate
                            
                            // Save scenario record into SwiftData
                            let scenario = SavingsScenario(
                                scenarioTitle: savingAdjustment,
                                applianceName: selectedAppliance,
                                adjustmentType: savingAdjustment,
                                originalHoursPerDay: navState.currentAcHours,
                                targetHoursPerDay: newUsageHours,
                                estimatedKwhSaved: kwhSaved,
                                estimatedLkrSaved: dollarSavedPerMonth
                            )
                            modelContext.insert(scenario)
                            try? modelContext.save()
                            
                            navState.navigate(to: .savingsSimulator)
                        }) {
                            Text("Done")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.08, green: 0.22, blue: 0.35))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    Text("Choose an appliance and adjust its daily usage.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    // Form Card (Dropdowns)
                    VStack(alignment: .leading, spacing: 14) {
                        // Appliance dropdown
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Appliance")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            let availableList = savedAppliances.isEmpty ? appliances : savedAppliances.map { $0.name }
                            Menu {
                                ForEach(availableList, id: \.self) { app in
                                    Button(app) { selectedAppliance = app }
                                }
                            } label: {
                                HStack {
                                    Text(selectedAppliance)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                }
                            }
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Saving adjustment dropdown
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Saving adjustment")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Menu {
                                ForEach(adjustments, id: \.self) { adj in
                                    Button(adj) { savingAdjustment = adj }
                                }
                            } label: {
                                HStack {
                                    Text(savingAdjustment)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Blue Card: New usage
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New usage")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        // Stepper row
                        HStack {
                            Button(action: {
                                if newUsageHours > 0 { newUsageHours -= 1 }
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(newUsageHours)) h/day")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                if newUsageHours < 12 { newUsageHours += 1 }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Slider
                        Slider(value: $newUsageHours, in: 0...12, step: 1)
                            .tint(EnergyLensTheme.accentGreen)
                            .padding(.top, 4)
                        
                        HStack {
                            Text("0 h")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text("12 h")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        // Footnote
                        Text("Current usage · \(String(format: "%.0f", navState.currentAcHours)) h/day. Savings calculated at \(currencySymbol) \(String(format: "%.2f", effectiveTariffRate))/kWh based on your bill.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                            .padding(.top, 4)
                    }
                    .padding(18)
                    .background(Color(red: 0.85, green: 0.94, blue: 0.99))
                    .cornerRadius(18)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
                .background(Color(red: 0.97, green: 0.97, blue: 0.99))
                .cornerRadius(24)
            }
        }
    }
}
