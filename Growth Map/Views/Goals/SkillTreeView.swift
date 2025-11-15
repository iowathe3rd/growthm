//
//  SkillTreeView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

struct SkillTreeView: View {
    @StateObject private var viewModel: SkillTreeViewModel

    init(goalId: UUID, initialGoal: Goal? = nil, growthMapAPI: GrowthMapAPIProtocol) {
        _viewModel = StateObject(
            wrappedValue: SkillTreeViewModel(goalId: goalId, initialGoal: initialGoal, growthMapAPI: growthMapAPI)
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            content
                .blur(radius: viewModel.isLoading && viewModel.skillTree != nil ? 2 : 0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)

            if viewModel.isLoading && viewModel.skillTree == nil {
                LoadingView(message: "Loading skill tree…")
            }

            if let errorMessage = viewModel.errorMessage {
                VStack {
                    ErrorView(message: errorMessage) {
                        viewModel.dismissError()
                    }
                    .padding()

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(viewModel.goal?.title ?? "Skill Tree")
        .toolbar {
            if viewModel.isLoading && viewModel.skillTree != nil {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData(force: true)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.hasSkillNodes {
            List {
                goalSection

                ForEach(viewModel.levelGroups) { group in
                    Section(header: Text("Level \(group.level)").font(AppTypography.title3)) {
                        ForEach(group.nodes) { node in
                            SkillNodeRow(node: node)
                                .listRowInsets(
                                    EdgeInsets(top: Layout.spacingS, leading: 0, bottom: Layout.spacingS, trailing: 0)
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        } else {
            VStack(spacing: Layout.spacingL) {
                goalSummaryCard

                Text("Once AI generates a skill tree for this goal, nodes will appear here.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.spacingXL)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var goalSection: some View {
        if viewModel.goal != nil {
            Section(header: Text("Goal Overview").font(AppTypography.title3)) {
                goalSummaryCard
                    .listRowInsets(
                        EdgeInsets(top: Layout.spacingS, leading: 0, bottom: Layout.spacingS, trailing: 0)
                    )
            }
            .listRowBackground(Color.clear)
            .textCase(nil)
        }
    }

    @ViewBuilder
    private var goalSummaryCard: some View {
        if let goal = viewModel.goal {
            CardView {
                VStack(alignment: .leading, spacing: Layout.spacingS) {
                    Text(goal.title)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)

                    Text(goal.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: Layout.spacingM) {
                        Label("\(goal.horizonMonths) mo horizon", systemImage: "calendar")
                        Label("\(goal.dailyMinutes) min/day", systemImage: "timer")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Goal summary. \(goal.title). Horizon \(goal.horizonMonths) months. Daily commitment \(goal.dailyMinutes) minutes."
            )
        }
    }
}

#Preview {
    struct PreviewGrowthMapAPI: GrowthMapAPIProtocol {
        func getGoalDetail(goalId: String) async throws -> GoalDetailResponse {
            GoalDetailResponse(
                goal: Goal(
                    id: UUID(),
                    userId: UUID(),
                    title: "Master SwiftUI",
                    description: "Learn SwiftUI to build modern iOS apps",
                    horizonMonths: 6,
                    dailyMinutes: 45,
                    status: .active,
                    priority: 1,
                    targetDate: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                skillTree: SkillTreeWithNodes(
                    skillTree: SkillTree(
                        id: UUID(),
                        goalId: UUID(),
                        treeJson: [:],
                        generatedBy: "ai",
                        version: 1,
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    nodes: [
                        SkillTreeNode(
                            id: UUID(),
                            skillTreeId: UUID(),
                            nodePath: "root.swift.basics",
                            title: "Swift Foundations",
                            level: 1,
                            focusHours: 20,
                            payload: ["progress": AnyCodable(0.4)],
                            createdAt: Date(),
                            updatedAt: Date()
                        ),
                        SkillTreeNode(
                            id: UUID(),
                            skillTreeId: UUID(),
                            nodePath: "root.swiftui.layouts",
                            title: "SwiftUI Layouts",
                            level: 2,
                            focusHours: 30,
                            payload: ["progress": AnyCodable(0.2)],
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    ]
                ),
                latestSprint: nil
            )
        }
    }

    return NavigationStack {
        SkillTreeView(goalId: UUID(), growthMapAPI: PreviewGrowthMapAPI())
    }
}
