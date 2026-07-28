//
//  Haptics.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 28/07/26.
//

import UIKit

enum Haptics {

    static func decision(delete: Bool) {
        let generator = UIImpactFeedbackGenerator(style: delete ? .medium : .light)
        generator.impactOccurred()
    }

    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    
    static func undo() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
