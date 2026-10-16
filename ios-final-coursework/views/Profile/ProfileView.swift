//
//  ProfileView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct ProfileView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Top Bar
                    Text("ENERGYLENS")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .tracking(0.8)
                        .padding(.top, 12)
                    
                    // Title
                    Text("Profile")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // User Header Gradient Card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(EnergyLensTheme.logoSkyBlue)
                                .frame(width: 52, height: 52)
                            
                            Text("AM")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(red: 0.08, green: 0.22, blue: 0.35))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(navState.firstName) \(navState.lastName)")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(navState.email)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.72, green: 0.92, blue: 0.82))
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(EnergyLensTheme.cardGradient)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                    
                    // Settings and Options Menu
                    VStack(spacing: 0) {
                        menuRow(icon: "person", iconBg: Color(red: 0.25, green: 0.60, blue: 0.85), title: "Profile", subtitle: nil, rightValue: nil, showDivider: true) {}
                        
                        menuRow(icon: "location.circle", iconBg: Color(red: 0.50, green: 0.40, blue: 0.80), title: "Location & Weather", subtitle: "Colombo", rightValue: nil, showDivider: true) {
                            navState.navigate(to: .weatherDetails)
                        }
                        
                        menuRow(icon: "sun.max", iconBg: Color(red: 0.92, green: 0.65, blue: 0.20), title: "Weather Settings", subtitle: nil, rightValue: nil, showDivider: true) {}
                        
                        menuRow(icon: "bell", iconBg: Color(red: 0.40, green: 0.50, blue: 0.85), title: "Notifications", subtitle: nil, rightValue: nil, showDivider: true) {
                            navState.navigate(to: .notifications)
                        }
                        
                        menuRow(icon: "faceid", iconBg: Color(red: 0.15, green: 0.60, blue: 0.40), title: "Face ID & Security", subtitle: "Face ID enabled", rightValue: nil, showDivider: true) {}
                        
                        menuRow(icon: "powerplug", iconBg: Color(red: 0.15, green: 0.60, blue: 0.65), title: "Appliance Preferences", subtitle: nil, rightValue: nil, showDivider: true) {
                            navState.navigate(to: .appliances)
                        }
                        
                        menuRow(icon: "ruler", iconBg: Color(red: 0.85, green: 0.65, blue: 0.20), title: "Units & Currency", subtitle: nil, rightValue: "kWh / LKR", showDivider: true) {}
                        
                        menuRow(icon: "info.circle", iconBg: Color(red: 0.45, green: 0.40, blue: 0.80), title: "About EnergyLens", subtitle: nil, rightValue: nil, showDivider: false) {}
                    }
                    .background(Color.white)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1)
                    )
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
    
    @ViewBuilder
    private func menuRow(
        icon: String,
        iconBg: Color,
        title: String,
        subtitle: String?,
        rightValue: String?,
        showDivider: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(iconBg)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                        
                        if let sub = subtitle {
                            Text(sub)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(EnergyLensTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let rv = rightValue {
                        Text(rv)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textSecondary)
                            .padding(.trailing, 4)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(EnergyLensTheme.textMuted)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                
                if showDivider {
                    Divider()
                        .padding(.leading, 64)
                        .background(EnergyLensTheme.fieldBorder)
                }
            }
        }
    }
}
