//
//  View+Utilities.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

extension View {
    /// Apply a shadow with consistent styling
    func cardShadow(colorScheme: ColorScheme) -> some View {
        self.shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    /// Apply standard card background styling (matches the app-wide glass card look)
    func cardBackground(cornerRadius: CGFloat = 16) -> some View {
        self.cardSurface(cornerRadius: cornerRadius)
    }
    
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
