//
//  ApplianceDetailView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct ApplianceDetailView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext

    public let applianceId: UUID?
    
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \Appliance.name) private var allAppliances: [Appliance]

    @State private var appliance: Appliance?
    @State private var isEditing = false

    public init(applianceId: UUID? = nil) {
        self.applianceId = applianceId
        self._appliance = State(initialValue: nil)
    }
    
    // Dynamic Calibrated calculations for this appliance
    private var calibratedData: (calibratedKwh: Double, percentage: Double, totalBillKwh: Double, monthlyCostLkr: Double) {
        let latestBill = savedBills.first
        let billKwh = latestBill?.consumptionKwh ?? 180.0
        
        if let app = appliance {
            let item = ApplianceCalibrationService.shared.calibrateSingleAppliance(
                appliance: app,
                allAppliances: allAppliances,
                targetBillKwh: billKwh
            )
            let cost = ApplianceCalibrationService.shared.estimateMonthlyCost(calibratedKwh: item.calibratedKwh, bill: latestBill)
            return (item.calibratedKwh, item.percentage, billKwh, cost)
        } else {
            // Fallback default (Air Conditioner: 40% of 180 kWh = 72 kWh)
            let kwh = billKwh * 0.40
            let cost = kwh * 43.75
            return (kwh, 0.40, billKwh, cost)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back & Edit Action
            HStack {
                CustomBackButton(title: "Appliances") {
                    navState.navigate(to: .appliances)
                }
                
                Spacer()
                
                Button(action: {
                    isEditing = true
                }) {
                    Text("Edit")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(EnergyLensTheme.accentGreen)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Title
                    Text(appliance?.name ?? "Air Conditioner")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Main Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Estimated Monthly Contribution")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            Spacer()
                            Text(savedBills.isEmpty ? "Estimated" : "Calibrated")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.18))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", calibratedData.calibratedKwh))
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("kWh")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text(savedBills.isEmpty ? "Based on monthly appliance profile" : "Calibrated to your \(String(format: "%.0f", calibratedData.totalBillKwh)) kWh bill")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            Spacer()
                            Text(String(format: "≈ LKR %.0f/mo", calibratedData.monthlyCostLkr))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Share of monthly consumption
                    VStack(spacing: 8) {
                        HStack {
                            Text("Share of monthly consumption")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%%", calibratedData.percentage * 100))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(EnergyLensTheme.accentGreen)
                                    .frame(width: max(geo.size.width * CGFloat(calibratedData.percentage), 6), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.top, 2)
                    
                    // Appliance profile section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Appliance profile")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                isEditing = true
                            }) {
                                Text("Edit appliance")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(EnergyLensTheme.accentGreen)
                            }
                        }
                        
                        // Info card
                        VStack(spacing: 12) {
                            if let brand = appliance?.brand, !brand.isEmpty {
                                profileRow(label: "Brand / Model", value: brand)
                                Divider().background(EnergyLensTheme.fieldBorder)
                            }
                            profileRow(label: "Nameplate power", value: "\(appliance?.powerW ?? 1200) W")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Daily usage", value: "\(String(format: "%.1f", appliance?.hoursPerDay ?? 6.0)) h/day")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Quantity", value: "\(appliance?.quantity ?? 1) unit")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Usage mode", value: appliance?.usageMode ?? "All day")
                            if appliance?.usageMode == "Weekly" {
                                Divider().background(EnergyLensTheme.fieldBorder)
                                profileRow(label: "Days per week", value: "\(appliance?.daysPerWeek ?? 1) days")
                            }
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Theoretical Monthly", value: String(format: "%.1f kWh", appliance?.estimatedMonthlyKwh ?? 72.0))
                        }
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    
                    // Footnote
                    Text("\(String(format: "%.0f", calibratedData.calibratedKwh)) kWh is calibrated to your bill and appliance profiles. It is not simply nameplate power × hours.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Callout
                    let currentHours = appliance?.hoursPerDay ?? 6.0
                    let targetHours = max(1.0, currentHours - 2.0)
                    let applianceName = appliance?.name ?? "Air Conditioner"
                    Text("Try reducing daily \(applianceName) usage from \(String(format: "%.0f", currentHours)) to \(String(format: "%.0f", targetHours)) hours in the simulator.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                        .lineSpacing(2)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(14)
                    
                    Spacer(minLength: 20)
                    
                    // Open Simulator Button
                    GradientButton(title: "Open Energy Saving Simulator") {
                        if let app = appliance {
                            navState.selectedAppliance = app.name
                            navState.selectedApplianceId = app.id
                            navState.currentAcHours = app.hoursPerDay
                            navState.simulationHours = targetHours
                        }
                        navState.navigate(to: .savingsSimulator)
                    }
                    .padding(.bottom, 10)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadAppliance()
        }
        .sheet(isPresented: $isEditing) {
            editApplianceSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var editApplianceSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { isEditing = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color(red: 0.95, green: 0.96, blue: 0.97))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            AddApplianceView(appliance: appliance) {
                isEditing = false
                loadAppliance()
            }
            .environmentObject(navState)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func loadAppliance() {
        if let id = applianceId ?? navState.selectedApplianceId {
            do {
                let predicate = #Predicate<Appliance> { item in
                    item.id == id
                }
                let descriptor = FetchDescriptor<Appliance>(predicate: predicate)
                if let found = try modelContext.fetch(descriptor).first {
                    self.appliance = found
                    return
                }
            } catch {
                print("Failed to fetch appliance by ID: \(error)")
            }
        }
        
        // Fallback: match by navState.selectedAppliance name
        if let match = allAppliances.first(where: { $0.name.lowercased() == navState.selectedAppliance.lowercased() }) {
            self.appliance = match
        } else if let first = allAppliances.first {
            self.appliance = first
        }
    }
    
    @ViewBuilder
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(EnergyLensTheme.textPrimary)
        }
    }
}
