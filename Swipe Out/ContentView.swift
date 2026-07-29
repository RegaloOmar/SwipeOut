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
