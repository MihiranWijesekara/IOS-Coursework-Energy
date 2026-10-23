//
//  BillAnalysisView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI
import SwiftData

public struct BillAnalysisView: View {
    @EnvironmentObject var navState: AppNavigationState
    @Query(sort: \ElectricityBill.periodEnd, order: .reverse) private var savedBills: [ElectricityBill]
    @Query(sort: \SavedBill.scannedDate, order: .reverse) private var pdfSavedBills: [SavedBill]
    
    private var hasBills: Bool {
        !savedBills.isEmpty || !pdfSavedBills.isEmpty
    }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Analysis") {
                navState.navigate(to: .analysis)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bill Analysis")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Turn your electricity bill into a clearer picture of\nyour household energy.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .lineSpacing(2)
                    }
                    
                    // Vision Framework Feature Card
                    VStack(alignment: .leading, spacing: 14) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Read your bill automatically")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Choose a bill image. Vision Framework\nrecognises the text and extracts your\nbilling period, readings and amount.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(2)
                        
                        Text("You review and edit the values before they are\nused in your analysis.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.78))
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Section: Most recent bill
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Most recent bill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        if hasBills {
                            Button(action: {
                                navState.navigate(to: .billAnalysisResult)
                            }) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let latest = savedBills.first {
                                            let formatter = DateFormatter()
                                            let _ = formatter.dateFormat = "MMMM yyyy"
                                            Text(formatter.string(from: latest.periodEnd))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.28))
                                            
                                            let periodStr = SwiftDataBillService.formatPeriod(start: latest.periodStart, end: latest.periodEnd)
                                            Text("\(periodStr) · \(Int(round(latest.consumptionKwh))) kWh")
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(EnergyLensTheme.textSecondary)
                                        } else if let pdfLatest = pdfSavedBills.first {
                                            Text(pdfLatest.billingMonth.isEmpty ? "Recent Bill" : pdfLatest.billingMonth)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.28))
                                            Text("\(Int(round(pdfLatest.totalKWh))) kWh")
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(EnergyLensTheme.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let latest = savedBills.first {
                                        let curr = (latest.currency.uppercased() == "USD" || latest.currency == "$") ? "$" : "Rs."
                                        Text("\(curr) \(String(format: "%.2f", latest.billAmount))")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.28))
                                    } else if let pdfLatest = pdfSavedBills.first {
                                        Text("Rs. \(String(format: "%.2f", pdfLatest.totalAmount))")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.28))
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 18)
                                .background(EnergyLensTheme.mintHighlight)
                                .cornerRadius(14)
                            }
                        } else {
                            Button(action: {
                                navState.navigate(to: .selectBillImage)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(EnergyLensTheme.accentGreen)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("No bills imported yet")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(EnergyLensTheme.textPrimary)
                                        Text("Import your electricity bill to see your real consumption")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(EnergyLensTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(EnergyLensTheme.textSecondary)
                                }
                                .padding(16)
                                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.top, 6)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        GradientButton(title: "Import Electricity Bill") {
                            navState.navigate(to: .selectBillImage)
                        }
                        
                        OutlineButton(title: "View Bill History") {
                            navState.navigate(to: .billHistory)
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
