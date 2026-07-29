//
//  ReviewViewUI.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import SwiftUI

struct ReviewView: View {
    let viewModel: ReviewViewModel
    @State private var cardCommand: Bool? = nil

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: Theme.Spacing.sm) {
                if viewModel.isLimitedAccess {
                    limitedAccessBanner
                }
                progressBar(
                    fraction: viewModel.total == 0 ? 0
                        : CGFloat(viewModel.currentIndex) / CGFloat(viewModel.total)
                )
                HStack {
                    Text("\(viewModel.currentIndex) of \(viewModel.total)")
                    Spacer()
                    if viewModel.toDeleteCount > 0 {
                        Text("≈ \(viewModel.freedSpaceText) to free")
                            .foregroundStyle(Theme.Colors.delete)
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            }

            if let image = viewModel.currentImage {
                GeometryReader { geo in
                    let cardW = geo.size.width - Theme.Spacing.lg * 2
                    let cardH = min(cardW * 4.0 / 3.0, geo.size.height)

                    ZStack {
                        if viewModel.total - viewModel.currentIndex > 2 {
                            deckCard(scale: 0.90, yOffset: 52)
                        }
                        if viewModel.total - viewModel.currentIndex > 1 {
                            deckCard(scale: 0.95, yOffset: 26)
                        }
                        SwipeCardView(image: image, command: $cardCommand) { delete in
                            Task { await viewModel.handleDecision(delete: delete) }
                        }
                        .id(viewModel.currentIndex)
                    }
                    .frame(width: cardW, height: cardH)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                ProgressView("Loading Photos…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack(spacing: Theme.Spacing.xl) {
                CircleActionButton(icon: "checkmark", tint: Theme.Colors.keep, size: 72, accessibilityLabel: "Keep photo") {
                    cardCommand = false
                }
                CircleActionButton(icon: "arrow.uturn.backward", tint: Theme.Colors.textSecondary, size: 52, accessibilityLabel: "Undo last decision") {
                    Haptics.undo()
                    withAnimation(.smooth(duration: 0.3)) {
                        viewModel.undo()
                    }
                }
                .disabled(!viewModel.canUndo)
                .opacity(viewModel.canUndo ? 1 : 0.35)
                CircleActionButton(icon: "trash.fill", tint: Theme.Colors.delete, size: 72, accessibilityLabel: "Mark photo for deletion") {
                    cardCommand = true
                }
            }

            ZStack {
                if viewModel.toDeleteCount > 0 {
                    DeleteButton(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .frame(height: 56)
        }
    }

    // MARK: - Helpers

    private func progressBar(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surface)
                Capsule()
                    .fill(Theme.Colors.accent)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * fraction)))
            }
        }
        .frame(height: 8)
        .animation(.easeInOut, value: fraction)
        .accessibilityHidden(true)
    }

    private func deckCard(scale: CGFloat, yOffset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .fill(Theme.Colors.surface)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 1)
            }
            .scaleEffect(scale)
            .offset(y: yOffset)
            .accessibilityHidden(true)
    }

    private var limitedAccessBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
            Text("You're only reviewing your selected photos.")
            Spacer(minLength: Theme.Spacing.sm)
            Button("Add more") {
                Task { await viewModel.expandLimitedSelection() }
            }
            .foregroundStyle(Theme.Colors.accent)
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.Colors.textSecondary)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}
