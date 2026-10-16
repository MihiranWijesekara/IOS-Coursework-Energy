//
//  AppliancesView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct AppliancesView: View {
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
                VStack(alignment: .leading, spacing: 20) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Appliances")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Manage your household appliances.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    
                    // Section: Household profiles
                    Text("Household profiles")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // List of profiles
                    VStack(spacing: 12) {
                        // Air Conditioner -> Tappable to details
                        Button(action: {
                            navState.navigate(to: .applianceDetail)
                        }) {
                            applianceItem(
                                icon: "air.conditioner.horizontal",
                                iconBg: Color(red: 0.12, green: 0.52, blue: 0.65),
                                name: "Air Conditioner",
                                specs: "1,200 W · 6 h/day · 1 unit"
                            )
                        }
                        
                        applianceItem(
                            icon: "refrigerator",
                            iconBg: Color(red: 0.90, green: 0.50, blue: 0.20),
                            name: "Refrigerator",
                            specs: "150 W · 24 h/day · 1 unit"
                        )
                        
                        applianceItem(
                            icon: "fanblades",
                            iconBg: Color(red: 0.15, green: 0.60, blue: 0.35),
                            name: "Fan",
                            specs: "60 W · 6 h/day · 2 units"
                        )
                        
                        applianceItem(
                            icon: "tv",
                            iconBg: Color(red: 0.50, green: 0.35, blue: 0.75),
                            name: "TV",
                            specs: "100 W · 4 h/day · 1 unit"
                        )
                        
                        applianceItem(
                            icon: "washer",
                            iconBg: Color(red: 0.20, green: 0.50, blue: 0.70),
                            name: "Washing Machine",
                            specs: "500 W · 2 h/day · 1 unit"
                        )
                    }
                    
                    // Callout Box
                    Text("Power ratings are nameplate values. Your bill and these profiles help calibrate estimated consumption.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(3)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(14)
                    
                    Spacer(minLength: 20)
                    
                    // Add Appliance Button
                    GradientButton(title: "Add Appliance") {
                        navState.navigate(to: .addAppliance)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func applianceItem(icon: String, iconBg: Color, name: String, specs: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Text(specs)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(EnergyLensTheme.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
        )
    }
}
