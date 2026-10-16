import SwiftUI

public struct SignInView: View {
    @EnvironmentObject var navState: AppNavigationState
    @State private var email: String = "achintha@example.com"
    @State private var password: String = "••••••••••••"
    
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
            
            // Sign In Button
            GradientButton(title: "Sign In") {
                navState.navigate(to: .home)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .background(Color.white.ignoresSafeArea())
    }
}

