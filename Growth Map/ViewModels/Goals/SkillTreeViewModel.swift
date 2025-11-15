//
//  SkillTreeViewModel.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import Foundation
import Combine

/// Organizes goal and skill tree details for the SkillTreeView
@MainActor
final class SkillTreeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var skillTree: SkillTreeWithNodes?
    @Published var goal: Goal?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let growthMapAPI: GrowthMapAPIProtocol
    private let goalId: UUID

    // MARK: - Initialization

    init(goalId: UUID, initialGoal: Goal? = nil, growthMapAPI: GrowthMapAPIProtocol) {
        self.goalId = goalId
        self.goal = initialGoal
        self.growthMapAPI = growthMapAPI
    }

    // MARK: - Data Loading

    /// Loads goal detail and skill tree data
    /// - Parameter force: Bypass cached result and fetch again
    func loadData(force: Bool = false) async {
        guard !isLoading else { return }
        if !force && skillTree != nil {
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await growthMapAPI.getGoalDetail(goalId: goalId.uuidString)
            goal = response.goal
            skillTree = response.skillTree
        } catch {
            handleError(error)
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        if let supabaseError = error as? SupabaseError {
            errorMessage = supabaseError.errorDescription ?? "An unexpected error occurred."
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Derived Data

    /// Groups skill tree nodes by level for sectioned display
    var levelGroups: [SkillTreeLevelGroup] {
        guard let nodes = skillTree?.nodes, !nodes.isEmpty else { return [] }

        let grouped = Dictionary(grouping: nodes) { max($0.level, 1) }

        return grouped.keys.sorted().compactMap { level in
            guard let nodes = grouped[level] else { return nil }
            let sortedNodes = nodes.sorted { lhs, rhs in
                if lhs.nodePath != rhs.nodePath {
                    return lhs.nodePath < rhs.nodePath
                }
                return lhs.title < rhs.title
            }
            return SkillTreeLevelGroup(level: level, nodes: sortedNodes)
        }
    }

    /// Indicates if there are nodes to render
    var hasSkillNodes: Bool {
        guard let nodes = skillTree?.nodes else { return false }
        return !nodes.isEmpty
    }
}

/// Represents a section of nodes grouped by level
struct SkillTreeLevelGroup: Identifiable, Equatable {
    let level: Int
    let nodes: [SkillTreeNode]

    var id: Int { level }
}
