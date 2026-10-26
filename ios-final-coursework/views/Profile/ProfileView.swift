//
//  ProfileView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct ProfileView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @AppStorage("userPasscode") private var storedPasscode: String = "123456"
    @AppStorage("hasRegisteredAccount") private var hasRegisteredAccount: Bool = false
    @AppStorage("lastLoggedInEmail") private var lastLoggedInEmail: String = ""
    
    // Sheet states
    @State private var showEditProfileSheet = false
    @State private var showChangePasscodeSheet = false
    @State private var showResetAlert = false
    
    // Edit Profile form fields
    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var editPhone = ""
    @State private var editTown = ""
    @State private var editOccupants = 3
    
    // Change Passcode form fields
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var passcodeAlertMessage = ""
    @State private var showPasscodeAlert = false
    
    public init() {}
    
    private var currentUser: User? {
        users.first(where: { $0.email.lowercased() == navState.email.lowercased() }) ?? users.first
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Top Bar
                    Text("ENERGYLENS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .tracking(0.8)
                        .padding(.top, 12)
                    
                    // Title
                    Text("Profile")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // User Header Gradient Card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(EnergyLensTheme.logoSkyBlue)
                                .frame(width: 52, height: 52)
                            
                            Text(navState.initials)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.22, blue: 0.35))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(navState.firstName) \(navState.lastName)")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(navState.email)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            prepareEditProfile()
                            showEditProfileSheet = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Settings and Options Menu
                    VStack(spacing: 0) {
                        menuRow(icon: "person", iconBg: Color(red: 0.25, green: 0.60, blue: 0.85), title: "Edit Profile & Location", subtitle: "Update name, phone & town", rightValue: nil, showDivider: true) {
                            prepareEditProfile()
                            showEditProfileSheet = true
                        }
                        
                        menuRow(icon: "location.circle", iconBg: Color(red: 0.50, green: 0.40, blue: 0.80), title: "Location & Weather", subtitle: navState.town.isEmpty ? "Colombo" : navState.town, rightValue: nil, showDivider: true) {
                            navState.navigate(to: .weatherDetails)
                        }
                        
                        menuRow(icon: "bell", iconBg: Color(red: 0.40, green: 0.50, blue: 0.85), title: "Notifications", subtitle: nil, rightValue: nil, showDivider: true) {
                            navState.navigate(to: .notifications)
                        }
                        
                        menuRow(icon: "faceid", iconBg: Color(red: 0.15, green: 0.60, blue: 0.40), title: "Face ID & Security", subtitle: "Change fallback passcode (PIN)", rightValue: nil, showDivider: true) {
                            newPasscode = ""
                            confirmPasscode = ""
                            showChangePasscodeSheet = true
                        }
                        
                        menuRow(icon: "powerplug", iconBg: Color(red: 0.15, green: 0.60, blue: 0.65), title: "Appliance Preferences", subtitle: nil, rightValue: nil, showDivider: true) {
                            navState.navigate(to: .appliances)
                        }
                        
                        menuRow(icon: "icloud.fill", iconBg: Color(red: 0.20, green: 0.55, blue: 0.90), title: "Firebase Cloud Sync", subtitle: "energylens-coursework", rightValue: "Active", showDivider: true) {}
                        
                        menuRow(icon: "ruler", iconBg: Color(red: 0.85, green: 0.65, blue: 0.20), title: "Units & Currency", subtitle: nil, rightValue: "kWh / LKR", showDivider: true) {}
                        
                        menuRow(icon: "info.circle", iconBg: Color(red: 0.45, green: 0.40, blue: 0.80), title: "About EnergyLens", subtitle: "Coursework v1.0", rightValue: nil, showDivider: false) {}
                    }
                    .background(Color.white)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Viva Account Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            navState.navigate(to: .secureData)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 16))
                                Text("Lock App (Test Biometrics)")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(EnergyLensTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1.2)
                            )
                        }
                        
                        Button(action: {
                            navState.isAuthenticated = false
                            navState.navigate(to: .signIn)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.88, green: 0.24, blue: 0.24))
                            .cornerRadius(14)
                            .shadow(color: Color.red.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        
                        Button(action: {
                            showResetAlert = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                Text("Reset All Data (Fresh Launch Test)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            
            // Bottom Tab Bar
            CustomTabBar(selectedTab: $navState.selectedTab) { tab in
                switch tab {
                case .home:
                    navState.navigate(to: .home)
                case .analysis:
                    navState.navigate(to: .analysis)
                case .savings:
                    navState.navigate(to: .savingsSimulator)
                case .profile:
                    navState.navigate(to: .profile)
                }
            }
        }
        .background(EnergyLensTheme.screenBackground.ignoresSafeArea())
        .sheet(isPresented: $showEditProfileSheet) {
            editProfileSheet
        }
        .sheet(isPresented: $showChangePasscodeSheet) {
            changePasscodeSheet
        }
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all saved users, bills, appliances, and passcodes so you can test from the first-time splash screen.")
        }
    }
    
    // MARK: - Edit Profile Sheet
    private var editProfileSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Edit Profile & Location")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.top, 10)
                
                VStack(spacing: 16) {
                    sheetInputField(label: "First Name", text: $editFirstName)
                    sheetInputField(label: "Last Name", text: $editLastName)
                    sheetInputField(label: "Phone Number", text: $editPhone)
                    sheetInputField(label: "Town / City", text: $editTown)

                    // Household Occupants Stepper (1 to 12)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Household Occupants (Family Size)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Text("\(editOccupants) \(editOccupants == 1 ? "person" : "people")")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        Spacer()
                        Stepper("", value: $editOccupants, in: 1...12)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                    Divider().background(EnergyLensTheme.fieldBorder)
                }
                
                Spacer()
                
                GradientButton(title: "Save & Sync Cloud") {
                    saveProfile()
                    showEditProfileSheet = false
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditProfileSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Change Passcode Sheet
    private var changePasscodeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Change Passcode")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.top, 10)
                
                Text("Enter a new 4 to 6 digit numeric PIN to unlock EnergyLens when Biometrics are not used.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Passcode (4-6 digits)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        
                        SecureField("New Passcode", text: $newPasscode)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16))
                            .padding(.bottom, 4)
                            .onChange(of: newPasscode) { _, newValue in
                                let digits = String(newValue.filter { $0.isASCII && $0.isNumber }.prefix(6))
                                if digits != newValue { newPasscode = digits }
                            }
                        Divider().background(EnergyLensTheme.fieldBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm Passcode")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                        
                        SecureField("Confirm Passcode", text: $confirmPasscode)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16))
                            .padding(.bottom, 4)
                            .onChange(of: confirmPasscode) { _, newValue in
                                let digits = String(newValue.filter { $0.isASCII && $0.isNumber }.prefix(6))
                                if digits != newValue { confirmPasscode = digits }
                            }
                        Divider().background(EnergyLensTheme.fieldBorder)
                    }
                }
                
                Spacer()
                
                GradientButton(title: "Update Passcode") {
                    if newPasscode.count < 4 || newPasscode.count > 6 {
                        passcodeAlertMessage = "Passcode must be between 4 and 6 digits."
                        showPasscodeAlert = true
                        return
                    }
                    if newPasscode != confirmPasscode {
                        passcodeAlertMessage = "Passcodes do not match."
                        showPasscodeAlert = true
                        return
                    }
                    
                    storedPasscode = newPasscode
                    showChangePasscodeSheet = false
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showChangePasscodeSheet = false
                    }
                }
            }
            .alert("Passcode", isPresented: $showPasscodeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(passcodeAlertMessage)
            }
        }
    }
    
    private func sheetInputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
            
            TextField(label, text: text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(EnergyLensTheme.textPrimary)
                .padding(.bottom, 4)
            
            Divider()
                .background(EnergyLensTheme.fieldBorder)
        }
    }
    
    private func prepareEditProfile() {
        editFirstName = navState.firstName
        editLastName = navState.lastName
        editPhone = navState.phone
        editTown = navState.town
        editOccupants = currentUser?.occupants ?? navState.occupants
    }
    
    private func saveProfile() {
        navState.firstName = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        navState.lastName = editLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        navState.phone = editPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        navState.town = editTown.trimmingCharacters(in: .whitespacesAndNewlines)
        navState.occupants = editOccupants
        
        if let user = currentUser {
            user.firstName = navState.firstName
            user.lastName = navState.lastName
            user.phone = navState.phone.isEmpty ? nil : navState.phone
            user.town = navState.town.isEmpty ? nil : navState.town
            user.occupants = editOccupants
            
            try? modelContext.save()
            
            Task {
                try? await FirebaseRESTService.shared.syncUserProfile(user: user)
            }
        }
    }
    
    private func resetAllData() {
        // Delete all SwiftData records
        try? modelContext.delete(model: User.self)
        try? modelContext.delete(model: Appliance.self)
        try? modelContext.delete(model: ElectricityBill.self)
        try? modelContext.delete(model: SavedBill.self)
        try? modelContext.delete(model: Prediction.self)
        try? modelContext.delete(model: WeatherData.self)
        try? modelContext.delete(model: SavingsScenario.self)
        try? modelContext.save()
        
        // Reset AppStorage keys
        hasRegisteredAccount = false
        lastLoggedInEmail = ""
        storedPasscode = "123456"
        
        // Reset navState
        navState.firstName = ""
        navState.lastName = ""
        navState.email = ""
        navState.phone = ""
        navState.town = "Colombo"
        navState.isAuthenticated = false
        
        // Navigate back to splash
        navState.navigate(to: .splash)
    }
    
    @ViewBuilder
    private func menuRow(
        icon: String,
        iconBg: Color,
        title: String,
        subtitle: String?,
        rightValue: String?,
        showDivider: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconBg)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        if let sub = subtitle {
                            Text(sub)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let rv = rightValue {
                        Text(rv)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(rv == "Active" ? Color(red: 0.12, green: 0.60, blue: 0.35) : EnergyLensTheme.textSecondary)
                            .padding(.trailing, 4)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(EnergyLensTheme.textMuted)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                
                if showDivider {
                    Divider()
                        .padding(.leading, 64)
                        .background(EnergyLensTheme.fieldBorder)
                }
            }
        }
    }
}
