import Foundation

enum TaskDifficulty: String, Codable, CaseIterable {
    case low
    case medium
    case high
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case done
    case skipped
}

struct SprintTask: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let difficulty: TaskDifficulty
    var status: TaskStatus
}
