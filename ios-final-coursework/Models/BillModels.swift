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
