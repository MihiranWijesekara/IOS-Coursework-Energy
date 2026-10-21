//
//  BillHistoryView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct BillHistoryView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @State private var selectedPeriod = 0 // 0: 5 months, 1: Year
    
    private let months = ["Apr", "May", "Jun", "Jul", "Aug"]
    private let values: [CGFloat] = [140, 155, 165, 160, 180]
    private let maxValue: CGFloat = 240
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Bar
            HStack {
                CustomBackButton(title: "Bill Analysis") {
                    navState.navigate(to: .billAnalysis)
                }
                
                Spacer()
                
                Button(action: {
                    navState.navigate(to: .selectBillImage)
                }) {
                    Text("Import")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(EnergyLensTheme.accentGreen)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Title
                    Text("Bill History")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Segmented Control: 5 months | Year
                    HStack(spacing: 0) {
                        Button(action: { selectedPeriod = 0 }) {
                            Text("5 months")
                                .font(.system(size: 15, weight: selectedPeriod == 0 ? .semibold : .medium))
                                .foregroundColor(selectedPeriod == 0 ? .white : EnergyLensTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedPeriod == 0 ? EnergyLensTheme.buttonGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                                .cornerRadius(12)
                        }
                        
                        Button(action: { selectedPeriod = 1 }) {
                            Text("Year")
                                .font(.system(size: 15, weight: selectedPeriod == 1 ? .semibold : .medium))
                                .foregroundColor(selectedPeriod == 1 ? .white : EnergyLensTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedPeriod == 1 ? EnergyLensTheme.buttonGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                                .cornerRadius(12)
                        }
                    }
                    .padding(3)
                    .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                    .cornerRadius(14)
                    
                    // Dark Navy Chart Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("— Actual · kWh")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        
                        darkTrendChart
                            .frame(height: 110)
                            .padding(.top, 8)
                        
                        // X-axis labels
                        HStack {
                            ForEach(months, id: \.self) { month in
                                Text(month)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.75))
                                if month != months.last {
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 2)
                    }
                    .padding(18)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(18)
                    
                    // Caption
                    Text("Apr 140 · May 155 · Jun 165 kWh are illustrative. Jul 160 ·\nAug 180 kWh.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Section: Bills
                    Text(savedBills.isEmpty ? "Sample bills" : "Imported bills")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                        .padding(.top, 4)
                    
                    // Bill list
                    VStack(spacing: 10) {
                        if !savedBills.isEmpty {
                            ForEach(Array(savedBills.enumerated()), id: \.element.id) { index, bill in
                                Button(action: {
                                    navState.navigate(to: .billAnalysisResult)
                                }) {
                                    let formatter = DateFormatter()
                                    let _ = formatter.dateFormat = "MMMM yyyy"
                                    let monthTitle = formatter.string(from: bill.periodEnd)
                                    let subtitle = "\(Int(round(bill.consumptionKwh))) kWh · LKR \(String(format: "%.2f", bill.billAmount))"
                                    
                                    billRow(
                                        month: monthTitle,
                                        subtitle: subtitle,
                                        iconColor: index == 0 ? EnergyLensTheme.accentGreen : EnergyLensTheme.textMuted,
                                        isHighlighted: index == 0
                                    )
                                }
                            }
                        } else {
                            // August (Selected/Latest sample)
                            Button(action: {
                                navState.navigate(to: .billAnalysisResult)
                            }) {
                                billRow(
                                    month: "August",
                                    subtitle: "180 kWh · LKR 7,850",
                                    iconColor: EnergyLensTheme.accentGreen,
                                    isHighlighted: true
                                )
                            }
                            
                            billRow(month: "July", subtitle: "160 kWh", iconColor: EnergyLensTheme.textMuted, isHighlighted: false)
                            billRow(month: "June", subtitle: "165 kWh · Illustrative", iconColor: EnergyLensTheme.textMuted, isHighlighted: false)
                            billRow(month: "May", subtitle: "155 kWh · Illustrative", iconColor: EnergyLensTheme.textMuted, isHighlighted: false)
                            billRow(month: "April", subtitle: "140 kWh · Illustrative", iconColor: EnergyLensTheme.textMuted, isHighlighted: false)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func billRow(month: String, subtitle: String, iconColor: Color, isHighlighted: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(month)
                    .font(.system(size: 16, weight: isHighlighted ? .bold : .medium))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(EnergyLensTheme.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(isHighlighted ? EnergyLensTheme.mintHighlight : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isHighlighted ? Color.clear : EnergyLensTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private var darkTrendChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftPad: CGFloat = 34
            let chartWidth = w - leftPad - 14
            let stepX = chartWidth / CGFloat(values.count - 1)
            
            ZStack {
                // Y-axis labels
                VStack {
                    HStack {
                        Text("240")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("0")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                        Spacer()
                    }
                }
                .frame(height: h)
                
                // Zero line
                Path { path in
                    path.move(to: CGPoint(x: leftPad, y: h - 8))
                    path.addLine(to: CGPoint(x: w, y: h - 8))
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                
                // Mint line
                Path { path in
                    for i in 0..<values.count {
                        let x = leftPad + CGFloat(i) * stepX
                        let ratio = values[i] / maxValue
                        let y = (h - 12) - (ratio * (h - 24))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color(red: 0.40, green: 0.90, blue: 0.70), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                
                // Dots and "180" label
                ForEach(0..<values.count, id: \.self) { i in
                    let x = leftPad + CGFloat(i) * stepX
                    let ratio = values[i] / maxValue
                    let y = (h - 12) - (ratio * (h - 24))
                    
                    Circle()
                        .fill(Color(red: 0.40, green: 0.90, blue: 0.70))
                        .frame(width: 5.5, height: 5.5)
                        .position(x: x, y: y)
                    
                    if i == values.count - 1 {
                        Text("180")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .position(x: x - 4, y: y - 14)
                    }
                }
            }
        }
    }
}
