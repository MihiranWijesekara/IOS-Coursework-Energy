//
//  WhyThisPredictionView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct WhyThisPredictionView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Prediction") {
                navState.navigate(to: .nextMonthPrediction)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Why this prediction?")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Based on your historical consumption,\nweather forecast, and appliance usage.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                    }
                    
                    // Section: Estimated influences
                    Text("Estimated influences")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Influences Card
                    VStack(spacing: 16) {
                        influenceRow(name: "Higher temperature forecast", value: "+8% usage", ratio: 0.90, color: Color(red: 0.12, green: 0.55, blue: 0.32))
                        influenceRow(name: "Increased AC usage", value: "+5% usage", ratio: 0.55, color: Color(red: 0.08, green: 0.20, blue: 0.30))
                        influenceRow(name: "Recent consumption trend", value: "+3% usage", ratio: 0.35, color: Color(red: 0.20, green: 0.50, blue: 0.70))
                        influenceRow(name: "Other appliances", value: "+2% usage", ratio: 0.22, color: Color(red: 0.55, green: 0.40, blue: 0.80))
                    }
                    .padding(18)
                    .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                    .cornerRadius(18)
                    
                    // Lavender Callout Box: How to read these factors
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.55))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to read these factors")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Text("Relative influences against the model baseline. They are not additive shares and do not sum to the 195 kWh forecast.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(18)
                    .background(EnergyLensTheme.purpleCardBg)
                    .cornerRadius(16)
                    
                    // Bottom Note
                    Text("Warmer conditions and your AC profile are the strongest influences in this update. Try an AC schedule change in Savings.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func influenceRow(name: String, value: String, ratio: CGFloat, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.8))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(geo.size.width * ratio, 6), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
