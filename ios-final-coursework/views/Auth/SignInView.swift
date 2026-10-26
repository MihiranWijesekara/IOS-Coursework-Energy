import SwiftUI

public struct SignInView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasRegisteredAccount") private var hasRegisteredAccount: Bool = false
    @AppStorage("lastLoggedInEmail") private var lastLoggedInEmail: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Navigation
            CustomBackButton(title: "Welcome") {
                navState.navigate(to: .splash)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
            
            // Heading & Subtitle
            Text("Sign In")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(EnergyLensTheme.textPrimary)
                .padding(.bottom, 8)
            
            Text("Access your EnergyLens account to monitor your energy usage and insights.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
                .lineSpacing(2)
                .padding(.bottom, 36)
            
            // Email Input
            VStack(alignment: .leading, spacing: 3) {
                Text("Email")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                
                TextField("Email", text: $email)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.bottom, 4)
                
                Divider()
                    .background(EnergyLensTheme.fieldBorder)
            }
            .padding(.bottom, 24)
            
            // Password Input
            VStack(alignment: .leading, spacing: 3) {
                Text("Password")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                
                SecureField("Password", text: $password)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textPrimary)
                    .padding(.bottom, 4)
                
                Divider()
                    .background(EnergyLensTheme.fieldBorder)
            }
            .padding(.bottom, 12)
            
            // Forgot Password Link
            HStack {
                Spacer()
                Button(action: {}) {
                    Text("Forgot Password?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(EnergyLensTheme.accentGreen)
                }
            }
            
            Spacer()
            
            // Create Account Link
            HStack {
                Spacer()
                Text("Don't have an account? ")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
                
                Button(action: {
                    navState.navigate(to: .createAccount)
                }) {
                    Text("Create Account")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(EnergyLensTheme.accentGreen)
                }
                Spacer()
            }
            .padding(.bottom, 18)
            
            // Action Buttons
            VStack(spacing: 12) {
                GradientButton(title: "Sign In") {
                    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedEmail.isEmpty || password.isEmpty {
                        alertMessage = "Please enter your email and password."
                        showAlert = true
                        return
                    }

                    if let user = SwiftDataUserService.shared.login(context: modelContext, email: trimmedEmail, password: password) {
                        navState.firstName = user.firstName
                        navState.lastName = user.lastName
                        navState.email = user.email
                        navState.phone = user.phone ?? ""
                        navState.province = user.province ?? navState.province
                        navState.district = user.district ?? navState.district
                        navState.town = user.town ?? navState.town
                        navState.isAuthenticated = true
                        hasRegisteredAccount = true
                        lastLoggedInEmail = user.email
                        
                        // Sign in to Firebase Auth in the background
                        let enteredPassword = password
                        Task { _ = try? await FirebaseRESTService.shared.signIn(email: trimmedEmail, password: enteredPassword) }
                        navState.navigate(to: .home)
                    } else {
                        alertMessage = "Invalid email or password. Please try again."
                        showAlert = true
                    }
                }

                OutlineButton(title: "Sign In with Face ID") {
                    navState.navigate(to: .secureData)
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            if email.isEmpty { email = lastLoggedInEmail }
        }
        .alert("Sign in", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}

