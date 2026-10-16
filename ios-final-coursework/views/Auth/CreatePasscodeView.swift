import SwiftUI

public struct CreatePasscodeView: View {
    @EnvironmentObject var navState: AppNavigationState
    @State private var passcode: String = ""
    private let passcodeLength = 6
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Back
            HStack {
                CustomBackButton(title: "Security") {
                    navState.navigate(to: .secureData)
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            // Header Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Create a passcode")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Choose a six-digit code to protect your\nenergy data.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 22)
            .padding(.horizontal, 20)
            .background(EnergyLensTheme.cardGradient)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
            
            // Passcode Pill Display
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ForEach(0..<passcodeLength, id: \.self) { index in
                        Circle()
                            .fill(index < passcode.count ? Color(red: 0.15, green: 0.20, blue: 0.25) : Color(red: 0.45, green: 0.50, blue: 0.55))
                            .frame(width: 14, height: 14)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.82, green: 0.84, blue: 0.86))
                .cornerRadius(16)
                
                Text("Enter your new passcode")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(EnergyLensTheme.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            // Numeric Keypad (3x4)
            NumberPadView(passcode: $passcode, maxDigits: passcodeLength) {
                if passcode.count == passcodeLength || passcode.count >= 4 {
                    navState.enteredPasscode = passcode
                    navState.isAuthenticated = true
                    navState.navigate(to: .home)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bottom Info Note
            Text("You'll confirm this code on the next step.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(EnergyLensTheme.textSecondary)
                .padding(.bottom, 20)
        }
        .background(Color.white.ignoresSafeArea())
    }
}
