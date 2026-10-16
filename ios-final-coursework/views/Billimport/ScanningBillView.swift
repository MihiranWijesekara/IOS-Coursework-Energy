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
                        
                        Text("Keep this screen open while we read your bill.")
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ELECTRICITY BILL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                                .tracking(0.6)
                            
                            Text("Household account · Colombo")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            
                            Text("01 Aug – 31 Aug 2025")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Previous Reading
                        HStack {
                            Text("Previous reading")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text("12,450 kWh")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        // Current Reading
                        HStack {
                            Text("Current reading")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text("12,630 kWh")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        // Consumption Highlight Banner
                        HStack {
                            Text("Consumption")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("180 kWh")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(red: 0.10, green: 0.48, blue: 0.28))
                        .cornerRadius(8)
                        
                        // Bill Amount
                        HStack {
                            Text("Bill amount")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                            Spacer()
                            Text("LKR 7,850")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                        }
                        
                        Divider()
                            .background(EnergyLensTheme.fieldBorder)
                        
                        // Bottom note
                        Text("Generic document preview · editable sample")
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
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.11, green: 0.52, blue: 0.32))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scanning bill...")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.10, green: 0.38, blue: 0.26))
                                
                                Text("Document detected")
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
                                
                                Text("Vision Framework · in progress")
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
                                Text("Extracting consumption data...")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(EnergyLensTheme.textPrimary)
                                
                                Text("Reading values as they are recognised")
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
                        
                        // Status 4: Detected consumption · 180 kWh (Tappable to Review Bill)
                        Button(action: {
                            navState.navigate(to: .reviewBill)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.badge.checkmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.55))
                                    .frame(width: 22)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Detected consumption · 180 kWh")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.55))
                                    
                                    Text("Not saved yet. Please review after recognition.")
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
            scanningService.startScanningSequence()
        }
    }
}
