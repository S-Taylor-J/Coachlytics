//
//  CustomTabBar.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        
        HStack{
            tabItem(icon: "house.fill", tab: .home)
            tabItem(icon: "plus.circle.fill", tab: .add)
            tabItem(icon: "person.3", tab: .pitch)
            tabItem(icon: "dice.fill", tab: .game)
            tabItem(icon: "gearshape.fill", tab: .settings)
        }
        .padding(.top, 12)
        .padding(.horizontal)
        .padding(.bottom, bottomSafeArea())
        .background(Color(.systemBackground)
            .shadow(color: .black.opacity(0.15), radius: 6, y: -3))
    }
    
    private func tabItem(icon: String, tab: Tab) -> some View {
        Button{
            selectedTab = tab
        }label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? Color.blue : Color.gray)
                .frame(maxWidth: .infinity)
        }
    }
    
    private func bottomSafeArea() -> CGFloat {
        // Find the key window's bottom safe area inset
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return 12
        }
        return max(window.safeAreaInsets.bottom, 12)
    }
}
