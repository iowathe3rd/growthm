//
//  CreateGoalView.swift
//  Growth Map
//
//  Created on 2025-11-16.
//

import SwiftUI

struct CreateGoalView: View {
    @ObservedObject var viewModel: CreateGoalViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.spacingL) {
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                }

                CustomTextField(
                    title: "Title",
                    text: $viewModel.title,
                    placeholder: "Ship a portfolio website",
                    errorMessage: viewModel.titleError,
                    autocapitalization: .words
                )

                CustomTextField(
                    title: "Description",
                    text: $viewModel.description,
                    placeholder: "Describe why this goal matters",
                    errorMessage: viewModel.descriptionError,
                    autocapitalization: .sentences
                )

                CustomTextField(
                    title: "Daily Minutes",
                    text: $viewModel.dailyMinutes,
                    placeholder: "30",
                    errorMessage: viewModel.dailyMinutesError,
                    keyboardType: .numberPad
                )

                CustomTextField(
                    title: "Horizon (months)",
                    text: $viewModel.horizonMonths,
                    placeholder: "6",
                    errorMessage: viewModel.horizonMonthsError,
                    keyboardType: .numberPad
                )

                PrimaryButton(title: "Create Goal", action: createGoal, isLoading: viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("Create Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    private func createGoal() {
        Task { await viewModel.createGoal() }
    }
}

#Preview {
    NavigationStack {
        CreateGoalView(
            viewModel: CreateGoalViewModel(
                growthMapAPI: GrowthMapAPI(supabaseService: try! SupabaseService())
            )
        )
    }
}
