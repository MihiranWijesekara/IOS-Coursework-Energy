import SwiftUI

public struct CreateAccountView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    @State private var password: String = "••••••••••••"
    @State private var confirmPassword: String = "••••••••••••"
    
    let provinces = ["Western", "Central", "Southern", "North Western", "Northern", "Eastern", "Sabaragamuwa", "Uva", "North Central"]
    let districts = ["Colombo", "Gampaha", "Kalutara", "Kandy", "Galle", "Matara"]
    let towns = ["Colombo", "Dehiwala", "Moratuwa", "Sri Jayawardenepura Kotte", "Negombo"]
    
    public init() {}
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Top Navigation Back
                CustomBackButton(title: "Welcome") {
                    navState.navigate(to: .splash)
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
                    dropdownField(label: "Province", selection: $navState.province, options: provinces)
                    dropdownField(label: "District", selection: $navState.district, options: districts)
                    dropdownField(label: "Town", selection: $navState.town, options: towns)
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
    
    // Universal overload (no keyboardType parameter)
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
    private func dropdownField(label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection.wrappedValue = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textPrimary)
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

