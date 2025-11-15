//
//  SprintTask.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation

/// Task difficulty levels matching database constraints
enum TaskDifficulty: String, Codable {
    case low
    case medium
    case high
}

/// Task status matching database constraints
enum TaskStatus: String, Codable {
    case pending
    case done
    case skipped
}

/// Represents a task within a sprint
/// Mirrors the `sprint_tasks` table in the database
struct SprintTask: Identifiable, Codable, Equatable {
    let id: UUID
    let sprintId: UUID
    let skillNodeId: UUID?
    let title: String
    let description: String
    let difficulty: TaskDifficulty
    let status: TaskStatus
    let dueDate: Date?
    let estimatedMinutes: Int?
    let createdAt: Date
    let updatedAt: Date

    /// Convenience flag for checking whether the task has been completed
    var isCompleted: Bool { status == .done }

    enum CodingKeys: String, CodingKey {
        case id
        case sprintId = "sprint_id"
        case skillNodeId = "skill_node_id"
        case title
        case description
        case difficulty
        case status
        case dueDate = "due_date"
        case estimatedMinutes = "estimated_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Draft structure for creating sprint tasks (used in Edge Functions)
struct SprintTaskDraft: Codable {
    let title: String
    let description: String
    let difficulty: TaskDifficulty
    let dueDate: String?
    let estimatedMinutes: Int?
    let nodePath: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case difficulty
        case dueDate = "due_date"
        case estimatedMinutes = "estimated_minutes"
        case nodePath = "node_path"
    }
}

/// Task status update for regenerating sprints
struct TaskStatusUpdate: Codable {
    let taskId: String
    let status: TaskStatus
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
        case notes
    }
}
