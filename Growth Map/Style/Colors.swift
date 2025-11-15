//
//  Colors.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI

/// Centralized color palette for the GrowthMap "Liquid Glass" design system
struct AppColors {
    // MARK: - Background Colors
    
    /// Primary background color (adapts to light/dark mode)
    static let background = Color(uiColor: .systemBackground)
    
    /// Secondary background for elevated surfaces
    static let backgroundElevated = Color(uiColor: .secondarySystemBackground)
    
    /// Tertiary background for further elevation
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
    
    // MARK: - Card & Material Colors
    
    /// Card background using ultra thin material for glass effect
    /// Use .ultraThinMaterial or .regularMaterial in SwiftUI instead
    static let cardBackground = Color.white.opacity(0.1)
    
    // MARK: - Accent Colors
    
    /// Primary accent color (cyan/neo-cyan for CTAs and highlights)
    static let accent = Color(red: 0.2, green: 0.6, blue: 1.0) // Blue accent color
    
    /// Alternative accent color for variety (green)
    static let accentSecondary = Color(red: 0.2, green: 0.8, blue: 0.6)
    
    /// Destructive action color
    static let destructive = Color.red
    
    // MARK: - Text Colors
    
    /// Primary text color (adapts to light/dark mode)
    static let textPrimary = Color.primary
    
    /// Secondary text color for less emphasis
    static let textSecondary = Color.secondary
    
    /// Tertiary text color for de-emphasized content
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    /// Text on accent colored backgrounds
    static let textOnAccent = Color.white
    
    // MARK: - Semantic Colors
    
    /// Success state color
    static let success = Color.green
    
    /// Warning state color
    static let warning = Color.orange
    
    /// Error state color
    static let error = Color.red
    
    /// Info state color
    static let info = Color.blue
    
    // MARK: - Overlay Colors
    
    /// Semi-transparent overlay for modals
    static let overlay = Color.black.opacity(0.3)
    
    /// Divider/separator color
    static let separator = Color(uiColor: .separator)
}
