//
//  NotificationsEmptyView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct NotificationsEmptyView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation Back
            CustomBackButton(title: "Home") {
                navState.navigate(to: .home)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .padding(.horizontal, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Notifications")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                    
                    // Large Nested Sky Blue Card Container
                    VStack(spacing: 24) {
                        // Mint circle with bell icon
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.82, green: 0.96, blue: 0.88))
                                .frame(width: 88, height: 88)
                            
                            Image(systemName: "bell")
                                .font(.system(size: 38, weight: .regular))
                                .foregroundColor(EnergyLensTheme.accentGreen)
                        }
                        .padding(.top, 16)
                        
                        // Inner Dark Teal/Emerald Gradient Card
                        VStack(spacing: 8) {
                            Text("You’re all caught up")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Energy tips, forecast updates and\ncooling alerts will appear here.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.92))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                                .padding(.horizontal, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .padding(.horizontal, 16)
                        .background(EnergyLensTheme.cardGradient)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.78, green: 0.91, blue: 0.99))
                    .cornerRadius(32)
                    
                    // Bottom Caption
                    Text("No notifications right now.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}
