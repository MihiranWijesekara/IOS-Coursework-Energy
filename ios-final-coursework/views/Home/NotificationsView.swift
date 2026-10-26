//
//  NotificationsView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct NotificationsView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var savedBills: [SavedBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    @Query private var savedUsers: [User]
    @ObservedObject private var weatherService = WeatherService.shared
    
    public init() {}
    
    private var prediction: EnergyPrediction? {
        EnergyPredictionService.shared.predictNextMonth(
            bills: savedBills,
            appliances: savedAppliances,
            user: savedUsers.first,
            temperatureC: weatherService.currentTemperature,
            humidityPercent: weatherService.currentHumidity
        )
    }
    
    private var coolingMessage: String {
        let temp = weatherService.tomorrowMaxTemperature ?? weatherService.currentTemperature
        let label = weatherService.tomorrowMaxTemperature != nil ? "Tomorrow" : "Today"
        return "\(label): \(Int(round(temp)))°C. Your cooling\nappliances may use more energy."
    }
    
    private var predictionMessage: String {
        guard let p = prediction else {
            return "Save an electricity bill to\nsee your next month forecast."
        }
        return "Next month’s estimated bill is \(p.currency)\n\(String(format: "%.0f", p.predictedCost)). Your forecast is now \(String(format: "%.0f", p.predictedKWh)) kWh."
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Home") {
                navState.navigate(to: .home)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Gradient Card
                    VStack(alignment: .leading) {
                        Text("Notifications")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Inbox Header & Mark All as Read
                    HStack {
                        Text("Inbox")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Mark All as Read")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Notification Cards List
                    VStack(spacing: 14) {
                        // Card 1: High Cooling Demand (Yellow)
                        notificationCard(
                            icon: "sun.haze",
                            iconColor: Color(red: 0.90, green: 0.50, blue: 0.15),
                            title: "High Cooling Demand",
                            message: coolingMessage,
                            meta: "● Live weather · \(navState.town.isEmpty ? "Colombo" : navState.town)",
                            bgColor: EnergyLensTheme.alertYellowBg
                        )
                        
                        // Card 2: Prediction Update (Lavender)
                        notificationCard(
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: Color(red: 0.55, green: 0.35, blue: 0.85),
                            title: "Prediction Update",
                            message: predictionMessage,
                            meta: "● Live forecast",
                            bgColor: EnergyLensTheme.purpleCardBg
                        )
                        
                        // Card 3: Energy Saving Tip (Light Mint)
                        notificationCard(
                            icon: "lightbulb",
                            iconColor: EnergyLensTheme.accentGreen,
                            title: "Energy Saving Tip",
                            message: "Reducing AC usage by 1 hour could\nsave approximately 1.2 kWh/day.",
                            meta: "Read · Yesterday, 3:15 PM",
                            bgColor: EnergyLensTheme.mintHighlight
                        )
                    }
                    
                    // Footnote
                    Text("The 1.2 kWh/day tip is an illustrative nameplate estimate (1,200 W × 1 hour). Savings simulations use your calibrated bill contribution instead.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .task {
            await weatherService.fetchWeather(forTown: navState.town)
        }
    }
    
    @ViewBuilder
    private func notificationCard(
        icon: String,
        iconColor: Color,
        title: String,
        message: String,
        meta: String,
        bgColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Text(message)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                    .lineSpacing(2)
                
                Text(meta)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(EnergyLensTheme.textSecondary.opacity(0.85))
                    .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(18)
        .background(bgColor)
        .cornerRadius(16)
    }
}
