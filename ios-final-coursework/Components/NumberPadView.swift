//
//  NumberPadView.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct NumberPadView: View {
    @Binding public var passcode: String
    public let maxDigits: Int
    public let onConfirm: () -> Void
    
    public init(passcode: Binding<String>, maxDigits: Int = 6, onConfirm: @escaping () -> Void) {
        self._passcode = passcode
        self.maxDigits = maxDigits
        self.onConfirm = onConfirm
    }
    
    private let keypadRows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["delete", "0", "OK"]
    ]
    
    public var body: some View {
        VStack(spacing: 12) {
            ForEach(keypadRows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        keyButton(for: key)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func keyButton(for key: String) -> some View {
        Button(action: {
            handleKeyPress(key)
        }) {
            Group {
                if key == "delete" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                } else if key == "OK" {
                    Text("OK")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                } else {
                    Text(key)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(EnergyLensTheme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(EnergyLensTheme.borderSubtle, lineWidth: 1.2)
            )
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "delete":
            if !passcode.isEmpty {
                passcode.removeLast()
            }
        case "OK":
            onConfirm()
        default:
            if passcode.count < maxDigits {
                passcode.append(key)
                if passcode.count == maxDigits {
                    // Automatically trigger or wait for OK
                }
            }
        }
    }
}
