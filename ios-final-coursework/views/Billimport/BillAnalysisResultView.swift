//
//  BillAnalysisResultView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct BillAnalysisResultView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    
    // Computed active bill values (Latest saved bill or fallback)
    private var activeBill: (periodText: String, kwh: Double, amountText: String, comparisonText: String, isIncrease: Bool) {
        let sortedPDF = pdfSavedBills.sorted { $0.actualBillingDate > $1.actualBillingDate }
        if let pdfLatest = sortedPDF.first {
            let period = pdfLatest.billingMonth.isEmpty ? "Current Billing Period" : pdfLatest.billingMonth
            let curr = (pdfLatest.currency.uppercased() == "USD" || pdfLatest.currency == "$") ? "$" : "Rs."
            let billAmount = pdfLatest.monthlyBill > 0 ? pdfLatest.monthlyBill : pdfLatest.totalAmount
            let amount = "\(curr) \(String(format: "%.2f", billAmount))"
            
            var comparison = "Latest imported bill"
            var isIncrease = false
            if sortedPDF.count > 1 {
                let previous = sortedPDF[1]
                if previous.totalKWh > 0 {
                    let diff = pdfLatest.totalKWh - previous.totalKWh
                    let pct = (diff / previous.totalKWh) * 100
                    isIncrease = diff > 0
                    let arrow = isIncrease ? "↑" : "↓"
                    let prevMonth = previous.billingMonth.isEmpty ? "previous bill" : previous.billingMonth
                    comparison = "\(arrow) \(String(format: "%.1f", abs(pct)))% vs \(prevMonth)"
                }
            }
            return (period, pdfLatest.totalKWh, amount, comparison, isIncrease)
        } else if let latest = savedBills.first {
            let period = SwiftDataBillService.formatPeriod(start: latest.periodStart, end: latest.periodEnd)
            let previous = savedBills.count > 1 ? savedBills[1] : nil
            let comp = SwiftDataBillService.shared.calculateComparison(latest: latest, previous: previous)
            let curr = (latest.currency.uppercased() == "USD" || latest.currency == "$") ? "$" : "Rs."
            let amount = "\(curr) \(String(format: "%.2f", latest.billAmount))"
            return (period, latest.consumptionKwh, amount, comp.text, comp.isIncrease)
        }
        return ("No bill imported", 0, "Rs. 0.00", "No billing history", false)
    }
    
    // Dynamic chart data from user's real saved bills (oldest -> newest, up to 5)
    private var chartModel: (months: [String], values: [CGFloat], maxValue: CGFloat) {
        let sortedPDF = pdfSavedBills.sorted { $0.actualBillingDate > $1.actualBillingDate }
        if !sortedPDF.isEmpty {
            let recent = Array(sortedPDF.prefix(5).reversed())
            let ms = recent.map { bill -> String in
                if !bill.billingMonth.isEmpty {
                    let parts = bill.billingMonth.components(separatedBy: " ")
                    if let first = parts.first, first.count >= 3 {
                        return String(first.prefix(3))
                    }
                    return bill.billingMonth
                }
                let df = DateFormatter()
                df.dateFormat = "MMM"
                return df.string(from: bill.actualBillingDate)
            }
            let vs = recent.map { CGFloat(round($0.totalKWh)) }
            let maxV = max(vs.max() ?? 100, 50) * 1.25
            return (ms, vs, maxV)
        } else if !savedBills.isEmpty {
            let recent = Array(savedBills.prefix(5).reversed())
            let df = DateFormatter()
            df.dateFormat = "MMM"
            let ms = recent.map { df.string(from: $0.periodEnd) }
            let vs = recent.map { CGFloat(round($0.consumptionKwh)) }
            let maxV = max(vs.max() ?? 100, 50) * 1.25
            return (ms, vs, maxV)
        }
        return (["No data"], [0], 100)
    }
    
    private var captionText: String {
        let chart = chartModel
        if chart.values.isEmpty || chart.months.first == "No data" {
            return "Import electricity bills to view your historical consumption trend."
        }
        let pairs = zip(chart.months, chart.values).map { "\($0.0) \(String(format: "%.0f", $0.1)) kWh" }
        return pairs.joined(separator: " · ")
    }
    
    public init() {}
    
    public var body: some View {
        let chart = chartModel
        
        return VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Done") {
                navState.navigateBack()
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
                        Text(activeBill.periodText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", activeBill.kwh))
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        Text(activeBill.amountText)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Alert Banner
                        HStack(spacing: 10) {
                            Image(systemName: activeBill.isIncrease ? "exclamationmark.triangle" : "arrow.down.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(activeBill.isIncrease ? Color(red: 0.75, green: 0.45, blue: 0.08) : EnergyLensTheme.accentGreen)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activeBill.comparisonText)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(activeBill.isIncrease ? Color(red: 0.55, green: 0.32, blue: 0.05) : Color(red: 0.12, green: 0.45, blue: 0.28))
                                
                                Text("Based on your imported billing history")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(activeBill.isIncrease ? Color(red: 0.60, green: 0.38, blue: 0.10) : Color(red: 0.15, green: 0.50, blue: 0.30))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(activeBill.isIncrease ? EnergyLensTheme.alertYellowBg : Color(red: 0.88, green: 0.96, blue: 0.90))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(activeBill.isIncrease ? EnergyLensTheme.alertYellowBorder : Color.clear, lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
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
                            trendChartView(chart: chart)
                                .frame(height: 120)
                                .padding(.top, 14)
                                .padding(.horizontal, 10)
                            
                            // X-Axis Labels
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
                        }
                        
                        // Dynamic Caption
                        Text(captionText)
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
    private func trendChartView(chart: (months: [String], values: [CGFloat], maxValue: CGFloat)) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftPad: CGFloat = 34
            let chartWidth = w - leftPad - 16
            let count = max(1, chart.values.count)
            let stepX = count > 1 ? chartWidth / CGFloat(count - 1) : chartWidth / 2
            let maxVal = chart.maxValue
            
            ZStack {
                // Y-axis labels and horizontal baseline
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
                
                // Trend Line (if multiple points)
                if chart.values.count > 1 {
                    Path { path in
                        for i in 0..<chart.values.count {
                            let x = leftPad + CGFloat(i) * stepX
                            let ratio = chart.values[i] / maxVal
                            let y = (h - 14) - (ratio * (h - 28))
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color(red: 0.12, green: 0.58, blue: 0.32), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
                
                // Data dots and value label on latest point
                ForEach(0..<chart.values.count, id: \.self) { i in
                    let x = count > 1 ? (leftPad + CGFloat(i) * stepX) : (leftPad + chartWidth / 2)
                    let ratio = chart.values[i] / maxVal
                    let y = (h - 14) - (ratio * (h - 28))
                    
                    Circle()
                        .fill(Color(red: 0.12, green: 0.58, blue: 0.32))
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                    
                    if i == chart.values.count - 1 && chart.values[i] > 0 {
                        Text(String(format: "%.0f", chart.values[i]))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                            .position(x: x - 4, y: y - 14)
                    }
                }
            }
        }
    }
}
