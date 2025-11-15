import Foundation

struct SkillNode: Identifiable, Equatable {
    let id: UUID
    let title: String
    let level: Int
    let progress: Double      // 0 ... 1
    let isLocked: Bool
}

struct SkillTree: Identifiable, Equatable {
    let id: UUID
    let goalTitle: String
    let nodes: [SkillNode]
}
