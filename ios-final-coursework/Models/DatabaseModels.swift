//
//  DatabaseModels.swift
//  ios-final-coursework
//
//  Created for SwiftData @Model schema
//

import Foundation
import SwiftData


@Model
public final class User {
    @Attribute(.unique) public var id: UUID
    public var firstName: String
    public var lastName: String
    @Attribute(.unique) public var email: String
    public var phone: String?
    public var province: String?
    public var district: String?
    public var town: String?
    public var passwordHash: String
    

    @Relationship(deleteRule: .cascade, inverse: \Appliance.user)
    public var appliances: [Appliance] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ElectricityBill.user)
    public var bills: [ElectricityBill] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Prediction.user)
    public var predictions: [Prediction] = []
    
    @Relationship(deleteRule: .cascade, inverse: \WeatherData.user)
    public var weatherRecords: [WeatherData] = []
    
    @Relationship(deleteRule: .cascade, inverse: \SavingsScenario.user)
    public var savingsScenarios: [SavingsScenario] = []
    
    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String? = nil,
        province: String? = nil,
        district: String? = nil,
        town: String? = nil,
        passwordHash: String
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.province = province
        self.district = district
        self.town = town
        self.passwordHash = passwordHash
    }
}


@Model
public final class Appliance {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var brand: String?
    public var category: String?
    public var powerW: Int
    public var quantity: Int
    public var hoursPerDay: Double
    public var usageMode: String       
    public var daysPerWeek: Int?         

    public var user: User?

    public init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        category: String? = nil,
        powerW: Int,
        quantity: Int = 1,
        hoursPerDay: Double,
        usageMode: String = "All day",
        daysPerWeek: Int? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.powerW = powerW
        self.quantity = quantity
        self.hoursPerDay = hoursPerDay
        self.usageMode = usageMode
        self.daysPerWeek = daysPerWeek
        self.user = user
    }

   
        let effectiveDays: Double

        if usageMode == "Weekly" {
            let weeklyDays = Double(daysPerWeek ?? 1)
            effectiveDays = weeklyDays * 4.33
        } else {
            effectiveDays = 30.0
        }

        return (Double(powerW * quantity) * hoursPerDay * effectiveDays) / 1000.0
    }

    /// Estimated daily average kWh across the full month
    public var estimatedDailyAverageKwh: Double {
        return estimatedMonthlyKwh / 30.0
    }

    public var wattage: Int {
        get { powerW }
        set { powerW = newValue }
    }

    public var estimatedMonthlyKWh: Double {
        estimatedMonthlyKwh
    }

    public var iconName: String {
        ApplianceCalibrationService.shared.iconForCategory(category ?? name)
    }
}

// MARK: - Savings Scenario Model
@Model
public final class SavingsScenario {
    @Attribute(.unique) public var id: UUID
    public var scenarioTitle: String       
    public var applianceName: String        
    public var adjustmentType: String         
    public var originalHoursPerDay: Double
    public var targetHoursPerDay: Double
    public var estimatedKwhSaved: Double     
    public var estimatedLkrSaved: Double     
    public var createdAt: Date
    
    // Relationship to User
    public var user: User?
    
    public init(
        id: UUID = UUID(),
        scenarioTitle: String,
        applianceName: String,
        adjustmentType: String,
        originalHoursPerDay: Double,
        targetHoursPerDay: Double,
        estimatedKwhSaved: Double,
        estimatedLkrSaved: Double,
        createdAt: Date = Date(),
        user: User? = nil
    ) {
        self.id = id
        self.scenarioTitle = scenarioTitle
        self.applianceName = applianceName
        self.adjustmentType = adjustmentType
        self.originalHoursPerDay = originalHoursPerDay
        self.targetHoursPerDay = targetHoursPerDay
        self.estimatedKwhSaved = estimatedKwhSaved
        self.estimatedLkrSaved = estimatedLkrSaved
        self.createdAt = createdAt
        self.user = user
    }
}


@Model
public final class ElectricityBill {
    @Attribute(.unique) public var id: UUID
    public var periodStart: Date
    public var periodEnd: Date
    public var prevReading: Int?
    public var currReading: Int?
    public var consumptionKwh: Double
    public var billAmount: Double
    public var currency: String

    public var provider: String = "CEB"                  // "CEB" or "LECO"
    public var accountNumber: String = ""               // e.g. "5410264908"
    public var customerName: String? = nil              // e.g. "R RANJITH"
    public var customerAddress: String? = nil
    public var tariffCategory: String? = nil            // e.g. "D1"
    public var billDate: Date? = nil                    // Reading / bill issue date
    public var dueDate: Date? = nil                     // Payment due date
    public var billingPeriodText: String = ""           // Formatted period string
    public var currentCharges: Double? = nil            // Electricity charge for current month
    public var fixedCharges: Double? = nil              // Fixed charge component
    public var taxesAndLevies: Double? = nil            // SSC Levy / adjustments
    public var previousBalance: Double? = nil           // B/F (Brought forward)
    public var payments: Double? = nil                  // Payments made
    public var outstandingBalance: Double? = nil        // Net outstanding balance
    public var totalAmountPayable: Double = 0.0         // Total due amount in LKR
    public var rawOcrText: String = ""                  // Complete OCR text extracted
    public var uploadedAt: Date = Date()                // Date scanned/uploaded
    @Attribute(.externalStorage) public var imageData: Data? = nil // Compressed screenshot data
    public var isVerified: Bool = false                 // User confirmation flag
    
 
    public var user: User?
    
    public init(
        id: UUID = UUID(),
        periodStart: Date = Date(),
        periodEnd: Date = Date(),
        prevReading: Int? = nil,
        currReading: Int? = nil,
        consumptionKwh: Double = 0.0,
        billAmount: Double = 0.0,
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
        uploadedAt: Date = Date(),
        imageData: Data? = nil,
        isVerified: Bool = false,
        user: User? = nil
    ) {
        self.id = id
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.prevReading = prevReading
        self.currReading = currReading
        self.consumptionKwh = consumptionKwh
        self.billAmount = billAmount
        self.currency = currency
        self.provider = provider
        self.accountNumber = accountNumber
        self.customerName = customerName
        self.customerAddress = customerAddress
        self.tariffCategory = tariffCategory
        self.billDate = billDate
        self.dueDate = dueDate
        self.billingPeriodText = billingPeriodText.isEmpty ? SwiftDataBillService.formatPeriod(start: periodStart, end: periodEnd) : billingPeriodText
        self.currentCharges = currentCharges
        self.fixedCharges = fixedCharges
        self.taxesAndLevies = taxesAndLevies
        self.previousBalance = previousBalance
        self.payments = payments
        self.outstandingBalance = outstandingBalance
        self.totalAmountPayable = totalAmountPayable ?? billAmount
        self.rawOcrText = rawOcrText
        self.uploadedAt = uploadedAt
        self.imageData = imageData
        self.isVerified = isVerified
        self.user = user
    }

    public func toDraft() -> BillExtractionDraft {
        var draft = BillExtractionDraft()
        draft.existingBillID = id
        draft.formatType = provider.localizedCaseInsensitiveContains("CEB") ? .cebEBill : (provider.localizedCaseInsensitiveContains("LECO") ? .lecoBill : .standard)
        draft.providerName = provider
        draft.accountNumber = accountNumber
        draft.customerName = customerName ?? ""
        draft.tariffCategory = tariffCategory ?? ""
        draft.billingMonth = billingPeriodText
        if let bDate = billDate {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            draft.readingDate = df.string(from: bDate)
        }
        if let dDate = dueDate {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            draft.dueDate = df.string(from: dDate)
        }
        draft.previousReading = prevReading.map { "\($0)" } ?? ""
        draft.currentReading = currReading.map { "\($0)" } ?? ""
        draft.totalKWh = String(format: "%.0f", consumptionKwh)
        draft.previousBalance = previousBalance.map { String(format: "%.2f", $0) } ?? ""
        draft.payments = payments.map { String(format: "%.2f", $0) } ?? ""
        draft.outstandingBalance = outstandingBalance.map { String(format: "%.2f", $0) } ?? ""
        draft.electricityCharge = currentCharges.map { String(format: "%.2f", $0) } ?? ""
        draft.sscLevy = taxesAndLevies.map { String(format: "%.2f", $0) } ?? ""
        draft.totalAmount = String(format: "%.2f", totalAmountPayable)
        draft.rawExtractedText = rawOcrText
        draft.currency = currency
        return draft
    }
}


@Model
public final class Prediction {
    @Attribute(.unique) public var id: UUID
    public var predictPeriodStart: Date?
    public var predictPeriodEnd: Date?
    public var predictedKwh: Double
    public var predictedBill: Double
    public var predictionDate: Date
    
    // Relationship to User
    public var user: User?
    
    public init(
        id: UUID = UUID(),
        predictPeriodStart: Date? = nil,
        predictPeriodEnd: Date? = nil,
        predictedKwh: Double,
        predictedBill: Double,
        predictionDate: Date = Date(),
        user: User? = nil
    ) {
        self.id = id
        self.predictPeriodStart = predictPeriodStart
        self.predictPeriodEnd = predictPeriodEnd
        self.predictedKwh = predictedKwh
        self.predictedBill = predictedBill
        self.predictionDate = predictionDate
        self.user = user
    }
}


@Model
public final class WeatherData {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var highTemp: Double?   // °C
    public var lowTemp: Double?    // °C
    public var condition: String?  // e.g. "Sunny", "Rain"
    public var precipProb: Double? // Chance of rain (0.0 to 1.0 or percentage)
    
    // Relationship to User
    public var user: User?
    
    public init(
        id: UUID = UUID(),
        date: Date,
        highTemp: Double? = nil,
        lowTemp: Double? = nil,
        condition: String? = nil,
        precipProb: Double? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.date = date
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.condition = condition
        self.precipProb = precipProb
        self.user = user
    }
}


@Model
public final class SavedBill {
    @Attribute(.unique) public var id: UUID
    public var userEmail: String
    public var billingMonth: String
    public var totalKWh: Double
    public var totalAmount: Double
    public var dueDate: String
    public var providerName: String
    public var scannedDate: Date

   
    public var accountNumber: String = ""
    public var customerName: String = ""
    public var tariffCategory: String = ""
    public var previousBalance: Double = 0.0
    public var payments: Double = 0.0
    public var outstandingBalance: Double = 0.0
    public var outstandingDate: String = ""
    public var readingDate: String = ""
    public var readingReference: String = ""
    public var previousReading: Int = 0
    public var currentReading: Int = 0
    public var electricityCharge: Double = 0.0
    public var sscLevy: Double = 0.0
    public var monthlyBill: Double = 0.0
    public var billURL: String = ""
    public var isCEBeBillFormat: Bool = false

    public var formatTypeRaw: String = "Standard Bill"
    public var currency: String = "LKR"
    public var rawOCRText: String = ""
    public var extractionConfidence: Double = 1.0
    public var hasPreviousBalanceValue: Bool = false
    public var hasPaymentsValue: Bool = false
    public var hasOutstandingValue: Bool = false
    public var hasReadingsValue: Bool = false
    public var hasEnergyChargeValue: Bool = false
    public var hasLevyValue: Bool = false
    public var hasMonthlyBillValue: Bool = false

    public init(
        id: UUID = UUID(),
        userEmail: String,
        billingMonth: String,
        totalKWh: Double,
        totalAmount: Double,
        dueDate: String,
        providerName: String,
        scannedDate: Date = Date(),
        accountNumber: String = "",
        customerName: String = "",
        tariffCategory: String = "",
        previousBalance: Double = 0.0,
        payments: Double = 0.0,
        outstandingBalance: Double = 0.0,
        outstandingDate: String = "",
        readingDate: String = "",
        readingReference: String = "",
        previousReading: Int = 0,
        currentReading: Int = 0,
        electricityCharge: Double = 0.0,
        sscLevy: Double = 0.0,
        monthlyBill: Double = 0.0,
        billURL: String = "",
        isCEBeBillFormat: Bool = false,
        formatTypeRaw: String = BillFormatType.standard.rawValue,
        currency: String = "LKR",
        rawOCRText: String = "",
        extractionConfidence: Double = 1.0,
        hasPreviousBalanceValue: Bool = false,
        hasPaymentsValue: Bool = false,
        hasOutstandingValue: Bool = false,
        hasReadingsValue: Bool = false,
        hasEnergyChargeValue: Bool = false,
        hasLevyValue: Bool = false,
        hasMonthlyBillValue: Bool = false
    ) {
        self.id = id
        self.userEmail = userEmail
        self.billingMonth = billingMonth
        self.totalKWh = totalKWh
        self.totalAmount = totalAmount
        self.dueDate = dueDate
        self.providerName = providerName
        self.scannedDate = scannedDate
        self.accountNumber = accountNumber
        self.customerName = customerName
        self.tariffCategory = tariffCategory
        self.previousBalance = previousBalance
        self.payments = payments
        self.outstandingBalance = outstandingBalance
        self.outstandingDate = outstandingDate
        self.readingDate = readingDate
        self.readingReference = readingReference
        self.previousReading = previousReading
        self.currentReading = currentReading
        self.electricityCharge = electricityCharge
        self.sscLevy = sscLevy
        self.monthlyBill = monthlyBill
        self.billURL = billURL
        self.isCEBeBillFormat = isCEBeBillFormat
        self.formatTypeRaw = formatTypeRaw
        self.currency = currency
        self.rawOCRText = rawOCRText
        self.extractionConfidence = extractionConfidence
        self.hasPreviousBalanceValue = hasPreviousBalanceValue
        self.hasPaymentsValue = hasPaymentsValue
        self.hasOutstandingValue = hasOutstandingValue
        self.hasReadingsValue = hasReadingsValue
        self.hasEnergyChargeValue = hasEnergyChargeValue
        self.hasLevyValue = hasLevyValue
        self.hasMonthlyBillValue = hasMonthlyBillValue
    }

    public var totalDueDecimal: Decimal {
        Decimal(string: String(format: "%.2f", totalAmount), locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(totalAmount)
    }

    public var monthlyBillDecimal: Decimal? {
        guard hasMonthlyBillValue || monthlyBill > 0 else { return nil }
        return Decimal(string: String(format: "%.2f", monthlyBill), locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Chronological billing date for sorting, analytics, and Core ML
    public var actualBillingDate: Date {
        if !readingDate.isEmpty, let d = BillExtractionDraft.parseFlexibleDate(readingDate) {
            return d
        }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["MMMM yyyy", "MMM yyyy", "yyyy-MM", "MM/yyyy", "MM-yyyy", "yyyy-MM-dd", "dd/MM/yyyy"] {
            df.dateFormat = fmt
            if !billingMonth.isEmpty, let d = df.date(from: billingMonth.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return d
            }
            if !readingDate.isEmpty, let d = df.date(from: readingDate.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return d
            }
        }
        return scannedDate
    }

    public func toDraft() -> BillExtractionDraft {
        var draft = BillExtractionDraft()
        draft.existingBillID = id
        draft.formatType = BillFormatType(rawValue: formatTypeRaw) ?? (isCEBeBillFormat ? .cebEBill : .standard)
        draft.providerName = providerName
        draft.accountNumber = accountNumber
        draft.customerName = customerName
        draft.tariffCategory = tariffCategory
        draft.billingMonth = billingMonth
        draft.readingDate = readingDate
        draft.readingReference = readingReference
        draft.dueDate = dueDate
        draft.previousReading = (hasReadingsValue || previousReading > 0) ? "\(previousReading)" : ""
        draft.currentReading = (hasReadingsValue || currentReading > 0) ? "\(currentReading)" : ""
        draft.totalKWh = String(format: "%.0f", totalKWh)
        draft.previousBalance = (hasPreviousBalanceValue || previousBalance != 0) ? String(format: "%.2f", previousBalance) : ""
        draft.payments = (hasPaymentsValue || payments != 0) ? String(format: "%.2f", payments) : ""
        draft.outstandingBalance = (hasOutstandingValue || outstandingBalance != 0) ? String(format: "%.2f", outstandingBalance) : ""
        draft.outstandingDate = outstandingDate
        draft.electricityCharge = (hasEnergyChargeValue || electricityCharge != 0) ? String(format: "%.2f", electricityCharge) : ""
        draft.sscLevy = (hasLevyValue || sscLevy != 0) ? String(format: "%.2f", sscLevy) : ""
        draft.monthlyBill = (hasMonthlyBillValue || monthlyBill != 0) ? String(format: "%.2f", monthlyBill) : ""
        draft.totalAmount = String(format: "%.2f", totalAmount)
        draft.billURL = billURL
        draft.currency = currency.isEmpty ? "LKR" : currency
        draft.rawExtractedText = rawOCRText
        draft.isCEBeBillFormat = isCEBeBillFormat
        draft.extractionConfidence = Float(extractionConfidence)
        return draft
    }
}

public typealias SavedUser = User
public typealias SavedAppliance = Appliance
public typealias SavedScenario = SavingsScenario


