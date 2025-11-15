//
//  SignUpView.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI

/// Sign up screen with email, password, and password confirmation
struct SignUpView: View {
    @ObservedObject var viewModel: SignUpViewModel
    
    var body: some View {
        VStack(spacing: Layout.spacingL) {
            // Header
            VStack(spacing: Layout.spacingS) {
                Text("Create Account")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Start your personal growth journey today")
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
                    placeholder: "At least 6 characters",
                    isSecure: true,
                    errorMessage: viewModel.passwordError,
                    textContentType: .newPassword
                )
                
                CustomTextField(
                    title: "Confirm Password",
                    text: $viewModel.confirmPassword,
                    placeholder: "Re-enter your password",
                    isSecure: true,
                    errorMessage: viewModel.confirmPasswordError,
                    textContentType: .newPassword
                )
            }
            
            // Sign up button
            PrimaryButton(
                title: "Create Account",
                action: {
                    Task {
                        await viewModel.signUp()
                    }
                },
                isLoading: viewModel.isLoading
            )
            .padding(.top, Layout.spacingM)
            
            // Terms and privacy disclaimer
            Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.spacingM)
            
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
                
                SignUpView(viewModel: SignUpViewModel(supabaseService: supabaseService))
            }
        }
    }
    
    return PreviewWrapper()
}
