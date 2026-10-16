//
//  BillAnalysisView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct BillAnalysisView: View {
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
                        Text("Bill Analysis")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Turn your electricity bill into a clearer picture of\nyour household energy.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                    }
                    
                    // Vision Framework Feature Card
                    VStack(alignment: .leading, spacing: 14) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Read your bill automatically")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Choose a bill image. Vision Framework\nrecognises the text and extracts your\nbilling period, readings and amount.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(2)
                        
                        Text("You review and edit the values before they are\nused in your analysis.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.78))
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Section: Most recent bill
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Most recent bill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Button(action: {
                            navState.navigate(to: .billAnalysisResult)
                        }) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("August 2025")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.28))
                                    
                                    Text("01 Aug – 31 Aug · 180 kWh")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text("LKR 7,850")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.28))
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 18)
                            .background(EnergyLensTheme.mintHighlight)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.top, 6)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        GradientButton(title: "Import Electricity Bill") {
                            navState.navigate(to: .selectBillImage)
                        }
                        
                        OutlineButton(title: "View Bill History") {
                            navState.navigate(to: .billHistory)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
