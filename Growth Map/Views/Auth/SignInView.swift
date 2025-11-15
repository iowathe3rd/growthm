//
//  SignInView.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI

/// Sign in screen with email and password authentication
struct SignInView: View {
    @ObservedObject var viewModel: SignInViewModel
    
    var body: some View {
        VStack(spacing: Layout.spacingL) {
            // Header
            VStack(spacing: Layout.spacingS) {
                Text("Welcome Back")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Sign in to continue your growth journey")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Layout.spacingXL)
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Form
            VStack(spacing: Layout.spacingM) {
                CustomTextField(
                    title: "Email",
                    text: $viewModel.email,
                    placeholder: "your.email@example.com",
                    errorMessage: viewModel.emailError,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                
                CustomTextField(
                    title: "Password",
                    text: $viewModel.password,
                    placeholder: "Enter your password",
                    isSecure: true,
                    errorMessage: viewModel.passwordError,
                    textContentType: .password
                )
            }
            
            // Sign in button
            PrimaryButton(
                title: "Sign In",
                action: {
                    Task {
                        await viewModel.signIn()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .padding(.top, Layout.spacingM)
            
            Spacer()
        }
        .padding(.horizontal, Layout.screenPadding)
        .animation(.easeInOut, value: viewModel.errorMessage)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var supabaseService: SupabaseService
        
        init() {
            // For preview, use a mock or handle potential error
            let service = try! SupabaseService()
            _supabaseService = StateObject(wrappedValue: service)
        }
        
        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                SignInView(viewModel: SignInViewModel(supabaseService: supabaseService))
            }
        }
    }
    
    return PreviewWrapper()
}
