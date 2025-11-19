import Foundation
import SupabaseClient

enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case unexpectedResponse(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .networkError(let e):
            return e.localizedDescription
        case .unexpectedResponse(let msg):
            return msg
        }
    }
}

struct SprintWithTasks {
    let sprint: Sprint
    let tasks: [SprintTask]
}

final class SupabaseService {
    private let client: SupabaseClientProtocol
    var currentUser: SupabaseUser? = nil

    init(client: SupabaseClientProtocol) {
        self.client = client
    }
}

extension SupabaseService {
    func fetchTasks(forSprint sprintId: UUID) async throws -> [SprintTask] {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let result = try await client
                .from("sprint_tasks")
                .select()
                .eq("sprint_id", value: sprintId.uuidString)
                .order("created_at", ascending: true)
                .execute()

            print("DEBUG: fetchTasks raw result -> \(result)")

            if let tasks = result.value as? [SprintTask] {
                return tasks
            }

            if let any = result.value {
                if JSONSerialization.isValidJSONObject(any) {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: any, options: [])
                        let decoded = try JSONDecoder().decode([SprintTask].self, from: data)
                        return decoded
                    } catch {
                        print("DEBUG: failed to JSON-decode tasks from result.value: \(error)")
                    }
                } else {
                    print("DEBUG: result.value exists but is not valid JSON object for serialization: \(type(of: any))")
                }
            } else {
                print("DEBUG: result.value is nil")
            }

            return []
        } catch {
            print("DEBUG: fetchTasks network error -> \(error)")
            throw SupabaseError.networkError(error)
        }
    }

    func fetchCurrentSprintWithTasks() async throws -> SprintWithTasks? {
        guard let user = currentUser else {
            throw SupabaseError.notAuthenticated
        }

        do {
            let sprintResult = try await client
                .from("sprints")
                .select()
                .eq("user_id", value: user.id)
                .eq("status", value: "active")
                .order("sprint_number", ascending: false)
                .limit(1)
                .execute()

            print("DEBUG: fetchCurrentSprintWithTasks sprintResult -> \(sprintResult)")

            if let sprintArray = sprintResult.value as? [Sprint], let sprint = sprintArray.first {
                let tasks = try await fetchTasks(forSprint: sprint.id)
                return SprintWithTasks(sprint: sprint, tasks: tasks)
            }

            if let any = sprintResult.value {
                print("DEBUG: sprintResult.value exists but unexpected type: \(type(of: any))")
            }

            return nil
        } catch {
            print("DEBUG: fetchCurrentSprintWithTasks error -> \(error)")
            throw SupabaseError.networkError(error)
        }
    }
}

protocol SupabaseClientProtocol {
    func from(_ table: String) -> PostgrestQueryBuilder
}

protocol PostgrestQueryBuilder {
    func select(_ columns: String...) -> PostgrestQueryBuilder
    func select() -> PostgrestQueryBuilder
    func eq(_ column: String, value: String) -> PostgrestQueryBuilder
    func order(_ column: String, ascending: Bool) -> PostgrestQueryBuilder
    func limit(_ count: Int) -> PostgrestQueryBuilder
    func execute() async throws -> PostgrestResponse
}

struct PostgrestResponse {
    let value: Any?
}

struct SupabaseUser {
    let id: String
    let email: String?
}

struct Sprint: Codable {
    let id: UUID
    let goalId: UUID
    let sprintNumber: Int
    let fromDate: Date?
    let toDate: Date?
    let status: String
    let summary: String?
    let metrics: [String: AnyCodable]?
    let createdAt: Date
    let updatedAt: Date

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

struct AnyCodable: Codable {}

struct SprintTask: Codable, Identifiable, Equatable {
    let id: UUID
    let sprintId: UUID
    let skillNodeId: UUID?
    let title: String
    let description: String
    let difficulty: String
    let status: String
    let dueDate: String?
    let estimatedMinutes: Int?
    let createdAt: Date
    let updatedAt: Date

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
