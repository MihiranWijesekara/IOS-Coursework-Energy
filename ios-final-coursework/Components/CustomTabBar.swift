//
//  CustomTabBar.swift
//  ios-final-coursework
//
//  Created by student5 on 2026-10-16.
//

import SwiftUI

public struct CustomTabBar: View {
    @Binding public var selectedTab: MainTab
    public var onSelect: ((MainTab) -> Void)? = nil
    
    public init(selectedTab: Binding<MainTab>, onSelect: ((MainTab) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.onSelect = onSelect
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(EnergyLensTheme.borderSubtle)
            
            HStack(alignment: .center) {
                tabButton(tab: .home, icon: "house", title: "Home")
                Spacer()
                tabButton(tab: .analysis, icon: "chart.bar", title: "Analysis")
                Spacer()
                tabButton(tab: .savings, icon: "slider.horizontal.3", title: "Savings")
                Spacer()
                tabButton(tab: .profile, icon: "person", title: "Profile")
            }
            .padding(.horizontal, 32)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(Color.white)
        }
    }
    
    @ViewBuilder
    private func tabButton(tab: MainTab, icon: String, title: String) -> some View {
        let isSelected = selectedTab == tab
        Button(action: {
            selectedTab = tab
            onSelect?(tab)
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? (icon == "slider.horizontal.3" ? icon : "\(icon).fill") : icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? EnergyLensTheme.accentGreen : EnergyLensTheme.textSecondary)
            .frame(minWidth: 54)
        }
    }
}
