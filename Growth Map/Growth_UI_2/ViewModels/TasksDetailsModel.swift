import Foundation

@MainActor
final class TaskDetailsViewModel: ObservableObject {
    @Published var task: SprintTask
    @Published var isSaving = false

    init(task: SprintTask) {
        self.task = task
    }

    var isDone: Bool {
        task.status == .done
    }

    func markAsDone() {
        task = SprintTask(
            id: task.id,
            title: task.title,
            description: task.description,
            difficulty: task.difficulty,
            status: .done
        )

    }
}
