//
//  SplashScreenView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct SplashScreenView: View {
    @EnvironmentObject var navState: AppNavigationState
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Image("backgroundImageSplash") 
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Centered Brand Card
                VStack(spacing: 24) {
                    // App Logo Icon Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(EnergyLensTheme.logoSkyBlue)
                            .frame(width: 96, height: 96)
                        
                        Image(systemName: "bolt")
                            .font(.system(size: 46, weight: .regular))
                            .foregroundColor(EnergyLensTheme.textPrimary)
                    }
                    .padding(.top, 16)
                    
                    VStack(spacing: 8) {
                        Text("EnergyLens")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Smart energy management.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 28)
                .background(EnergyLensTheme.cardGradient)
                .cornerRadius(34)
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Bottom Tagline
                Text("Analyze. Predict. Save.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 36)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    navState.navigate(to: .signIn)
                }
            }
        }
    }
}
