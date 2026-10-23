//
//  ios_final_courseworkApp.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

@main
struct ios_final_courseworkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            User.self,
            Appliance.self,
            ElectricityBill.self,
            SavedBill.self,
            Prediction.self,
            WeatherData.self,
            SavingsScenario.self
        ])
    }
}
 
