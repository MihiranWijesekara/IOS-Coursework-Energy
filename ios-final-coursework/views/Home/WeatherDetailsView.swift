//
//  WeatherDetailsView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct WeatherDetailsView: View {
    @EnvironmentObject var navState: AppNavigationState
    @ObservedObject private var weatherService = WeatherService.shared
    
    @State private var tomorrowTemp: Double?
    @State private var highTemp: Double?
    @State private var lowTemp: Double?
    @State private var rainProb: Int?
    @State private var windSpeed: Double?
    
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
                                Text("\(Int(round(weatherService.currentTemperature)))°")
                                    .font(.system(size: 52, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("C")
                                    .font(.system(size: 26, weight: .regular))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: weatherService.weatherIconName)
                            .font(.system(size: 44))
                            .foregroundColor(Color(red: 0.98, green: 0.78, blue: 0.15))
                    }
                    .padding(22)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Condition Subtitle
                    Text(weatherService.conditionDescription)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Live Hourly Forecast Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hourly Forecast")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        HStack(spacing: 12) {
                            ForEach(weatherService.hourlyForecast, id: \.time) { slot in
                                VStack(spacing: 8) {
                                    Text(slot.time)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                    
                                    Image(systemName: slot.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.15))
                                        .frame(height: 28)
                                    
                                    Text("\(slot.temp)°C")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Tomorrow Row Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tomorrow")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Text("High \(temperatureText(highTemp)) · Low \(temperatureText(lowTemp))")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(temperatureText(tomorrowTemp))
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
                        statColumn(label: "Humidity", value: "\(Int(round(weatherService.currentHumidity)))%")
                        Spacer()
                        statColumn(label: "Wind", value: windSpeed.map { "\(Int(round($0))) km/h" } ?? "—")
                        Spacer()
                        statColumn(label: "Rain", value: rainProb.map { "\($0)%" } ?? "—")
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color(red: 0.88, green: 0.95, blue: 0.99))
                    .cornerRadius(16)
                    
                    // Yellow Alert Card: Dynamic AC cooling demand
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.08))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("High cooling demand")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.05))
                                
                                Spacer()
                                
                                Text("+\(weatherService.acLoadImpactPercent)% AC Load")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(red: 0.75, green: 0.35, blue: 0.05))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                            
                            Text("Current \(Int(round(weatherService.currentTemperature)))°C temperature and \(Int(round(weatherService.currentHumidity)))% humidity elevate household AC load by +\(weatherService.acLoadImpactPercent)%.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.60, green: 0.38, blue: 0.10))
                                .lineSpacing(2)
                        }
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
                        
                        Text("Use AC at 24–26°C or reduce usage by 1 hour to offset the +\(weatherService.acLoadImpactPercent)% climate impact.")
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
        
        do {
            let coords = try await weatherService.fetchCoordinates(for: town)
            let forecast = try await weatherService.fetchWeather(latitude: coords.lat, longitude: coords.lon)
            
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
            if let current = forecast.current {
                withAnimation {
                    self.windSpeed = current.windSpeed10m
                }
            }

        } catch {
            print("Failed loading weather details: \(error.localizedDescription)")
            // Fallback to default Sri Lanka coordinates
            _ = try? await weatherService.fetchWeather()
        }
    }

    private func temperatureText(_ temperature: Double?) -> String {
        guard let temperature else { return "—" }
        return "\(Int(round(temperature)))°C"
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
