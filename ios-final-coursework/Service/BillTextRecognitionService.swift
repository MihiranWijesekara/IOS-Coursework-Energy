//
//  BillTextRecognitionService.swift
//  ios-final-coursework
//
//  Production Vision OCR & Intelligent Sri Lankan Electricity Bill Parsing Engine
//  Supports CEB e-Bills, CEB Invoices, and LECO physical statements.
//

import Foundation
import UIKit
import Vision

// MARK: - Extracted Bill Data Model
public struct ExtractedBillData: Equatable {
    public var provider: String                  // "CEB", "LECO", or "Unknown"
    public var accountNumber: String              // e.g. "5410264908"
    public var tariffCategory: String?            // e.g. "D1"
    public var customerName: String?              // e.g. "R RANJITH"
    public var customerAddress: String?           // Billing address if present
    public var readingDate: String?               // e.g. "2026-09-30"
    public var billingPeriod: String              // e.g. "01 Sep – 30 Sep 2026"
    public var dueDate: String?                   // e.g. "2026-09-17"
    public var previousReading: String            // e.g. "10,678 kWh"
    public var currentReading: String             // e.g. "10,756 kWh"
    public var consumptionKwh: String             // e.g. "78 kWh"
    public var currentCharge: String?             // e.g. "Rs. 1,588.00"
    public var fixedCharges: String?              // e.g. "Rs. 540.00"
    public var taxesAndLevies: String?            // e.g. "Rs. 40.72" (SSC Levy)
    public var monthlyBill: String?               // e.g. "Rs. 1,628.72"
    public var previousBalance: String?           // e.g. "Rs. 2,987.07" (B/F)
    public var payments: String?                  // e.g. "Rs. 2,200.00"
    public var outstandingBalance: String?        // e.g. "Rs. 787.07"
    public var totalAmountPayable: String         // e.g. "Rs. 2,415.79"
    public var ebillLink: String?                 // e.g. "https://ebill.edl.lk/..."
    public var rawText: String                    // Complete detected text
    
    // Mathematical & Verification Metadata
    public var isMathConsistent: Bool
    public var validationMessages: [String]
    public var confidenceScore: Double            // 0.0 to 1.0

    // Backward-compatibility alias for views expecting billAmount
    public var billAmount: String {
        get {
            if !totalAmountPayable.isEmpty {
                return totalAmountPayable
            } else if let mb = monthlyBill, !mb.isEmpty {
                return mb
            }
            return "LKR 0.00"
        }
        set {
            totalAmountPayable = newValue
        }
    }

    public init(
        provider: String = "CEB",
        accountNumber: String = "",
        tariffCategory: String? = nil,
        customerName: String? = nil,
        customerAddress: String? = nil,
        readingDate: String? = nil,
        billingPeriod: String = "",
        dueDate: String? = nil,
        previousReading: String = "",
        currentReading: String = "",
        consumptionKwh: String = "",
        currentCharge: String? = nil,
        fixedCharges: String? = nil,
        taxesAndLevies: String? = nil,
        monthlyBill: String? = nil,
        previousBalance: String? = nil,
        payments: String? = nil,
        outstandingBalance: String? = nil,
        totalAmountPayable: String = "",
        ebillLink: String? = nil,
        rawText: String = "",
        isMathConsistent: Bool = true,
        validationMessages: [String] = [],
        confidenceScore: Double = 1.0
    ) {
        self.provider = provider
        self.accountNumber = accountNumber
        self.tariffCategory = tariffCategory
        self.customerName = customerName
        self.customerAddress = customerAddress
        self.readingDate = readingDate
        self.billingPeriod = billingPeriod
        self.dueDate = dueDate
        self.previousReading = previousReading
        self.currentReading = currentReading
        self.consumptionKwh = consumptionKwh
        self.currentCharge = currentCharge
        self.fixedCharges = fixedCharges
        self.taxesAndLevies = taxesAndLevies
        self.monthlyBill = monthlyBill
        self.previousBalance = previousBalance
        self.payments = payments
        self.outstandingBalance = outstandingBalance
        self.totalAmountPayable = totalAmountPayable
        self.ebillLink = ebillLink
        self.rawText = rawText
        self.isMathConsistent = isMathConsistent
        self.validationMessages = validationMessages
        self.confidenceScore = confidenceScore
    }

    // Default sample for previews and mock states
    public static let sample = ExtractedBillData(
        provider: "CEB",
        accountNumber: "5410264908",
        tariffCategory: "D1",
        customerName: "R RANJITH",
        customerAddress: "Colombo, Sri Lanka",
        readingDate: "2026-09-30",
        billingPeriod: "01 Sep – 30 Sep 2026",
        dueDate: "2026-09-17",
        previousReading: "10,678 kWh",
        currentReading: "10,756 kWh",
        consumptionKwh: "78 kWh",
        currentCharge: "Rs. 1,588.00",
        fixedCharges: "Rs. 0.00",
        taxesAndLevies: "Rs. 40.72",
        monthlyBill: "Rs. 1,628.72",
        previousBalance: "Rs. 2,987.07",
        payments: "Rs. 2,200.00",
        outstandingBalance: "Rs. 787.07",
        totalAmountPayable: "Rs. 2,415.79",
        ebillLink: "https://ebill.edl.lk/v1/NTQxMDI2NDkwOCo0NTcqNTg2",
        rawText: "Sample CEB e-Bill",
        isMathConsistent: true,
        validationMessages: [
            "Meter readings verified (10756 - 10678 = 78 Units)",
            "Charge + SSC Levy equals Monthly Bill (1588.00 + 40.72 = 1628.72)",
            "Outstanding + Monthly Bill equals Total Due (787.07 + 1628.72 = 2415.79)"
        ],
        confidenceScore: 0.98
    )

    // Numeric extractors
    public var previousReadingValue: Int? {
        Int(Self.cleanNumericString(from: previousReading))
    }

    public var currentReadingValue: Int? {
        Int(Self.cleanNumericString(from: currentReading))
    }

    public var consumptionValue: Double? {
        Double(Self.cleanNumericString(from: consumptionKwh))
    }

    public var totalAmountValue: Double? {
        Double(Self.cleanNumericString(from: totalAmountPayable))
    }

    public var monthlyBillValue: Double? {
        guard let mb = monthlyBill else { return nil }
        return Double(Self.cleanNumericString(from: mb))
    }

    public var currentChargeValue: Double? {
        guard let c = currentCharge else { return nil }
        return Double(Self.cleanNumericString(from: c))
    }

    public var taxesValue: Double? {
        guard let t = taxesAndLevies else { return nil }
        return Double(Self.cleanNumericString(from: t))
    }

    public var previousBalanceValue: Double? {
        guard let p = previousBalance else { return nil }
        return Double(Self.cleanNumericString(from: p))
    }

    public var paymentsValue: Double? {
        guard let p = payments else { return nil }
        return Double(Self.cleanNumericString(from: p))
    }

    public var outstandingValue: Double? {
        guard let o = outstandingBalance else { return nil }
        return Double(Self.cleanNumericString(from: o))
    }

    public static func cleanNumericString(from input: String) -> String {
        var sanitized = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "kWh", with: "")
            .replacingOccurrences(of: "KWH", with: "")
            .replacingOccurrences(of: "kwh", with: "")
            .replacingOccurrences(of: "Units", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Unit", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "LKR", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let numberPattern = #"[-+]?\d+(?:\.\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: numberPattern),
              let match = regex.firstMatch(in: sanitized, range: NSRange(sanitized.startIndex..., in: sanitized)) else {
            return "0"
        }

        return (sanitized as NSString).substring(with: match.range)
    }

    // MARK: - Intelligent Parser Engine
    public static func parse(from rawText: String) -> ExtractedBillData {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ExtractedBillData(provider: "Unknown", rawText: "")
        }

        let lines = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var validationMessages: [String] = []

        // 1. PROVIDER IDENTIFICATION
        var provider = "Unknown"
        if trimmed.range(of: "\\bCEB\\b|Ceylon Electricity Board|ebill\\.edl\\.lk", options: .regularExpression) != nil {
            provider = "CEB"
        } else if trimmed.range(of: "\\bLECO\\b|Lanka Electricity", options: .regularExpression) != nil {
            provider = "LECO"
        } else {
            provider = "CEB"
        }

        // 2. ACCOUNT NUMBER & TARIFF CATEGORY
        var accountNumber = ""
        var tariffCategory: String? = nil

        let acRegexPatterns = [
            #"A/C\s*(?:No|Numbers?)?[\s.:]*([0-9\s]{9,14})(?:\s*\(([A-Z0-9]+)\))?"#,
            #"Account\s*(?:No|Number)?[\s.:]*([0-9\s]{9,14})(?:\s*\(([A-Z0-9]+)\))?"#,
            #"Payment\s*Ref[\s.:]*([0-9]{10})"#
        ]

        for pat in acRegexPatterns {
            if let groups = captureGroups(in: trimmed, pattern: pat, count: 2) {
                let cleanedAc = groups[0].replacingOccurrences(of: " ", with: "")
                if cleanedAc.count >= 9 {
                    accountNumber = cleanedAc
                    if !groups[1].isEmpty {
                        tariffCategory = groups[1]
                    }
                    break
                }
            } else if let single = firstCaptureGroup(in: trimmed, pattern: pat) {
                let cleanedAc = single.replacingOccurrences(of: " ", with: "")
                if cleanedAc.count >= 9 {
                    accountNumber = cleanedAc
                    break
                }
            }
        }

        if tariffCategory == nil {
            if let tMatch = firstCaptureGroup(in: trimmed, pattern: #"(?:Tariff|Category)[\s.:]*([A-Z0-9\s-]{2,12})"#) {
                tariffCategory = tMatch.trimmingCharacters(in: .whitespaces)
            }
        }

        // 3. CUSTOMER NAME
        var customerName: String? = nil
        for (idx, line) in lines.enumerated() {
            if line.contains("A/C No") || line.contains("A/C Numbers") {
                if idx + 1 < lines.count {
                    let next = lines[idx + 1]
                    if !next.contains("B/F") && !next.contains("Reading") && !next.contains("http") && !next.contains("Date") {
                        if next.range(of: #"^[A-Za-z\s.]{2,40}$"#, options: .regularExpression) != nil {
                            customerName = next
                            break
                        }
                    }
                }
            } else if line.contains("Account Name") || line.contains("Customer Name") {
                if let name = firstCaptureGroup(in: line, pattern: #"(?:Account\s*Name|Customer\s*Name)[\s.:]*([A-Za-z\s.]+)"#) {
                    customerName = name
                    break
                }
            }
        }

        // 4. DATES (Reading Date, Due Date, Billing Period)
        var readingDate: String? = nil
        var dueDate: String? = nil
        var billingPeriod = ""

        if let rdMatch = firstCaptureGroup(in: trimmed, pattern: #"Reading\s*Date[\s.:]*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{2}/\d{2}/\d{2})"#) {
            readingDate = rdMatch
        } else if let bpdMatch = firstCaptureGroup(in: trimmed, pattern: #"Bill\s*Print\s*Date[\s.:]*(\d{2}/\d{2}/\d{2,4})"#) {
            readingDate = bpdMatch
        }

        if let dueMatch = firstCaptureGroup(in: trimmed, pattern: #"(?:by|Due\s*Date)[\s.:]*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{2}/\d{2}/\d{2})"#) {
            dueDate = dueMatch
        }

        let rangePattern = #"(\d{1,2}\s+[A-Za-z]{3,9}(?:\s+\d{4})?\s*(?:-|–|to)\s*\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})"#
        if let rangeMatch = firstCaptureGroup(in: trimmed, pattern: rangePattern) {
            billingPeriod = rangeMatch
        } else if let rDate = readingDate, let formattedPeriod = convertDateToBillingPeriod(rDate) {
            billingPeriod = formattedPeriod
        } else {
            billingPeriod = "Statement Period"
        }

        // 5. READINGS & CONSUMPTION EQUATION
        var prevReadingStr = ""
        var currReadingStr = ""
        var consumptionStr = ""

        let cebEquationPattern = #"Reading[\s:]*(\d[\d,]*)\s*[-–]\s*(\d[\d,]*)\s*=\s*(\d[\d,]*)\s*(?:Units|kWh)?"#
        if let eqGroups = captureGroups(in: trimmed, pattern: cebEquationPattern, count: 3) {
            currReadingStr = "\(eqGroups[0]) kWh"
            prevReadingStr = "\(eqGroups[1]) kWh"
            consumptionStr = "\(eqGroups[2]) kWh"
        } else {
            let foundPrev = findNumberNearKeywords(in: lines, keywords: ["previous reading", "prev. reading", "prev reading", "previous"])
            let foundCurr = findNumberNearKeywords(in: lines, keywords: ["current reading", "curr. reading", "present reading", "meter reading"])
            let foundCons = findNumberNearKeywords(in: lines, keywords: ["consumption", "units consumed", "units", "total units"])

            if let p = foundPrev { prevReadingStr = "\(p) kWh" }
            if let c = foundCurr { currReadingStr = "\(c) kWh" }
            if let k = foundCons { consumptionStr = "\(k) kWh" }

            if consumptionStr.isEmpty,
               let pInt = Int(cleanNumericString(from: prevReadingStr)),
               let cInt = Int(cleanNumericString(from: currReadingStr)),
               cInt >= pInt {
                consumptionStr = "\(cInt - pInt) kWh"
            }
        }

        // 6. DETAILED CHARGES BREAKDOWN
        var currentCharge: String? = nil
        if let cMatch = firstCaptureGroup(in: trimmed, pattern: #"\bCharge[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#) {
            currentCharge = "Rs. \(cMatch)"
        }

        var fixedCharges: String? = nil
        if let fMatch = firstCaptureGroup(in: trimmed, pattern: #"Fixed\s*Charge[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#) {
            fixedCharges = "Rs. \(fMatch)"
        }

        var taxesAndLevies: String? = nil
        if let sscMatch = firstCaptureGroup(in: trimmed, pattern: #"(?:SSC\s*Levy|Adjustment|VAT|Taxes)[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#) {
            taxesAndLevies = "Rs. \(sscMatch)"
        }

        var monthlyBill: String? = nil
        let monthlyPatterns = [
            #"Monthly\s*Bill[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#,
            #"Total\s*amount\s*for\s*this\s*month[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#
        ]
        for pat in monthlyPatterns {
            if let m = firstCaptureGroup(in: trimmed, pattern: pat) {
                monthlyBill = "Rs. \(m)"
                break
            }
        }

        // 7. PREVIOUS BALANCES & PAYMENTS
        var previousBalance: String? = nil
        if let bfMatch = firstCaptureGroup(in: trimmed, pattern: #"(?:B/F|Brought\s*Forward|Account\s*Balance[^\n:]*)[\s.:]+(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#) {
            previousBalance = "Rs. \(bfMatch)"
        }

        var payments: String? = nil
        if let pmtMatch = firstCaptureGroup(in: trimmed, pattern: #"(?:Payments?|Last\s*Payment)[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#) {
            payments = "Rs. \(pmtMatch)"
        }

        var outstandingBalance: String? = nil
        if let outMatch = firstCaptureGroup(in: trimmed, pattern: #"Outstanding[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#) {
            outstandingBalance = "Rs. \(outMatch)"
        }

        // 8. TOTAL AMOUNT PAYABLE
        var totalAmountPayable = ""
        let totalPatterns = [
            #"Total\s*Due[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#,
            #"Amount\s*Payable[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#,
            #"TOTAL\s*CHARGES\s*DUE[^\n:]*[\s:]+(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#,
            #"Total\s*Payable[\s.:]*(?:Rs\.?|LKR)?[\s]*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?|[0-9]+(?:\.[0-9]{2})?)"#
        ]
        for pat in totalPatterns {
            if let tot = firstCaptureGroup(in: trimmed, pattern: pat) {
                totalAmountPayable = "Rs. \(tot)"
                break
            }
        }

        if totalAmountPayable.isEmpty {
            if let mb = monthlyBill {
                totalAmountPayable = mb
            } else if let ch = currentCharge {
                totalAmountPayable = ch
            }
        }

        // 9. E-BILL LINK
        var ebillLink: String? = nil
        if let link = firstCaptureGroup(in: trimmed, pattern: #"(https?://ebill\.[^\s]+)"#) {
            ebillLink = link
        }

        // 10. MATHEMATICAL CROSS-VALIDATION
        var isMathConsistent = true
        var confidenceScore = 0.5

        let prevVal = Int(cleanNumericString(from: prevReadingStr)) ?? 0
        let currVal = Int(cleanNumericString(from: currReadingStr)) ?? 0
        let consVal = Int(cleanNumericString(from: consumptionStr)) ?? 0

        if prevVal > 0 && currVal > 0 && consVal > 0 {
            if currVal - prevVal == consVal {
                validationMessages.append("Meter readings verified: \(currVal) - \(prevVal) = \(consVal) Units")
                confidenceScore += 0.2
            } else {
                isMathConsistent = false
                validationMessages.append("Warning: Meter reading difference (\(currVal - prevVal)) differs from detected consumption (\(consVal))")
            }
        }

        let chargeVal = Double(cleanNumericString(from: currentCharge ?? "")) ?? 0.0
        let taxVal = Double(cleanNumericString(from: taxesAndLevies ?? "")) ?? 0.0
        let monthlyVal = Double(cleanNumericString(from: monthlyBill ?? "")) ?? 0.0

        if chargeVal > 0.0 && monthlyVal > 0.0 {
            let expectedMonthly = round((chargeVal + taxVal) * 100) / 100
            if abs(expectedMonthly - monthlyVal) <= 0.05 {
                validationMessages.append("Monthly calculation verified: Rs. \(String(format: "%.2f", chargeVal)) + Rs. \(String(format: "%.2f", taxVal)) = Rs. \(String(format: "%.2f", monthlyVal))")
                confidenceScore += 0.15
            }
        }

        let outVal = Double(cleanNumericString(from: outstandingBalance ?? "")) ?? 0.0
        let totalVal = Double(cleanNumericString(from: totalAmountPayable)) ?? 0.0

        if monthlyVal > 0.0 && totalVal > 0.0 {
            let expectedTotal = round((outVal + monthlyVal) * 100) / 100
            if abs(expectedTotal - totalVal) <= 0.05 {
                validationMessages.append("Total due verified: Outstanding Rs. \(String(format: "%.2f", outVal)) + Monthly Rs. \(String(format: "%.2f", monthlyVal)) = Rs. \(String(format: "%.2f", totalVal))")
                confidenceScore += 0.15
            }
        }

        let bfVal = Double(cleanNumericString(from: previousBalance ?? "")) ?? 0.0
        let pmtVal = Double(cleanNumericString(from: payments ?? "")) ?? 0.0

        if bfVal > 0.0 && pmtVal > 0.0 && outVal > 0.0 {
            let expectedOut = round((bfVal - pmtVal) * 100) / 100
            if abs(expectedOut - outVal) <= 0.05 {
                validationMessages.append("B/F settlement verified: Rs. \(String(format: "%.2f", bfVal)) - Rs. \(String(format: "%.2f", pmtVal)) = Rs. \(String(format: "%.2f", outVal))")
                confidenceScore += 0.1
            }
        }

        if !accountNumber.isEmpty {
            confidenceScore += 0.15
        }

        return ExtractedBillData(
            provider: provider,
            accountNumber: accountNumber,
            tariffCategory: tariffCategory,
            customerName: customerName,
            customerAddress: nil,
            readingDate: readingDate,
            billingPeriod: billingPeriod,
            dueDate: dueDate,
            previousReading: prevReadingStr,
            currentReading: currReadingStr,
            consumptionKwh: consumptionStr,
            currentCharge: currentCharge,
            fixedCharges: fixedCharges,
            taxesAndLevies: taxesAndLevies,
            monthlyBill: monthlyBill,
            previousBalance: previousBalance,
            payments: payments,
            outstandingBalance: outstandingBalance,
            totalAmountPayable: totalAmountPayable,
            ebillLink: ebillLink,
            rawText: trimmed,
            isMathConsistent: isMathConsistent,
            validationMessages: validationMessages,
            confidenceScore: min(1.0, confidenceScore)
        )
    }

    // MARK: - Helpers
    private static func convertDateToBillingPeriod(_ dateStr: String) -> String? {
        let clean = dateStr.trimmingCharacters(in: .whitespacesAndNewlines)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        var parsedDate: Date? = nil
        for format in ["yyyy-MM-dd", "dd/MM/yyyy", "dd/MM/yy", "yyyy/MM/dd"] {
            df.dateFormat = format
            if let d = df.date(from: clean) {
                parsedDate = d
                break
            }
        }

        guard let endDate = parsedDate else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: endDate)
        guard let startOfMonth = calendar.date(from: components) else { return nil }

        let outStart = DateFormatter()
        outStart.locale = Locale(identifier: "en_US_POSIX")
        outStart.dateFormat = "dd MMM"

        let outEnd = DateFormatter()
        outEnd.locale = Locale(identifier: "en_US_POSIX")
        outEnd.dateFormat = "dd MMM yyyy"

        return "\(outStart.string(from: startOfMonth)) – \(outEnd.string(from: endDate))"
    }

    private static func findNumberNearKeywords(in lines: [String], keywords: [String]) -> String? {
        let numberPattern = #"([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+(?:\.[0-9]+)?)"#
        for (i, line) in lines.enumerated() {
            let lower = line.lowercased()
            if keywords.contains(where: { lower.contains($0) }) {
                if let sameLine = firstCaptureGroup(in: line, pattern: numberPattern) {
                    return sameLine
                }
                if i + 1 < lines.count, let nextLine = firstCaptureGroup(in: lines[i + 1], pattern: numberPattern) {
                    return nextLine
                }
            }
        }
        return nil
    }

    private static func firstCaptureGroup(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func captureGroups(in text: String, pattern: String, count: Int) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > count else { return nil }

        var results: [String] = []
        for idx in 1...count {
            guard let r = Range(match.range(at: idx), in: text) else { return nil }
            results.append(String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return results
    }
}

// MARK: - Native Vision OCR Engine
public enum BillTextRecognitionService {

    public static func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "BillOCR", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data."])
        }

        let orientation = cgImageOrientation(from: image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(returning: "")
                    return
                }

                // Sort observations top-to-bottom, left-to-right to preserve text geometry
                let sorted = observations.sorted { lhs, rhs in
                    if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.015 {
                        return lhs.boundingBox.midY > rhs.boundingBox.midY
                    }
                    return lhs.boundingBox.minX < rhs.boundingBox.minX
                }

                let text = sorted.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "en-GB"]

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
