//
//  BillModels.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import Foundation

public struct BillData {
    public let monthYear: String
    public let periodText: String
    public let previousReading: Int
    public let currentReading: Int
    public let consumptionUnits: Int
    public let amountLKR: Int
    public let vsLastMonthPercent: Double
    public let lastMonthConsumption: Int
    public let nextMonthPrediction: Int
    public let refreshedForecast: Int
    public let location: String
    
    public static let sample = BillData(
        monthYear: "AUG 2025",
        periodText: "01 Aug – 31 Aug 2025",
        previousReading: 12450,
        currentReading: 12630,
        consumptionUnits: 180,
        amountLKR: 7850,
        vsLastMonthPercent: 12.5,
        lastMonthConsumption: 160,
        nextMonthPrediction: 190,
        refreshedForecast: 195,
        location: "Household account · Colombo"
    )
}

public enum ScanningStage: Int, CaseIterable {
    case documentDetected = 1
    case recognisingText = 2
    case extractingData = 3
    case completed = 4
}

// MARK: - Bill Format Classification
public enum BillFormatType: String, Codable, CaseIterable, Sendable {
    case cebEBill = "CEB e-Bill"
    case cebPrinted = "CEB Printed Bill"
    case lecoBill = "LECO Bill"
    case standard = "Standard Bill"
    case unknown = "Unclassified Bill"
}

// MARK: - Field Confidence & Evidence Metadata
public struct FieldExtractionMetadata: Codable, Equatable, Sendable {
    public let fieldName: String
    public let rawLine: String
    public let confidence: Float
    public let wasOCRCleaned: Bool

    public init(fieldName: String, rawLine: String, confidence: Float, wasOCRCleaned: Bool) {
        self.fieldName = fieldName
        self.rawLine = rawLine
        self.confidence = confidence
        self.wasOCRCleaned = wasOCRCleaned
    }

    public var isLowConfidence: Bool {
        confidence < 0.75 || wasOCRCleaned
    }
}

// MARK: - Validation Warning Model
public enum ValidationSeverity: String, Codable, Equatable, Sendable {
    case info
    case warning
    case error
}

public struct BillValidationWarning: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID = UUID()
    public let fieldKey: String
    public let severity: ValidationSeverity
    public let title: String
    public let message: String
    public let expectedValue: String?
    public let actualValue: String?

    public init(
        id: UUID = UUID(),
        fieldKey: String,
        severity: ValidationSeverity,
        title: String,
        message: String,
        expectedValue: String? = nil,
        actualValue: String? = nil
    ) {
        self.id = id
        self.fieldKey = fieldKey
        self.severity = severity
        self.title = title
        self.message = message
        self.expectedValue = expectedValue
        self.actualValue = actualValue
    }
}

// MARK: - Strongly Typed Intermediate Extraction Model
public struct ExtractedElectricityBill: Equatable, Sendable {
    public var formatType: BillFormatType = .unknown
    public var provider: String? = nil
    public var accountNumber: String? = nil
    public var tariffCode: String? = nil
    public var customerName: String? = nil

    public var readingDate: Date? = nil
    public var readingDateRaw: String? = nil
    public var readingDateSuffix: String? = nil

    public var previousReading: Int? = nil
    public var currentReading: Int? = nil
    public var consumptionUnits: Int? = nil

    public var broughtForward: Decimal? = nil
    public var payments: Decimal? = nil
    public var outstandingBalance: Decimal? = nil
    public var outstandingDueDate: Date? = nil
    public var outstandingDueDateRaw: String? = nil

    public var energyCharge: Decimal? = nil
    public var levyAmount: Decimal? = nil
    public var monthlyBill: Decimal? = nil
    public var totalDue: Decimal? = nil

    public var paymentDueDate: Date? = nil
    public var paymentDueDateRaw: String? = nil
    public var billURL: String? = nil
    public var currency: String = "LKR"

    public var rawOCRText: String = ""
    public var extractionConfidence: Float = 0.0
    public var fieldMetadata: [String: FieldExtractionMetadata] = [:]
    public var validationWarnings: [BillValidationWarning] = []

    public init() {}
}

// MARK: - Editable Review Draft Model (Used by NavigationModel & ReviewBillView)
public struct BillExtractionDraft: Equatable, Sendable {
    public var existingBillID: UUID? = nil
    public var formatType: BillFormatType = .unknown
    public var providerName: String = ""
    public var accountNumber: String = ""
    public var customerName: String = ""
    public var tariffCategory: String = ""
    public var billingMonth: String = ""

    public var readingDate: String = ""
    public var readingReference: String = ""
    public var dueDate: String = ""

    public var previousReading: String = ""
    public var currentReading: String = ""
    public var totalKWh: String = ""

    public var previousBalance: String = ""
    public var payments: String = ""
    public var outstandingBalance: String = ""
    public var outstandingDate: String = ""

    public var electricityCharge: String = ""
    public var sscLevy: String = ""
    public var monthlyBill: String = ""
    public var totalAmount: String = ""
    public var billURL: String = ""
    public var currency: String = "LKR"

    public var rawExtractedText: String = ""
    public var isCEBeBillFormat: Bool = false
    public var extractionConfidence: Float = 0.0
    public var fieldMetadata: [String: FieldExtractionMetadata] = [:]
    public var validationWarnings: [BillValidationWarning] = []

    public init() {}

    public init(from extracted: ExtractedElectricityBill) {
        self.formatType = extracted.formatType
        self.isCEBeBillFormat = (extracted.formatType == .cebEBill)
        self.providerName = extracted.provider ?? ""
        self.accountNumber = extracted.accountNumber ?? ""
        self.customerName = extracted.customerName ?? ""
        self.tariffCategory = extracted.tariffCode ?? ""

        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd"

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "en_US_POSIX")
        monthFormatter.dateFormat = "MMMM yyyy"

        if let rDate = extracted.readingDate {
            self.readingDate = extracted.readingDateRaw ?? isoFormatter.string(from: rDate)
            self.billingMonth = monthFormatter.string(from: rDate)
        } else {
            self.readingDate = extracted.readingDateRaw ?? ""
            self.billingMonth = ""
        }

        self.readingReference = extracted.readingDateSuffix ?? ""

        if let pDue = extracted.paymentDueDate {
            self.dueDate = extracted.paymentDueDateRaw ?? isoFormatter.string(from: pDue)
        } else {
            self.dueDate = extracted.paymentDueDateRaw ?? ""
        }

        self.previousReading = extracted.previousReading.map(String.init) ?? ""
        self.currentReading = extracted.currentReading.map(String.init) ?? ""
        self.totalKWh = extracted.consumptionUnits.map(String.init) ?? ""

        self.previousBalance = Self.formatDecimal(extracted.broughtForward)
        self.payments = Self.formatDecimal(extracted.payments)
        self.outstandingBalance = Self.formatDecimal(extracted.outstandingBalance)

        if let oDate = extracted.outstandingDueDate {
            self.outstandingDate = extracted.outstandingDueDateRaw ?? isoFormatter.string(from: oDate)
        } else {
            self.outstandingDate = extracted.outstandingDueDateRaw ?? ""
        }

        self.electricityCharge = Self.formatDecimal(extracted.energyCharge)
        self.sscLevy = Self.formatDecimal(extracted.levyAmount)
        self.monthlyBill = Self.formatDecimal(extracted.monthlyBill)
        self.totalAmount = Self.formatDecimal(extracted.totalDue)
        self.billURL = extracted.billURL ?? ""
        self.currency = extracted.currency

        self.rawExtractedText = extracted.rawOCRText
        self.extractionConfidence = extracted.extractionConfidence
        self.fieldMetadata = extracted.fieldMetadata
        self.validationWarnings = extracted.validationWarnings
    }

    public func toExtractedElectricityBill() -> ExtractedElectricityBill {
        var bill = ExtractedElectricityBill()
        bill.formatType = formatType
        bill.provider = providerName.trimmedNilIfEmpty
        bill.accountNumber = accountNumber.trimmedNilIfEmpty
        bill.customerName = customerName.trimmedNilIfEmpty
        bill.tariffCode = tariffCategory.trimmedNilIfEmpty

        bill.readingDateRaw = readingDate.trimmedNilIfEmpty
        bill.readingDate = Self.parseFlexibleDate(readingDate)
        bill.readingDateSuffix = readingReference.trimmedNilIfEmpty

        bill.previousReading = Int(previousReading.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
        bill.currentReading = Int(currentReading.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
        if let unitsInt = Int(totalKWh.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)) {
            bill.consumptionUnits = unitsInt
        } else if let unitsDec = Self.parseDecimal(totalKWh) {
            bill.consumptionUnits = NSDecimalNumber(decimal: unitsDec).intValue
        }

        bill.broughtForward = Self.parseDecimal(previousBalance)
        bill.payments = Self.parseDecimal(payments)
        bill.outstandingBalance = Self.parseDecimal(outstandingBalance)
        bill.outstandingDueDateRaw = outstandingDate.trimmedNilIfEmpty
        bill.outstandingDueDate = Self.parseFlexibleDate(outstandingDate)

        bill.energyCharge = Self.parseDecimal(electricityCharge)
        bill.levyAmount = Self.parseDecimal(sscLevy)
        bill.monthlyBill = Self.parseDecimal(monthlyBill)
        bill.totalDue = Self.parseDecimal(totalAmount)

        bill.paymentDueDateRaw = dueDate.trimmedNilIfEmpty
        bill.paymentDueDate = Self.parseFlexibleDate(dueDate)
        bill.billURL = billURL.trimmedNilIfEmpty
        bill.currency = currency.trimmedNilIfEmpty ?? "LKR"
        bill.rawOCRText = rawExtractedText
        bill.extractionConfidence = extractionConfidence
        bill.fieldMetadata = fieldMetadata
        return bill
    }

    public static func formatDecimal(_ value: Decimal?) -> String {
        guard let value else { return "" }
        var rounded = Decimal()
        var input = value
        NSDecimalRound(&rounded, &input, 2, .plain)
        return String(format: "%.2f", NSDecimalNumber(decimal: rounded).doubleValue)
    }

    public static func parseDecimal(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Rs.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Rs", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "LKR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "kWh", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Units", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    public static func parseFlexibleDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formats = [
            "yyyy-MM-dd", "dd/MM/yyyy", "dd-MM-yyyy", "yyyy/MM/dd", "MMM dd, yyyy", "dd MMM yyyy"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }
}

public extension String {
    var trimmedNilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

