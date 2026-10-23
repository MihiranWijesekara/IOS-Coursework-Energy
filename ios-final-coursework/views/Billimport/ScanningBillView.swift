import SwiftUI

public struct ScanningBillView: View {
    @Environment(NavigationModel.self) private var navModel
    @State private var isAnimating = false
    @State private var scanTask: Task<Void, Never>? = nil
    @State private var statusText: String = "Running Vision OCR on bill image..."

    public init() {}

    public var body: some View {
        ZStack {
            EnergyLensTheme.background.ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(EnergyLensTheme.cardBackground)
                        .frame(width: 260, height: 340)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(EnergyLensTheme.cyanAccent.opacity(0.5), lineWidth: 2)
                        )

                    if let image = navModel.selectedBillImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 236, height: 316)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .opacity(0.65)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 80))
                            .foregroundColor(EnergyLensTheme.textTertiary.opacity(0.3))
                    }

                    // Laser Scanner Beam
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, EnergyLensTheme.cyanAccent, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 240, height: 4)
                        .shadow(color: EnergyLensTheme.cyanAccent, radius: 10)
                        .offset(y: isAnimating ? 140 : -140)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                VStack(spacing: 12) {
                    Text("Extracting Bill Details...")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(statusText)
                        .font(.system(size: 14))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button {
                    scanTask?.cancel()
                    navModel.navigateBack()
                } label: {
                    Text("Cancel Scan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(EnergyLensTheme.AlertOrange)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(EnergyLensTheme.AlertOrange.opacity(0.12))
                        .cornerRadius(12)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isAnimating = true
            startOCRTask()
        }
        .onDisappear {
            scanTask?.cancel()
        }
    }

    private func startOCRTask() {
        guard scanTask == nil else { return }
        guard let imageToProcess = navModel.selectedBillImage else {
            navModel.lastOCRWarningMessage = "No electricity bill image was provided for scanning."
            navModel.navigate(to: .billScanError)
            return
        }

        scanTask = Task {
            do {
                let extractedDraft = try await BillTextRecognitionService.shared.extractBillData(from: imageToProcess)
                try Task.checkCancellation()

                await MainActor.run {
                    navModel.currentBillDraft = extractedDraft
                    let hasMinimumFields = !extractedDraft.accountNumber.isEmpty || 
                                           !extractedDraft.totalKWh.isEmpty || 
                                           !extractedDraft.totalAmount.isEmpty || 
                                           !extractedDraft.monthlyBill.isEmpty
                    
                    if !extractedDraft.rawExtractedText.isEmpty && hasMinimumFields {
                        navModel.lastOCRWarningMessage = nil
                        navModel.navigate(to: .reviewBill)
                    } else if !extractedDraft.rawExtractedText.isEmpty {
                        navModel.lastOCRWarningMessage = "Text was detected, but standard electricity bill labels were incomplete. You can review the raw OCR text or enter values manually."
                        navModel.navigate(to: .billScanError)
                    } else {
                        navModel.lastOCRWarningMessage = "No readable text was found in the selected image."
                        navModel.navigate(to: .billScanError)
                    }
                }
            } catch is CancellationError {
                // Cancelled cleanly by user
            } catch {
                await MainActor.run {
                    navModel.lastOCRWarningMessage = error.localizedDescription
                    navModel.navigate(to: .billScanError)
                }
            }
        }
    }
}
