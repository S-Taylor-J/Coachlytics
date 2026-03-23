//
//  PitchBackgroundImageView.swift
//  CoachingManager
//

import SwiftUI
import UIKit

struct PitchBackgroundImageView: View {
    var isDropTargeted: Bool = false
    var imageContentMode: ContentMode = .fit

    var body: some View {
        ZStack {
            if let image = UIImage(named: "PitchBackground") ?? UIImage(named: "pitch") {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: imageContentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                fallbackPitchBackground
            }

            if isDropTargeted {
                Color.blue.opacity(0.1)
                    .transition(.opacity)
            }
        }
        .clipped()
    }

    private var fallbackPitchBackground: some View {
        ZStack {
            Color(red: 0.18, green: 0.52, blue: 0.22)

            RadialGradient(
                colors: [.clear, Color.black.opacity(0.1)],
                center: .center,
                startRadius: 120,
                endRadius: 520
            )
        }
    }
}
