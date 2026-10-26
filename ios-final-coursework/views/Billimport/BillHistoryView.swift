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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]

    @State private var selectedPeriod = 0 // 0: 5 months, 1: Year
    @State private var billToDelete: ElectricityBill? = nil
    @State private var pdfBillToDelete: SavedBill? = nil
    @State private var showDeleteAlert = false
    
    public init() {}

    // Functional 5 months (selectedPeriod == 0) vs Year (selectedPeriod == 1) dynamic chart model
    private var chartModel: (months: [String], values: [CGFloat], maxValue: CGFloat, latestValue: CGFloat) {
        let maxCount = (selectedPeriod == 0) ? 5 : 12
        
        let sortedPDF = pdfSavedBills.sorted { $0.actualBillingDate > $1.actualBillingDate }
        if !sortedPDF.isEmpty {
            let slice = Array(sortedPDF.prefix(maxCount).reversed())
            let ms = slice.map { b -> String in
                if !b.billingMonth.isEmpty {
                    let parts = b.billingMonth.components(separatedBy: " ")
                    if let first = parts.first, first.count >= 3 {
                        return String(first.prefix(3))
                    }
                    return b.billingMonth
                }
                let df = DateFormatter()
                df.dateFormat = "MMM"
                return df.string(from: b.actualBillingDate)
            }
            let vs = slice.map { CGFloat(round($0.totalKWh)) }
            let maxV = max(vs.max() ?? 100, 50) * 1.25
            let latest = vs.last ?? 0
            return (ms, vs, maxV, latest)
        } else if !savedBills.isEmpty {
            let slice = Array(savedBills.prefix(maxCount).reversed())
            let df = DateFormatter()
            df.dateFormat = "MMM"
            let ms = slice.map { df.string(from: $0.periodEnd) }
            let vs = slice.map { CGFloat(round($0.consumptionKwh)) }
            let maxV = max(vs.max() ?? 100, 50) * 1.25
            let latest = vs.last ?? 0
            return (ms, vs, maxV, latest)
        }
        return ([], [], 100, 0)
    }

    private var totalBillCount: Int {
        if !savedBills.isEmpty {
            return savedBills.count
        }
        return pdfSavedBills.count
    }
    
    public var body: some View {
        if savedBills.isEmpty && pdfSavedBills.isEmpty {
            BillHistoryEmptyView()
        } else {
            mainHistoryContent
        }
    }

    private var mainHistoryContent: some View {
        let chart = chartModel
        
        return VStack(alignment: .leading, spacing: 0) {
            // Top Bar
            HStack {
                CustomBackButton(title: "Bill Analysis") {
                    navState.navigate(to: .billAnalysis)
                }
                
                Spacer()
                
                Button(action: {
                    navState.navigate(to: .selectBillImage)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Import")
                    }
                    .font(.system(size: 16, weight: .semibold))
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
                        
                        darkTrendChart(chart: chart)
                            .frame(height: 110)
                            .padding(.top, 8)
                        
                        // X-axis labels
                        if !chart.months.isEmpty {
                            HStack {
                                ForEach(Array(chart.months.enumerated()), id: \.offset) { index, month in
                                    Text(month)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.75))
                                    if index != chart.months.count - 1 {
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, chart.months.count == 1 ? 50 : 32)
                            .padding(.top, 2)
                        }
                    }
                    .padding(18)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(18)
                    
                    // Caption
                    Text("Monthly electricity trend. Tap any saved bill below to view full details or edit.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Section: Bills
                    HStack {
                        Text("Imported bills (\(totalBillCount))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    // Bill list
                    VStack(spacing: 10) {
                        if !savedBills.isEmpty {
                            ForEach(Array(savedBills.enumerated()), id: \.element.id) { index, bill in
                                Button(action: {
                                    navState.selectedBillId = bill.id
                                    navState.navigate(to: .billDetail)
                                }) {
                                    let formatter = DateFormatter()
                                    let _ = formatter.dateFormat = "MMMM yyyy"
                                    let monthTitle = bill.billingPeriodText.isEmpty ? formatter.string(from: bill.periodEnd) : bill.billingPeriodText
                                    let curr = (bill.currency.uppercased() == "USD" || bill.currency == "$") ? "$" : "Rs."
                                    let subtitle = "\(bill.accountNumber.isEmpty ? "" : "A/C: " + bill.accountNumber + " · ")\(Int(round(bill.consumptionKwh))) kWh · \(curr) \(String(format: "%.2f", bill.totalAmountPayable))"
                                    
                                    billRow(
                                        month: monthTitle,
                                        subtitle: subtitle,
                                        provider: bill.provider,
                                        hasImage: bill.imageData != nil,
                                        isHighlighted: index == 0,
                                        onDelete: {
                                            billToDelete = bill
                                            showDeleteAlert = true
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            ForEach(Array(pdfSavedBills.enumerated()), id: \.element.id) { index, bill in
                                Button(action: {
                                    navState.selectedBillId = bill.id
                                    navState.navigate(to: .billDetail)
                                }) {
                                    let monthTitle = bill.billingMonth.isEmpty ? "Saved Bill" : bill.billingMonth
                                    let curr = (bill.currency.uppercased() == "USD" || bill.currency == "$") ? "$" : "Rs."
                                    let amt = bill.monthlyBill > 0 ? bill.monthlyBill : bill.totalAmount
                                    let subtitle = "\(bill.accountNumber.isEmpty ? "" : "A/C: " + bill.accountNumber + " · ")\(Int(round(bill.totalKWh))) kWh · \(curr) \(String(format: "%.2f", amt))"
                                    
                                    billRow(
                                        month: monthTitle,
                                        subtitle: subtitle,
                                        provider: bill.providerName,
                                        hasImage: false,
                                        isHighlighted: index == 0,
                                        onDelete: {
                                            pdfBillToDelete = bill
                                            showDeleteAlert = true
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .alert("Delete Electricity Bill?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let b = billToDelete {
                    try? SwiftDataBillService.shared.deleteBill(context: modelContext, bill: b)
                    billToDelete = nil
                } else if let pb = pdfBillToDelete {
                    try? SwiftDataBillService.shared.deleteBill(context: modelContext, bill: pb)
                    pdfBillToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                billToDelete = nil
                pdfBillToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this electricity bill from SwiftData?")
        }
    }

    @ViewBuilder
    private func billRow(
        month: String,
        subtitle: String,
        provider: String,
        hasImage: Bool,
        isHighlighted: Bool,
        onDelete: (() -> Void)?
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 22))
                .foregroundColor(isHighlighted ? EnergyLensTheme.accentGreen : EnergyLensTheme.textMuted)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(month)
                        .font(.system(size: 15, weight: isHighlighted ? .bold : .medium))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    Text(provider)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.10, green: 0.45, blue: 0.55).opacity(0.15))
                        .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.55))
                        .cornerRadius(4)
                    
                    if hasImage {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 10))
                            .foregroundColor(EnergyLensTheme.accentGreen)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
            }
            
            Spacer()
            
            if let del = onDelete {
                Button(action: del) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(EnergyLensTheme.textMuted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(isHighlighted ? EnergyLensTheme.mintHighlight : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isHighlighted ? Color.clear : EnergyLensTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private func darkTrendChart(chart: (months: [String], values: [CGFloat], maxValue: CGFloat, latestValue: CGFloat)) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let leftPad: CGFloat = 34
            let rightPad: CGFloat = 16
            let chartWidth = max(10, w - leftPad - rightPad)
            let count = chart.values.count
            let maxVal = max(chart.maxValue, 10)
            
            ZStack {
                // Y-axis labels
                VStack {
                    HStack {
                        Text(String(format: "%.0f", maxVal))
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
                    path.addLine(to: CGPoint(x: w - 8, y: h - 8))
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                
                if count == 0 {
                    Text("No billing data to display")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .position(x: leftPad + chartWidth / 2, y: h / 2)
                } else if count == 1 {
                    let x = leftPad + chartWidth / 2
                    let ratio = min(1.0, max(0.0, chart.values[0] / maxVal))
                    let y = (h - 12) - (ratio * (h - 24))
                    
                    Circle()
                        .fill(Color(red: 0.40, green: 0.90, blue: 0.70))
                        .frame(width: 7, height: 7)
                        .position(x: x, y: y)
                    
                    Text(String(format: "%.0f", chart.values[0]))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .position(x: x, y: y - 14)
                } else {
                    let stepX = chartWidth / CGFloat(count - 1)
                    
                    // Mint line
                    Path { path in
                        for i in 0..<count {
                            let x = leftPad + CGFloat(i) * stepX
                            let ratio = min(1.0, max(0.0, chart.values[i] / maxVal))
                            let y = (h - 12) - (ratio * (h - 24))
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color(red: 0.40, green: 0.90, blue: 0.70), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    
                    // Dots and latest label
                    ForEach(0..<count, id: \.self) { i in
                        let x = leftPad + CGFloat(i) * stepX
                        let ratio = min(1.0, max(0.0, chart.values[i] / maxVal))
                        let y = (h - 12) - (ratio * (h - 24))
                        
                        Circle()
                            .fill(Color(red: 0.40, green: 0.90, blue: 0.70))
                            .frame(width: 5.5, height: 5.5)
                            .position(x: x, y: y)
                        
                        if i == count - 1 && chart.values[i] > 0 {
                            Text(String(format: "%.0f", chart.values[i]))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .position(x: x - 4, y: y - 14)
                        }
                    }
                }
            }
        }
    }
}
