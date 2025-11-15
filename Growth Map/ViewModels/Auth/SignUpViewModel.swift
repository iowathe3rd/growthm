//
//  SignUpViewModel.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI
import Combine
/// ViewModel for sign up screen
/// Handles email/password validation, password confirmation, and registration
@MainActor
class SignUpViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Form validation errors
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
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
        
        // Optional: Add stronger password requirements
        // Example: Check for uppercase, lowercase, number, special char
        
        return true
    }
    
    /// Validate password confirmation
    private func validateConfirmPassword() -> Bool {
        confirmPasswordError = nil
        
        guard !confirmPassword.isEmpty else {
            confirmPasswordError = "Please confirm your password"
            return false
        }
        
        guard password == confirmPassword else {
            confirmPasswordError = "Passwords do not match"
            return false
        }
        
        return true
    }
    
    /// Validate entire form
    private func validateForm() -> Bool {
        let isEmailValid = validateEmail()
        let isPasswordValid = validatePassword()
        let isConfirmPasswordValid = validateConfirmPassword()
        
        return isEmailValid && isPasswordValid && isConfirmPasswordValid
    }
    
    // MARK: - Actions
    
    /// Sign up with email and password
    func signUp() async {
        // Clear previous errors
        errorMessage = nil
        
        // Validate form
        guard validateForm() else {
            return
        }
        
        isLoading = true
        
        do {
            _ = try await supabaseService.signUp(email: email, password: password)
            // Navigation handled automatically by observing supabaseService.isAuthenticated
            // Note: If email confirmation is enabled, user won't be auto-signed in
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Clear all form data
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
    }
    
    // MARK: - Error Handling
    
    /// Convert technical errors to user-friendly messages
    private func handleError(_ error: Error) {
        if let supabaseError = error as? SupabaseError {
            errorMessage = supabaseError.userFriendlyMessage
        } else {
            let errorDescription = error.localizedDescription.lowercased()
            
            // Map common error messages
            if errorDescription.contains("user already registered") || errorDescription.contains("email already exists") {
                errorMessage = "An account with this email already exists. Please sign in instead."
            } else if errorDescription.contains("invalid email") {
                errorMessage = "Please enter a valid email address."
            } else if errorDescription.contains("password") && errorDescription.contains("weak") {
                errorMessage = "Password is too weak. Please use a stronger password."
            } else if errorDescription.contains("network") || errorDescription.contains("connection") {
                errorMessage = "Network error. Please check your connection and try again."
            } else {
                errorMessage = "An error occurred during sign up. Please try again later."
            }
        }
    }
}
