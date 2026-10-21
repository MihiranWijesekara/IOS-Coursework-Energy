//
//  SelectBillImageView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
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

                        Text("Choose a clear image of the entire bill.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    .padding(.bottom, 4)

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

                            Text(isProcessingOCR ? "Recognising bill..." : "Choose from Photos")
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
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            await processSelectedImage(newItem)
                        }
                    }

                    Button(action: {
                        showCameraPicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.36))

                            Text("Take Photo")
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
                    .sheet(isPresented: $showCameraPicker) {
                        ImagePicker(image: $inputImage, sourceType: .camera) {
                            Task {
                                await processSelectedImage(nil, imageOverride: inputImage)
                            }
                        }
                    }

                    Text("DOCUMENT EXAMPLE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .tracking(0.6)
                        .padding(.top, 8)

                    SampleBillDocumentView()

                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.45))
                            .frame(width: 24)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Automatic extraction")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)

                            Text("Vision Framework detects the bill text. You'll review the readings and amount next.")
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
                    .padding(.bottom, 24)

                    Button(action: {
                        if let image = inputImage {
                            Task {
                                await processSelectedImage(nil, imageOverride: image)
                            }
                        } else {
                            navState.navigate(to: .scanningBill)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Extract the Bill from Image")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 18)
                        .background(EnergyLensTheme.buttonGradient)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
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

            // 1. Run Vision OCR
            let rawText = try await BillTextRecognitionService.recognizeText(from: image)

            // 2. Parse into ExtractedBillData
            let parsed = ExtractedBillData.parse(from: rawText)
            extractedBillData = parsed
            isProcessingOCR = false

            // 3. Check for unreadable/blank image
            if parsed.rawText.isEmpty {
                navState.navigate(to: .billScanError)
                return
            }

            // 4. Save to shared navState and navigate to Review Bill
            navState.extractedBillData = parsed
            navState.navigate(to: .reviewBill)
        } catch {
            isProcessingOCR = false
            navState.navigate(to: .billScanError)
        }
    }
}

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

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController, ) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
