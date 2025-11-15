//
//  SupabaseService+Goals.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation
import Supabase

/// Extension for Goal-related database operations
extension SupabaseService {
    
    // MARK: - Goal CRUD Operations
    
    /// Fetch all goals for the current user
    /// - Returns: Array of goals
    func fetchGoals() async throws -> [Goal] {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let goals: [Goal] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return goals
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch goals filtered by status
    /// - Parameter status: Goal status to filter by
    /// - Returns: Array of goals matching the status
    func fetchGoals(status: GoalStatus) async throws -> [Goal] {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let goals: [Goal] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: status.rawValue)
                .order("priority", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return goals
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch a single goal by ID
    /// - Parameter id: Goal ID
    /// - Returns: Goal if found, nil otherwise
    func fetchGoal(id: UUID) async throws -> Goal? {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let goal: Goal = try await client
                .from("goals")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            
            return goal
        } catch {
            if error.localizedDescription.contains("404") {
                return nil
            }
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Create a new goal
    /// - Parameter input: Goal input data
    /// - Returns: The created goal
    func createGoal(title: String, description: String, horizonMonths: Int, dailyMinutes: Int) async throws -> Goal {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        // Create insert data structure
        struct GoalInsert: Encodable {
            let userId: String
            let title: String
            let description: String
            let horizonMonths: Int
            let dailyMinutes: Int
            let status: String
            let priority: Int
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title
                case description
                case horizonMonths = "horizon_months"
                case dailyMinutes = "daily_minutes"
                case status
                case priority
            }
        }
        
        let insertData = GoalInsert(
            userId: userId.uuidString,
            title: title,
            description: description,
            horizonMonths: horizonMonths,
            dailyMinutes: dailyMinutes,
            status: GoalStatus.draft.rawValue,
            priority: 0
        )
        
        do {
            let goal: Goal = try await client
                .from("goals")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value
            
            return goal
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Update an existing goal
    /// - Parameters:
    ///   - id: Goal ID to update
    ///   - updates: Dictionary of fields to update
    /// - Returns: The updated goal
    func updateGoal(id: UUID, updates: [String: AnyCodable]) async throws -> Goal {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        // Add updated_at timestamp
        var updateData = updates
        updateData["updated_at"] = AnyCodable(ISO8601DateFormatter().string(from: Date()))
        
        do {
            let goal: Goal = try await client
                .from("goals")
                .update(updateData)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            return goal
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Update goal status
    /// - Parameters:
    ///   - id: Goal ID
    ///   - status: New status
    /// - Returns: The updated goal
    func updateGoalStatus(id: UUID, status: GoalStatus) async throws -> Goal {
        try await updateGoal(id: id, updates: ["status": AnyCodable(status.rawValue)])
    }
    
    /// Delete a goal
    /// - Parameter id: Goal ID to delete
    func deleteGoal(id: UUID) async throws {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            try await client
                .from("goals")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Skill Tree Operations
    
    /// Fetch skill tree for a goal
    /// - Parameter goalId: Goal ID
    /// - Returns: Skill tree with nodes if found
    func fetchSkillTree(forGoal goalId: UUID) async throws -> SkillTreeWithNodes? {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let skillTree: SkillTree = try await client
                .from("skill_trees")
                .select()
                .eq("goal_id", value: goalId.uuidString)
                .order("version", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value
            
            // Fetch nodes for this skill tree
            let nodes: [SkillTreeNode] = try await client
                .from("skill_tree_nodes")
                .select()
                .eq("skill_tree_id", value: skillTree.id.uuidString)
                .order("level", ascending: true)
                .execute()
                .value
            
            return SkillTreeWithNodes(skillTree: skillTree, nodes: nodes)
        } catch {
            if error.localizedDescription.contains("404") {
                return nil
            }
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Sprint Operations
    
    /// Fetch sprints for a goal
    /// - Parameter goalId: Goal ID
    /// - Returns: Array of sprints ordered by sprint number
    func fetchSprints(forGoal goalId: UUID) async throws -> [Sprint] {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let sprints: [Sprint] = try await client
                .from("sprints")
                .select()
                .eq("goal_id", value: goalId.uuidString)
                .order("sprint_number", ascending: true)
                .execute()
                .value
            
            return sprints
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch the latest sprint for a goal
    /// - Parameter goalId: Goal ID
    /// - Returns: Latest sprint with tasks if found
    func fetchLatestSprint(forGoal goalId: UUID) async throws -> SprintWithTasks? {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let sprint: Sprint = try await client
                .from("sprints")
                .select()
                .eq("goal_id", value: goalId.uuidString)
                .order("sprint_number", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value
            
            // Fetch tasks for this sprint
            let tasks: [SprintTask] = try await client
                .from("sprint_tasks")
                .select()
                .eq("sprint_id", value: sprint.id.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            return SprintWithTasks(sprint: sprint, tasks: tasks)
        } catch {
            if error.localizedDescription.contains("404") {
                return nil
            }
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch tasks for a sprint
    /// - Parameter sprintId: Sprint ID
    /// - Returns: Array of sprint tasks
    func fetchTasks(forSprint sprintId: UUID) async throws -> [SprintTask] {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let tasks: [SprintTask] = try await client
                .from("sprint_tasks")
                .select()
                .eq("sprint_id", value: sprintId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value

            return tasks
        } catch {
            throw SupabaseError.networkError(error)
        }
    }

    /// Fetch the current active sprint for the user with all of its tasks
    /// - Returns: SprintWithTasks if found, nil otherwise
    func fetchCurrentSprintWithTasks() async throws -> SprintWithTasks? {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let sprint: Sprint = try await client
                .from("sprints")
                .select()
                .eq("status", value: "active")
                .order("from_date", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value

            let tasks = try await fetchTasks(forSprint: sprint.id)
            return SprintWithTasks(sprint: sprint, tasks: tasks)
        } catch {
            if error.localizedDescription.contains("404") {
                return nil
            }
            throw SupabaseError.networkError(error)
        }
    }

    /// Mark a sprint as finished by updating its status to completed
    /// - Parameter sprintId: Sprint ID to update
    /// - Returns: Updated sprint model
    func finishSprint(sprintId: UUID) async throws -> Sprint {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }

        struct SprintUpdate: Encodable {
            let status: String
            let updatedAt: String

            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }

        let updateData = SprintUpdate(
            status: "completed",
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        do {
            let sprint: Sprint = try await client
                .from("sprints")
                .update(updateData)
                .eq("id", value: sprintId.uuidString)
                .select()
                .single()
                .execute()
                .value

            return sprint
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Update task status
    /// - Parameters:
    ///   - taskId: Task ID
    ///   - status: New status
    /// - Returns: Updated task
    func updateTaskStatus(taskId: UUID, status: TaskStatus) async throws -> SprintTask {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        struct TaskUpdate: Encodable {
            let status: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }
        
        let updateData = TaskUpdate(
            status: status.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            let task: SprintTask = try await client
                .from("sprint_tasks")
                .update(updateData)
                .eq("id", value: taskId.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            return task
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
}
