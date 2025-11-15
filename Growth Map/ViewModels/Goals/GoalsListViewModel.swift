//
//  GoalsListViewModel.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import Foundation

/// View model that loads the authenticated user's goals and exposes loading/error state
@MainActor
final class GoalsListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var goals: [Goal] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isShowingCreateGoalSheet: Bool = false

    // MARK: - Dependencies

    let supabaseService: SupabaseService

    // MARK: - Private State

    private var hasLoadedOnce = false

    // MARK: - Initialization

    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

    // MARK: - Public API

    /// Load goals if they haven't been loaded yet
    func loadGoalsIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await loadGoals(forceReload: true)
    }

    /// Refresh the goal list regardless of cached state
    func refreshGoals() async {
        await loadGoals(forceReload: true)
    }

    /// Synchronous accessor for sorted goals to keep the view code tidy
    func orderedGoals() -> [Goal] {
        goals.sorted(by: Goal.statusPriorityComparator)
    }

    // MARK: - Private Helpers

    private func loadGoals(forceReload: Bool) async {
        if isLoading { return }
        if !forceReload, hasLoadedOnce { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedGoals = try await supabaseService.fetchGoals()
            goals = fetchedGoals
            hasLoadedOnce = true
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    private func handleError(_ error: Error) {
        if let supabaseError = error as? SupabaseError {
            errorMessage = supabaseError.errorDescription ?? "Something went wrong."
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Goal Sorting Helper

private extension Goal {
    /// Comparator that sorts goals by status priority (active, draft, paused, completed) and creation date
    static func statusPriorityComparator(lhs: Goal, rhs: Goal) -> Bool {
        let lhsPriority = lhs.status.sortPriority
        let rhsPriority = rhs.status.sortPriority

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

private extension GoalStatus {
    /// Lower numbers are higher priority
    var sortPriority: Int {
        switch self {
        case .active:
            return 0
        case .draft:
            return 1
        case .paused:
            return 2
        case .completed:
            return 3
        }
    }
}
