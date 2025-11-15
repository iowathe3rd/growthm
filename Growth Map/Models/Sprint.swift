//
//  Sprint.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation

/// Represents a weekly sprint for a goal
/// Mirrors the `sprints` table in the database
struct Sprint: Identifiable, Codable, Equatable {
    let id: UUID
    let goalId: UUID
    let sprintNumber: Int
    let fromDate: Date
    let toDate: Date
    let status: String
    let summary: String?
    let metrics: [String: AnyCodable]
    let createdAt: Date
    let updatedAt: Date

    /// Convenience property to detect whether the sprint has already been completed
    var isCompleted: Bool {
        status.lowercased() == "completed" || status.lowercased() == "finished"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case sprintNumber = "sprint_number"
        case fromDate = "from_date"
        case toDate = "to_date"
        case status
        case summary
        case metrics
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Draft structure for creating sprint plans (used in Edge Functions)
struct SprintPlan: Codable {
    let sprintNumber: Int
    let fromDate: String
    let toDate: String
    let summary: String
    let tasks: [SprintTaskDraft]
    
    enum CodingKeys: String, CodingKey {
        case sprintNumber = "sprint_number"
        case fromDate = "from_date"
        case toDate = "to_date"
        case summary
        case tasks
    }
}

/// Sprint summary for reporting
struct SprintSummary: Codable, Equatable {
    let sprint: Sprint
    let completed: Int
    let pending: Int
    let skipped: Int
}

/// Sprint with its tasks combined
struct SprintWithTasks: Equatable {
    let sprint: Sprint
    let tasks: [SprintTask]
}

extension SprintWithTasks: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode base sprint fields
        let id = try container.decode(UUID.self, forKey: .id)
        let goalId = try container.decode(UUID.self, forKey: .goalId)
        let sprintNumber = try container.decode(Int.self, forKey: .sprintNumber)
        let fromDate = try container.decode(Date.self, forKey: .fromDate)
        let toDate = try container.decode(Date.self, forKey: .toDate)
        let status = try container.decode(String.self, forKey: .status)
        let summary = try container.decodeIfPresent(String.self, forKey: .summary)
        let metrics = try container.decode([String: AnyCodable].self, forKey: .metrics)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        self.sprint = Sprint(
            id: id,
            goalId: goalId,
            sprintNumber: sprintNumber,
            fromDate: fromDate,
            toDate: toDate,
            status: status,
            summary: summary,
            metrics: metrics,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Decode tasks array
        self.tasks = try container.decode([SprintTask].self, forKey: .tasks)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sprint.id, forKey: .id)
        try container.encode(sprint.goalId, forKey: .goalId)
        try container.encode(sprint.sprintNumber, forKey: .sprintNumber)
        try container.encode(sprint.fromDate, forKey: .fromDate)
        try container.encode(sprint.toDate, forKey: .toDate)
        try container.encode(sprint.status, forKey: .status)
        try container.encodeIfPresent(sprint.summary, forKey: .summary)
        try container.encode(sprint.metrics, forKey: .metrics)
        try container.encode(sprint.createdAt, forKey: .createdAt)
        try container.encode(sprint.updatedAt, forKey: .updatedAt)
        try container.encode(tasks, forKey: .tasks)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case sprintNumber = "sprint_number"
        case fromDate = "from_date"
        case toDate = "to_date"
        case status
        case summary
        case metrics
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tasks
    }
}
