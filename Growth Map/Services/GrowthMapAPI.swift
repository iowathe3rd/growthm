//
//  GrowthMapAPI.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation
import Combine
import Supabase

protocol GrowthMapAPIProtocol: AnyObject {
    func getGoalDetail(goalId: String) async throws -> GoalDetailResponse
}

/// Service for calling Supabase Edge Functions
/// Handles all AI-powered growth map operations
@MainActor
final class GrowthMapAPI: ObservableObject, GrowthMapAPIProtocol {
    
    // MARK: - Properties
    
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Edge Function Calls
    
    /// Create a new growth map with AI-generated skill tree and first sprint
    /// Calls the `create-growth-map` Edge Function
    /// - Parameter body: Goal details and configuration
    /// - Returns: Complete growth map with goal, skill tree, and first sprint
    func createGrowthMap(_ body: CreateGrowthMapBody) async throws -> CreateGrowthMapResult {
        guard supabaseService.isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            // Call Edge Function - invoke returns decoded result directly
            let result: CreateGrowthMapResult = try await supabaseService.supabaseClient.functions.invoke(
                "create-growth-map",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            
            return result
        } catch let error as DecodingError {
            throw SupabaseError.decodingFailed(error)
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Regenerate a sprint based on progress and feedback
    /// Calls the `regenerate-sprint` Edge Function
    /// - Parameter body: Sprint ID, task updates, and user feedback
    /// - Returns: New sprint with tasks and progress log
    func regenerateSprint(_ body: RegenerateSprintBody) async throws -> RegenerateSprintResult {
        guard supabaseService.isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            // Call Edge Function - invoke returns decoded result directly
            let result: RegenerateSprintResult = try await supabaseService.supabaseClient.functions.invoke(
                "regenerate-sprint",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            
            return result
        } catch let error as DecodingError {
            throw SupabaseError.decodingFailed(error)
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Get a comprehensive growth report for a goal
    /// Calls the `growth-report` Edge Function
    /// - Parameter body: Goal ID and time range filters
    /// - Returns: Detailed growth report with insights and recommendations
    func getGrowthReport(_ body: GrowthReportBody) async throws -> GrowthReportResult {
        guard supabaseService.isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            // Call Edge Function - invoke returns decoded result directly
            let result: GrowthReportResult = try await supabaseService.supabaseClient.functions.invoke(
                "growth-report",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
            
            return result
        } catch let error as DecodingError {
            throw SupabaseError.decodingFailed(error)
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Get detailed information about a goal including skill tree and latest sprint
    /// Calls the `get-goal-detail` Edge Function
    /// - Parameter goalId: Goal ID to fetch details for
    /// - Returns: Goal detail with skill tree and sprint information
    func getGoalDetail(goalId: String) async throws -> GoalDetailResponse {
        guard supabaseService.isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            // Call Edge Function - invoke returns decoded result directly
            let result: GoalDetailResponse = try await supabaseService.supabaseClient.functions.invoke(
                "get-goal-detail",
                options: FunctionInvokeOptions(
                    body: ["goal_id": goalId]
                )
            )
            
            return result
        } catch let error as DecodingError {
            throw SupabaseError.decodingFailed(error)
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Create growth map with simplified parameters
    /// - Parameters:
    ///   - title: Goal title
    ///   - description: Goal description
    ///   - horizonMonths: Time horizon in months
    ///   - dailyMinutes: Daily time commitment in minutes
    ///   - targetDate: Optional target completion date
    /// - Returns: Complete growth map result
    func createGrowthMap(
        title: String,
        description: String,
        horizonMonths: Int,
        dailyMinutes: Int,
        targetDate: Date? = nil
    ) async throws -> CreateGrowthMapResult {
        let targetDateString = targetDate.map { DateFormatters.iso8601DateOnly.string(from: $0) }
        
        let body = CreateGrowthMapBody(
            title: title,
            description: description,
            horizonMonths: horizonMonths,
            dailyMinutes: dailyMinutes,
            tags: nil,
            targetDate: targetDateString
        )
        
        return try await createGrowthMap(body)
    }
    
    /// Regenerate sprint with task status updates
    /// - Parameters:
    ///   - sprintId: Sprint ID to regenerate
    ///   - taskUpdates: Array of task status updates
    ///   - feedback: Optional user feedback
    ///   - feelingTags: Optional feeling tags for context
    /// - Returns: Regenerated sprint result
    func regenerateSprint(
        sprintId: String,
        taskUpdates: [TaskStatusUpdate] = [],
        feedback: String? = nil,
        feelingTags: [String]? = nil
    ) async throws -> RegenerateSprintResult {
        let body = RegenerateSprintBody(
            sprintId: sprintId,
            statusUpdates: taskUpdates.isEmpty ? nil : taskUpdates,
            feedback: feedback,
            feelingTags: feelingTags
        )
        
        return try await regenerateSprint(body)
    }
    
    /// Get growth report for a goal
    /// - Parameters:
    ///   - goalId: Goal ID
    ///   - since: Optional start date filter
    ///   - until: Optional end date filter
    ///   - includeSprints: Number of recent sprints to include
    /// - Returns: Growth report with insights
    func getGrowthReport(
        goalId: String,
        since: Date? = nil,
        until: Date? = nil,
        includeSprints: Int? = nil
    ) async throws -> GrowthReportResult {
        let sinceString = since.map { DateFormatters.iso8601DateOnly.string(from: $0) }
        let untilString = until.map { DateFormatters.iso8601DateOnly.string(from: $0) }
        
        let body = GrowthReportBody(
            goalId: goalId,
            since: sinceString,
            until: untilString,
            includeSprints: includeSprints
        )
        
        return try await getGrowthReport(body)
    }
}
