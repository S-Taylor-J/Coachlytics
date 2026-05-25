//
//  CustomTabBar.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            tabItem(icon: "house.fill", title: "Home", tab: .home)
            tabItem(icon: "person.crop.circle.badge.plus", title: "Team", tab: .add)
            tabItem(icon: "sportscourt.fill", title: "Pitch", tab: .pitch)
            tabItem(icon: "list.bullet.rectangle.fill", title: "Games", tab: .game)
            tabItem(icon: "gearshape.fill", title: "Settings", tab: .settings)
        }
        .padding(.top, 10)
        .padding(.horizontal, 12)
        .padding(.bottom, bottomSafeArea())
        .background(
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .background(backgroundColor.opacity(colorScheme == .dark ? 0.94 : 0.96))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.12), radius: 18, x: 0, y: -10)
        )
    }

    private func tabItem(icon: String, title: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        brandAccent.opacity(0.28),
                                        brandAccent.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(brandAccent.opacity(0.30), lineWidth: 1)
                            )
                            .frame(width: 46, height: 32)
                            .shadow(color: brandAccent.opacity(0.30), radius: 12, x: 0, y: 4)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isSelected ? brandAccent : Color.white.opacity(0.45))
                        .frame(width: 46, height: 32)
                }

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? brandAccent : Color.white.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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

    private var backgroundColor: Color {
        Color(red: 0.025, green: 0.034, blue: 0.055)
    }

    private var brandAccent: Color {
        Color(red: 0.31, green: 0.58, blue: 1.0)
    }
}
