//
//  FinishedViewUI.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import SwiftUI

struct FinishedView: View {
    let viewModel: ReviewViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            StatusView(
                icon: "checkmark.circle.fill",
                iconColor: Theme.Colors.keep,
                title: "All done! 🎉",
                message: "You've gone through every photo in your gallery. Nice work!"
            )

            if viewModel.toDeleteCount > 0 {
                DeleteButton(viewModel: viewModel)
            }

            if viewModel.toDeleteCount == 0 {
                Button {
                    withAnimation(.smooth(duration: 0.35)) {
                        viewModel.restart()
                    }
                } label: {
                    Label("Start over", systemImage: "arrow.clockwise")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.accent,
                                    in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .buttonStyle(.plain)
            }

            if viewModel.canUndo {
                Button {
                    Haptics.undo()
                    withAnimation(.smooth(duration: 0.35)) {
                        viewModel.undo()
                    }
                } label: {
                    Label("Go back to last photo", systemImage: "arrow.uturn.backward")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.surface,
                                    in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
