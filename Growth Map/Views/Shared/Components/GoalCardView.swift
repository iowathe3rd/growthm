//
//  GoalCardView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI
import Foundation

/// Displays the high-level summary of a goal along with a lightweight progress indicator
struct GoalCardView: View {
    let goal: Goal

    var body: some View {
        CardView(padding: Layout.spacingL) {
            VStack(alignment: .leading, spacing: Layout.spacingM) {
                header

                Text(goal.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(3)

                progressSection

                Divider()
                    .background(AppColors.separator)

                metaRow
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Layout.spacingXS) {
                Text(goal.title)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                Text(goal.statusText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(goal.status.displayTitle)
            .font(AppTypography.caption.weight(.semibold))
            .padding(.horizontal, Layout.spacingS)
            .padding(.vertical, Layout.spacingXS)
            .background(goal.status.badgeColor.opacity(0.15))
            .foregroundColor(goal.status.badgeColor)
            .cornerRadius(Layout.cornerRadiusS)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Layout.spacingXS) {
            HStack {
                Text("Progress")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(goal.progressLabel)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            ProgressView(value: goal.estimatedProgress)
                .tint(goal.status.badgeColor)
        }
    }

    private var metaRow: some View {
        HStack(spacing: Layout.spacingL) {
            Label("\(goal.dailyMinutes) min/day", systemImage: "clock")
            Label("\(goal.horizonMonths) mo horizon", systemImage: "calendar")
        }
        .font(AppTypography.footnote)
        .foregroundColor(AppColors.textSecondary)
        .labelStyle(.iconOnlyWithText)
    }
}

private extension LabelStyle where Self == IconOnlyWithTextLabelStyle {
    static var iconOnlyWithText: IconOnlyWithTextLabelStyle { IconOnlyWithTextLabelStyle() }
}

private struct IconOnlyWithTextLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Layout.spacingXS) {
            configuration.icon
            configuration.title
        }
    }
}

private extension Goal {
    var statusText: String {
        let formattedDate = DateFormatters.shortDate.string(from: createdAt)
        return "Created \(formattedDate)"
    }

    var estimatedProgress: Double {
        status.progressEstimate
    }

    var progressLabel: String {
        let percentage = Int(estimatedProgress * 100)
        return "\(percentage)%" + (status == .completed ? " Complete" : " towards mastery")
    }
}

private extension GoalStatus {
    var badgeColor: Color {
        switch self {
        case .active:
            return AppColors.accent
        case .draft:
            return AppColors.info
        case .paused:
            return AppColors.warning
        case .completed:
            return AppColors.success
        }
    }

    var displayTitle: String {
        switch self {
        case .active:
            return "Active"
        case .draft:
            return "Draft"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        }
    }

    var progressEstimate: Double {
        switch self {
        case .completed:
            return 1.0
        case .active:
            return 0.65
        case .paused:
            return 0.35
        case .draft:
            return 0.15
        }
    }
}

private extension DateFormatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    GoalCardView(
        goal: Goal(
            id: UUID(),
            userId: UUID(),
            title: "Launch portfolio website",
            description: "Design, build, and ship a personal portfolio that highlights recent work and improves inbound leads.",
            horizonMonths: 3,
            dailyMinutes: 45,
            status: .active,
            priority: 1,
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 90),
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date()
        )
    )
    .padding()
    .background(
        LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    )
}
