import SwiftUI

enum Theme {
    static let primaryGreen = Color(red: 0.18, green: 0.62, blue: 0.34)
    static let darkGreen = Color(red: 0.08, green: 0.28, blue: 0.16)
    static let surface = Color.white // Always white
    static let cardBackground = Color.white
    static let cardBorder = Color(red: 0.86, green: 0.92, blue: 0.86)
    static let premiumSurface = Color.white // Always white instead of gradient
    static let premiumShadow = Color.black.opacity(0.08)
    static let textPrimary = Color.black // Dark text
    static let textSecondary = Color.gray
    
    // Tab bar colors
    static let tabBarBackground = Color.white
    static let tabBarCardBackground = Color(red: 0.976, green: 0.976, blue: 0.976) // #f9f9f9
    static let tabBarBorder = Color(red: 0.933, green: 0.933, blue: 0.933) // #eeeeee
    static let tabBarTextInactive = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    static let tabBarCardShadow = Color.black.opacity(0.06)
    static let tabBarCardActiveShadow = Color(red: 0.176, green: 0.618, blue: 0.247, opacity: 0.3) // #2d9e3f with 30% opacity
    
    // Neumorphic color system - independent of system theme
    static let neuWhite = Color(red: 1.0, green: 1.0, blue: 1.0) // #ffffff
    static let neuCardBackground = Color(red: 0.976, green: 0.976, blue: 0.976) // #f9f9f9
    static let neuCardBorder = Color(red: 0.941, green: 0.941, blue: 0.941) // #f0f0f0
    static let neuPrimaryGreen = Color(red: 0.176, green: 0.620, blue: 0.247) // #2d9e3f
    static let neuTextPrimary = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
    static let neuTextSecondary = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    static let neuTextTertiary = Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
    static let neuTextDisabled = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
    static let neuBorderLight = Color(red: 0.933, green: 0.933, blue: 0.933) // #eeeeee
}
