//
//  AddApplianceView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct AddApplianceView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    @State private var applianceName: String = "Air Conditioner"
    @State private var category: String = "Cooling"
    @State private var powerRating: String = "1,200 W"
    @State private var hoursPerDay: String = "6 hours"
    @State private var quantity: Int = 1
    @State private var usagePattern: String = "Evening"
    
    let categories = ["Cooling", "Refrigeration", "Ventilation", "Entertainment", "Cleaning", "Lighting", "Cooking"]
    let patterns = ["Morning", "Afternoon", "Evening", "Night", "All Day"]
    
    public init() {}
    
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
                        
                        // Category (Dropdown Pill)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Menu {
                                ForEach(categories, id: \.self) { cat in
                                    Button(cat) { category = cat }
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
                        
                        // Hours per day
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Hours per day")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            TextField("Hours per day", text: $hoursPerDay)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Form Card 2: Quantity & Usage pattern
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
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Usage pattern
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Usage pattern · Optional")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Menu {
                                ForEach(patterns, id: \.self) { pat in
                                    Button(pat) { usagePattern = pat }
                                }
                            } label: {
                                HStack {
                                    Text(usagePattern)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
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
                        navState.navigate(to: .appliances)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
