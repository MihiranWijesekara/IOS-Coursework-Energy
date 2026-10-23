//
//  WeatherErrorView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct WeatherErrorView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \WeatherData.date, order: .reverse) private var cachedWeatherRecords: [WeatherData]
    
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
                        Text(navState.town.isEmpty ? "Colombo" : navState.town)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Weather context")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    
                    // Yellow Weather Unavailable Banner
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.08))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Weather unavailable")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.05))
                            
                            Text("We couldn’t refresh the Weather API. No\nfresh forecast is available.")
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
                    
                    // Dark Navy Last Known Temperature Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LAST-KNOWN TEMPERATURE · NOT FRESH")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .tracking(0.6)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if let cached = cachedWeatherRecords.first, let temp = cached.highTemp {
                                Text("\(Int(round(temp)))°")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("33°")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("C")
                                .font(.system(size: 26, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        Text("Last-known conditions · \(cachedWeatherRecords.first?.condition ?? "Mostly sunny")")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(18)
                    
                    // Tomorrow’s outlook section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tomorrow’s outlook")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Unavailable. Cooling demand guidance will\nrefresh when weather data is available.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                    }
                    .padding(.top, 4)
                    
                    Text("Your bill and appliance profiles are still available.\nCheck your connection and try again.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    Spacer(minLength: 40)
                    
                    // Try Again Button
                    GradientButton(title: "Try Again") {
                        Task {
                            _ = try? await WeatherService.shared.fetchWeather()
                            await MainActor.run {
                                navState.navigate(to: .weatherDetails)
                            }
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
