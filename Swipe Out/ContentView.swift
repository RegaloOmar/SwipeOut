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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.authState {
            case .unknown:
                loadingView
            case .authorized:
                if viewModel.isFinished {
                    FinishedView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    ReviewView(viewModel: viewModel)
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.refreshOnForeground() }
            }
        }
        // Cortina de privacidad: oculta las fotos en el app switcher.
        .overlay {
            if scenePhase != .active {
                privacyCurtain
            }
        }
    }

    private var privacyCurtain: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
                Text("Swipe Out")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
        }
    }

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

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}
