// ViewModels/GrowthReportViewModel.swift
import Foundation

struct GrowthReportSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

@MainActor
final class GrowthReportViewModel: ObservableObject {
    @Published var headline: String = "This week’s growth"
    @Published var score: Int = 78
    @Published var sections: [GrowthReportSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        loadMock()
    }

    func loadMock() {
        isLoading = true
        errorMessage = nil

        score = 78
        sections = [
            GrowthReportSection(
                title: "What worked",
                body: "You consistently completed medium-difficulty tasks related to SwiftUI and layout."
            ),
            GrowthReportSection(
                title: "What to improve",
                body: "Deep work blocks are irregular. Consider protecting 45–60 minute slots 3 times a week."
            ),
            GrowthReportSection(
                title: "Next focus",
                body: "Prioritize 1 high-impact skill: Async/Await or NavigationStack patterns."
            )
        ]

        isLoading = false
    }
}
