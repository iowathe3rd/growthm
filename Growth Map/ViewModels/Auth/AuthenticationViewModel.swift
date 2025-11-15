//
//  AuthenticationViewModel.swift
//  Growth Map
//
//  Created on 2025-11-15.
//

import SwiftUI
import Combine

/// Coordinator ViewModel for authentication flow
/// Manages state for switching between Sign In and Sign Up views
@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Authentication Mode
    
    enum AuthMode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
    }
    
    // MARK: - Published Properties
    
    @Published var currentMode: AuthMode = .signIn
    
    // MARK: - Child ViewModels
    
    let signInViewModel: SignInViewModel
    let signUpViewModel: SignUpViewModel
    
    // MARK: - Dependencies
    
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        self.signInViewModel = SignInViewModel(supabaseService: supabaseService)
        self.signUpViewModel = SignUpViewModel(supabaseService: supabaseService)
    }
    
    // MARK: - Actions
    
    /// Switch to sign in mode
    func switchToSignIn() {
        currentMode = .signIn
        signUpViewModel.clearForm()
    }
    
    /// Switch to sign up mode
    func switchToSignUp() {
        currentMode = .signUp
        signInViewModel.clearForm()
    }
    
    /// Toggle between modes
    func toggleMode() {
        switch currentMode {
        case .signIn:
            switchToSignUp()
        case .signUp:
            switchToSignIn()
        }
    }
}
