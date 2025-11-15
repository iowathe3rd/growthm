//
//  Growth_MapApp.swift
//  Growth Map
//
//  Created by Baurzhan Beglerov on 15.11.2025.
//

import SwiftUI
import SwiftData

@main
struct Growth_MapApp: App {
    // MARK: - SwiftData Container (for future local caching)
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Services
    @StateObject private var supabaseService: SupabaseService
    @StateObject private var growthMapAPI: GrowthMapAPI

    init() {
        let supabaseService: SupabaseService
        do {
            supabaseService = try SupabaseService()
        } catch {
            fatalError("Failed to initialize SupabaseService: \(error)")
        }

        _supabaseService = StateObject(wrappedValue: supabaseService)
        _growthMapAPI = StateObject(wrappedValue: GrowthMapAPI(supabaseService: supabaseService))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseService.isAuthenticated {
                    // Main app view (post-authentication)
                    MainTabView()
                        .environmentObject(supabaseService)
                        .environmentObject(growthMapAPI)
                } else {
                    // Authentication view
                    AuthenticationView(supabaseService: supabaseService)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
