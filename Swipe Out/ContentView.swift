//
//  ContentView.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 20/07/26.
//

import SwiftUI
import UIKit

struct ContentView: View {

    
    @State private var viewModel = ReviewViewModel(library: PhotoKitLibraryService())
    @State private var isDeleting = false
    @State private var showResult = false
    @State private var resultText = ""
    @State private var cardCommand: Bool? = nil

    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.authState {
            case .unknown:
                    loadingView
            case .authorized:
                    if viewModel.isFinished {
                        finishedView
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        reviewView
                            .transition(.opacity)
                    }
            case .denied:
                StatusView(
                    icon: "lock.fill",
                    iconColor: Theme.Colors.delete,
                    title: "No access to photos",
                    message: "Swipe Out needs access to your library to help you clean it up. Enable it in Settings to continue.",
                    actionTitle: "Open Settings",
                    action: openSettings
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            await viewModel.requestAccess()
        }
        .alert(resultText, isPresented: $showResult) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Sub-vistas por estado

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.Colors.accent)
            Text("Getting your photos ready…")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var finishedView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            StatusView(
               icon: "checkmark.circle.fill",
               iconColor: Theme.Colors.keep,
               title: "All done! 🎉",
               message: "You've gone through every photo in your gallery. Nice work!"
           )

            if viewModel.toDeleteCount > 0 {
                deleteButton
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

    private var reviewView: some View {
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
                    HStack {
                        Text("\(viewModel.currentIndex) of \(viewModel.total)")
                        Spacer()
                        if viewModel.toDeleteCount > 0 {
                            Text("≈ \(viewModel.freedSpaceText) to free")
                                .foregroundStyle(Theme.Colors.delete)
                        }
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
                            withAnimation(.smooth(duration: 0.3)) {
                                viewModel.handleDecision(delete: delete)
                            }
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
                CircleActionButton(icon: "checkmark", tint: Theme.Colors.keep, size: 72) {
                    cardCommand = false
                }
                CircleActionButton(icon: "arrow.uturn.backward", tint: Theme.Colors.textSecondary, size: 52) {
                    withAnimation(.smooth(duration: 0.3)) {
                        viewModel.undo()
                    }
                }
                .disabled(!viewModel.canUndo)
                .opacity(viewModel.canUndo ? 1 : 0.35)
                CircleActionButton(icon: "trash.fill", tint: Theme.Colors.delete, size: 72) {
                    cardCommand = true
                }
            }

            ZStack {
                if viewModel.toDeleteCount > 0 {
                    deleteButton
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .frame(height: 56)
        }
    }

    // MARK: - Reusable views
    private var deleteButton: some View {
        Button {
            Task {
                isDeleting = true
                let freed = viewModel.freedSpaceText
                let outcome = await viewModel.deleteMarkedPhotos()
                isDeleting = false
                switch outcome {
                case .success:
                    resultText = "You freed \(freed)! 🎉"
                    showResult = true
                case .failed:
                    resultText = "Something went wrong. Your photos are safe, please try again."
                    showResult = true
                case .cancelled:
                    break
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if isDeleting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "trash.fill")
                    Text("Delete \(viewModel.toDeleteCount) Photo\(viewModel.toDeleteCount == 1 ? "" : "s")")
                }
            }
            .font(Theme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.delete, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
    }

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
    }
    
    private var limitedAccessBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
            Text("You're only reviewing your selected photos.")
            Spacer(minLength: Theme.Spacing.sm)
            Button("Add more") {
                Task {
                    await viewModel.expandLimitedSelection()
                }
            }
            .foregroundStyle(Theme.Colors.accent)
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.Colors.textSecondary)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}
