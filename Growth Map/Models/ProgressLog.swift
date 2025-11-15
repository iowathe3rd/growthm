//
//  ProgressLog.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation

/// Represents a progress log entry
/// Mirrors the `progress_logs` table in the database
struct ProgressLog: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let goalId: UUID
    let sprintId: UUID?
    let payload: [String: AnyCodable]
    let recordedAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case goalId = "goal_id"
        case sprintId = "sprint_id"
        case payload
        case recordedAt = "recorded_at"
        case createdAt = "created_at"
    }
}
