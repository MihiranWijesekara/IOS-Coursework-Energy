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
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
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
                VStack(alignment: .leading, spacing: 18) {
                    // Headings
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select Bill Image")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Choose a clear image of the entire bill.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    .padding(.bottom, 4)
                    
                    // Option 1: Choose from Photos
                    Button(action: {
                        navState.navigate(to: .scanningBill)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Choose from Photos")
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
                    
                    // Option 2: Take Photo
                    Button(action: {
                        navState.navigate(to: .scanningBill)
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
                    
                    // Section: DOCUMENT EXAMPLE
                    Text("DOCUMENT EXAMPLE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .tracking(0.6)
                        .padding(.top, 8)
                    
                    // Sample Document Preview
                    SampleBillDocumentView()
                    
                    // Bottom Feature Card: Automatic extraction
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
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
