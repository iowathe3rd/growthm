//
//  GoalsListView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

struct GoalsListView: View {
    @StateObject private var viewModel: GoalsListViewModel

    init(viewModel: GoalsListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                content
                    .animation(.easeInOut, value: viewModel.goals.count)
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingCreateGoalSheet = true
                    } label: {
                        Label("Add Goal", systemImage: "plus")
                    }
                }
            }
            .task {
                await viewModel.loadGoalsIfNeeded()
            }
            .sheet(isPresented: $viewModel.isShowingCreateGoalSheet) {
                CreateGoalSheet(viewModel: viewModel)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Layout.spacingL) {
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.errorMessage = nil
                        Task { await viewModel.refreshGoals() }
                    }
                    .padding(.top, Layout.spacingM)
                }

                PrimaryButton(title: "+ Add Goal") {
                    viewModel.isShowingCreateGoalSheet = true
                }

                if viewModel.isLoading && viewModel.orderedGoals().isEmpty {
                    ProgressView("Loading goals...")
                        .padding()
                } else if viewModel.orderedGoals().isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No goals yet",
                        message: "Kick off your growth journey by creating a goal. We'll help you craft the roadmap.",
                        actionTitle: "Create Goal"
                    ) {
                        viewModel.isShowingCreateGoalSheet = true
                    }
                    .padding(.top, Layout.spacingXL)
                } else {
                    LazyVStack(spacing: Layout.spacingM, pinnedViews: []) {
                        ForEach(viewModel.orderedGoals()) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                GoalCardView(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshGoals()
        }
    }
}

// MARK: - Sheet Factory

private extension GoalsListView {
    struct CreateGoalSheet: View {
        @Environment(\.dismiss) private var dismiss
        let viewModel: GoalsListViewModel

        var body: some View {
            NavigationStack {
                CreateGoalView(
                    viewModel: CreateGoalViewModel(
                        growthMapAPI: GrowthMapAPI(supabaseService: viewModel.supabaseService),
                        onGoalCreated: { _ in
                            Task {
                                await viewModel.refreshGoals()
                            }
                            dismiss()
                        }
                    )
                )
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var supabaseService: SupabaseService
        @StateObject private var viewModel: GoalsListViewModel

        init() {
            let service = try! SupabaseService()
            _supabaseService = StateObject(wrappedValue: service)
            _viewModel = StateObject(wrappedValue: GoalsListViewModel(supabaseService: service))
        }

        var body: some View {
            GoalsListView(viewModel: viewModel)
                .environmentObject(supabaseService)
        }
    }

    return PreviewWrapper()
}
