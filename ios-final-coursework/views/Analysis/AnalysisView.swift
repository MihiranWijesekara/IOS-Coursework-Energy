//
//  AnalysisView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct AnalysisView: View {
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
            humidityPercent: weatherService.currentHumidity,
            occupants: savedUsers.first?.occupants ?? navState.occupants
        )
    }
    
    private var forecastSubtitle: String {
        if let p = prediction {
            return "Updated forecast · \(String(format: "%.0f", p.predictedKWh)) kWh"
        }
        return "Import a bill to see your forecast"
    }
    
    private var footnoteText: String {
        if let latest = savedBills.first {
            return "\(latest.billingMonth) bill is the basis for your current analysis.\nEstimates are not live meter readings."
        }
        return "Import a bill to start your analysis.\nEstimates are not live meter readings."
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Top Bar
                    Text("ENERGYLENS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .tracking(0.8)
                        .padding(.top, 12)
                    
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("See where your energy goes, and what comes\nnext.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Section 1: Your household
                    Text("Your household")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                        .padding(.top, 6)
                    
                    VStack(spacing: 0) {
                        analysisRow(
                            icon: "doc.text.fill",
                            iconBg: EnergyLensTheme.iconGreenBg,
                            title: "Bill Analysis",
                            subtitle: "Import and understand your electricity\nbill",
                            showDivider: true,
                            isHighlighted: false
                        ) {
                            navState.navigate(to: .billAnalysis)
                        }
                        
                        analysisRow(
                            icon: "chart.bar.fill",
                            iconBg: EnergyLensTheme.iconOrangeBg,
                            title: "Consumption Breakdown",
                            subtitle: "Estimated usage by appliance category",
                            showDivider: true,
                            isHighlighted: false
                        ) {
                            navState.navigate(to: .consumptionBreakdown)
                        }
                        
                        analysisRow(
                            icon: "powerplug.fill",
                            iconBg: EnergyLensTheme.iconPurpleBg,
                            title: "Appliances",
                            subtitle: "Manage power ratings and usage profiles",
                            showDivider: true,
                            isHighlighted: false
                        ) {
                            navState.navigate(to: .appliances)
                        }
                        
                        // Next Month Prediction - Highlighted row matching Page 7
                        analysisRow(
                            icon: "chart.line.uptrend.xyaxis",
                            iconBg: EnergyLensTheme.iconTealBg,
                            title: "Next Month Prediction",
                            subtitle: forecastSubtitle,
                            showDivider: false,
                            isHighlighted: true
                        ) {
                            navState.navigate(to: .nextMonthPrediction)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Section 2: Explore scenarios
                    Text("Explore scenarios")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                        .padding(.top, 10)
                    
                    VStack(spacing: 0) {
                        analysisRow(
                            icon: "slider.horizontal.3",
                            iconBg: EnergyLensTheme.iconGreenBg,
                            title: "Energy Saving Simulator",
                            subtitle: "Test a change in the Savings tab",
                            showDivider: true,
                            isHighlighted: false
                        ) {
                            navState.navigate(to: .savingsSimulator)
                        }
                        
                        analysisRow(
                            icon: "sun.max.fill",
                            iconBg: EnergyLensTheme.iconAmberBg,
                            title: "Solar Analysis",
                            subtitle: "Explore Solar generation scenario",
                            showDivider: false,
                            isHighlighted: false
                        ) {
                            navState.navigate(to: .solarAnalysis)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Footnote
                    Text(footnoteText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
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
    }
    
    @ViewBuilder
    private func analysisRow(
        icon: String,
        iconBg: Color,
        title: String,
        subtitle: String,
        showDivider: Bool,
        isHighlighted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconBg)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(EnergyLensTheme.textMuted)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(isHighlighted ? EnergyLensTheme.mintHighlight : Color.white)
                
                if showDivider {
                    Divider()
                        .padding(.leading, 64)
                        .background(EnergyLensTheme.fieldBorder)
                }
            }
        }
    }
}
