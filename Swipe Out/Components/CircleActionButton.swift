//
//  CircleActionButton.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 23/07/26.
//


import SwiftUI

struct CircleActionButton: View {
    let icon: String
    let tint: Color
    var size: CGFloat = 64
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(Theme.Colors.surface))
                .overlay(Circle().strokeBorder(tint.opacity(0.45), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
