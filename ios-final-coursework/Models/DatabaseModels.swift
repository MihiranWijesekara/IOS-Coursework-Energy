//
//  DatabaseModels.swift
//  ios-final-coursework
//
//  Created for SwiftData @Model schema
//

import Foundation
import SwiftData

// MARK: - User Model
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
    
    // Relationships (1-to-Many cascade delete)
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

// MARK: - Appliance Model
@Model
public final class Appliance {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var brand: String?
    public var category: String?
    public var powerW: Int
    public var quantity: Int
    public var hoursPerDay: Double
    public var usageMode: String         // "All day" or "Weekly"
    public var daysPerWeek: Int?         // 1...7 when usageMode == "Weekly"

    // Relationship to User
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

    /// Estimated monthly kWh based on the selected operating mode.
    /// All-day appliances use 30 days/month; weekly appliances use the selected days per week x ~4.33 weeks.
    public var estimatedMonthlyKwh: Double {
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
}

// MARK: - Savings Scenario Model
@Model
public final class SavingsScenario {
    @Attribute(.unique) public var id: UUID
    public var scenarioTitle: String          // e.g. "Reduce AC usage", "Wash full loads"
    public var applianceName: String          // Targeted appliance
    public var adjustmentType: String         // e.g. "Reduce hours per day", "Turn off on peak hours", "Upgrade to Inverter"
    public var originalHoursPerDay: Double
    public var targetHoursPerDay: Double
    public var estimatedKwhSaved: Double      // Projected monthly kWh reduction
    public var estimatedLkrSaved: Double      // Projected monthly bill reduction in LKR
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

// MARK: - Electricity Bill Model
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
    
    // Relationship to User
    public var user: User?
    
    public init(
        id: UUID = UUID(),
        periodStart: Date,
        periodEnd: Date,
        prevReading: Int? = nil,
        currReading: Int? = nil,
        consumptionKwh: Double,
        billAmount: Double,
        currency: String = "LKR",
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
        self.user = user
    }
}

// MARK: - Prediction Model
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

// MARK: - Weather Data Model
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

