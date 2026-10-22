//
//  AppliancesEmptyView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct AppliancesEmptyView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    
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
                    
                    // Large Dark Green Empty State Card
                    VStack(spacing: 16) {
                        Image(systemName: "powerplug")
                            .font(.system(size: 38, weight: .light))
                            .foregroundColor(.white)
                            .padding(.top, 16)
                        
                        Text("Add your first appliance")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Start with the appliances you use most,\nsuch as your AC, refrigerator and fans.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .padding(.horizontal, 20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Callout Card: Calibrated to your bill
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.45))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calibrated to your bill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.40))
                            
                            Text("Your appliance profiles help calibrate breakdowns and saving scenarios to your bill.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.82, green: 0.92, blue: 0.96), lineWidth: 1)
                    )
                    
                    Spacer(minLength: 30)
                    
                    // Load Samples Button
                    Button(action: {
                        if (try? SwiftDataApplianceService.shared.seedDefaultHouseholdAppliances(context: modelContext)) != nil {
                            navState.navigate(to: .appliances)
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Load Standard Coursework Appliances")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.42))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.88, green: 0.95, blue: 0.97))
                        .cornerRadius(14)
                    }
                    .padding(.bottom, 8)
                    
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
}
