//
//  TasksView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

/// Tasks tab showing the user's current sprint tasks
struct TasksView: View {
    @StateObject private var viewModel: TasksViewModel
    @State private var showFinishAlert = false

    private let onSprintFinished: () -> Void

    init(viewModel: TasksViewModel, onSprintFinished: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSprintFinished = onSprintFinished
    }

    var body: some View {
        ZStack {
            List {
                Section {
                    progressHeader
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if viewModel.tasks.isEmpty {
                    Section {
                        emptyState
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section(header: Text("This Week")) {
                        ForEach(viewModel.tasks) { task in
                            taskRow(for: task)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        viewModel.selectedTask = task
                                    } label: {
                                        Label("Details", systemImage: "info.circle")
                                    }
                                    .tint(AppColors.accent)
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .refreshable {
                await viewModel.loadCurrentSprint()
            }

            if viewModel.isLoading && viewModel.tasks.isEmpty {
                LoadingView(message: "Loading sprint tasks...")
            }
        }
        .navigationTitle("Tasks")
        .task {
            await viewModel.loadCurrentSprint()
        }
        .sheet(item: $viewModel.selectedTask) { task in
            TaskDetailSheet(task: task)
        }
        .alert(item: $viewModel.alertInfo) { alertInfo in
            Alert(
                title: Text(alertInfo.title),
                message: Text(alertInfo.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Sprint Finished", isPresented: $showFinishAlert) {
            Button("Great!") {
                showFinishAlert = false
                onSprintFinished()
            }
        } message: {
            Text("Nice work! We'll take you back to your goals to plan what's next.")
        }
        .safeAreaInset(edge: .bottom) {
            finishSprintButton
        }
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Layout.spacingM) {
            HStack {
                Text("Sprint Progress")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(viewModel.progressDescription)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(AppColors.accent)
        }
        .padding(Layout.spacingM)
        .background(AppColors.backgroundElevated)
        .cornerRadius(Layout.cornerRadiusM)
    }

    private var emptyState: some View {
        VStack(spacing: Layout.spacingS) {
            Image(systemName: "checklist")
                .font(.system(size: 44))
                .foregroundColor(AppColors.accent)
            Text("You're all caught up")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            Text("Once your next sprint is ready, it'll appear here.")
                .font(AppTypography.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, Layout.spacingXL)
    }

    private func taskRow(for task: SprintTask) -> some View {
        HStack(spacing: Layout.spacingM) {
            Button {
                Task {
                    await viewModel.toggleCompletion(for: task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(task.isCompleted ? AppColors.accent : AppColors.textSecondary)
                    .accessibilityLabel(task.isCompleted ? "Mark as pending" : "Mark as complete")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Layout.spacingXS) {
                Text(task.title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(task.description)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: Layout.spacingS) {
                    Image(systemName: "flame")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(task.difficulty.rawValue.capitalized)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, Layout.spacingS)
    }

    private var finishSprintButton: some View {
        PrimaryButton(
            title: viewModel.isSprintFinished ? "Sprint Completed" : "Finish Sprint",
            action: {
                Task {
                    let didFinish = await viewModel.finishSprint()
                    if didFinish {
                        showFinishAlert = true
                    }
                }
            },
            isLoading: viewModel.isFinishingSprint,
            isDisabled: !viewModel.hasActiveSprint || viewModel.isSprintFinished
        )
        .padding(.horizontal, Layout.screenPadding)
        .padding(.top, Layout.spacingS)
        .padding(.bottom, Layout.spacingS)
        .background(AppColors.background)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
    }
}

// MARK: - Detail Sheet

private struct TaskDetailSheet: View {
    let task: SprintTask
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Layout.spacingL) {
                VStack(alignment: .leading, spacing: Layout.spacingS) {
                    Text(task.title)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    Text(task.description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: Layout.spacingS) {
                    detailRow(title: "Difficulty", value: task.difficulty.rawValue.capitalized, systemImage: "flame")

                    if let minutes = task.estimatedMinutes {
                        detailRow(title: "Estimated Time", value: "\(minutes) min", systemImage: "clock")
                    }

                    if let dueDate = task.dueDate {
                        detailRow(title: "Due", value: DateFormatter.localizedString(from: dueDate, dateStyle: .medium, timeStyle: .none), systemImage: "calendar")
                    }
                }

                Spacer()
            }
            .padding(Layout.spacingL)
            .navigationTitle("Task Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailRow(title: String, value: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    let service = try! SupabaseService()
    return TasksView(viewModel: TasksViewModel(supabaseService: service)) {}
}
