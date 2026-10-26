import SwiftUI

public struct SecureDataView: View {
    @EnvironmentObject var navState: AppNavigationState
    @StateObject private var authService = AuthenticationService()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                CustomBackButton(title: "Sign In") {
                    navState.navigate(to: .signIn)
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.96, blue: 0.95))
                        .frame(width: 84, height: 84)

                    ZStack {
                        Image(systemName: "faceid")
                            .font(.system(size: 46, weight: .light))
                            .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.28))
                    }
                }
                .padding(.top, 16)

                Text("Secure your energy\ndata")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("Protect your energy information and\npersonal data.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Text("Use Face ID to sign in quickly and securely to your dashboard.\nFace ID helps keep access to your account private. You can use a passcode instead.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .background(EnergyLensTheme.cardGradient)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                GradientButton(title: "Sign In with Face ID") {
                    authService.authenticateWithBiometrics { success in
                        if success {
                            navState.isAuthenticated = true
                            navState.navigate(to: .home)
                        } else {
                            alertMessage = "Face ID authentication failed. Please try again."
                            showingAlert = true
                        }
                    }
                }

//                OutlineButton(title: "Use Passcode") {
//                    navState.navigate(to: .createPasscode)
//                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.white.ignoresSafeArea())
        .alert("Authentication Failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}
