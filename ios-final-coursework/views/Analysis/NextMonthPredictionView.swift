//
//  NextMonthPredictionView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct NextMonthPredictionView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    private let months = ["Apr", "May", "Jun", "Jul", "Aug", "Sep"]
    private let actualValues: [CGFloat] = [140, 155, 165, 160, 180]
    private let forecastValue: CGFloat = 195
    private let maxValue: CGFloat = 240
    
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
                    
                    // Gradient Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SEPTEMBER 2025 · UPDATED FORECAST")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            .tracking(0.6)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("195")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("LKR 8,520")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("Estimated bill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        }
                        
                        Text("Prior forecast: 190 kWh → Updated: 195 kWh")
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
                        
                        forecastChart
                            .frame(height: 120)
                            .padding(.top, 14)
                            .padding(.horizontal, 10)
                        
                        // X-axis labels
                        HStack {
                            ForEach(months, id: \.self) { month in
                                Text(month)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                                if month != months.last {
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        
                        Text("Apr 140 · May 155 · Jun 165 kWh are illustrative. Jul 160 ·\nAug 180 kWh.")
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
                        factorRow(icon: "clock.arrow.circlepath", title: "Historical electricity usage", showDivider: true)
                        factorRow(icon: "sun.haze", title: "Weather forecast", showDivider: true)
                        factorRow(icon: "powerplug", title: "Appliance usage", showDivider: false)
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
    
    private var forecastChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftPad: CGFloat = 34
            let chartWidth = w - leftPad - 16
            let stepX = chartWidth / CGFloat(months.count - 1)
            
            ZStack {
                // Y-axis labels
                VStack {
                    HStack {
                        Text("240")
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
                
                // Actual solid line (Apr to Aug)
                Path { path in
                    for i in 0..<actualValues.count {
                        let x = leftPad + CGFloat(i) * stepX
                        let ratio = actualValues[i] / maxValue
                        let y = (h - 14) - (ratio * (h - 28))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color(red: 0.12, green: 0.58, blue: 0.32), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                
                // Forecast dashed line (Aug to Sep)
                Path { path in
                    let lastActualIdx = actualValues.count - 1
                    let x1 = leftPad + CGFloat(lastActualIdx) * stepX
                    let y1 = (h - 14) - ((actualValues[lastActualIdx] / maxValue) * (h - 28))
                    
                    let x2 = leftPad + CGFloat(lastActualIdx + 1) * stepX
                    let y2 = (h - 14) - ((forecastValue / maxValue) * (h - 28))
                    
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                }
                .stroke(Color(red: 0.12, green: 0.58, blue: 0.32), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [5, 4]))
                
                // Data dots
                ForEach(0..<actualValues.count, id: \.self) { i in
                    let x = leftPad + CGFloat(i) * stepX
                    let ratio = actualValues[i] / maxValue
                    let y = (h - 14) - (ratio * (h - 28))
                    
                    Circle()
                        .fill(Color(red: 0.12, green: 0.58, blue: 0.32))
                        .frame(width: 5.5, height: 5.5)
                        .position(x: x, y: y)
                    
                    if i == actualValues.count - 1 {
                        Text("180")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                            .position(x: x - 4, y: y - 14)
                    }
                }
                
                // Sep forecast dot and label
                let sepX = leftPad + CGFloat(months.count - 1) * stepX
                let sepY = (h - 14) - ((forecastValue / maxValue) * (h - 28))
                
                Circle()
                    .fill(Color(red: 0.12, green: 0.58, blue: 0.32))
                    .frame(width: 5.5, height: 5.5)
                    .position(x: sepX, y: sepY)
                
                Text("195")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .position(x: sepX, y: sepY - 14)
            }
        }
    }
}
