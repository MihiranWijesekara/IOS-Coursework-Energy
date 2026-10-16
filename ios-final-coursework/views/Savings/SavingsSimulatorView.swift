//
//  SavingsSimulatorView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct SavingsSimulatorView: View {
    @EnvironmentObject var navState: AppNavigationState
    @State private var dailyHours: Double = 4.0
    
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
                    
                    // Selected Appliance Row
                    HStack(spacing: 14) {
                        Image(systemName: "air.conditioner.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.45))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Air Conditioner")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Text("Current · 6 h/day")
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
                                if dailyHours < 12 { dailyHours += 1 }
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
                        Slider(value: $dailyHours, in: 0...12, step: 1)
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
                            Text("24")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh/month")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("≈ LKR 1,050/month")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Calibrated AC contribution: 72 → 48 kWh. Estimates use your bill and profile, not nameplate power × hours.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        GradientButton(title: "Run Simulation") {
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
    }
}
