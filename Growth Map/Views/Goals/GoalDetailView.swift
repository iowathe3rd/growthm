//
//  GoalDetailView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Placeholder view that will host the full goal detail experience
struct GoalDetailView: View {
    let goal: Goal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacingL) {
                Text(goal.title)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)

                Text(goal.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                GoalCardView(goal: goal)

                Text("Sprint timeline and AI insights coming soon.")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.backgroundElevated)
                    .cornerRadius(Layout.cornerRadiusM)
            }
            .padding()
        }
        .navigationTitle("Goal Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    GoalDetailView(
        goal: Goal(
            id: UUID(),
            userId: UUID(),
            title: "Learn SwiftUI",
            description: "Complete the SwiftUI tutorials and build a personal app.",
            horizonMonths: 4,
            dailyMinutes: 30,
            status: .active,
            priority: 1,
            targetDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
