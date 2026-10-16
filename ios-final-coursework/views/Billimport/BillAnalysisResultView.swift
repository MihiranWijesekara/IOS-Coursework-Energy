//
//  BillAnalysisResultView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct BillAnalysisResultView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    // Sample monthly trend data
    private let months = ["Apr", "May", "Jun", "Jul", "Aug"]
    private let values: [CGFloat] = [140, 155, 165, 160, 180]
    private let maxValue: CGFloat = 240
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Bill Analysis") {
                navState.navigate(to: .billAnalysis)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Bill Analysis Result")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Main Highlight Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("01 Aug – 31 Aug 2025")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("180")
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        Text("LKR 7,850")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Alert Banner
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.75, green: 0.45, blue: 0.08))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("↑ 12.5% vs previous month")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.05))
                                
                                Text("August 180 kWh · July 160 kWh")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.60, green: 0.38, blue: 0.10))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(EnergyLensTheme.alertYellowBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(EnergyLensTheme.alertYellowBorder, lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Consumption trend
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Consumption trend")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("— Actual · kWh")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        
                        // Trend Line Chart
                        VStack(spacing: 0) {
                            trendChart
                                .frame(height: 120)
                                .padding(.top, 14)
                                .padding(.horizontal, 10)
                            
                            // X-Axis Labels
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
                        }
                        
                        // Caption
                        Text("Apr 140 · May 155 · Jun 165 kWh are illustrative. Jul 160 ·\nAug 180 kWh.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                            .padding(.top, 4)
                    }
                    .padding(.top, 4)
                    
                    // Bottom Note
                    Text("Your imported bill is ready. Explore the estimated contribution of each appliance in Detailed Analysis.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    Spacer(minLength: 20)
                    
                    // Button
                    GradientButton(title: "View Detailed Analysis") {
                        navState.navigate(to: .consumptionBreakdown)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    // Custom Chart Drawing
    private var trendChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftPad: CGFloat = 34
            let chartWidth = w - leftPad - 16
            let stepX = chartWidth / CGFloat(values.count - 1)
            
            ZStack {
                // Y-axis labels and horizontal baseline
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
                
                // Trend Line
                Path { path in
                    for i in 0..<values.count {
                        let x = leftPad + CGFloat(i) * stepX
                        let ratio = values[i] / maxValue
                        let y = (h - 14) - (ratio * (h - 28))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color(red: 0.12, green: 0.58, blue: 0.32), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                
                // Data dots and "180" label on Aug
                ForEach(0..<values.count, id: \.self) { i in
                    let x = leftPad + CGFloat(i) * stepX
                    let ratio = values[i] / maxValue
                    let y = (h - 14) - (ratio * (h - 28))
                    
                    Circle()
                        .fill(Color(red: 0.12, green: 0.58, blue: 0.32))
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                    
                    if i == values.count - 1 {
                        Text("180")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                            .position(x: x - 4, y: y - 14)
                    }
                }
            }
        }
    }
}
