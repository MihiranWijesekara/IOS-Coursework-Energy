//
//  SwiftDataBillService.swift
//  ios-final-coursework
//
//  Created for managing local SwiftData operations, comparisons, and analytics for Electricity Bills
//

import Foundation
import SwiftData

public final class SwiftDataBillService {
    public static let shared = SwiftDataBillService()
    
    private init() {}
    
    /// Save an extracted/reviewed bill into SwiftData
    @discardableResult
    public func saveBill(
        context: ModelContext,
        periodStart: Date,
        periodEnd: Date,
        prevReading: Int?,
        currReading: Int?,
        consumptionKwh: Double,
        billAmount: Double,
        currency: String = "LKR",
        user: User? = nil
    ) throws -> ElectricityBill {
        let bill = ElectricityBill(
            periodStart: periodStart,
            periodEnd: periodEnd,
            prevReading: prevReading,
            currReading: currReading,
            consumptionKwh: max(0, consumptionKwh),
            billAmount: max(0, billAmount),
            currency: currency,
            user: user
        )
        
        context.insert(bill)
        try context.save()
        return bill
    }
    
    /// Fetch all bills sorted by periodEnd descending (most recent first)
    public func fetchAllBills(context: ModelContext) throws -> [ElectricityBill] {
        let descriptor = FetchDescriptor<ElectricityBill>(
            sortBy: [SortDescriptor(\.periodEnd, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// Delete a bill
    public func deleteBill(context: ModelContext, bill: ElectricityBill) throws {
        context.delete(bill)
        try context.save()
    }
    
    /// Calculate month-over-month comparison between the latest bill and previous bill
    public func calculateComparison(latest: ElectricityBill, previous: ElectricityBill?) -> (percentageChange: Double, diffKwh: Double, isIncrease: Bool, text: String) {
        guard let prev = previous, prev.consumptionKwh > 0 else {
            return (0, 0, false, "First imported bill")
        }
        
        let diff = latest.consumptionKwh - prev.consumptionKwh
        let percent = (diff / prev.consumptionKwh) * 100.0
        let isIncrease = diff >= 0
        
        let arrow = isIncrease ? "↑" : "↓"
        let sign = isIncrease ? "+" : ""
        let percentStr = String(format: "%.1f", abs(percent))
        let diffStr = String(format: "%.0f", abs(diff))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let latestMonth = formatter.string(from: latest.periodEnd)
        let prevMonth = formatter.string(from: prev.periodEnd)
        
        let summaryText = "\(arrow) \(percentStr)% vs \(prevMonth) · \(Int(round(prev.consumptionKwh))) kWh"
        
        return (percent, diff, isIncrease, summaryText)
    }
    
    /// Format billing period (e.g., "01 Sep – 30 Sep 2026")
    public static func formatPeriod(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        let startStr = formatter.string(from: start)
        
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "dd MMM yyyy"
        let endStr = endFormatter.string(from: end)
        
        return "\(startStr) – \(endStr)"
    }
    
    /// Format Month & Year for Header (e.g. "SEPTEMBER 2026")
    public static func formatMonthYear(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }
}
