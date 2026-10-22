//
//  ScanningBillView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ScanningBillView: View {
    @EnvironmentObject var navState: AppNavigationState
    @StateObject private var scanningService = BillScanningService()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Import Bill") {
                navState.navigate(to: .selectBillImage)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Top Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scanning bill…")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Keep this screen open while Apple Vision reads your bill.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.92))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Card 1: ELECTRICITY BILL Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(navState.latestExtractedBill.provider) ELECTRICITY BILL")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                    .tracking(0.6)
                                
                                Text(navState.latestExtractedBill.customerName ?? "Customer Account")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text(navState.latestExtractedBill.billingPeriod.isEmpty ? "Current Period" : navState.latestExtractedBill.billingPeriod)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            if let img = navState.selectedBillImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(EnergyLensTheme.accentGreen, lineWidth: 1.5)
                                    )
                            }
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Previous Reading
                        HStack {
                            Text("Previous reading")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text(navState.latestExtractedBill.previousReading.isEmpty ? "10,678 kWh" : navState.latestExtractedBill.previousReading)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        // Current Reading
                        HStack {
                            Text("Current reading")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text(navState.latestExtractedBill.currentReading.isEmpty ? "10,756 kWh" : navState.latestExtractedBill.currentReading)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        // Consumption Highlight Banner
                        HStack {
                            Text("Consumption")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(navState.latestExtractedBill.consumptionKwh.isEmpty ? "78 kWh" : navState.latestExtractedBill.consumptionKwh)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(red: 0.10, green: 0.48, blue: 0.28))
                        .cornerRadius(8)
                        
                        // Bill Amount
                        HStack {
                            Text("Total Payable")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text(navState.latestExtractedBill.totalAmountPayable.isEmpty ? "Rs. 2,415.79" : navState.latestExtractedBill.totalAmountPayable)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Bottom note
                        Text("Live OCR detection · Apple Vision Engine")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textMuted)
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
                    
                    // Card 2: Status Progress Rows
                    VStack(spacing: 10) {
                        // Status 1: Document detected
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.11, green: 0.52, blue: 0.32))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scanning bill...")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.26))
                                
                                Text("Document image detected")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.89, green: 0.96, blue: 0.91))
                        .cornerRadius(12)
                        
                        // Status 2: Recognising text (Vision Framework)
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 22, height: 22)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recognising text...")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Vision Framework · accurate recognition")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(EnergyLensTheme.scanningBlueGradient)
                        .cornerRadius(12)
                        
                        // Status 3: Extracting consumption data
                        HStack(spacing: 12) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .frame(width: 22)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Extracting Sri Lankan bill fields...")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Account number, readings, charges, and dates")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(EnergyLensTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                        
                        // Status 4: Tappable to Review Bill
                        Button(action: {
                            navState.navigate(to: .reviewBill)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.badge.checkmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.55))
                                    .frame(width: 22)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Extraction complete · Review Bill")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.55))
                                    
                                    Text("Tap here to verify detected values before saving.")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.55))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.93, green: 0.98, blue: 0.96))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.82, green: 0.94, blue: 0.88), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            scanningService.startScanningSequence {
                // Auto navigate to review on completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navState.navigate(to: .reviewBill)
                }
            }
        }
    }
}
