//
//  HomeSkeletonView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct HomeSkeletonView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Bar
                    HStack(alignment: .center) {
                        Text("ENERGYLENS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .tracking(0.8)
                        
                        Spacer()
                        
                        Button(action: {
                            navState.navigate(to: .notifications)
                        }) {
                            Text("Inbox")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                        }
                    }
                    .padding(.top, 12)
                    
                    // Greeting & Title
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Home")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        Text("Good morning, \(navState.firstName)")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                    }
                    
                    // Loading Energy Overview Banner
                    HStack(alignment: .center, spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.10, green: 0.40, blue: 0.50)))
                            .scaleEffect(1.1)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Loading your energy overview")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.35, blue: 0.45))
                            
                            Text("Fetching your latest bill and estimates…")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(red: 0.82, green: 0.92, blue: 0.98))
                    .cornerRadius(16)
                    
                    // Dark Forest Green Skeleton Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Top Pill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.38, green: 0.58, blue: 0.50).opacity(0.8))
                            .frame(width: 140, height: 16)
                        
                        // Large Block
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.38, green: 0.58, blue: 0.50).opacity(0.8))
                            .frame(width: 220, height: 44)
                        
                        // Medium Pill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.38, green: 0.58, blue: 0.50).opacity(0.8))
                            .frame(width: 170, height: 22)
                        
                        // Bottom Pill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.38, green: 0.58, blue: 0.50).opacity(0.8))
                            .frame(width: 230, height: 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(Color(red: 0.07, green: 0.28, blue: 0.22))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Muted Lavender Skeleton Rows
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.85, green: 0.86, blue: 0.95))
                            .frame(maxWidth: .infinity)
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.78, green: 0.88, blue: 0.96))
                            .frame(maxWidth: .infinity)
                            .frame(height: 14)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.85, green: 0.86, blue: 0.95))
                            .frame(width: 230, height: 20)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.78, green: 0.88, blue: 0.96))
                            .frame(width: 310, height: 14)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.85, green: 0.86, blue: 0.95))
                            .frame(width: 230, height: 20)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.78, green: 0.88, blue: 0.96))
                            .frame(width: 310, height: 14)
                    }
                    .padding(.vertical, 6)
                    
                    // Import Shortcut Card
                    Button(action: {
                        navState.navigate(to: .billAnalysis)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                                .frame(width: 24)
                            
                            Text("Import Electricity Bill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(EnergyLensTheme.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(EnergyLensTheme.textMuted)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                        )
                    }
                    
                    // Bottom Caption
                    Text("Your overview will appear here once it’s ready.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .padding(.top, 2)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            
            // Bottom Tab Bar
            CustomTabBar(selectedTab: $navState.selectedTab) { tab in
                switch tab {
                case .home:
                    navState.navigate(to: .home)
                case .analysis:
                    navState.navigate(to: .analysis)
                case .savings:
                    navState.navigate(to: .savingsSimulator)
                case .profile:
                    navState.navigate(to: .profile)
                }
            }
        }
        .background(EnergyLensTheme.screenBackground.ignoresSafeArea())
    }
}
