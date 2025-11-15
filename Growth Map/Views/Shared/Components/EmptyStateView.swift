//
//  EmptyStateView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Generic empty state used when a screen has no data to display
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Layout.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .padding()
                .background(AppColors.accent.opacity(0.1))
                .clipShape(Circle())

            VStack(spacing: Layout.spacingS) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 320)
            }
        }
        .padding(Layout.spacingL)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Empty state: \(title)")
    }
}

#Preview {
    EmptyStateView(
        icon: "target",
        title: "No Goals Yet",
        message: "Tap the button below to create your first growth goal and let the AI craft your roadmap.",
        actionTitle: "Create Goal",
        action: {}
    )
    .padding()
}
