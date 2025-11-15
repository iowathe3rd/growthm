//
//  MainTabView.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI
import Auth
import Auth

/// Main app view shown after successful authentication
/// Placeholder for future goals/sprints/progress views
struct MainTabView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    
    var body: some View {
        TabView {
            // Goals tab (placeholder)
            NavigationStack {
                VStack(spacing: Layout.spacingL) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accent)
                    
                    Text("Goals")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Your growth map will appear here")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    // Sign out button for testing
                    SecondaryButton(title: "Sign Out") {
                        Task {
                            try? await supabaseService.signOut()
                        }
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.bottom, Layout.spacingL)
                }
                .padding(.top, Layout.spacingXL)
                .navigationTitle("GrowthMap")
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            
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
