import SwiftUI
import SwiftData
import LocalAuthentication

public struct SecureDataView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query private var users: [User]
    @StateObject private var authService = AuthenticationService()
    
    @AppStorage("userPasscode") private var storedPasscode: String = "123456"
    @AppStorage("lastLoggedInEmail") private var lastLoggedInEmail: String = ""
    
    @State private var isPasscodeMode = false
    @State private var enteredPasscode = ""
    @State private var passcodeError = ""
    @State private var didAttemptBiometrics = false
    
    private let pinLength = 6

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
            .padding(.bottom, 16)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerCard
                    
                    if isPasscodeMode {
                        NumberPadView(passcode: $enteredPasscode, maxDigits: pinLength) {
                            validatePasscode()
                        }
                        .padding(.horizontal, 24)
                        .onChange(of: enteredPasscode) { _, newValue in
                            passcodeError = ""
                            // Auto-validate as soon as the entered PIN reaches the stored PIN length
                            if newValue.count == storedPasscode.count {
                                validatePasscode()
                            }
                        }
                    }
                    
                    actionButtons
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadProfileIfNeeded()
            guard !didAttemptBiometrics else { return }
            didAttemptBiometrics = true
            if authService.canUseBiometrics() {
                attemptBiometrics()
            } else {
                switchToPasscodeMode()
            }
        }
    }
    
 
    
    private var headerCard: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.85, green: 0.96, blue: 0.95))
                    .frame(width: 84, height: 84)

                Image(systemName: isPasscodeMode ? "lock.fill" : biometricIconName)
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.28))
            }
            .padding(.top, 8)

            Text(isPasscodeMode ? "Enter your passcode" : "Secure your energy\ndata")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            if isPasscodeMode {
                pinDots
                
                Text(passcodeError.isEmpty ? "Unlock EnergyLens with your passcode." : passcodeError)
                    .font(.system(size: 14, weight: passcodeError.isEmpty ? .regular : .semibold))
                    .foregroundColor(passcodeError.isEmpty ? .white.opacity(0.85) : Color(red: 1.0, green: 0.82, blue: 0.80))
                    .multilineTextAlignment(.center)
            } else {
                Text("Use \(biometricName) to unlock quickly and securely.\nYou can use your passcode instead.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(EnergyLensTheme.cardGradient)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
        .padding(.horizontal, 24)
    }
    
    private var pinDots: some View {
        HStack(spacing: 14) {
            ForEach(0..<pinLength, id: \.self) { index in
                Circle()
                    .fill(index < enteredPasscode.count ? Color.white : Color.white.opacity(0.0))
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                    .frame(width: 14, height: 14)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isPasscodeMode {
                GradientButton(title: "Unlock with Passcode") {
                    validatePasscode()
                }
                
                if authService.canUseBiometrics() {
                    OutlineButton(title: "Use \(biometricName)") {
                        attemptBiometrics()
                    }
                }
            } else {
                GradientButton(title: "Sign In with \(biometricName)") {
                    attemptBiometrics()
                }
                
                OutlineButton(title: "Unlock with Passcode") {
                    switchToPasscodeMode()
                }
            }
            
            Button(action: {
                navState.navigate(to: .signIn)
            }) {
                Text("Sign In with Email & Password")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(EnergyLensTheme.accentGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 24)
    }

    
    private var biometricName: String {
        authService.biometryType == .touchID ? "Touch ID" : "Face ID"
    }
    
    private var biometricIconName: String {
        authService.biometryType == .touchID ? "touchid" : "faceid"
    }
    
    private func attemptBiometrics() {
        authService.authenticateWithBiometrics { success in
            if success {
                unlock()
            } else {
                // Unavailable, failed or cancelled: fall back to the passcode pad
                switchToPasscodeMode()
            }
        }
    }
    
    private func switchToPasscodeMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPasscodeMode = true
        }
    }
    
    private func validatePasscode() {
        guard !enteredPasscode.isEmpty else { return }
        if enteredPasscode == storedPasscode {
            unlock()
        } else {
            passcodeError = "Incorrect passcode. Please try again."
            enteredPasscode = ""
        }
    }
    
    private func unlock() {
        navState.isAuthenticated = true
        navState.navigate(to: .home)
    }
    

    private func loadProfileIfNeeded() {
        guard !lastLoggedInEmail.isEmpty,
              navState.email.lowercased() != lastLoggedInEmail.lowercased(),
              let user = users.first(where: { $0.email.lowercased() == lastLoggedInEmail.lowercased() }) else { return }
        navState.firstName = user.firstName
        navState.lastName = user.lastName
        navState.email = user.email
        navState.phone = user.phone ?? ""
        navState.province = user.province ?? navState.province
        navState.district = user.district ?? navState.district
        navState.town = user.town ?? navState.town
    }
}

