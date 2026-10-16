//
//  ConsumptionBreakdownView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ConsumptionBreakdownView: View {
    @EnvironmentObject var navState: AppNavigationState
    
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
                        Text("August 2025 · Total consumption")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("180")
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
                            
                            Text("Bill calibrated")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.12, green: 0.50, blue: 0.32))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(EnergyLensTheme.mintHighlight)
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 2)
                        
                        // Breakdown rows
                        breakdownRow(name: "Air Conditioner", value: "72 kWh · 40%", percent: 0.40, color: Color(red: 0.12, green: 0.55, blue: 0.32))
                        breakdownRow(name: "Refrigerator", value: "45 kWh · 25%", percent: 0.25, color: Color(red: 0.95, green: 0.60, blue: 0.10))
                        breakdownRow(name: "Fans", value: "21.6 kWh · 12%", percent: 0.12, color: Color(red: 0.55, green: 0.35, blue: 0.85))
                        breakdownRow(name: "Lights", value: "14.4 kWh · 8%", percent: 0.08, color: Color(red: 0.90, green: 0.30, blue: 0.55))
                        breakdownRow(name: "Others", value: "14.4 kWh · 8%", percent: 0.08, color: Color(red: 0.25, green: 0.50, blue: 0.90))
                        breakdownRow(name: "TV", value: "12.6 kWh · 7%", percent: 0.07, color: Color(red: 0.95, green: 0.45, blue: 0.20))
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Footnote
                    Text("Estimates calibrated to your bill and appliance profiles. Not measured live data.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Air Conditioner details card
                    Button(action: {
                        navState.navigate(to: .applianceDetail)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "air.conditioner.horizontal")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.42))
                                .frame(width: 26)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Air Conditioner details")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Largest estimated contribution")
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
