//
//  ApplianceDetailView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ApplianceDetailView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    private let usageMode: String = "All day"
    private let daysPerWeek: Int = 2
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back & Edit Action
            HStack {
                CustomBackButton(title: "Appliances") {
                    navState.navigate(to: .appliances)
                }
                
                Spacer()
                
                Button(action: {
                    navState.navigate(to: .addAppliance)
                }) {
                    Text("Edit")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(EnergyLensTheme.accentGreen)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Title
                    Text("Air Conditioner")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Main Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Estimated August contribution")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("72")
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        Text("40% of your 180 kWh bill")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Share of monthly consumption
                    VStack(spacing: 8) {
                        HStack {
                            Text("Share of monthly consumption")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Text("40%")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(EnergyLensTheme.accentGreen)
                                    .frame(width: geo.size.width * 0.40, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.top, 2)
                    
                    // Appliance profile section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Appliance profile")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                navState.navigate(to: .addAppliance)
                            }) {
                                Text("Edit appliance")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                            }
                        }
                        
                        // Info card
                        VStack(spacing: 12) {
                            profileRow(label: "Nameplate power", value: "1,200 W")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Daily usage", value: "6 h/day")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Quantity", value: "1 unit")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Usage mode", value: usageMode)
                            if usageMode == "Weekly" {
                                Divider().background(EnergyLensTheme.fieldBorder)
                                profileRow(label: "Days per week", value: "\(daysPerWeek) days")
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    
                    // Footnote
                    Text("72 kWh is calibrated to your bill and appliance profiles. It is not a measured reading or simply power × hours.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Callout
                    Text("Try reducing daily AC usage from 6 to 4 hours in the simulator.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                        .lineSpacing(2)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(14)
                    
                    Spacer(minLength: 20)
                    
                    // Open Simulator Button
                    GradientButton(title: "Open Energy Saving Simulator") {
                        navState.navigate(to: .savingsSimulator)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(EnergyLensTheme.textPrimary)
        }
    }
}
