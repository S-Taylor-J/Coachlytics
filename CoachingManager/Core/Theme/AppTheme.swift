//
//  AppTheme.swift
//  CoachingManager
//
//  Shared design system: colors, surfaces and backgrounds used across the app.
//  Extracted from the Home dashboard so every screen shares one visual language.
//

import SwiftUI

enum AppTheme {
    // MARK: - Brand Colors
    static let brandAccent = Color(red: 0.42, green: 0.70, blue: 1.0)
    static let brandAccentSoft = Color(red: 0.55, green: 0.80, blue: 1.0)
    static let brandDeepBlue = Color(red: 0.17, green: 0.35, blue: 1.0)

    static let success = Color(red: 0.16, green: 0.92, blue: 0.59)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.22)
    static let danger = Color(red: 1.0, green: 0.36, blue: 0.32)
    static let purpleAccent = Color(red: 0.67, green: 0.48, blue: 1.0)
    static let cyanAccent = Color(red: 0.22, green: 0.82, blue: 1.0)
    static let goldAccent = Color(red: 1.0, green: 0.72, blue: 0.20)

    // MARK: - Text
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.72) : Color(red: 0.25, green: 0.31, blue: 0.41)
    }

    static func mutedText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.46) : Color(red: 0.45, green: 0.50, blue: 0.60)
    }

    // MARK: - Surfaces
    static func surfaceFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.86)
    }

    static func secondarySurfaceFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.72)
    }

    static func insetFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.70)
    }

    static func strokeColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
    }

    static func controlFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.78)
    }

    static func shadowColor(_ scheme: ColorScheme) -> Color {
        Color.black.opacity(scheme == .dark ? 0.24 : 0.10)
    }

    // MARK: - Background gradient
    static func backgroundGradientColors(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark ? [
            Color(red: 0.015, green: 0.026, blue: 0.045),
            Color(red: 0.034, green: 0.052, blue: 0.086),
            Color(red: 0.015, green: 0.018, blue: 0.030)
        ] : [
            Color(red: 0.965, green: 0.980, blue: 1.000),
            Color(red: 0.925, green: 0.950, blue: 0.990),
            Color(red: 0.985, green: 0.990, blue: 1.000)
        ]
    }
}

// MARK: - App Background
/// The Home dashboard's ambient gradient background. Drop this behind any screen's
/// content with `.appBackground()` to keep light/dark styling consistent app-wide.
struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: AppTheme.backgroundGradientColors(colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    AppTheme.brandAccent.opacity(colorScheme == .dark ? 0.14 : 0.16),
                    Color.clear,
                    AppTheme.success.opacity(colorScheme == .dark ? 0.05 : 0.10)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Card Surface
/// The glass card treatment used throughout the Home dashboard: translucent fill,
/// ultra-thin material, subtle stroke and soft shadow.
struct CardSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 20
    var strokeAccent: Color? = nil
    var showShadow: Bool = true

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.surfaceFill(colorScheme))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(strokeAccent?.opacity(0.30) ?? AppTheme.strokeColor(colorScheme), lineWidth: 1)
                )
                .shadow(
                    color: showShadow ? AppTheme.shadowColor(colorScheme) : .clear,
                    radius: 16, x: 0, y: 10
                )
        )
    }
}

extension View {
    /// Applies the app's premium background gradient, matching the Home dashboard.
    func appBackground() -> some View {
        background(AppBackgroundView())
    }

    /// Applies the app's glass card surface (fill + material + stroke + shadow).
    func cardSurface(cornerRadius: CGFloat = 20, strokeAccent: Color? = nil, showShadow: Bool = true) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius, strokeAccent: strokeAccent, showShadow: showShadow))
    }
}
