import Foundation

@MainActor
final class SkillTreeViewModel: ObservableObject {
    @Published var skillTree: SkillTree?
    @Published var isLoading = false
    @Published var errorMessage: String?
    init() {
        loadMock()
    }

    func loadMock() {
        isLoading = true
        errorMessage = nil

        let nodes = [
            SkillNode(id: UUID(), title: "Foundation", level: 1, progress: 1.0, isLocked: false),
            SkillNode(id: UUID(), title: "Swift Language", level: 1, progress: 0.8, isLocked: false),
            SkillNode(id: UUID(), title: "Async/Await", level: 2, progress: 0.3, isLocked: false),
            SkillNode(id: UUID(), title: "SwiftUI Layout", level: 2, progress: 0.5, isLocked: false),
            SkillNode(id: UUID(), title: "Architecture (MVVM)", level: 3, progress: 0.1, isLocked: true)
        ]

        skillTree = SkillTree(
            id: UUID(),
            goalTitle: "Become iOS Developer",
            nodes: nodes
        )

        isLoading = false
    }
}
