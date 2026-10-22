//
//  ConsumptionBreakdownView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct ConsumptionBreakdownView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    
    // Computed calibrated values
    private var calibrationResult: (items: [CalibratedApplianceItem], totalKwh: Double, highest: CalibratedApplianceItem?) {
        let billKwh = savedBills.first?.consumptionKwh
        if !savedAppliances.isEmpty {
            let res = ApplianceCalibrationService.shared.calibrateAppliances(
                appliances: savedAppliances,
                targetBillKwh: billKwh
            )
            return (res.items, res.totalKwh, res.highestConsumer)
        } else {
            let total = billKwh ?? 180.0
            let items = ApplianceCalibrationService.defaultCalibratedItems(totalBillKwh: total)
            return (items, total, items.first)
        }
    }
    
    private var headerSubtitle: String {
        if let latest = savedBills.first {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return "\(formatter.string(from: latest.periodEnd)) · Total consumption"
        }
        return "August 2025 · Total consumption"
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
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Headings
                    Text("Consumption\nBreakdown")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                        .lineSpacing(2)
                    
                    // Header Total Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text(headerSubtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", calibrationResult.totalKwh))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Calibrated breakdown Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Calibrated breakdown")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Text(savedBills.isEmpty ? "Estimated" : "Bill calibrated")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.12, green: 0.50, blue: 0.32))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(EnergyLensTheme.mintHighlight)
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 2)
                        
                        // Dynamic breakdown rows
                        ForEach(calibrationResult.items) { item in
                            let kwhText = String(format: "%.1f kWh", item.calibratedKwh)
                            let percentText = "\(Int(round(item.percentage * 100)))%"
                            Button(action: {
                                navState.selectedAppliance = item.name
                                navState.selectedApplianceId = item.id
                                navState.navigate(to: .applianceDetail)
                            }) {
                                breakdownRow(
                                    name: item.name,
                                    value: "\(kwhText) · \(percentText)",
                                    percent: CGFloat(item.percentage),
                                    color: item.color
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Footnote
                    Text(savedBills.isEmpty ? "Estimates based on household appliances. Import a bill to calibrate." : "Estimates calibrated proportionally to match your \(String(format: "%.0f", calibrationResult.totalKwh)) kWh electricity bill.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Highest consumer details card
                    if let highest = calibrationResult.highest {
                        Button(action: {
                            navState.selectedAppliance = highest.name
                            navState.selectedApplianceId = highest.id
                            navState.navigate(to: .applianceDetail)
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: highest.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.42))
                                    .frame(width: 26)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(highest.name) details")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                    
                                    Text("Largest estimated contribution (\(Int(round(highest.percentage * 100)))%)")
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
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Manage Appliances Button
                    Button(action: {
                        navState.navigate(to: .appliances)
                    }) {
                        Text("Manage Appliances")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.42))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.88, green: 0.95, blue: 0.97))
                            .cornerRadius(14)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func breakdownRow(name: String, value: String, percent: CGFloat, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(geo.size.width * percent, 6), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 3)
    }
}
