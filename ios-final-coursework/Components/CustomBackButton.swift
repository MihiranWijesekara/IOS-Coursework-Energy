//
//  CustomBackButton.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//


import SwiftUI

public struct CustomBackButton: View {
    public let title: String
    public let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(EnergyLensTheme.accentGreen)
        }
    }
}
