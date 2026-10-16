//
//  BillHistoryEmptyView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct BillHistoryEmptyView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Bill Analysis") {
                navState.navigate(to: .billAnalysis)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Bill History")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Large Dark Navy Empty State Card
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 38, weight: .light))
                            .foregroundColor(Color(red: 0.45, green: 0.88, blue: 0.65))
                            .padding(.top, 16)
                        
                        Text("No bill history yet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Import your first electricity bill to start\nunderstanding your energy use.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .padding(.horizontal, 20)
                    .background(EnergyLensTheme.darkNavyCard)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Footnote
                    Text("We’ll extract the readings automatically. You can review and edit them before saving.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 4)
                    
                    Spacer(minLength: 40)
                    
                    // Import Button
                    GradientButton(title: "Import Electricity Bill") {
                        navState.navigate(to: .selectBillImage)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
