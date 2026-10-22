//
//  SelectBillImageView.swift
//  ios-final-coursework
//
//  Interactive Bill Selection & Vision OCR Trigger Screen
//

import SwiftUI
import PhotosUI

public struct SelectBillImageView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCameraPicker = false
    @State private var inputImage: UIImage? = nil
    @State private var isProcessingOCR = false
    @State private var errorMessage = ""
    @State private var extractedBillData: ExtractedBillData? = nil
    
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomBackButton(title: "Bill Analysis") {
                navState.navigate(to: .billAnalysis)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select Bill Image")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)

                        Text("Choose a clear screenshot or photo of your Sri Lankan electricity bill.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    .padding(.bottom, 4)

                    // Photo Picker Button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 12) {
                            if isProcessingOCR {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text(isProcessingOCR ? "Processing with Apple Vision..." : (inputImage != nil ? "Change Selected Image" : "Choose from Photos"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(EnergyLensTheme.buttonGradient)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .disabled(isProcessingOCR)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            await processSelectedImage(newItem)
                        }
                    }

                    // Camera Picker Button
                    Button(action: {
                        showCameraPicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.36))

                            Text("Take Photo with Camera")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.36))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.36).opacity(0.8))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(Color(red: 0.88, green: 0.95, blue: 0.97))
                        .cornerRadius(14)
                    }
                    .disabled(isProcessingOCR)
                    .sheet(isPresented: $showCameraPicker) {
                        ImagePicker(image: $inputImage, sourceType: .camera) {
                            Task {
                                await processSelectedImage(nil, imageOverride: inputImage)
                            }
                        }
                    }

                    // Preview of Selected Image OR Reference Template
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(inputImage != nil ? "SELECTED BILL IMAGE PREVIEW" : "DOCUMENT EXAMPLE / TEMPLATE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .tracking(0.6)
                            
                            Spacer()
                            
                            if inputImage != nil {
                                Button(action: {
                                    inputImage = nil
                                    navState.selectedBillImage = nil
                                }) {
                                    Text("Remove")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.top, 4)

                        if let image = inputImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 260)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EnergyLensTheme.accentGreen, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        } else if let cached = navState.selectedBillImage {
                            Image(uiImage: cached)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 260)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EnergyLensTheme.accentGreen, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        } else {
                            SampleBillDocumentView()
                        }
                    }

                    // Native Apple Vision Feature Info Card
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.45))
                            .frame(width: 24)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Automatic Vision Extraction")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)

                            Text("Apple Vision OCR reads meter readings, electricity consumption, charges, and account details with mathematical validation.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .lineSpacing(2)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Color(red: 0.94, green: 0.97, blue: 0.98))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.85, green: 0.92, blue: 0.94), lineWidth: 1)
                    )

                    // Extract Button
                    Button(action: {
                        if let image = inputImage ?? navState.selectedBillImage {
                            Task {
                                await processSelectedImage(nil, imageOverride: image)
                            }
                        } else {
                            // If no image has been selected yet, route to Scanning demo view
                            navState.navigate(to: .scanningBill)
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isProcessingOCR {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text(isProcessingOCR ? "Extracting..." : "Extract Bill Information")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(EnergyLensTheme.buttonGradient)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .disabled(isProcessingOCR)

                    if !errorMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    @MainActor
    private func processSelectedImage(_ item: PhotosPickerItem?, imageOverride: UIImage? = nil) async {
        isProcessingOCR = true
        errorMessage = ""

        do {
            let image: UIImage
            if let imageOverride {
                image = imageOverride
            } else {
                guard let item else {
                    isProcessingOCR = false
                    return
                }
                guard let data = try await item.loadTransferable(type: Data.self),
                      let loaded = UIImage(data: data) else {
                    throw NSError(domain: "BillOCR", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not load the selected image."])
                }
                image = loaded
            }

            inputImage = image
            navState.selectedBillImage = image

            // 1. Run Apple Vision Text Recognition
            let rawText = try await BillTextRecognitionService.recognizeText(from: image)

            // 2. Parse into ExtractedBillData structure
            let parsed = ExtractedBillData.parse(from: rawText)
            extractedBillData = parsed
            navState.latestExtractedBill = parsed
            navState.extractedBillData = parsed
            isProcessingOCR = false

            // 3. Check for unreadable/blank image
            if parsed.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                navState.navigate(to: .billScanError)
                return
            }

            // 4. Save to shared navState and navigate to Review Bill
            navState.navigate(to: .reviewBill)
        } catch {
            isProcessingOCR = false
            errorMessage = "OCR failed: \(error.localizedDescription)"
            navState.navigate(to: .billScanError)
        }
    }
}

// Camera Helper Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .camera
    var onCompletion: () -> Void
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onCompletion()
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
