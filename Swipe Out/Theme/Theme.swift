//
//  Theme.swift
//  Swipe Out
//
//  Created by Omar Regalado Mendoza on 23/07/26.
//

import SwiftUI

enum Theme {
    
    enum Colors {
        static let backgroundTop = Color(red: 0.086, green: 0.086, blue: 0.114)
        static let backgroundBottom = Color(red: 0.043, green: 0.043, blue: 0.059)
        static let surface = Color(red: 0.110, green: 0.110, blue: 0.149)
        static let accent = Color(red: 0.486, green: 0.361, blue: 0.988)
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.604, green: 0.604, blue: 0.651)
        static let delete = Color(red: 1.0,   green: 0.271, blue: 0.227)
        static let keep   = Color(red: 0.196, green: 0.843, blue: 0.294)
        
        static let background = LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 28
        static let xl: CGFloat = 32
    }
    
    enum Radius {
        static let card: CGFloat = 28
        static let button: CGFloat = 16
    }
    
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold,      design: .rounded)
        static let title      = Font.system(size: 24, weight: .semibold,  design: .rounded)
        static let headline   = Font.system(size: 18, weight: .semibold,  design: .rounded)
        static let body        = Font.system(size: 16, weight: .regular,  design: .rounded)
        static let caption    = Font.system(size: 13, weight: .medium,    design: .rounded)
    }


}
