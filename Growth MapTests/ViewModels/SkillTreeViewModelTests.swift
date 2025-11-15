//
//  SkillTreeViewModelTests.swift
//  Growth MapTests
//
//  Created on 2025-11-16.
//

import Testing
@testable import Growth_Map

@MainActor
struct SkillTreeViewModelTests {

    @Test func loadDataSuccessUpdatesPublishedState() async throws {
        let goalId = UUID()
        let nodes = [
            Self.makeNode(level: 1, path: "root.one"),
            Self.makeNode(level: 2, path: "root.one.child")
        ]
        let response = Self.makeResponse(goalId: goalId, nodes: nodes)
        let api = GrowthMapAPIMock(response: .success(response))

        let viewModel = SkillTreeViewModel(goalId: goalId, growthMapAPI: api)
        await viewModel.loadData()

        #expect(viewModel.goal == response.goal)
        #expect(viewModel.skillTree == response.skillTree)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.hasSkillNodes)
        #expect(viewModel.levelGroups.count == 2)
    }

    @Test func loadDataHandlesSupabaseError() async throws {
        let goalId = UUID()
        let api = GrowthMapAPIMock(response: .failure(SupabaseError.notAuthenticated))

        let viewModel = SkillTreeViewModel(goalId: goalId, growthMapAPI: api)
        await viewModel.loadData(force: true)

        #expect(viewModel.skillTree == nil)
        #expect(viewModel.goal == nil)
        #expect(viewModel.errorMessage == SupabaseError.notAuthenticated.errorDescription)
        #expect(!viewModel.isLoading)
    }

    @Test func loadingFlagReflectsNetworkActivity() async throws {
        let goalId = UUID()
        let response = Self.makeResponse(goalId: goalId, nodes: [Self.makeNode(level: 1, path: "root.node")])
        let api = GrowthMapAPIMock(response: .success(response), delayNanoseconds: 50_000_000)
        let viewModel = SkillTreeViewModel(goalId: goalId, growthMapAPI: api)

        let task = Task { await viewModel.loadData(force: true) }
        try await Task.sleep(nanoseconds: 5_000_000)
        #expect(viewModel.isLoading)
        await task.value
        #expect(!viewModel.isLoading)
    }

    @Test func levelGroupingSortsNodesByLevelAndPath() async throws {
        let goalId = UUID()
        let nodes = [
            Self.makeNode(level: 2, path: "root.b"),
            Self.makeNode(level: 1, path: "root.a"),
            Self.makeNode(level: 2, path: "root.a.child")
        ]
        let skillTree = Self.makeSkillTree(goalId: goalId, nodes: nodes)
        let viewModel = SkillTreeViewModel(goalId: goalId, growthMapAPI: GrowthMapAPIMock(response: .failure(MockError.stub)))
        viewModel.skillTree = skillTree

        let groups = viewModel.levelGroups
        #expect(groups.map { $0.level } == [1, 2])
        #expect(groups.first?.nodes.count == 1)
        #expect(groups.last?.nodes.first?.nodePath == "root.a.child")
    }
}

// MARK: - Helpers

private extension SkillTreeViewModelTests {
    static func makeResponse(goalId: UUID, nodes: [SkillTreeNode]) -> GoalDetailResponse {
        GoalDetailResponse(
            goal: makeGoal(id: goalId),
            skillTree: makeSkillTree(goalId: goalId, nodes: nodes),
            latestSprint: nil
        )
    }

    static func makeGoal(id: UUID) -> Goal {
        Goal(
            id: id,
            userId: UUID(),
            title: "Goal \(id.uuidString.prefix(4))",
            description: "Test goal description",
            horizonMonths: 6,
            dailyMinutes: 45,
            status: .active,
            priority: 1,
            targetDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static func makeSkillTree(goalId: UUID, nodes: [SkillTreeNode]) -> SkillTreeWithNodes {
        SkillTreeWithNodes(
            skillTree: SkillTree(
                id: UUID(),
                goalId: goalId,
                treeJson: [:],
                generatedBy: "ai",
                version: 1,
                createdAt: Date(),
                updatedAt: Date()
            ),
            nodes: nodes
        )
    }

    static func makeNode(level: Int, path: String) -> SkillTreeNode {
        SkillTreeNode(
            id: UUID(),
            skillTreeId: UUID(),
            nodePath: path,
            title: path.components(separatedBy: ".").last ?? "Node",
            level: level,
            focusHours: 10,
            payload: ["progress": AnyCodable(0.5)],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

private enum MockError: Error {
    case stub
}

private final class GrowthMapAPIMock: GrowthMapAPIProtocol {
    var response: Result<GoalDetailResponse, Error>
    var delayNanoseconds: UInt64
    private(set) var lastRequestedGoalId: String?

    init(response: Result<GoalDetailResponse, Error>, delayNanoseconds: UInt64 = 0) {
        self.response = response
        self.delayNanoseconds = delayNanoseconds
    }

    func getGoalDetail(goalId: String) async throws -> GoalDetailResponse {
        lastRequestedGoalId = goalId
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        switch response {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
