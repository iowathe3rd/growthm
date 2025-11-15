//
//  MainTabView.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI
import Auth

/// Main app view shown after successful authentication
/// Placeholder for future goals/sprints/progress views
struct MainTabView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var selectedTab: Tab = .goals

    private enum Tab {
        case goals
        case progress
        case tasks
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GoalsListView(viewModel: GoalsListViewModel(supabaseService: supabaseService))
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(Tab.goals)
            
            // Progress tab (placeholder)
            NavigationStack {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accent)
                    
                    Text("Progress")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Track your growth over time")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .navigationTitle("Progress")
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(Tab.progress)

            // Tasks tab
            NavigationStack {
                TasksView(
                    viewModel: TasksViewModel(supabaseService: supabaseService),
                    onSprintFinished: {
                        selectedTab = .goals
                    }
                )
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(Tab.tasks)

            // Profile tab (placeholder)
            NavigationStack {
                VStack {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accent)
                    
                    Text("Profile")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let user = supabaseService.currentUser {
                        Text(user.email ?? "No email")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(Tab.profile)
        }
        .accentColor(AppColors.accent)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var supabaseService: SupabaseService
        
        init() {
            let service = try! SupabaseService()
            _supabaseService = StateObject(wrappedValue: service)
        }
        
        var body: some View {
            MainTabView()
                .environmentObject(supabaseService)
        }
    }
    
    return PreviewWrapper()
}