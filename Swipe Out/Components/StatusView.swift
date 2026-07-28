//
//  StatusView.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 23/07/26.
//

import SwiftUI

struct StatusView: View {
    let icon: String
    var iconColor: Color = Theme.Colors.accent
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.accent,
                                    in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .buttonStyle(.plain)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}
