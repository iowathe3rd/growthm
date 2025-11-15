//
//  CreateGoalViewModel.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import Foundation

/// Handles validation and submission logic for the create goal sheet
@MainActor
final class CreateGoalViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var title: String = ""
    @Published var description: String = ""
    @Published var dailyMinutes: String = "30"
    @Published var horizonMonths: String = "6"

    @Published var titleError: String?
    @Published var descriptionError: String?
    @Published var dailyMinutesError: String?
    @Published var horizonMonthsError: String?
    @Published var errorMessage: String?

    @Published private(set) var isLoading = false
    @Published private(set) var createdGoal: Goal?

    // MARK: - Dependencies

    private let growthMapAPI: GrowthMapAPI
    private let onGoalCreated: ((Goal) -> Void)?

    // MARK: - Initialization

    init(growthMapAPI: GrowthMapAPI, onGoalCreated: ((Goal) -> Void)? = nil) {
        self.growthMapAPI = growthMapAPI
        self.onGoalCreated = onGoalCreated
    }

    // MARK: - Public API

    func createGoal() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil

        do {
            guard let dailyMinutesValue = Int(dailyMinutes),
                  let horizonMonthsValue = Int(horizonMonths) else {
                throw ValidationError.invalidNumber
            }

            let result = try await growthMapAPI.createGrowthMap(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                horizonMonths: horizonMonthsValue,
                dailyMinutes: dailyMinutesValue,
                targetDate: nil
            )

            createdGoal = result.goal
            onGoalCreated?(result.goal)
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    // MARK: - Validation

    private func validateForm() -> Bool {
        titleError = nil
        descriptionError = nil
        dailyMinutesError = nil
        horizonMonthsError = nil

        var isValid = true

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleError = "Title is required"
            isValid = false
        }

        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            descriptionError = "Description is required"
            isValid = false
        }

        if let dailyMinutesValue = Int(dailyMinutes) {
            if dailyMinutesValue <= 0 {
                dailyMinutesError = "Enter minutes greater than 0"
                isValid = false
            }
        } else {
            dailyMinutesError = "Enter a valid number"
            isValid = false
        }

        if let horizonMonthsValue = Int(horizonMonths) {
            if horizonMonthsValue <= 0 {
                horizonMonthsError = "Enter months greater than 0"
                isValid = false
            }
        } else {
            horizonMonthsError = "Enter a valid number"
            isValid = false
        }

        return isValid
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        if let supabaseError = error as? SupabaseError {
            errorMessage = supabaseError.errorDescription ?? "Unable to create goal."
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Validation Error

private enum ValidationError: Error {
    case invalidNumber
}
