//
//  AddApplianceView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct AddApplianceView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var applianceToEdit: Appliance?
    
    private let onSave: (() -> Void)?
    
    @State private var applianceName: String = ""
    @State private var applianceBrandName: String = ""
    @State private var category: String = "Select a category"
    @State private var customCategory: String = ""
    @State private var powerRating: String = ""
    @State private var hoursPerDay: String = ""
    @State private var quantity: Int = 1
    @State private var usageMode: String = "Select a usage mode"
    @State private var daysPerWeek: Int = 1
    
    let categories = ["Cooling", "Refrigeration", "Ventilation", "Entertainment", "Cleaning", "Lighting", "Cooking", "Other"]
    let usageModes = ["All day", "Weekly"]
    let weeklyDays = Array(1...7)
    
    public init(appliance: Appliance? = nil, onSave: (() -> Void)? = nil) {
        self.onSave = onSave
        self._applianceToEdit = State(initialValue: appliance)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Appliances") {
                navState.navigate(to: .appliances)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header Gradient Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Appliance")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("A few details help refine your estimates.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Form Card 1
                    VStack(alignment: .leading, spacing: 14) {
                        // Appliance name
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Appliance name")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            TextField("Appliance name", text: $applianceName)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)

                        // Appliance brand name
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Appliance Brand name")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            TextField("Appliance Brand name", text: $applianceBrandName)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Category (Dropdown Pill)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Menu {
                                ForEach(categories, id: \.self) { cat in
                                    Button(cat) {
                                        category = cat
                                        if cat != "Other" {
                                            customCategory = ""
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(category)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                                .cornerRadius(10)
                            }

                            if category == "Other" {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Custom category")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)

                                    TextField("Enter appliance category", text: $customCategory)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                }
                            }
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Power rating
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Power rating (nameplate)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            TextField("Power rating", text: $powerRating)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Hours per day / usage mode
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hours per day")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)

                            Menu {
                                ForEach(usageModes, id: \.self) { mode in
                                    Button(mode) { usageMode = mode }
                                }
                            } label: {
                                HStack {
                                    Text(usageMode)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.48))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                                .cornerRadius(10)
                            }

                            if usageMode == "Weekly" {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Days per week")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)

                                    Menu {
                                        ForEach(weeklyDays, id: \.self) { day in
                                            Button("\(day)") { daysPerWeek = day }
                                        }
                                    } label: {
                                        HStack {
                                            Text("\(daysPerWeek)")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(EnergyLensTheme.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(EnergyLensTheme.textSecondary)
                                        }
                                        .padding(.bottom, 4)
                                    }

                                    Divider()
                                        .background(EnergyLensTheme.fieldBorder)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Hours per day")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)

                                TextField("Hours per day", text: $hoursPerDay)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Form Card 2: Quantity
                    VStack(alignment: .leading, spacing: 14) {
                        // Quantity with Stepper
                        HStack {
                            Text("Quantity")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if quantity > 1 { quantity -= 1 }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                        .frame(width: 32, height: 32)
                                        .background(Color(red: 0.93, green: 0.94, blue: 0.96))
                                        .cornerRadius(8)
                                }
                                
                                Text("\(quantity)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                    .frame(minWidth: 20)
                                
                                Button(action: {
                                    quantity += 1
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(EnergyLensTheme.accentGreen)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Callout Card
                    Text("Use the wattage printed on the appliance.\nActual energy use varies with cycling, settings and usage.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(3)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(14)
                    
                    Spacer(minLength: 20)
                    
                    // Save Button
                    GradientButton(title: "Save Appliance") {
                        saveAppliance()
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            if let appliance = applianceToEdit {
                applianceName = appliance.name
                applianceBrandName = appliance.brand ?? ""
                category = appliance.category ?? "Select a category"
                customCategory = category == "Other" ? "" : ""
                powerRating = "\(appliance.powerW)"
                hoursPerDay = "\(appliance.hoursPerDay)"
                quantity = appliance.quantity
                usageMode = appliance.usageMode
                daysPerWeek = appliance.daysPerWeek ?? 1
            }
        }
        .alert("Appliance", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func saveAppliance() {
        let trimmedName = applianceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            alertMessage = "Please add the appliance name."
            showAlert = true
            return
        }

        let cleanedPower = powerRating.filter { $0.isNumber }
        guard let powerValue = Int(cleanedPower), powerValue > 0 else {
            alertMessage = "Power rating must be a valid number greater than zero."
            showAlert = true
            return
        }

        guard let hoursValue = Double(hoursPerDay.trimmingCharacters(in: .whitespacesAndNewlines)), hoursValue > 0 else {
            alertMessage = "Hours per day must be a valid number greater than zero."
            showAlert = true
            return
        }

        let finalUsageMode = usageMode == "Weekly" ? "Weekly" : "All day"
        let finalDaysPerWeek = finalUsageMode == "Weekly" ? min(max(1, daysPerWeek), 7) : nil
        let finalCategory = category == "Other" ? (customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Other" : customCategory) : category

        do {
            if let applianceToEdit {
                try SwiftDataApplianceService.shared.updateAppliance(
                    context: modelContext,
                    appliance: applianceToEdit,
                    name: trimmedName,
                    brand: applianceBrandName,
                    category: finalCategory,
                    powerW: powerValue,
                    quantity: quantity,
                    hoursPerDay: hoursValue,
                    usageMode: finalUsageMode,
                    daysPerWeek: finalDaysPerWeek
                )
                let edited = applianceToEdit
                Task { try? await FirebaseRESTService.shared.syncAppliance(appliance: edited, userEmail: navState.email) }
            } else {
                let created = try SwiftDataApplianceService.shared.createAppliance(
                    context: modelContext,
                    name: trimmedName,
                    brand: applianceBrandName,
                    category: finalCategory,
                    powerW: powerValue,
                    quantity: quantity,
                    hoursPerDay: hoursValue,
                    usageMode: finalUsageMode,
                    daysPerWeek: finalDaysPerWeek
                )
                Task { try? await FirebaseRESTService.shared.syncAppliance(appliance: created, userEmail: navState.email) }
            }

            if let onSave {
                onSave()
            } else {
                navState.navigate(to: .appliances)
            }
        } catch {
            alertMessage = "Unable to save appliance. Please try again."
            showAlert = true
        }
    }
}
