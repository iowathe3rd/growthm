//
//  SignInViewModel.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI
import Combine
import Combine
/// ViewModel for sign in screen
/// Handles email/password validation and authentication flow
@MainActor
class SignInViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Form validation
    @Published var emailError: String?
    @Published var passwordError: String?
    
    // MARK: - Dependencies
    
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Validation
    
    /// Email validation regex pattern
    private let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    /// Validate email format
    private func validateEmail() -> Bool {
        emailError = nil
        
        guard !email.isEmpty else {
            emailError = "Email is required"
            return false
        }
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            emailError = "Please enter a valid email address"
            return false
        }
        
        return true
    }
    
    /// Validate password (minimum 6 characters per Supabase config)
    private func validatePassword() -> Bool {
        passwordError = nil
        
        guard !password.isEmpty else {
            passwordError = "Password is required"
            return false
        }
        
        guard password.count >= 6 else {
            passwordError = "Password must be at least 6 characters"
            return false
        }
        
        return true
    }
    
    /// Validate entire form
    private func validateForm() -> Bool {
        let isEmailValid = validateEmail()
        let isPasswordValid = validatePassword()
        return isEmailValid && isPasswordValid
    }
    
    // MARK: - Actions
    
    /// Sign in with email and password
    func signIn() async {
        // Clear previous errors
        errorMessage = nil
        
        // Validate form
        guard validateForm() else {
            return
        }
        
        isLoading = true
        
        do {
            _ = try await supabaseService.signIn(email: email, password: password)
            // Navigation handled automatically by observing supabaseService.isAuthenticated
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Clear all form data
    func clearForm() {
        email = ""
        password = ""
        errorMessage = nil
        emailError = nil
        passwordError = nil
    }
    
    // MARK: - Error Handling
    
    /// Convert technical errors to user-friendly messages
    private func handleError(_ error: Error) {
        if let supabaseError = error as? SupabaseError {
            errorMessage = supabaseError.userFriendlyMessage
        } else {
            let errorDescription = error.localizedDescription.lowercased()
            
            // Map common error messages
            if errorDescription.contains("invalid login credentials") {
                errorMessage = "Invalid email or password. Please try again."
            } else if errorDescription.contains("email not confirmed") {
                errorMessage = "Please confirm your email address before signing in."
            } else if errorDescription.contains("network") || errorDescription.contains("connection") {
                errorMessage = "Network error. Please check your connection and try again."
            } else {
                errorMessage = "An error occurred. Please try again later."
            }
        }
    }
}

// MARK: - Error Message Extension

extension SupabaseError {
    /// User-friendly error messages for auth flow
    var userFriendlyMessage: String {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .invalidConfiguration:
            return "App configuration error. Please contact support."
        case .invalidResponse:
            return "Invalid server response. Please try again."
        case .decodingFailed:
            return "Data processing error. Please try again."
        case .networkError(let error):
            let description = error.localizedDescription.lowercased()
            if description.contains("invalid login credentials") {
                return "Invalid email or password"
            } else if description.contains("network") {
                return "Network error. Please check your connection."
            }
            return "An error occurred. Please try again."
        }
    }
}
