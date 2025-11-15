//
//  Goal.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation

/// Goal status enumeration matching database constraints
enum GoalStatus: String, Codable {
    case draft
    case active
    case paused
    case completed
}

/// Represents a user's goal
/// Mirrors the `goals` table in the database
struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let horizonMonths: Int
    let dailyMinutes: Int
    let status: GoalStatus
    let priority: Int
    let targetDate: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case horizonMonths = "horizon_months"
        case dailyMinutes = "daily_minutes"
        case status
        case priority
        case targetDate = "target_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Input model for creating a new goal
struct GoalInput: Codable {
    let title: String
    let description: String
    let horizonMonths: Int
    let dailyMinutes: Int
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case horizonMonths = "horizon_months"
        case dailyMinutes = "daily_minutes"
        case tags
    }
}

/// Body for creating a growth map with goal details
struct CreateGrowthMapBody: Codable {
    let title: String
    let description: String
    let horizonMonths: Int
    let dailyMinutes: Int
    let tags: [String]?
    let targetDate: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case horizonMonths = "horizon_months"
        case dailyMinutes = "daily_minutes"
        case tags
        case targetDate = "target_date"
    }
}
