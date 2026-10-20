//
//  CreateAccountView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct CreateAccountView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    @State private var password: String = "••••••••••••"
    @State private var confirmPassword: String = "••••••••••••"
    
    // Sri Lankan Province, District, and Town Hierarchy Data Structure
    private let locationData: [String: [String: [String]]] = [
        "Western": [
            "Colombo": ["Colombo", "Dehiwala-Mount Lavinia", "Moratuwa", "Sri Jayawardenepura Kotte", "Kotte", "Kolonnawa", "Maharagama", "Kesbewa", "Ratmalana", "Homagama", "Kaduwela"],
            "Gampaha": ["Gampaha", "Negombo", "Katunayake", "Ja-Ela", "Wattala", "Gampaha", "Minuwangoda", "Kadawatha", "Kiribathgoda"],
            "Kalutara": ["Kalutara", "Panadura", "Horana", "Beruwala", "Aluthgama", "Matugama"]
        ],
        "Central": [
            "Kandy": ["Kandy", "Gampola", "Nawalapitiya", "Katugastota", "Peradeniya", "Kundasale"],
            "Matale": ["Matale", "Dambulla", "Sigiriya", "Galewela"],
            "Nuwara Eliya": ["Nuwara Eliya", "Hatton", "Talawakele", "Maskeliya"]
        ],
        "Southern": [
            "Galle": ["Galle", "Ambalangoda", "Hikkaduwa", "Elpitiya", "Baddegama"],
            "Matara": ["Matara", "Weligama", "Akuressa", "Dickwella"],
            "Hambantota": ["Hambantota", "Tangalle", "Tissamaharama", "Ambalantota"]
        ],
        "Northern": [
            "Jaffna": ["Jaffna", "Chavakachcheri", "Point Pedro", "Nallur", "Valvettithurai"],
            "Mannar": ["Mannar", "Pesalai", "Nanattan"],
            "Vavuniya": ["Vavuniya", "Cheddikulam"],
            "Mullaitivu": ["Mullaitivu", "Puthukkudiyiruppu"],
            "Kilinochchi": ["Kilinochchi", "Paranthan"]
        ],
        "Eastern": [
            "Trincomalee": ["Trincomalee", "Kinniya", "Kantale"],
            "Batticaloa": ["Batticaloa", "Kattankudy", "Eravur", "Valaichchenai"],
            "Ampara": ["Ampara", "Kalmunai", "Sammanthurai", "Akkaraipattu"]
        ],
        "North Western": [
            "Kurunegala": ["Kurunegala", "Kuliyapitiya", "Pannala", "Nikaweratiya"],
            "Puttalam": ["Puttalam", "Chilaw", "Wennappuwa", "Marawila"]
        ],
        "North Central": [
            "Anuradhapura": ["Anuradhapura", "Kekirawa", "Medawachchiya", "Tambuttegama"],
            "Polonnaruwa": ["Polonnaruwa", "Kaduruwela", "Hingurakgoda", "Medirigiriya"]
        ],
        "Uva": [
            "Badulla": ["Badulla", "Bandarawela", "Haputale", "Welimada", "Mahiyanganaya"],
            "Monaragala": ["Monaragala", "Wellawaya", "Bibile", "Kataragama"]
        ],
        "Sabaragamuwa": [
            "Ratnapura": ["Ratnapura", "Embilipitiya", "Pelmadulla", "Balangoda"],
            "Kegalle": ["Kegalle", "Mawanella", "Warakapola", "Rambukkana"]
        ]
    ]
    
    // Computed list of available provinces
    private var provinces: [String] {
        Array(locationData.keys).sorted()
    }
    
    // Computed list of districts based on selected province
    private var districts: [String] {
        guard let provinceDistricts = locationData[navState.province] else { return [] }
        return Array(provinceDistricts.keys).sorted()
    }
    
    // Computed list of towns based on selected province and district
    private var towns: [String] {
        guard let provinceDistricts = locationData[navState.province],
              let districtTowns = provinceDistricts[navState.district] else { return [] }
        return districtTowns.sorted()
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Top Navigation Back
                CustomBackButton(title: "Sign In") {
                    navState.navigate(to: .signIn)
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                // Headings
                Text("Create Account")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.bottom, 6)
                
                Text("Your household. Your energy, understood.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                    .padding(.bottom, 26)
                
                // Section: Identity
                sectionHeader("Identity")
                
                VStack(spacing: 16) {
                    labeledInputField(label: "First Name", text: $navState.firstName)
                    labeledInputField(label: "Last Name", text: $navState.lastName)
                    labeledInputField(label: "Email", text: $navState.email)
                    labeledInputField(label: "Phone Number", text: $navState.phone)
                }
                .padding(.bottom, 24)
                
                // Section: Location
                sectionHeader("Location")
                
                VStack(spacing: 16) {
                    dropdownField(label: "Province", selection: $navState.province, options: provinces) { newProvince in
                        // Auto-select the first available district and town when province changes
                        if let firstDistrict = locationData[newProvince]?.keys.sorted().first {
                            navState.district = firstDistrict
                            if let firstTown = locationData[newProvince]?[firstDistrict]?.sorted().first {
                                navState.town = firstTown
                            }
                        }
                    }
                    
                    dropdownField(label: "District", selection: $navState.district, options: districts) { newDistrict in
                        // Auto-select the first available town when district changes
                        if let firstTown = locationData[navState.province]?[newDistrict]?.sorted().first {
                            navState.town = firstTown
                        }
                    }
                    
                    dropdownField(label: "Town", selection: $navState.town, options: towns) { _ in }
                }
                .padding(.bottom, 24)
                
                // Section: Security
                sectionHeader("Security")
                
                VStack(spacing: 16) {
                    secureInputField(label: "Password", text: $password)
                    secureInputField(label: "Confirm Password", text: $confirmPassword)
                }
                .padding(.bottom, 8)
                
                Text("Use at least 8 characters for your password.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                    .padding(.bottom, 28)
                
                // Submit Button
                GradientButton(title: "Create Account") {
                    navState.navigate(to: .secureData)
                }
                .padding(.bottom, 16)
                
                // Sign In Footer Link
                HStack {
                    Spacer()
                    Text("Already have an account? ")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                    
                    Button(action: {
                        navState.navigate(to: .signIn)
                    }) {
                        Text("Sign In")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EnergyLensTheme.accentGreen)
                    }
                    Spacer()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(EnergyLensTheme.textSecondary)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func labeledInputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
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

    @ViewBuilder
    private func dropdownField(label: String, selection: Binding<String>, options: [String], onChange: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
             
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection.wrappedValue = option
                        onChange(option)
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Select \(label)" : selection.wrappedValue)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(selection.wrappedValue.isEmpty ? EnergyLensTheme.textSecondary : EnergyLensTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                }
                .padding(.bottom, 4)
            }
             
            Divider()
                .background(EnergyLensTheme.fieldBorder)
        }
    }
    
    @ViewBuilder
    private func secureInputField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
             
            SecureField(label, text: text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(EnergyLensTheme.textPrimary)
                .padding(.bottom, 4)
             
            Divider()
                .background(EnergyLensTheme.fieldBorder)
        }
    }
}
