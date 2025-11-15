//
//  Typography.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI

/// Centralized typography styles for the GrowthMap design system
/// Supports Dynamic Type for accessibility
struct AppTypography {
    // MARK: - Display Styles
    
    /// Large display text (onboarding, hero sections)
    static let largeTitle = Font.largeTitle.weight(.bold)
    
    /// Screen titles and major headings
    static let title = Font.title.weight(.bold)
    
    /// Section titles
    static let title2 = Font.title2.weight(.semibold)
    
    /// Subsection titles
    static let title3 = Font.title3.weight(.semibold)
    
    // MARK: - Body Styles
    
    /// Standard heading text
    static let headline = Font.headline
    
    /// Emphasized body text
    static let subheadline = Font.subheadline.weight(.medium)
    
    /// Default body text
    static let body = Font.body
    
    /// De-emphasized body text
    static let callout = Font.callout
    
    // MARK: - Supporting Styles
    
    /// Small supporting text
    static let footnote = Font.footnote
    
    /// Very small text (legal, timestamps)
    static let caption = Font.caption
    
    /// Smallest text size
    static let caption2 = Font.caption2
    
    // MARK: - Specialized Styles
    
    /// Button labels (medium weight for prominence)
    static let button = Font.body.weight(.semibold)
    
    /// Navigation bar titles
    static let navigationTitle = Font.headline
    
    /// Input field text
    static let textField = Font.body
    
    /// Error/helper text
    static let helperText = Font.caption.weight(.medium)
}

// MARK: - Text Modifiers

extension Text {
    /// Apply primary text color and default body style
    func primaryText() -> some View {
        self
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply secondary text color and callout style
    func secondaryText() -> some View {
        self
            .font(AppTypography.callout)
            .foregroundColor(AppColors.textSecondary)
    }
    
    /// Apply headline style with primary color
    func headlineText() -> some View {
        self
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply title style with primary color
    func titleText() -> some View {
        self
            .font(AppTypography.title)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply error text styling
    func errorText() -> some View {
        self
            .font(AppTypography.helperText)
            .foregroundColor(AppColors.error)
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply error text styling to any view containing text elements
    func errorText() -> some View {
        self
            .font(AppTypography.helperText)
            .foregroundColor(AppColors.error)
    }
}
