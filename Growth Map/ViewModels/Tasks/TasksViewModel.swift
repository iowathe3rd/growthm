//
//  TasksViewModel.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import Foundation

/// View model that manages the list of sprint tasks for the Tasks tab
@MainActor
final class TasksViewModel: ObservableObject {
    // MARK: - Nested Types

    /// Simple alert data structure for surfacing errors to the UI
    struct AlertInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    // MARK: - Published State

    @Published private(set) var tasks: [SprintTask] = []
    @Published private(set) var currentSprint: Sprint?
    @Published var selectedTask: SprintTask?
    @Published var alertInfo: AlertInfo?
    @Published private(set) var isLoading = false
    @Published private(set) var isFinishingSprint = false

    // MARK: - Dependencies

    private let supabaseService: SupabaseService

    // MARK: - Initialization

    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

    // MARK: - Computed Properties

    /// Percentage progress for the current sprint
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTaskCount) / Double(tasks.count)
    }

    /// Human readable description of the sprint progress
    var progressDescription: String {
        guard !tasks.isEmpty else { return "No sprint tasks yet" }
        return "\(completedTaskCount) of \(tasks.count) completed"
    }

    /// Count of completed tasks used for quick calculations
    private var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    /// Determines if the current sprint is already marked as finished
    var isSprintFinished: Bool {
        currentSprint?.isCompleted ?? false
    }

    /// Determines whether there is a sprint to act on
    var hasActiveSprint: Bool {
        currentSprint != nil
    }

    // MARK: - Data Loading

    /// Loads the current week's sprint and its tasks from Supabase
    func loadCurrentSprint() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let sprintWithTasks = try await supabaseService.fetchCurrentSprintWithTasks() {
                currentSprint = sprintWithTasks.sprint
                tasks = sprintWithTasks.tasks
            } else {
                currentSprint = nil
                tasks = []
            }
        } catch {
            alertInfo = AlertInfo(
                title: "Unable to load tasks",
                message: message(for: error)
            )
        }
    }

    // MARK: - Task Updates

    /// Toggle completion for an individual task
    /// - Parameter task: The task to update
    func toggleCompletion(for task: SprintTask) async {
        guard !isSprintFinished else { return }

        let newStatus: TaskStatus = task.isCompleted ? .pending : .done

        // Optimistically update the local state for snappier UI feedback
        replaceTask(task.updatingStatus(to: newStatus))

        do {
            let updatedTask = try await supabaseService.updateTaskStatus(taskId: task.id, status: newStatus)
            replaceTask(updatedTask)
        } catch {
            // Reload to keep local state in sync when API fails
            await loadCurrentSprint()
            alertInfo = AlertInfo(
                title: "Update failed",
                message: message(for: error)
            )
        }
    }

    /// Finishes the sprint once the user confirms the action
    /// - Returns: Bool indicating if the sprint was successfully finished
    func finishSprint() async -> Bool {
        guard let sprint = currentSprint, !sprint.isCompleted else { return false }

        isFinishingSprint = true
        defer { isFinishingSprint = false }

        do {
            let updatedSprint = try await supabaseService.finishSprint(sprintId: sprint.id)
            currentSprint = updatedSprint
            return updatedSprint.isCompleted
        } catch {
            alertInfo = AlertInfo(
                title: "Unable to finish sprint",
                message: message(for: error)
            )
            return false
        }
    }

    // MARK: - Helpers

    private func replaceTask(_ updatedTask: SprintTask) {
        guard let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) else { return }
        tasks[index] = updatedTask
    }

    private func message(for error: Error) -> String {
        if let supabaseError = error as? SupabaseError {
            return supabaseError.errorDescription ?? "An unknown error occurred."
        }

        return error.localizedDescription
    }
}

private extension SprintTask {
    /// Returns a copy of the task with an updated status used for optimistic UI
    func updatingStatus(to status: TaskStatus) -> SprintTask {
        SprintTask(
            id: id,
            sprintId: sprintId,
            skillNodeId: skillNodeId,
            title: title,
            description: description,
            difficulty: difficulty,
            status: status,
            dueDate: dueDate,
            estimatedMinutes: estimatedMinutes,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
