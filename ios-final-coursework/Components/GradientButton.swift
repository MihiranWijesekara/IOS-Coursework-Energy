//
//  GradientButton.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct GradientButton: View {
    public let title: String
    public var iconName: String? = nil
    public var rightChevron: Bool = false
    public let action: () -> Void
    
    public init(
        title: String,
        iconName: String? = nil,
        rightChevron: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.rightChevron = rightChevron
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                if rightChevron {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(EnergyLensTheme.buttonGradient)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        }
    }
}
