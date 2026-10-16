//
//  SimulationResultView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//


import SwiftUI

public struct SimulationResultView: View {
    @EnvironmentObject var navState: AppNavigationState
    
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
                            Text("24")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh/month")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("≈ LKR 1,050/month")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Comparison Card (Air Conditioner)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Air Conditioner")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        // Before
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Before · 6 h/day")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                Spacer()
                                Text("72 kWh")
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
                                Text("After · 4 h/day")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                Spacer()
                                Text("48 kWh")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            
                            // Green bar (48/72 = 66% width)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.90, green: 0.92, blue: 0.95))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(EnergyLensTheme.accentGreen)
                                        .frame(width: geo.size.width * 0.66, height: 6)
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
                            Text("24 kWh/month")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.92, green: 0.96, blue: 0.98))
                    .cornerRadius(18)
                    
                    // Footnote
                    Text("A calibrated scenario based on your August bill. Actual savings depend on settings, weather and usage.")
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
