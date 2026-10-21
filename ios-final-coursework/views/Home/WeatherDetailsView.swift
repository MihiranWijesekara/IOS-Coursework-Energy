//
//  WeatherDetailsView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct WeatherDetailsView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    // Live Weather State
    @State private var currentTemp: Double = 33.0
    @State private var tomorrowTemp: Double = 33.0
    @State private var highTemp: Double = 34.0
    @State private var lowTemp: Double = 27.0
    @State private var conditionText: String = "Mostly sunny"
    @State private var weatherIcon: String = "sun.max.fill"
    @State private var humidity: Int = 75
    @State private var rainProb: Int = 10
    @State private var windSpeed: Double = 12.0
    @State private var coolingDemandTitle: String = "High cooling demand"
    @State private var coolingDemandDesc: String = "Higher temperatures may increase AC and fan usage."
    @State private var coolingRecommendation: String = "Use AC at 24–26°C or reduce usage by 1 hour."
    @State private var isLoading: Bool = false
    
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
                                Text("\(Int(round(currentTemp)))°")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("C")
                                    .font(.system(size: 26, weight: .regular))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: weatherIcon)
                            .font(.system(size: 44))
                            .foregroundColor(Color(red: 0.98, green: 0.78, blue: 0.15))
                    }
                    .padding(22)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Condition Subtitle
                    Text(conditionText)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Tomorrow Row Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tomorrow")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Text("High \(Int(round(highTemp)))°C · Low \(Int(round(lowTemp)))°C")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(round(tomorrowTemp)))°C")
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
                        statColumn(label: "Humidity", value: "\(humidity)%")
                        Spacer()
                        statColumn(label: "Wind", value: "\(Int(round(windSpeed))) km/h")
                        Spacer()
                        statColumn(label: "Rain", value: "\(rainProb)%")
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
        .task {
            await loadWeatherDetails()
        }
    }
    
    private func loadWeatherDetails() async {
        let town = navState.town.isEmpty ? "Colombo" : navState.town
        isLoading = true
        
        do {
            let coords = try await WeatherService.shared.fetchCoordinates(for: town)
            let forecast = try await WeatherService.shared.fetchWeather(latitude: coords.lat, longitude: coords.lon)
            
            if let current = forecast.current {
                withAnimation {
                    self.currentTemp = current.temperature2m
                    let mapped = WeatherService.mapWeatherCode(current.weatherCode, temperature: current.temperature2m)
                    self.conditionText = mapped.condition
                    self.weatherIcon = mapped.icon
                    
                    if let relHum = current.relativeHumidity2m {
                        self.humidity = Int(relHum)
                    }
                    if let wind = current.windSpeed10m {
                        self.windSpeed = wind
                    }
                }
            }
            
            if let daily = forecast.daily {
                withAnimation {
                    if daily.temperature2mMax.count > 1 {
                        self.highTemp = daily.temperature2mMax[1]
                        self.lowTemp = daily.temperature2mMin[1]
                        self.tomorrowTemp = daily.temperature2mMax[1]
                    }
                    if let precipArray = daily.precipitationProbabilityMax, precipArray.count > 1, let p = precipArray[1] as Int? {
                        self.rainProb = p
                    }
                }
            }
        } catch {
            print("Failed loading weather details: \(error.localizedDescription)")
        }
        isLoading = false
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
