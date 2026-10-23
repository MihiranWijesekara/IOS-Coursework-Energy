import SwiftUI
import SwiftData

public struct AppliancesView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appliance.name) private var savedAppliances: [Appliance]
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]

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
                    HStack {
                        Text("Household profiles")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Spacer()
                        
                        if savedAppliances.isEmpty {
                            Button("Load Samples") {
                                try? SwiftDataApplianceService.shared.seedDefaultHouseholdAppliances(context: modelContext)
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(EnergyLensTheme.accentGreen)
                        }
                    }

                    VStack(spacing: 12) {
                        if savedAppliances.isEmpty {
                            VStack(spacing: 12) {
                                applianceItem(
                                    icon: "powerplug",
                                    iconBg: Color(red: 0.12, green: 0.52, blue: 0.65),
                                    name: "No saved appliances",
                                    specs: "Add an appliance or load standard household samples",
                                    kwhBadge: nil
                                )
                                
                                Button(action: {
                                    try? SwiftDataApplianceService.shared.seedDefaultHouseholdAppliances(context: modelContext)
                                }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Load Standard Coursework Appliances")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.42))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(red: 0.88, green: 0.95, blue: 0.97))
                                    .cornerRadius(12)
                                }
                            }
                        } else {
                            let targetKwh = savedBills.first?.consumptionKwh
                            ForEach(savedAppliances) { appliance in
                                let cal = ApplianceCalibrationService.shared.calibrateSingleAppliance(
                                    appliance: appliance,
                                    allAppliances: savedAppliances,
                                    targetBillKwh: targetKwh
                                )
                                let badgeText = "\(Int(round(cal.calibratedKwh))) kWh"
                                
                                Button(action: {
                                    navState.selectedAppliance = appliance.name
                                    navState.selectedApplianceID = appliance.id
                                    navState.selectedApplianceId = appliance.id
                                    navState.navigate(to: .applianceDetail)
                                }) {
                                    applianceItem(
                                        icon: applianceIcon(for: appliance.category ?? appliance.name),
                                        iconBg: applianceColor(for: appliance.category ?? appliance.name),
                                        name: appliance.name,
                                        specs: specText(for: appliance),
                                        kwhBadge: badgeText
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
    private func applianceItem(icon: String, iconBg: Color, name: String, specs: String, kwhBadge: String? = nil) -> some View {
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

            if let badge = kwhBadge {
                Text(badge)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(EnergyLensTheme.accentGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(EnergyLensTheme.mintHighlight)
                    .clipShape(Capsule())
            }

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
