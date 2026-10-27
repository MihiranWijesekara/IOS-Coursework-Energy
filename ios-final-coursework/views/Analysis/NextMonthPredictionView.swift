//
//  NextMonthPredictionView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct NextMonthPredictionView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var weatherService = WeatherService.shared
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    @Query private var savedUsers: [User]
    
    public init() {}
    
    private var sortedBills: [SavedBill] {
        pdfSavedBills.sorted { $0.actualBillingDate > $1.actualBillingDate }
    }

    private var prediction: EnergyPrediction? {
        EnergyPredictionService.shared.predictNextMonth(
            bills: sortedBills,
            appliances: savedAppliances,
            user: savedUsers.first,
            temperatureC: weatherService.currentTemperature,
            humidityPercent: weatherService.currentHumidity,
            occupants: savedUsers.first?.occupants ?? navState.occupants
        )
    }
    
    private var hasBills: Bool {
        prediction != nil
    }
    
    private var latestKwh: Double {
        sortedBills.first?.totalKWh ?? 0.0
    }
    
    private var currencySymbol: String {
        prediction?.currency ?? "Rs."
    }
    
    private var forecastKwh: Double {
        round(prediction?.predictedKWh ?? 0)
    }
    
    private var forecastAmount: Double {
        round(prediction?.predictedCost ?? 0)
    }
    
    private var forecastMonthTitle: String {
        let cal = Calendar.current
        let nextDate = cal.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "\(formatter.string(from: nextDate).uppercased()) · UPDATED FORECAST"
    }
    
    // Monthly trend points for the chart (past 5 periods + 1 forecast)
    private var chartModel: (months: [String], actualValues: [CGFloat], forecastValue: CGFloat, maxValue: CGFloat) {
        let cal = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "MMM"
        
        // Real historical bills sorted chronologically by actual billing date
        let recent = Array(sortedBills.prefix(5).reversed())
        let actuals: [CGFloat] = recent.map { CGFloat(round($0.totalKWh)) }
        let forecast = CGFloat(forecastKwh)
        let maxVal = max(actuals.max() ?? 0, forecast, 1) * 1.25
        
        var monthNames: [String] = []
        for bill in recent {
            if !bill.billingMonth.isEmpty {
                let parts = bill.billingMonth.components(separatedBy: " ")
                if let first = parts.first, first.count >= 3 {
                    monthNames.append(String(first.prefix(3)))
                    continue
                }
            }
            monthNames.append(df.string(from: bill.actualBillingDate))
        }
        if let nextDate = cal.date(byAdding: .month, value: 1, to: sortedBills.first?.actualBillingDate ?? Date()) {
            monthNames.append(df.string(from: nextDate))
        } else {
            monthNames.append("Next")
        }
        
        return (monthNames, actuals, forecast, maxVal)
    }
    
    public var body: some View {
        Group {
            if !hasBills {
                PredictionEmptyView()
            } else {
                contentView
            }
        }
        .onAppear {
            syncWidgetSnapshot()
        }
    }

    private func syncWidgetSnapshot() {
        WidgetDataStore.shared.syncFrom(
            bills: sortedBills,
            appliances: savedAppliances,
            user: savedUsers.first,
            temperatureC: weatherService.currentTemperature,
            humidityPercent: weatherService.currentHumidity
        )
    }
    
    private var contentView: some View {
        let chart = chartModel
        
        return VStack(alignment: .leading, spacing: 0) {
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
                    
                    // Gradient Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text(forecastMonthTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            .tracking(0.6)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", forecastKwh))
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("\(currencySymbol) \(String(format: "%.0f", forecastAmount))")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("Estimated bill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        }
                        
                        Text("Prior usage: \(String(format: "%.0f", latestKwh)) kWh → Forecast: \(String(format: "%.0f", forecastKwh)) kWh")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Forecast Trend Chart Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 16) {
                            Text("— Actual · kWh")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Text("- - Forecast")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        forecastChart(chart: chart)
                            .frame(height: 120)
                            .padding(.top, 14)
                            .padding(.horizontal, 10)
                        
                        // X-axis labels
                        HStack {
                            ForEach(chart.months, id: \.self) { month in
                                Text(month)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                if month != chart.months.last {
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        
                        Text("Past historical bill trend with projected \(String(format: "%.0f", forecastKwh)) kWh Core ML forecast based on appliance calibration and weather.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                            .padding(.top, 2)
                    }
                    .padding(.top, 2)
                    
                    // Section: What informs your forecast
                    Text("What informs your forecast")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                        .padding(.top, 4)
                    
                    VStack(spacing: 0) {
                        factorRow(icon: "cpu", title: (prediction?.usedCoreML ?? false) ? "On-device Core ML inference: Active" : "On-device Core ML inference: Inactive (regression fallback)", showDivider: true)
                        factorRow(icon: "doc.text", title: "Historical Bills Analyzed: \(prediction?.billsAnalyzed ?? 0)", showDivider: true)
                        factorRow(icon: "clock.arrow.circlepath", title: "Historical Avg: \(String(format: "%.0f", prediction?.historicalAvgKWh ?? 0)) kWh", showDivider: true)
                        factorRow(icon: "powerplug", title: "Calibrated Appliances: \(String(format: "%.0f", prediction?.applianceMonthlyKWh ?? 0)) kWh/mo (\(savedAppliances.count))", showDivider: true)
                        factorRow(icon: "person.2", title: "Household Occupants: \(prediction?.occupants ?? 3) people", showDivider: true)
                        factorRow(icon: "tag", title: "Effective Tariff: \(prediction?.currency ?? "Rs.") \(String(format: "%.2f", prediction?.effectiveRatePerKWh ?? 0))/kWh", showDivider: true)
                        factorRow(icon: "sun.haze", title: "Current Weather Temperature: \(String(format: "%.1f", weatherService.currentTemperature))°C", showDivider: false)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Note
                    Text("Forecast generated with Core ML. This is an estimate, not a guaranteed bill or meter reading.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    Spacer(minLength: 20)
                    
                    // View Prediction Details Button
                    GradientButton(title: "View Prediction Details") {
                        navState.navigate(to: .whyThisPrediction)
                    }
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
    private func factorRow(icon: String, title: String, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            
            if showDivider {
                Divider()
                    .padding(.leading, 54)
                    .background(EnergyLensTheme.fieldBorder)
            }
        }
    }
    
    private func forecastChart(chart: (months: [String], actualValues: [CGFloat], forecastValue: CGFloat, maxValue: CGFloat)) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftPad: CGFloat = 34
            let chartWidth = w - leftPad - 16
            let stepX = chartWidth / CGFloat(max(1, chart.months.count - 1))
            let maxVal = chart.maxValue
            
            ZStack {
                // Y-axis labels
                VStack {
                    HStack {
                        Text(String(format: "%.0f", maxVal))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("0")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        Spacer()
                    }
                }
                .frame(height: h)
                
                // Zero baseline
                Path { path in
                    path.move(to: CGPoint(x: leftPad, y: h - 10))
                    path.addLine(to: CGPoint(x: w, y: h - 10))
                }
                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                
                // Actual solid line
                Path { path in
                    for i in 0..<chart.actualValues.count {
                        let x = leftPad + CGFloat(i) * stepX
                        let ratio = chart.actualValues[i] / maxVal
                        let y = (h - 14) - (ratio * (h - 28))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color(red: 0.12, green: 0.58, blue: 0.32), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                
                // Forecast dashed line
                Path { path in
                    let lastActualIdx = chart.actualValues.count - 1
                    let x1 = leftPad + CGFloat(lastActualIdx) * stepX
                    let y1 = (h - 14) - ((chart.actualValues[lastActualIdx] / maxVal) * (h - 28))
                    
                    let x2 = leftPad + CGFloat(lastActualIdx + 1) * stepX
                    let y2 = (h - 14) - ((chart.forecastValue / maxVal) * (h - 28))
                    
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                }
                .stroke(Color(red: 0.12, green: 0.58, blue: 0.32), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [5, 4]))
                
                // Data dots
                ForEach(0..<chart.actualValues.count, id: \.self) { i in
                    let x = leftPad + CGFloat(i) * stepX
                    let ratio = chart.actualValues[i] / maxVal
                    let y = (h - 14) - (ratio * (h - 28))
                    
                    Circle()
                        .fill(Color(red: 0.12, green: 0.58, blue: 0.32))
                        .frame(width: 5.5, height: 5.5)
                        .position(x: x, y: y)
                    
                    if i == chart.actualValues.count - 1 {
                        Text(String(format: "%.0f", chart.actualValues[i]))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                            .position(x: x - 4, y: y - 14)
                    }
                }
                
                // Forecast dot and label
                let sepX = leftPad + CGFloat(chart.months.count - 1) * stepX
                let sepY = (h - 14) - ((chart.forecastValue / maxVal) * (h - 28))
                
                Circle()
                    .fill(Color(red: 0.12, green: 0.58, blue: 0.32))
                    .frame(width: 5.5, height: 5.5)
                    .position(x: sepX, y: sepY)
                
                Text(String(format: "%.0f", chart.forecastValue))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .position(x: sepX, y: sepY - 14)
            }
        }
    }
}
