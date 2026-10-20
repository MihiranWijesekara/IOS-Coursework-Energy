//
//  AppliancesView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct AppliancesView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @State private var savedAppliances: [Appliance] = []

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Analysis") {
                navState.navigate(to: .analysis)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Appliances")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)

                        Text("Manage your household appliances.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }

                    // Section: Household profiles
                    Text("Household profiles")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)

                    VStack(spacing: 12) {
                        if savedAppliances.isEmpty {
                            applianceItem(
                                icon: "powerplug",
                                iconBg: Color(red: 0.12, green: 0.52, blue: 0.65),
                                name: "No saved appliances",
                                specs: "Add your first appliance to begin"
                            )
                        } else {
                            ForEach(savedAppliances) { appliance in
                                Button(action: {
                                    navState.selectedApplianceId = appliance.id
                                    navState.navigate(to: .applianceDetail)
                                }) {
                                    applianceItem(
                                        icon: applianceIcon(for: appliance.category ?? appliance.name),
                                        iconBg: applianceColor(for: appliance.category ?? appliance.name),
                                        name: appliance.name,
                                        specs: specText(for: appliance)
                                    )
                                }
                            }
                        }
                    }

                    // Callout Box
                    Text("Power ratings are nameplate values. Your bill and these profiles help calibrate estimated consumption.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(3)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.90, green: 0.96, blue: 0.98))
                        .cornerRadius(14)

                    Spacer(minLength: 20)

                    // Add Appliance Button
                    GradientButton(title: "Add Appliance") {
                        navState.navigate(to: .addAppliance)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            do {
                savedAppliances = try SwiftDataApplianceService.shared.fetchAppliances(context: modelContext)
            } catch {
                savedAppliances = []
            }
        }
    }

    private func specText(for appliance: Appliance) -> String {
        let usageText: String
        if appliance.usageMode == "Weekly" {
            let weekdayCount = appliance.daysPerWeek ?? 1
            usageText = "\(appliance.hoursPerDay) h/day · \(weekdayCount) day/week"
        } else {
            usageText = "\(appliance.hoursPerDay) h/day · All day"
        }
        return "\(appliance.powerW) W · \(usageText) · \(appliance.quantity) unit"
    }

    private func applianceIcon(for category: String) -> String {
        switch category.lowercased() {
        case "cooling": return "air.conditioner.horizontal"
        case "refrigeration": return "refrigerator"
        case "ventilation": return "fanblades"
        case "entertainment": return "tv"
        case "cleaning": return "sparkles"
        case "lighting": return "lightbulb"
        case "cooking": return "stove"
        default: return "powerplug"
        }
    }

    private func applianceColor(for category: String) -> Color {
        switch category.lowercased() {
        case "cooling": return Color(red: 0.12, green: 0.52, blue: 0.65)
        case "refrigeration": return Color(red: 0.90, green: 0.50, blue: 0.20)
        case "ventilation": return Color(red: 0.15, green: 0.60, blue: 0.35)
        case "entertainment": return Color(red: 0.50, green: 0.35, blue: 0.75)
        case "cleaning": return Color(red: 0.20, green: 0.50, blue: 0.70)
        case "lighting": return Color(red: 0.75, green: 0.65, blue: 0.30)
        case "cooking": return Color(red: 0.85, green: 0.35, blue: 0.30)
        default: return Color(red: 0.12, green: 0.52, blue: 0.65)
        }
    }

    @ViewBuilder
    private func applianceItem(icon: String, iconBg: Color, name: String, specs: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)

                Text(specs)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(EnergyLensTheme.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
        )
    }
}
