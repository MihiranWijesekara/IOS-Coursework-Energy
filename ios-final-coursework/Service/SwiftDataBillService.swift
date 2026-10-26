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
    
    /// Update an existing saved bill permanently and synchronize corresponding SavedBill & Firebase
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
        
        // Find and update the matching SavedBill in context
        let billId = bill.id
        let descriptor = FetchDescriptor<SavedBill>()
        if let allSaved = try? context.fetch(descriptor) {
            let matched = allSaved.first { s in
                s.id == billId ||
                (!accountNumber.isEmpty && s.accountNumber == accountNumber &&
                 (s.billingMonth.lowercased() == billingPeriodText.lowercased() || s.readingDate == billingPeriodText))
            }
            if let matched {
                matched.accountNumber = accountNumber
                matched.customerName = customerName ?? ""
                matched.previousReading = prevReading ?? 0
                matched.currentReading = currReading ?? 0
                matched.hasReadingsValue = (prevReading != nil || currReading != nil)
                matched.totalKWh = max(0, consumptionKwh)
                if let currentCharges {
                    matched.electricityCharge = currentCharges
                    matched.hasEnergyChargeValue = true
                }
                if let taxesAndLevies {
                    matched.sscLevy = taxesAndLevies
                    matched.hasLevyValue = true
                }
                if let outstandingBalance {
                    matched.outstandingBalance = outstandingBalance
                    matched.hasOutstandingValue = true
                }
                matched.totalAmount = totalAmountPayable
                matched.monthlyBill = totalAmountPayable
                matched.hasMonthlyBillValue = true
                matched.billingMonth = billingPeriodText
                if let dueDate {
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd"
                    matched.dueDate = df.string(from: dueDate)
                }

                Task {
                    try? await FirebaseRESTService.shared.syncBill(bill: matched)
                }
            }
        }

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
    
    /// Delete an ElectricityBill and its corresponding SavedBill
    public func deleteBill(context: ModelContext, bill: ElectricityBill) throws {
        let billId = bill.id
        let acct = bill.accountNumber
        let period = bill.billingPeriodText

        context.delete(bill)

        let descriptor = FetchDescriptor<SavedBill>()
        if let allSaved = try? context.fetch(descriptor) {
            let matching = allSaved.filter { s in
                s.id == billId ||
                (!acct.isEmpty && s.accountNumber == acct &&
                 (s.billingMonth.lowercased() == period.lowercased() || s.readingDate == period))
            }
            for m in matching {
                context.delete(m)
            }
        }
        try context.save()
    }

    public func deleteBill(_ bill: ElectricityBill, in context: ModelContext) throws {
        try deleteBill(context: context, bill: bill)
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

    // MARK: - PDF Specification: SavedBill Persistence Methods

    /// Fetches all saved bills for a user sorted newest first by actual billing date.
    public func fetchBills(for email: String, in context: ModelContext) -> [SavedBill] {
        let descriptor = FetchDescriptor<SavedBill>(
            predicate: #Predicate { $0.userEmail == email }
        )
        let bills = (try? context.fetch(descriptor)) ?? []
        return bills.sorted { $0.actualBillingDate > $1.actualBillingDate }
    }

    /// Detects if a bill with the same Account Number and Reading Date (or Billing Month + Consumption) already exists.
    public func findDuplicateBill(for draft: BillExtractionDraft, userEmail: String, in context: ModelContext) -> SavedBill? {
        let existing = fetchBills(for: userEmail, in: context)
        let acct = draft.accountNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let rDate = draft.readingDate.trimmingCharacters(in: .whitespacesAndNewlines)
        let bMonth = draft.billingMonth.trimmingCharacters(in: .whitespacesAndNewlines)

        return existing.first { saved in
            if let editingID = draft.existingBillID, saved.id == editingID {
                return false
            }
            if !acct.isEmpty && !rDate.isEmpty {
                return saved.accountNumber == acct && saved.readingDate == rDate
            }
            if !acct.isEmpty && !bMonth.isEmpty {
                let draftKWh = Double(draft.totalKWh) ?? -1
                return saved.accountNumber == acct && saved.billingMonth == bMonth &&
                    abs(saved.totalKWh - draftKWh) < 0.01
            }
            return false
        }
    }

    /// Persists a user-reviewed and confirmed bill draft into SwiftData.
    @discardableResult
    public func saveReviewedBill(
        from draft: BillExtractionDraft,
        userEmail: String,
        overwriteDuplicateID: UUID? = nil,
        in context: ModelContext
    ) throws -> SavedBill {
        let structured = draft.toExtractedElectricityBill()
        guard let consumption = structured.consumptionUnits, consumption >= 0 else {
            throw BillPersistenceError.missingRequiredFields("Please enter a valid consumption (kWh / Units) value before saving.")
        }

        let resolvedTotalDecimal = structured.totalDue ?? structured.monthlyBill ?? structured.energyCharge
        guard let finalTotalDecimal = resolvedTotalDecimal, finalTotalDecimal >= 0 else {
            throw BillPersistenceError.missingRequiredFields("Please enter a valid Total Due or Monthly Bill amount before saving.")
        }

        let resolvedBillingMonth: String = {
            if let existingMonth = draft.billingMonth.trimmedNilIfEmpty {
                return existingMonth
            }
            if let rDate = structured.readingDate {
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "MMMM yyyy"
                return df.string(from: rDate)
            }
            if let rRaw = structured.readingDateRaw {
                return rRaw
            }
            let df = DateFormatter()
            df.dateFormat = "MMMM yyyy"
            return df.string(from: Date())
        }()

        let targetID = overwriteDuplicateID ?? draft.existingBillID
        let billToSave: SavedBill

        if let targetID,
           let existing = fetchBill(by: targetID, in: context) {
            billToSave = existing
        } else {
            billToSave = SavedBill(
                userEmail: userEmail,
                billingMonth: resolvedBillingMonth,
                totalKWh: Double(consumption),
                totalAmount: NSDecimalNumber(decimal: finalTotalDecimal).doubleValue,
                dueDate: draft.dueDate,
                providerName: structured.provider ?? "Electricity Provider"
            )
            context.insert(billToSave)
        }

        billToSave.userEmail = userEmail
        billToSave.formatTypeRaw = draft.formatType.rawValue
        billToSave.isCEBeBillFormat = (draft.formatType == .cebEBill)
        billToSave.providerName = structured.provider ?? "Electricity Provider"
        billToSave.accountNumber = structured.accountNumber ?? ""
        billToSave.customerName = structured.customerName ?? ""
        billToSave.tariffCategory = structured.tariffCode ?? ""
        billToSave.billingMonth = resolvedBillingMonth
        billToSave.readingDate = structured.readingDateRaw ?? draft.readingDate
        billToSave.readingReference = structured.readingDateSuffix ?? ""
        billToSave.dueDate = structured.paymentDueDateRaw ?? draft.dueDate
        billToSave.previousReading = structured.previousReading ?? 0
        billToSave.currentReading = structured.currentReading ?? 0
        billToSave.hasReadingsValue = (structured.previousReading != nil || structured.currentReading != nil)
        billToSave.totalKWh = Double(consumption)

        billToSave.previousBalance = structured.broughtForward.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        billToSave.hasPreviousBalanceValue = (structured.broughtForward != nil)
        billToSave.payments = structured.payments.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        billToSave.hasPaymentsValue = (structured.payments != nil)
        billToSave.outstandingBalance = structured.outstandingBalance.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        billToSave.hasOutstandingValue = (structured.outstandingBalance != nil)
        billToSave.outstandingDate = structured.outstandingDueDateRaw ?? draft.outstandingDate
        billToSave.electricityCharge = structured.energyCharge.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        billToSave.hasEnergyChargeValue = (structured.energyCharge != nil)
        billToSave.sscLevy = structured.levyAmount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        billToSave.hasLevyValue = (structured.levyAmount != nil)
        billToSave.monthlyBill = structured.monthlyBill.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        billToSave.hasMonthlyBillValue = (structured.monthlyBill != nil)
        billToSave.totalAmount = NSDecimalNumber(decimal: finalTotalDecimal).doubleValue
        billToSave.billURL = structured.billURL ?? ""
        billToSave.currency = structured.currency
        billToSave.rawOCRText = structured.rawOCRText
        billToSave.extractionConfidence = Double(structured.extractionConfidence)

        // Lookup matching User by userEmail for ownership
        var matchedUser: User? = nil
        if !userEmail.isEmpty {
            let userDesc = FetchDescriptor<User>()
            if let users = try? context.fetch(userDesc) {
                matchedUser = users.first { $0.email.lowercased() == userEmail.lowercased() }
            }
        }

        // Synchronize with ElectricityBill using the exact same ID
        let cal = Calendar.current
        let rDateObj = structured.readingDate ?? Date()
        let pStart = cal.date(byAdding: .day, value: -30, to: rDateObj) ?? rDateObj

        let elecDesc = FetchDescriptor<ElectricityBill>()
        let existingElecBills = (try? context.fetch(elecDesc)) ?? []
        let targetElecID = billToSave.id
        let existingElec = existingElecBills.first { e in
            e.id == targetElecID ||
            (!billToSave.accountNumber.isEmpty && e.accountNumber == billToSave.accountNumber && e.billingPeriodText.lowercased() == resolvedBillingMonth.lowercased())
        }

        if let existingElec {
            existingElec.periodStart = pStart
            existingElec.periodEnd = rDateObj
            existingElec.prevReading = structured.previousReading
            existingElec.currReading = structured.currentReading
            existingElec.consumptionKwh = Double(consumption)
            existingElec.billAmount = NSDecimalNumber(decimal: finalTotalDecimal).doubleValue
            existingElec.currency = structured.currency
            existingElec.provider = structured.provider ?? "CEB"
            existingElec.accountNumber = structured.accountNumber ?? ""
            existingElec.customerName = structured.customerName
            existingElec.tariffCategory = structured.tariffCode
            existingElec.billDate = structured.readingDate
            existingElec.dueDate = structured.paymentDueDate
            existingElec.billingPeriodText = resolvedBillingMonth
            existingElec.currentCharges = structured.energyCharge.map { NSDecimalNumber(decimal: $0).doubleValue }
            existingElec.taxesAndLevies = structured.levyAmount.map { NSDecimalNumber(decimal: $0).doubleValue }
            existingElec.previousBalance = structured.broughtForward.map { NSDecimalNumber(decimal: $0).doubleValue }
            existingElec.payments = structured.payments.map { NSDecimalNumber(decimal: $0).doubleValue }
            existingElec.outstandingBalance = structured.outstandingBalance.map { NSDecimalNumber(decimal: $0).doubleValue }
            existingElec.totalAmountPayable = NSDecimalNumber(decimal: finalTotalDecimal).doubleValue
            existingElec.rawOcrText = structured.rawOCRText
            existingElec.isVerified = true
            if let matchedUser {
                existingElec.user = matchedUser
            }
        } else {
            let newElec = ElectricityBill(
                id: billToSave.id,
                periodStart: pStart,
                periodEnd: rDateObj,
                prevReading: structured.previousReading,
                currReading: structured.currentReading,
                consumptionKwh: Double(consumption),
                billAmount: NSDecimalNumber(decimal: finalTotalDecimal).doubleValue,
                currency: structured.currency,
                provider: structured.provider ?? "CEB",
                accountNumber: structured.accountNumber ?? "",
                customerName: structured.customerName,
                customerAddress: nil,
                tariffCategory: structured.tariffCode,
                billDate: structured.readingDate,
                dueDate: structured.paymentDueDate,
                billingPeriodText: resolvedBillingMonth,
                currentCharges: structured.energyCharge.map { NSDecimalNumber(decimal: $0).doubleValue },
                fixedCharges: nil,
                taxesAndLevies: structured.levyAmount.map { NSDecimalNumber(decimal: $0).doubleValue },
                previousBalance: structured.broughtForward.map { NSDecimalNumber(decimal: $0).doubleValue },
                payments: structured.payments.map { NSDecimalNumber(decimal: $0).doubleValue },
                outstandingBalance: structured.outstandingBalance.map { NSDecimalNumber(decimal: $0).doubleValue },
                totalAmountPayable: NSDecimalNumber(decimal: finalTotalDecimal).doubleValue,
                rawOcrText: structured.rawOCRText,
                uploadedAt: Date(),
                imageData: nil,
                isVerified: true,
                user: matchedUser
            )
            context.insert(newElec)
        }

        do {
            try context.save()
            return billToSave
        } catch {
            if overwriteDuplicateID == nil && draft.existingBillID == nil {
                context.delete(billToSave)
            }
            throw BillPersistenceError.saveFailed(error.localizedDescription)
        }
    }

    public func fetchBill(by id: UUID, in context: ModelContext) -> SavedBill? {
        let descriptor = FetchDescriptor<SavedBill>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    /// Delete a SavedBill and its corresponding ElectricityBill
    public func deleteBill(_ bill: SavedBill, in context: ModelContext) throws {
        let billId = bill.id
        let acct = bill.accountNumber
        let period = bill.billingMonth
        let rDate = bill.readingDate

        context.delete(bill)

        let descriptor = FetchDescriptor<ElectricityBill>()
        if let allElec = try? context.fetch(descriptor) {
            let matching = allElec.filter { e in
                e.id == billId ||
                (!acct.isEmpty && e.accountNumber == acct &&
                 (e.billingPeriodText.lowercased() == period.lowercased() || e.billingPeriodText == rDate))
            }
            for m in matching {
                context.delete(m)
            }
        }
        try context.save()
    }

    public func deleteBill(context: ModelContext, bill: SavedBill) throws {
        try deleteBill(bill, in: context)
    }
}

// MARK: - Persistence Errors
public enum BillPersistenceError: LocalizedError {
    case contextUnavailable
    case missingRequiredFields(String)
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .contextUnavailable:
            return "Database storage context is unavailable."
        case .missingRequiredFields(let details):
            return details
        case .saveFailed(let reason):
            return "Failed to save electricity bill: \(reason)"
        }
    }
}

