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

    private struct TabEntry: Identifiable {
        let tab: Tab
        let icon: String
        let title: String
        var id: Tab { tab }
    }

    /// On-screen order, which intentionally differs from the declaration order of `Tab`.
    private static let entries: [TabEntry] = [
        .init(tab: .home,     icon: "house.fill",                    title: "Home"),
        .init(tab: .add,      icon: "person.crop.circle.badge.plus", title: "Team"),
        .init(tab: .pitch,    icon: "sportscourt.fill",              title: "Pitch"),
        .init(tab: .game,     icon: "list.bullet.rectangle.fill",    title: "Games"),
        .init(tab: .settings, icon: "gearshape.fill",                title: "Settings")
    ]

    private static let itemSpacing: CGFloat = 6
    private static let indicatorWidth: CGFloat = 46
    private static let indicatorHeight: CGFloat = 32
    /// Matches the tab item's `.padding(.vertical, 4)` above the 32pt icon slot.
    private static let itemTopPadding: CGFloat = 4
    private static let itemBottomPadding: CGFloat = 12

    private var selectedIndex: Int {
        Self.entries.firstIndex { $0.tab == selectedTab } ?? 0
    }

    var body: some View {
        HStack(spacing: Self.itemSpacing) {
            ForEach(Self.entries) { entry in
                tabItem(icon: entry.icon, title: entry.title, tab: entry.tab)
            }
        }
        // A single indicator that always exists and only changes position, so the
        // selection slides instead of cross-fading.
        .background(alignment: .topLeading) { indicator }
        // Scoped to the bar so the page switch in RootView stays instant.
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selectedTab)
        .padding(.top, 10)
        .padding(.horizontal, 12)
        .padding(.bottom, Self.itemBottomPadding)
        .background(
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .background(backgroundColor.opacity(colorScheme == .dark ? 0.94 : 0.96))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [topBorderColor, Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.12), radius: 18, x: 0, y: -10)
            // Only the backdrop bleeds under the home indicator. The bar's contents stay
            // inside the safe area because RootView no longer ignores it.
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var indicator: some View {
        GeometryReader { geo in
            let count = CGFloat(Self.entries.count)
            let itemWidth = (geo.size.width - Self.itemSpacing * (count - 1)) / count
            let centerX = CGFloat(selectedIndex) * (itemWidth + Self.itemSpacing) + itemWidth / 2

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
                .frame(width: Self.indicatorWidth, height: Self.indicatorHeight)
                .shadow(color: brandAccent.opacity(0.30), radius: 12, x: 0, y: 4)
                .position(x: centerX, y: Self.itemTopPadding + Self.indicatorHeight / 2)
        }
    }

    private func tabItem(icon: String, title: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? brandAccent : inactiveColor)
                    .frame(width: Self.indicatorWidth, height: Self.indicatorHeight)

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? brandAccent : inactiveColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.vertical, Self.itemTopPadding)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.025, green: 0.034, blue: 0.055) : Color.white
    }

    private var brandAccent: Color {
        AppTheme.brandAccent
    }

    private var inactiveColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.48) : Color(red: 0.42, green: 0.47, blue: 0.56)
    }

    private var topBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.08)
    }
}
