//
//  SolarAnalysisView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct SolarAnalysisView: View {
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
                            
                            Text("Explore a simple household consumption offset, not a solar system quote.")
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
                            
                            Text("180 kWh")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example solar generation")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Text("60 kWh/month")
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
                            Text("120")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        Text("180 kWh consumption − 60 kWh example generation")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
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
                                Text("180 kWh")
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
                                Text("60 kWh")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            
                            // 60/180 = 33% bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.90, green: 0.92, blue: 0.95))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.92, green: 0.58, blue: 0.15))
                                        .frame(width: geo.size.width * 0.33, height: 6)
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
                    Text("Illustrative energy offset only. No tariff, export credit, installation cost or financial return is estimated.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 2)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
