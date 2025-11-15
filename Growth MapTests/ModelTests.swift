//
//  ModelTests.swift
//  Growth MapTests
//
//  Created on November 15, 2025.
//

import Testing
import Foundation
@testable import Growth_Map

/// Tests for data model Codable conformance and mapping
struct ModelTests {
    
    // MARK: - Goal Tests
    
    @Test func goalCodable() async throws {
        // Given: JSON matching backend format
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "user_id": "123e4567-e89b-12d3-a456-426614174001",
            "title": "Learn Swift",
            "description": "Master iOS development",
            "horizon_months": 12,
            "daily_minutes": 60,
            "status": "active",
            "priority": 1,
            "target_date": "2025-12-31",
            "created_at": "2025-01-01T10:00:00.000Z",
            "updated_at": "2025-01-01T10:00:00.000Z"
        }
        """
        
        // When: Decoding JSON to Goal
        let data = json.data(using: .utf8)!
        let goal = try DateFormatters.jsonDecoder.decode(Goal.self, from: data)
        
        // Then: Properties are correctly mapped
        #expect(goal.id.uuidString == "123E4567-E89B-12D3-A456-426614174000")
        #expect(goal.title == "Learn Swift")
        #expect(goal.description == "Master iOS development")
        #expect(goal.horizonMonths == 12)
        #expect(goal.dailyMinutes == 60)
        #expect(goal.status == .active)
        #expect(goal.priority == 1)
        #expect(goal.targetDate != nil)
        
        // And: Can encode back to JSON
        let encoded = try DateFormatters.jsonEncoder.encode(goal)
        let decoded = try DateFormatters.jsonDecoder.decode(Goal.self, from: encoded)
        #expect(decoded.id == goal.id)
        #expect(decoded.title == goal.title)
    }
    
    @Test func goalStatusEnum() async throws {
        // Test all status values
        #expect(GoalStatus.draft.rawValue == "draft")
        #expect(GoalStatus.active.rawValue == "active")
        #expect(GoalStatus.paused.rawValue == "paused")
        #expect(GoalStatus.completed.rawValue == "completed")
        
        // Test decoding from string
        let activeData = "\"active\"".data(using: .utf8)!
        let status = try JSONDecoder().decode(GoalStatus.self, from: activeData)
        #expect(status == .active)
    }
    
    // MARK: - UserProfile Tests
    
    @Test func userProfileCodable() async throws {
        // Given: JSON with metadata
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "display_name": "John Doe",
            "email": "john@example.com",
            "timezone": "America/New_York",
            "onboarding_complete": true,
            "metadata": {
                "preference": "dark_mode",
                "level": 5
            },
            "created_at": "2025-01-01T10:00:00.000Z",
            "updated_at": "2025-01-01T10:00:00.000Z"
        }
        """
        
        // When: Decoding
        let data = json.data(using: .utf8)!
        let profile = try DateFormatters.jsonDecoder.decode(UserProfile.self, from: data)
        
        // Then: Properties are mapped
        #expect(profile.displayName == "John Doe")
        #expect(profile.email == "john@example.com")
        #expect(profile.timezone == "America/New_York")
        #expect(profile.onboardingComplete == true)
        #expect(profile.metadata.count == 2)
    }
    
    // MARK: - SprintTask Tests
    
    @Test func sprintTaskCodable() async throws {
        // Given: JSON for sprint task
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "sprint_id": "123e4567-e89b-12d3-a456-426614174001",
            "skill_node_id": null,
            "title": "Complete tutorial",
            "description": "Finish SwiftUI basics",
            "difficulty": "medium",
            "status": "pending",
            "due_date": "2025-01-07",
            "estimated_minutes": 120,
            "created_at": "2025-01-01T10:00:00.000Z",
            "updated_at": "2025-01-01T10:00:00.000Z"
        }
        """
        
        // When: Decoding
        let data = json.data(using: .utf8)!
        let task = try DateFormatters.jsonDecoder.decode(SprintTask.self, from: data)
        
        // Then: Properties are mapped
        #expect(task.title == "Complete tutorial")
        #expect(task.difficulty == .medium)
        #expect(task.status == .pending)
        #expect(task.skillNodeId == nil)
        #expect(task.estimatedMinutes == 120)
    }
    
    @Test func taskDifficultyEnum() async throws {
        // Test difficulty values
        #expect(TaskDifficulty.low.rawValue == "low")
        #expect(TaskDifficulty.medium.rawValue == "medium")
        #expect(TaskDifficulty.high.rawValue == "high")
    }
    
    @Test func taskStatusEnum() async throws {
        // Test status values
        #expect(TaskStatus.pending.rawValue == "pending")
        #expect(TaskStatus.done.rawValue == "done")
        #expect(TaskStatus.skipped.rawValue == "skipped")
    }
    
    // MARK: - SkillTree Tests
    
    @Test func skillTreeNodeCodable() async throws {
        // Given: JSON for skill tree node
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "skill_tree_id": "123e4567-e89b-12d3-a456-426614174001",
            "node_path": "root.swift.basics",
            "title": "Swift Basics",
            "level": 1,
            "focus_hours": 20.5,
            "payload": {
                "topics": ["variables", "functions"],
                "resources": 3
            },
            "created_at": "2025-01-01T10:00:00.000Z",
            "updated_at": "2025-01-01T10:00:00.000Z"
        }
        """
        
        // When: Decoding
        let data = json.data(using: .utf8)!
        let node = try DateFormatters.jsonDecoder.decode(SkillTreeNode.self, from: data)
        
        // Then: Properties are mapped
        #expect(node.nodePath == "root.swift.basics")
        #expect(node.title == "Swift Basics")
        #expect(node.level == 1)
        #expect(node.focusHours == 20.5)
        #expect(node.payload.count == 2)
    }
    
    // MARK: - Sprint Tests
    
    @Test func sprintCodable() async throws {
        // Given: JSON for sprint
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "goal_id": "123e4567-e89b-12d3-a456-426614174001",
            "sprint_number": 1,
            "from_date": "2025-01-01T00:00:00.000Z",
            "to_date": "2025-01-07T23:59:59.000Z",
            "status": "active",
            "summary": "Week 1: Foundation building",
            "metrics": {
                "completion_rate": 0.75,
                "tasks_completed": 3
            },
            "created_at": "2025-01-01T10:00:00.000Z",
            "updated_at": "2025-01-01T10:00:00.000Z"
        }
        """
        
        // When: Decoding
        let data = json.data(using: .utf8)!
        let sprint = try DateFormatters.jsonDecoder.decode(Sprint.self, from: data)
        
        // Then: Properties are mapped
        #expect(sprint.sprintNumber == 1)
        #expect(sprint.status == "active")
        #expect(sprint.summary == "Week 1: Foundation building")
        #expect(sprint.metrics.count == 2)
    }
    
    // MARK: - Edge Function Models Tests
    
    @Test func createGrowthMapBodyCodable() async throws {
        // Given: Input for creating growth map
        let body = CreateGrowthMapBody(
            title: "Learn AI",
            description: "Master machine learning",
            horizonMonths: 6,
            dailyMinutes: 90,
            tags: ["ai", "ml"],
            targetDate: "2025-07-01"
        )
        
        // When: Encoding to JSON
        let encoded = try DateFormatters.jsonEncoder.encode(body)
        let json = String(data: encoded, encoding: .utf8)!
        
        // Then: JSON contains snake_case keys
        #expect(json.contains("horizon_months"))
        #expect(json.contains("daily_minutes"))
        #expect(json.contains("target_date"))
        
        // And: Can decode back
        let decoded = try DateFormatters.jsonDecoder.decode(CreateGrowthMapBody.self, from: encoded)
        #expect(decoded.title == body.title)
        #expect(decoded.horizonMonths == body.horizonMonths)
    }
    
    @Test func taskStatusUpdateCodable() async throws {
        // Given: Task status update
        let update = TaskStatusUpdate(
            taskId: "123e4567-e89b-12d3-a456-426614174000",
            status: .done,
            notes: "Completed successfully"
        )
        
        // When: Encoding
        let encoded = try DateFormatters.jsonEncoder.encode(update)
        
        // Then: Can decode back
        let decoded = try DateFormatters.jsonDecoder.decode(TaskStatusUpdate.self, from: encoded)
        #expect(decoded.taskId == update.taskId)
        #expect(decoded.status == .done)
        #expect(decoded.notes == "Completed successfully")
    }
    
    // MARK: - AnyCodable Tests
    
    @Test func anyCodableWithPrimitives() async throws {
        // Test different types
        let stringValue = AnyCodable("test")
        let intValue = AnyCodable(42)
        let boolValue = AnyCodable(true)
        let doubleValue = AnyCodable(3.14)
        
        // Encode to JSON
        let dict: [String: AnyCodable] = [
            "string": stringValue,
            "int": intValue,
            "bool": boolValue,
            "double": doubleValue
        ]
        
        let encoded = try JSONEncoder().encode(dict)
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        
        // Verify values are preserved
        #expect(decoded.count == 4)
    }
    
    // MARK: - Date Formatting Tests
    
    @Test func iso8601DateFormatting() async throws {
        // Given: ISO8601 timestamp with milliseconds
        let dateString = "2025-01-01T10:30:45.123Z"
        
        // When: Parsing with custom formatter
        let date = DateFormatters.iso8601WithMilliseconds.date(from: dateString)
        
        // Then: Date is parsed correctly
        #expect(date != nil)
        
        // And: Can format back to string
        let formatted = DateFormatters.iso8601WithMilliseconds.string(from: date!)
        #expect(formatted == dateString)
    }
    
    @Test func dateOnlyFormatting() async throws {
        // Given: Date-only string
        let dateString = "2025-12-31"
        
        // When: Parsing with date-only formatter
        let date = DateFormatters.iso8601DateOnly.date(from: dateString)
        
        // Then: Date is parsed
        #expect(date != nil)
        
        // And: Can format back
        let formatted = DateFormatters.iso8601DateOnly.string(from: date!)
        #expect(formatted == dateString)
    }
}
