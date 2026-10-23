//
//  SolarAnalysisView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct SolarAnalysisView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    
    private var hasBills: Bool {
        !savedBills.isEmpty || !pdfSavedBills.isEmpty
    }
    
    private var consumption: Double {
        pdfSavedBills.first?.totalKWh ?? savedBills.first?.consumptionKwh ?? 0.0
    }
    
    private var billAmount: Double {
        pdfSavedBills.first?.totalAmount ?? savedBills.first?.totalAmountPayable ?? 0.0
    }
    
    private var currencySymbol: String {
        let raw = pdfSavedBills.first?.currency ?? savedBills.first?.currency ?? "LKR"
        return (raw.uppercased() == "USD" || raw == "$") ? "$" : "Rs."
    }
    
    private var solarGen: Double {
        max(1.0, round(consumption * 0.33))
    }
    
    private var remainingGrid: Double {
        max(0.0, consumption - solarGen)
    }
    
    private var estimatedSavings: Double {
        guard consumption > 0 else { return 0.0 }
        return round((solarGen / consumption) * billAmount)
    }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Analysis") {
                navState.navigate(to: .analysis)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            if !hasBills {
                emptyStateView
            } else {
                contentScrollView
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    private var emptyStateView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Solar Analysis")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    Text("Explore Solar generation scenario")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                }
                
                VStack(spacing: 16) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.15))
                        .padding(.top, 16)
                    
                    Text("No Bills Imported Yet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    Text("Import an electricity bill to calculate realistic rooftop solar generation offsets and projected grid bill savings for your household.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                )
                
                GradientButton(title: "Import Electricity Bill") {
                    navState.navigate(to: .selectBillImage)
                }
                .padding(.top, 12)
                
                Spacer(minLength: 30)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var contentScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Headings
                VStack(alignment: .leading, spacing: 4) {
                    Text("Solar Analysis")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    Text("Explore Solar generation scenario")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                }
                
                // Yellow Example Scenario Banner
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.10))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Example scenario")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.05))
                        
                        Text("Explore a household consumption offset based on your latest bill, not a commercial solar quote.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.60, green: 0.38, blue: 0.10))
                            .lineSpacing(2)
                    }
                }
                .padding(16)
                .background(EnergyLensTheme.alertYellowBg)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(EnergyLensTheme.alertYellowBorder, lineWidth: 1)
                )
                
                // Input Card
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly household consumption")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        
                        Text(String(format: "%.0f kWh", consumption))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                    }
                    
                    Divider()
                        .background(EnergyLensTheme.fieldBorder)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example solar generation (33% offset)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        
                        Text(String(format: "%.0f kWh/month", solarGen))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                )
                
                // Dark Navy Highlight Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Example remaining grid consumption")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f", remainingGrid))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("kWh")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(String(format: "%.0f", consumption)) kWh consumption − \(String(format: "%.0f", solarGen)) kWh example generation")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                    
                    if estimatedSavings > 0 {
                        Text("Projected bill reduction: ~\(currencySymbol) \(String(format: "%.0f", estimatedSavings)) / month")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(EnergyLensTheme.darkNavyCard)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                
                // Section: Consumption offset
                Text("Consumption offset")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.top, 4)
                
                // Consumption offset visual card
                VStack(alignment: .leading, spacing: 14) {
                    // Household
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Household consumption")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            Spacer()
                            Text(String(format: "%.0f kWh", consumption))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(EnergyLensTheme.darkNavyCard)
                            .frame(height: 6)
                    }
                    
                    // Solar offset
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Example solar offset")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            Spacer()
                            Text(String(format: "%.0f kWh (33%%)", solarGen))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.90, green: 0.92, blue: 0.95))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.92, green: 0.58, blue: 0.15))
                                    .frame(width: max(geo.size.width * 0.33, 6), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                )
                
                // Footnote
                Text("Illustrative energy offset only based on your real saved bills. No grid export feed-in tariff, installation cost, or battery storage return is guaranteed.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                    .lineSpacing(2)
                    .padding(.top, 2)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}
