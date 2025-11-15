//
//  SkillNodeRow.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Displays a single skill node using the "Liquid Glass" design system
struct SkillNodeRow: View {
    let node: SkillTreeNode

    private var indentation: CGFloat {
        CGFloat(max(node.level - 1, 0)) * Layout.spacingM
    }

    private var focusHoursText: String {
        String(format: "%.1f h focus", node.focusHours)
    }

    private var createdDateText: String {
        node.createdAt.formatted(.dateTime.month().day().year())
    }

    private var progressValue: Double? {
        if let progress = normalizedProgress(from: node.payload["progress"]?.value) {
            return progress
        }
        if let completion = normalizedProgress(from: node.payload["completion"]?.value) {
            return completion
        }
        return nil
    }

    private func normalizedProgress(from value: Any?) -> Double? {
        guard let value else { return nil }
        if let doubleValue = value as? Double {
            return clamp(doubleValue > 1 ? doubleValue / 100 : doubleValue)
        }
        if let intValue = value as? Int {
            return clamp(Double(intValue) / 100)
        }
        return nil
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Layout.spacingS) {
                HStack(alignment: .firstTextBaseline) {
                    Text(node.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Spacer(minLength: Layout.spacingS)

                    Text("Level \(node.level)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, Layout.spacingS)
                        .padding(.vertical, Layout.spacingXS)
                        .background(AppColors.backgroundElevated.opacity(0.5))
                        .cornerRadius(Layout.cornerRadiusS)
                }

                HStack(spacing: Layout.spacingM) {
                    Label(focusHoursText, systemImage: "clock")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Label(createdDateText, systemImage: "calendar")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                if let progress = progressValue {
                    VStack(alignment: .leading, spacing: Layout.spacingXS) {
                        Text("Progress")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(AppColors.accent)

                        Text("\(Int(progress * 100))% complete")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Progress \(Int(progress * 100)) percent complete")
                }
            }
        }
        .padding(.leading, indentation)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(node.title), level \(node.level), requires \(focusHoursText). Created on \(createdDateText)."
        )
    }
}

#Preview {
    let node = SkillTreeNode(
        id: UUID(),
        skillTreeId: UUID(),
        nodePath: "root.swift.basics",
        title: "Swift Basics",
        level: 1,
        focusHours: 24,
        payload: ["progress": AnyCodable(0.5)],
        createdAt: Date(),
        updatedAt: Date()
    )

    return ZStack {
        LinearGradient(
            colors: [.purple.opacity(0.4), .blue.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        SkillNodeRow(node: node)
            .padding()
    }
}
