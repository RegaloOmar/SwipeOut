//
//  SwipeCardView.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 22/07/26.
//

import SwiftUI

struct SwipeCardView: View {

    let image: UIImage
    @Binding var command: Bool?
    let onDecision: (_ delete: Bool) -> Void

    @State private var offset: CGSize = .zero
    @State private var committedDelete: Bool? = nil
    private let threshold: CGFloat = 130
    private let deadzone: CGFloat = 10

    private var isDeleting: Bool { committedDelete ?? (offset.width > 0) }
    private var showsFeedback: Bool { abs(offset.width) > deadzone }
    private var decisionColor: Color { isDeleting ? Theme.Colors.delete : Theme.Colors.keep }
    private var decisionIcon: String { isDeleting ? "trash.fill" : "checkmark.circle.fill" }
    private var decisionText: String { isDeleting ? "DELETE" : "KEEP" }
    private var dragFraction: CGFloat { min(abs(offset.width) / threshold, 1) }
    private var feedbackFraction: CGFloat { min(abs(offset.width) / (threshold * 0.6), 1) }

    var body: some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                decisionColor.opacity(showsFeedback ? feedbackFraction * 0.45 : 0)
            }
            .overlay {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: decisionIcon)
                        .font(.system(size: 60, weight: .bold))
                    Text(decisionText)
                        .font(Theme.Typography.title)
                }
                .foregroundStyle(.white)
                .padding(Theme.Spacing.lg)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                .opacity(showsFeedback ? feedbackFraction : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 12)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 18)))
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        committedDelete = value.translation.width > 0
                    }
                    .onEnded { value in
                        if value.translation.width > threshold {
                            flyAway(delete: true)
                        } else if value.translation.width < -threshold {
                            flyAway(delete: false)
                        } else {
                            withAnimation(.spring(duration: 0.3, bounce: 0)) {
                                offset = .zero
                            } completion: {
                                committedDelete = nil
                            }
                        }
                    }
            )
            .onChange(of: command) { _, newValue in
                if let delete = newValue {
                    flyAway(delete: delete)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo. Use the Keep or Delete buttons below.")
    }

    private func flyAway(delete: Bool) {
        Haptics.decision(delete: delete)
        let endX: CGFloat = delete ? 600 : -600
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(width: endX, height: offset.height)
        } completion: {
            command = nil
            onDecision(delete)
        }
    }
}
