//
//  DeleteButton.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import SwiftUI

struct DeleteButton: View {
    let viewModel: ReviewViewModel

    @State private var isDeleting = false
    @State private var showResult = false
    @State private var resultText = ""

    var body: some View {
        Button {
            Task {
                isDeleting = true
                let freed = viewModel.freedSpaceText
                let outcome = await viewModel.deleteMarkedPhotos()
                isDeleting = false
                switch outcome {
                case .success:
                    Haptics.success()
                    resultText = String(localized: "You freed \(freed)! 🎉")
                    showResult = true
                case .failed:
                    resultText = String(localized: "Something went wrong. Your photos are safe — please try again.")
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
                    Text("Delete \(viewModel.toDeleteCount) Photos")
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
        .alert(resultText, isPresented: $showResult) {
            Button("OK", role: .cancel) { }
        }
    }
}
