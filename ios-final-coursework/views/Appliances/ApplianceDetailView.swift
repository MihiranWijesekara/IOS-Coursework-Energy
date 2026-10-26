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
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    @Query(sort: \Appliance.name) private var allAppliances: [Appliance]

    @State private var appliance: Appliance?
    @State private var isEditing = false
    @State private var editWattageText: String = ""
    @State private var editHours: Double = 6.0
    @State private var showDeleteConfirmation = false

    public init(applianceId: UUID? = nil) {
        self.applianceId = applianceId
        self._appliance = State(initialValue: nil)
    }
    
    private var currencySymbol: String {
        let raw = pdfSavedBills.first?.currency ?? savedBills.first?.currency ?? "LKR"
        return (raw.uppercased() == "USD" || raw == "$") ? "$" : "Rs."
    }
    
    private var effectiveTariffRate: Double {
        if let pdf = pdfSavedBills.first, pdf.totalKWh > 0, pdf.totalAmount > 0 {
            return pdf.totalAmount / pdf.totalKWh
        }
        if let bill = savedBills.first, bill.consumptionKwh > 0, bill.billAmount > 0 {
            return bill.billAmount / bill.consumptionKwh
        }
        return currencySymbol == "$" ? 0.288 : 30.0
    }
    
    // Dynamic Calibrated calculations for this appliance
    private var calibratedData: (calibratedKwh: Double, percentage: Double, totalBillKwh: Double, monthlyCost: Double) {
        let billKwh = pdfSavedBills.first?.totalKWh ?? savedBills.first?.consumptionKwh ?? 180.0
        
        if let app = appliance {
            let item = ApplianceCalibrationService.shared.calibrateSingleAppliance(
                appliance: app,
                allAppliances: allAppliances,
                targetBillKwh: billKwh
            )
            let cost = item.calibratedKwh * effectiveTariffRate
            return (item.calibratedKwh, item.percentage, billKwh, cost)
        } else {
            let kwh = billKwh * 0.40
            let cost = kwh * effectiveTariffRate
            return (kwh, 0.40, billKwh, cost)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back & Edit Action
            HStack {
                CustomBackButton(title: "Appliances") {
                    navState.navigateBack()
                }
                
                Spacer()
                
                Button(action: {
                    if let app = appliance {
                        editWattageText = "\(app.wattage)"
                        editHours = app.hoursPerDay
                        isEditing = true
                    }
                }) {
                    Text("Edit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(EnergyLensTheme.accentGreen)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Title and Icon Header
                    HStack(spacing: 12) {
                        if let app = appliance {
                            Image(systemName: app.iconName)
                                .font(.system(size: 26))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                                .frame(width: 44, height: 44)
                                .background(EnergyLensTheme.mintHighlight)
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appliance?.name ?? "Appliance Details")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            if let cat = appliance?.category, !cat.isEmpty {
                                Text(cat)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                        }
                    }
                    
                    // Main Highlight Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Estimated Monthly Contribution")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            Spacer()
                            Text(savedBills.isEmpty && pdfSavedBills.isEmpty ? "Estimated" : "Calibrated")
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
                            Text(savedBills.isEmpty && pdfSavedBills.isEmpty ? "Based on appliance nameplate rating" : "Calibrated to your \(String(format: "%.0f", calibratedData.totalBillKwh)) kWh bill")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                            Spacer()
                            Text(String(format: "≈ \(currencySymbol) %.0f/mo", calibratedData.monthlyCost))
                                .font(.system(size: 14, weight: .bold))
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
                            Text("Appliance Profile")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                if let app = appliance {
                                    editWattageText = "\(app.wattage)"
                                    editHours = app.hoursPerDay
                                    isEditing = true
                                }
                            }) {
                                Text("Edit Specs")
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
                            profileRow(label: "Nameplate Power", value: "\(appliance?.wattage ?? 1200) W")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Daily Usage", value: "\(String(format: "%.1f", appliance?.hoursPerDay ?? 6.0)) h/day")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Quantity", value: "\(appliance?.quantity ?? 1) unit")
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Usage Mode", value: appliance?.usageMode ?? "All day")
                            if appliance?.usageMode == "Weekly" {
                                Divider().background(EnergyLensTheme.fieldBorder)
                                profileRow(label: "Days per Week", value: "\(appliance?.daysPerWeek ?? 1) days")
                            }
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Estimated Monthly", value: String(format: "%.1f kWh", appliance?.estimatedMonthlyKWh ?? 72.0))
                            Divider().background(EnergyLensTheme.fieldBorder)
                            profileRow(label: "Estimated Monthly Cost", value: String(format: "\(currencySymbol) %.0f", calibratedData.monthlyCost))
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
                    Text("\(String(format: "%.0f", calibratedData.calibratedKwh)) kWh is dynamically calibrated using your \(currencySymbol) tariff and household profile.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                    
                    // Callout
                    let currentHours = appliance?.hoursPerDay ?? 6.0
                    let targetHours = max(1.0, currentHours - 2.0)
                    let appName = appliance?.name ?? "Air Conditioner"
                    Text("Try reducing daily \(appName) usage from \(String(format: "%.0f", currentHours)) to \(String(format: "%.0f", targetHours)) hours in the savings simulator.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                        .lineSpacing(2)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(14)
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Open Simulator Button
                        GradientButton(title: "Open Energy Saving Simulator") {
                            if let app = appliance {
                                navState.selectedAppliance = app.name
                                navState.selectedApplianceID = app.id
                                navState.selectedApplianceId = app.id
                                navState.currentAcHours = app.hoursPerDay
                                navState.simulationHours = targetHours
                            }
                            navState.navigate(to: .savingsSimulator)
                        }
                        
                        // Delete Appliance Button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Appliance")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.20))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.99, green: 0.92, blue: 0.92))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadAppliance()
        }
        .confirmationDialog(
            "Delete Appliance",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(appliance?.name ?? "Appliance")", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this appliance? This will permanently remove its profile from SwiftData.")
        }
        .sheet(isPresented: $isEditing) {
            editSheetContent
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var editSheetContent: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit \(appliance?.name ?? "Appliance")")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.top, 10)
                
                // Wattage
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nameplate Power (Watts)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                    
                    TextField("Wattage (e.g. 1200)", text: $editWattageText)
                        .keyboardType(.numberPad)
                        .padding(14)
                        .background(Color(red: 0.96, green: 0.97, blue: 0.98)) // Standard fallback background
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(EnergyLensTheme.fieldBorder, lineWidth: 1))
                }
                
                // Hours per day
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Daily Usage")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        Spacer()
                        Text("\(String(format: "%.1f", editHours)) hours/day")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(EnergyLensTheme.accentGreen)
                    }
                    
                    Slider(value: $editHours, in: 0.5...24.0, step: 0.5)
                        .tint(EnergyLensTheme.accentGreen)
                }
                
                Spacer()
                
                // Save button
                GradientButton(title: "Save Changes") {
                    saveEdits()
                    isEditing = false
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .navigationTitle("Edit Appliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
            }
        }
    }

    private func saveEdits() {
        guard let app = appliance else { return }
        if let newW = Int(editWattageText), newW > 0 {
            app.wattage = newW
            app.powerW = newW
        }
        app.hoursPerDay = editHours
        try? modelContext.save()
        loadAppliance()
    }

    private func performDelete() {
        guard let app = appliance else {
            navState.navigateBack()
            return
        }
        do {
            try SwiftDataApplianceService.shared.deleteAppliance(app, in: modelContext)
            navState.selectedApplianceID = nil
            navState.selectedApplianceId = nil
            navState.navigateBack()
        } catch {
            print("Failed to delete appliance: \(error)")
            modelContext.delete(app)
            try? modelContext.save()
            navState.navigateBack()
        }
    }

    private func loadAppliance() {
        let targetId = applianceId ?? navState.selectedApplianceID ?? navState.selectedApplianceId
        if let id = targetId {
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
