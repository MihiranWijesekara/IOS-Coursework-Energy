//
//  ReviewBillView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ReviewBillView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    @State private var billingPeriod: String = "01 Aug – 31 Aug 2025"
    @State private var previousReading: String = "12,450 kWh"
    @State private var currentReading: String = "12,630 kWh"
    @State private var consumption: String = "180 kWh"
    @State private var billAmount: String = "LKR 7,850"
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Import Bill") {
                navState.navigate(to: .scanningBill)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review your bill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Automatically extracted. Tap a field to edit.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    
                    // Extraction successful banner
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Extraction successful")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Please check the values against your bill.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.92))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(EnergyLensTheme.buttonGradient)
                    .cornerRadius(14)
                    
                    // Bill information section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Bill information")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Edit")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                            }
                        }
                        
                        // Card with field values
                        VStack(alignment: .leading, spacing: 14) {
                            // Billing period
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Billing period")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                
                                HStack {
                                    Text(billingPeriod)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                }
                            }
                            
                            Divider()
                                .background(EnergyLensTheme.fieldBorder)
                            
                            // Previous reading
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Previous reading")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                
                                Text(previousReading)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            
                            Divider()
                                .background(EnergyLensTheme.fieldBorder)
                            
                            // Current reading
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current reading")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                
                                Text(currentReading)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                            
                            // Highlighted Consumption Box
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Consumption")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.12, green: 0.45, blue: 0.28))
                                
                                Text(consumption)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.10, green: 0.42, blue: 0.26))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(EnergyLensTheme.mintHighlight)
                            .cornerRadius(10)
                            
                            // Highlighted Bill Amount Box
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bill amount")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.50))
                                
                                Text(billAmount)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.08, green: 0.38, blue: 0.48))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                            .cornerRadius(10)
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
                    Text("The difference between your readings is 180 kWh.\nContinue when all information is correct.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    Spacer(minLength: 30)
                    
                    // Continue Button
                    GradientButton(title: "Continue") {
                        navState.navigate(to: .billAnalysisResult)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
