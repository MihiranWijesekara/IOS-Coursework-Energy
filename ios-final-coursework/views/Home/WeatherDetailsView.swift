//
//  WeatherDetailsView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct WeatherDetailsView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Home") {
                navState.navigate(to: .home)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Headings
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Colombo")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Weather for your energy decisions")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    
                    // Dark Navy Temperature Card
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current temperature")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("33°")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("C")
                                    .font(.system(size: 26, weight: .regular))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(red: 0.98, green: 0.78, blue: 0.15))
                    }
                    .padding(22)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Condition Subtitle
                    Text("Mostly sunny")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Tomorrow Row Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tomorrow")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Text("High 34°C · Low 27°C (sample range)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("33°C")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // 3 Stat Columns Card
                    HStack {
                        statColumn(label: "Humidity", value: "75%")
                        Spacer()
                        statColumn(label: "Wind", value: "12 km/h")
                        Spacer()
                        statColumn(label: "Rain", value: "10%")
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color(red: 0.88, green: 0.95, blue: 0.99))
                    .cornerRadius(16)
                    
                    // Yellow Alert Card: High cooling demand
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.08))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("High cooling demand")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.05))
                            
                            Text("Higher temperatures may increase AC and\nfan usage.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.60, green: 0.38, blue: 0.10))
                                .lineSpacing(2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(EnergyLensTheme.alertYellowBg)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(EnergyLensTheme.alertYellowBorder, lineWidth: 1)
                    )
                    
                    // Recommended Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Use AC at 24–26°C or reduce usage by 1 hour.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Footnote
                    Text("Weather API context informs recommendations; it does not measure appliance energy use.")
                        .font(.system(size: 12, weight: .regular))
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
    
    @ViewBuilder
    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(EnergyLensTheme.textPrimary)
        }
    }
}
