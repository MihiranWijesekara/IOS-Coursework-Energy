//
//  PredictionEmptyView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct PredictionEmptyView: View {
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
                    // Title
                    Text("Next Month Prediction")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Large Dark Navy Empty State Card
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))
                            .padding(.top, 16)
                        
                        Text("More history is needed")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Import historical bills so EnergyLens can\nrecognise your consumption pattern.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Light Sky Blue Banner
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.45))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Forecast unavailable")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.40))
                            
                            Text("No forecast or estimated bill is shown until sufficient history is available.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.88, green: 0.95, blue: 0.99))
                    .cornerRadius(16)
                    
                    // Caption
                    Text("Already added bills? Retry to refresh the forecast.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .padding(.top, 2)
                    
                    Spacer(minLength: 30)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        GradientButton(title: "Import Electricity Bill") {
                            navState.navigate(to: .selectBillImage)
                        }
                        
                        OutlineButton(title: "Retry") {
                            navState.navigate(to: .nextMonthPrediction)
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
