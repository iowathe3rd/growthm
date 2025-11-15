//
//  EdgeFunctionModels.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation
import Combine

/// Response from the create-growth-map Edge Function
struct CreateGrowthMapResult: Codable {
    let goal: Goal
    let skillTree: SkillTreeWithNodes
    let sprint: SprintWithTasks
    
    enum CodingKeys: String, CodingKey {
        case goal
        case skillTree = "skill_tree"
        case sprint
    }
}

/// Request body for regenerate-sprint Edge Function
struct RegenerateSprintBody: Codable {
    let sprintId: String
    let statusUpdates: [TaskStatusUpdate]?
    let feedback: String?
    let feelingTags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case sprintId = "sprint_id"
        case statusUpdates = "status_updates"
        case feedback
        case feelingTags = "feeling_tags"
    }
}

/// Response from the regenerate-sprint Edge Function
struct RegenerateSprintResult: Codable {
    let sprint: SprintWithTasks
    let progressLog: ProgressLog
    
    enum CodingKeys: String, CodingKey {
        case sprint
        case progressLog = "progress_log"
    }
}

/// Request body for growth-report Edge Function
struct GrowthReportBody: Codable {
    let goalId: String
    let since: String?
    let until: String?
    let includeSprints: Int?
    
    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case since
        case until
        case includeSprints = "include_sprints"
    }
}

/// Response from the growth-report Edge Function
struct GrowthReportResult: Codable {
    let goal: Goal
    let sprintSummaries: [SprintSummary]
    let insights: GrowthInsights
    let progressLogs: [ProgressLog]
    
    enum CodingKeys: String, CodingKey {
        case goal
        case sprintSummaries = "sprint_summaries"
        case insights
        case progressLogs = "progress_logs"
    }
}

/// Insights from growth report
struct GrowthInsights: Codable, Equatable {
    let narrative: String
    let recommendations: [String]
}

/// Response from the get-goal-detail Edge Function
struct GoalDetailResponse: Codable {
    let goal: Goal
    let skillTree: SkillTreeWithNodes?
    let latestSprint: SprintWithTasks?
    
    enum CodingKeys: String, CodingKey {
        case goal
        case skillTree = "skill_tree"
        case latestSprint = "latest_sprint"
    }
}
