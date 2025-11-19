import Foundation
import Supabase

extension SupabaseService {
    
    // MARK: - Fetch Goals
    
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
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return goals
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    
    // MARK: - Fetch Tasks
    
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

    
    // MARK: - Fetch Current Sprint With Tasks
    
    func fetchCurrentSprintWithTasks() async throws -> SprintWithTasks? {
        guard let user = currentUser else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let sprintArray: [Sprint] = try await client
                .from("sprints")
                .select()
                .eq("user_id", value: user.id)
                .eq("status", value: "active")
                .order("sprint_number", ascending: false)
                .limit(1)
                .execute()
                .value

            if let sprint = sprintArray.first {
                let tasks = try await fetchTasks(forSprint: sprint.id)
                return SprintWithTasks(sprint: sprint, tasks: tasks)
            }

            return nil
        } catch {
            throw SupabaseError.networkError(error)
        }
    }

    
    // MARK: - Update Task Status
    
    struct TaskStatusPayload: Encodable {
        let status: String
    }

    func updateTaskStatus(taskId: UUID, status: TaskStatus) async throws -> SprintTask {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let updated: SprintTask = try await client
                .from("sprint_tasks")
                .update(TaskStatusPayload(status: status.rawValue))
                .eq("id", value: taskId.uuidString)
                .select()
                .single()
                .execute()
                .value

            return updated
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    
    // MARK: - Finish Sprint  ← вот этот метод требовался
    
    struct SprintStatusPayload: Encodable {
        let status: String
    }

    func finishSprint(sprintId: UUID) async throws -> Sprint {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let updated: Sprint = try await client
                .from("sprints")
                .update(SprintStatusPayload(status: "finished")) // если у тебя другое значение — скажи
                .eq("id", value: sprintId.uuidString)
                .select()
                .single()
                .execute()
                .value

            return updated
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
}

