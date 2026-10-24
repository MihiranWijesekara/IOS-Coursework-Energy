//
//  HomeDashboardView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct HomeDashboardView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    
    // Live Weather State
    @State private var weatherTemp: Double? = 33.0
    @State private var weatherCondition: String = "Sunny"
    @State private var weatherIcon: String = "sun.max"
    @State private var weatherAdvice: String = "High cooling demand"
    @State private var isLoadingWeather: Bool = false
    @State private var weatherFetchFailed: Bool = false
    
    // Computed Latest Bill values for Home Dashboard
    private var latestBillData: (headerMonth: String, kwh: Double, amountText: String, comparisonText: String) {
        if let latest = savedBills.first {
            let header = "THIS MONTH · \(SwiftDataBillService.formatMonthYear(date: latest.periodEnd))"
            let previous = savedBills.count > 1 ? savedBills[1] : nil
            let comp = SwiftDataBillService.shared.calculateComparison(latest: latest, previous: previous)
            let amount = String(format: "LKR %.2f", latest.billAmount)
            return (header, latest.consumptionKwh, amount, comp.text)
        }
        return ("THIS MONTH · AUG 2025", 180, "LKR 7,850", "↑ 12.5% vs July · 160 kWh")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Bar
                    HStack(alignment: .center) {
                        Text("ENERGYLENS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .tracking(0.8)
                        
                        Spacer()
                        
                        // Profile Initials AM
                        Button(action: {
                            navState.navigate(to: .profile)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.90, green: 0.94, blue: 0.98))
                                    .frame(width: 34, height: 34)
                                
                                Text("AM")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                        }
                        
                        // Bell Notification Icon
                        Button(action: {
                            navState.navigate(to: .notifications)
                        }) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                                .padding(.leading, 12)
                        }
                    }
                    .padding(.top, 12)
                    
                    // Greeting
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(greeting), \(navState.firstName)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Home")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    .padding(.bottom, 2)
                    
                    // Main Highlight Card: THIS MONTH
                    Button(action: {
                        if savedBills.isEmpty {
                            navState.navigate(to: .billHistoryEmpty)
                        } else {
                            navState.navigate(to: .billAnalysisResult)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(latestBillData.headerMonth)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                                    .tracking(0.6)
                                
                                Spacer()
                                
                                Text(savedBills.isEmpty ? "Sample bill" : "Imported bill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.65, green: 0.88, blue: 0.76))
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.0f", latestBillData.kwh))
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("kWh")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.white)
                            }
                            
                            Text(latestBillData.amountText)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(latestBillData.comparisonText)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(EnergyLensTheme.cardGradient)
                        .cornerRadius(22)
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Card 2: Next month · 190 kWh
                    Button(action: {
                        navState.navigate(to: .nextMonthPrediction)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Next month · 190 kWh")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Earlier estimate · refreshed to 195 kWh")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    
                    // Card 3: Live Weather Card
                    Button(action: {
                        if weatherFetchFailed {
                            navState.navigate(to: .weatherError)
                        } else {
                            navState.navigate(to: .weatherDetails)
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: weatherIcon)
                                .font(.system(size: 20))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                if let temp = weatherTemp {
                                    Text("\(weatherCondition) · \(Int(round(temp)))°C")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                } else {
                                    Text(weatherCondition)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                }
                                
                                Text("\(navState.town.isEmpty ? "Colombo" : navState.town) · \(weatherAdvice)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    
                    // Card 4: Cool thoughtfully
                    Button(action: {
                        navState.navigate(to: .savingsSimulator)
                    }) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.12, green: 0.35, blue: 0.30))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cool thoughtfully")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.10, green: 0.28, blue: 0.24))
                                
                                Text("Set your AC to 24–26°C. Try a shorter schedule in Savings.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.20, green: 0.40, blue: 0.35))
                                    .lineSpacing(2)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.90, green: 0.97, blue: 0.95))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.78, green: 0.92, blue: 0.88), lineWidth: 1)
                        )
                    }
                    
                    // Card 5: Import Electricity Bill
                    Button(action: {
                        navState.navigate(to: .billAnalysis)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Import Electricity Bill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Add a new bill to your history")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    
                    // View Analysis Action Button
                    GradientButton(title: "View Analysis") {
                        navState.navigate(to: .analysis)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            
            // Bottom Tab Navigation Bar
            CustomTabBar(selectedTab: $navState.selectedTab) { tab in
                switch tab {
                case .home:
                    navState.navigate(to: .home)
                case .analysis:
                    navState.navigate(to: .analysis)
                case .savings:
                    navState.navigate(to: .savingsSimulator)
                case .profile:
                    navState.navigate(to: .profile)
                }
            }
        }
        .background(EnergyLensTheme.screenBackground.ignoresSafeArea())
        .task {
            await loadLiveWeather()
        }
    }
    
    private func loadLiveWeather() async {
        let town = navState.town.isEmpty ? "Colombo" : navState.town
        isLoadingWeather = true
        weatherFetchFailed = false
        
        do {
            let coords = try await WeatherService.shared.fetchCoordinates(for: town)
            let forecast = try await WeatherService.shared.fetchWeather(latitude: coords.lat, longitude: coords.lon)
            
            if let current = forecast.current {
                withAnimation {
                    self.weatherTemp = current.temperature2m
                    let mapped = WeatherService.mapWeatherCode(current.weatherCode, temperature: current.temperature2m)
                    self.weatherCondition = mapped.condition
                    self.weatherIcon = mapped.icon
                    self.weatherAdvice = mapped.advice
                }
                
                // Save/update WeatherData record in SwiftData
                let weatherRecord = WeatherData(
                    date: Date(),
                    highTemp: current.temperature2m,
                    lowTemp: current.temperature2m - 4.0,
                    condition: self.weatherCondition,
                    precipProb: Double(forecast.daily?.precipitationProbabilityMax?.first ?? 10)
                )
                modelContext.insert(weatherRecord)
                try? modelContext.save()
            }
        } catch {
            print("Weather fetch error: \(error.localizedDescription)")
            self.weatherFetchFailed = true
        }
        
        isLoadingWeather = false
    }
}
