//
//  BillScanErrorView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct BillScanErrorView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Import Bill") {
                navState.navigate(to: .selectBillImage)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Title
                    Text("Bill couldn’t be read")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Large Dark Navy Error Card
                    VStack(spacing: 16) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 38, weight: .light))
                            .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))
                            .padding(.top, 16)
                        
                        Text("Try a clearer image")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if let warningMsg = navState.lastOCRWarningMessage, !warningMsg.isEmpty {
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))
                                    Text("OCR Analysis Note")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))
                                }
                                Text(warningMsg)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.92))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        } else {
                            Text("The document is unreadable. Some\nreadings may be blurred, cropped or too\ndark.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.88))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Light Sky Blue Banner
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.10, green: 0.40, blue: 0.45))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Nothing has been saved")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.40))
                            
                            Text("Your existing bill history is unchanged.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.88, green: 0.95, blue: 0.99))
                    .cornerRadius(16)
                    
                    // Caption
                    Text("Place the bill flat in good light. Include all four\ncorners and keep the readings in focus.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 2)
                    
                    Spacer(minLength: 30)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        GradientButton(title: "Retake") {
                            navState.navigate(to: .scanningBill)
                        }

                        Button {
                            navState.currentBillDraft = BillExtractionDraft()
                            navState.shouldOpenManualEntryModal = true
                            navState.navigate(to: .reviewBill)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Enter Bill Details Manually")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EnergyLensTheme.mintHighlight)
                            .foregroundColor(EnergyLensTheme.accentGreen)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(EnergyLensTheme.accentGreen.opacity(0.4), lineWidth: 1.2)
                            )
                        }
                        
                        OutlineButton(title: "Choose Another Image") {
                            navState.navigate(to: .selectBillImage)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
