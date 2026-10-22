//
//  SwiftDataBillService.swift
//  ios-final-coursework
//
//  Production SwiftData Manager for Electricity Bills
//  Provides CRUD operations, duplicate detection, analytics, and period formatting.
//

import Foundation
import SwiftData

public final class SwiftDataBillService {
    public static let shared = SwiftDataBillService()
    
    private init() {}
    
    /// Save an extracted and verified bill into SwiftData
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
        provider: String = "CEB",
        accountNumber: String = "",
        customerName: String? = nil,
        customerAddress: String? = nil,
        tariffCategory: String? = nil,
        billDate: Date? = nil,
        dueDate: Date? = nil,
        billingPeriodText: String = "",
        currentCharges: Double? = nil,
        fixedCharges: Double? = nil,
        taxesAndLevies: Double? = nil,
        previousBalance: Double? = nil,
        payments: Double? = nil,
        outstandingBalance: Double? = nil,
        totalAmountPayable: Double? = nil,
        rawOcrText: String = "",
        imageData: Data? = nil,
        isVerified: Bool = true,
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
            provider: provider,
            accountNumber: accountNumber,
            customerName: customerName,
            customerAddress: customerAddress,
            tariffCategory: tariffCategory,
            billDate: billDate,
            dueDate: dueDate,
            billingPeriodText: billingPeriodText,
            currentCharges: currentCharges,
            fixedCharges: fixedCharges,
            taxesAndLevies: taxesAndLevies,
            previousBalance: previousBalance,
            payments: payments,
            outstandingBalance: outstandingBalance,
            totalAmountPayable: totalAmountPayable ?? billAmount,
            rawOcrText: rawOcrText,
            uploadedAt: Date(),
            imageData: imageData,
            isVerified: isVerified,
            user: user
        )
        
        context.insert(bill)
        try context.save()
        return bill
    }
    
    /// Update an existing saved bill permanently
    public func updateBill(
        context: ModelContext,
        bill: ElectricityBill,
        accountNumber: String,
        customerName: String?,
        prevReading: Int?,
        currReading: Int?,
        consumptionKwh: Double,
        currentCharges: Double?,
        taxesAndLevies: Double?,
        outstandingBalance: Double?,
        totalAmountPayable: Double,
        billingPeriodText: String,
        dueDate: Date?
    ) throws {
        bill.accountNumber = accountNumber
        bill.customerName = customerName
        bill.prevReading = prevReading
        bill.currReading = currReading
        bill.consumptionKwh = max(0, consumptionKwh)
        bill.currentCharges = currentCharges
        bill.taxesAndLevies = taxesAndLevies
        bill.outstandingBalance = outstandingBalance
        bill.totalAmountPayable = totalAmountPayable
        bill.billAmount = totalAmountPayable
        bill.billingPeriodText = billingPeriodText
        bill.dueDate = dueDate
        bill.isVerified = true
        
        try context.save()
    }
    
    /// Detect if a bill for the same account number and billing period already exists
    public func findDuplicate(
        context: ModelContext,
        accountNumber: String,
        billingPeriodText: String
    ) throws -> ElectricityBill? {
        guard !accountNumber.isEmpty else { return nil }
        let allBills = try fetchAllBills(context: context)
        return allBills.first { b in
            b.accountNumber.replacingOccurrences(of: " ", with: "") == accountNumber.replacingOccurrences(of: " ", with: "") &&
            (!billingPeriodText.isEmpty && b.billingPeriodText.lowercased() == billingPeriodText.lowercased())
        }
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
    
    /// Calculate month-over-month comparison between latest bill and previous bill
    public func calculateComparison(latest: ElectricityBill, previous: ElectricityBill?) -> (percentageChange: Double, diffKwh: Double, isIncrease: Bool, text: String) {
        guard let prev = previous, prev.consumptionKwh > 0 else {
            return (0, 0, false, "First imported bill")
        }
        
        let diff = latest.consumptionKwh - prev.consumptionKwh
        let percent = (diff / prev.consumptionKwh) * 100.0
        let isIncrease = diff >= 0
        
        let arrow = isIncrease ? "↑" : "↓"
        let percentStr = String(format: "%.1f", abs(percent))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
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
