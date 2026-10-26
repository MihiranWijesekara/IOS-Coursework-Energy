//
//  WhyThisPredictionView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct WhyThisPredictionView: View {
    @EnvironmentObject var navState: AppNavigationState
    @ObservedObject private var weatherService = WeatherService.shared
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var savedBills: [SavedBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    @Query private var savedUsers: [User]
    
    public init() {}
    
    private var prediction: EnergyPrediction? {
        let sorted = savedBills.sorted { $0.actualBillingDate > $1.actualBillingDate }
        return EnergyPredictionService.shared.predictNextMonth(
            bills: sorted,
            appliances: savedAppliances,
            user: savedUsers.first,
            temperatureC: weatherService.currentTemperature,
            humidityPercent: weatherService.currentHumidity
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Prediction") {
                navState.navigate(to: .nextMonthPrediction)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Why this prediction?")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Based on your historical consumption,\nweather forecast, and appliance usage.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                    }
                    
                    // Section: Estimated influences
                    Text("Estimated influences")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    if let p = prediction {
                        VStack(spacing: 16) {
                            // Card 1: Weather Impact
                            influenceRow(
                                name: "Weather impact · \(String(format: "%.1f", p.temperatureC))°C, \(String(format: "%.0f", p.humidityPercent))% humidity",
                                value: "+\(String(format: "%.1f", p.coolingLoadImpactPercent))%",
                                ratio: CGFloat(min(1.0, p.coolingLoadImpactPercent / 40.0)),
                                color: Color(red: 0.12, green: 0.55, blue: 0.32))
                            
                            // Card 2: Historical Usage
                            influenceRow(
                                name: "Historical usage · \(p.billsAnalyzed) saved \(p.billsAnalyzed == 1 ? "bill" : "bills")",
                                value: "\(String(format: "%.0f", p.historicalAvgKWh)) kWh/mo",
                                ratio: ratio(p.historicalAvgKWh, of: p),
                                color: Color(red: 0.08, green: 0.20, blue: 0.30))
                            
                            // Card 3: Appliance Calibration
                            influenceRow(
                                name: "Appliance calibration · \(p.calibratedApplianceCount) \(p.calibratedApplianceCount == 1 ? "appliance" : "appliances")",
                                value: "\(String(format: "%.0f", p.applianceMonthlyKWh)) kWh/mo",
                                ratio: ratio(p.applianceMonthlyKWh, of: p),
                                color: Color(red: 0.20, green: 0.50, blue: 0.70))
                        }
                        .padding(18)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(18)
                    } else {
                        Text("Save at least one electricity bill to see what drives your prediction.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                            .cornerRadius(18)
                    }
                    
                    // Lavender Callout Box: How to read these factors
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.55))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to read these factors")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Text("Relative influences against the model baseline. They are not additive shares and do not sum to the \(prediction.map { String(format: "%.0f", $0.predictedKWh) } ?? "--") kWh forecast.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(18)
                    .background(EnergyLensTheme.purpleCardBg)
                    .cornerRadius(16)
                    
                    // Bottom Note
                    Text("Weather, your saved bill history and calibrated appliances are combined by the \((prediction?.usedCoreML ?? false) ? "on-device Core ML model" : "regression model") to estimate next month's usage.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 4)
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
    
    private func ratio(_ value: Double, of p: EnergyPrediction) -> CGFloat {
        let denom = max(p.predictedKWh, 1)
        return CGFloat(min(1.0, max(0.0, value / denom)))
    }
    
    @ViewBuilder
    private func influenceRow(name: String, value: String, ratio: CGFloat, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.8))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(geo.size.width * ratio, 6), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
