//
//  SupabaseService.swift
//  Growth Map
//
//  Created on November 15, 2025.
//

import Foundation
import Supabase
import Auth

/// Custom errors for Supabase operations
enum SupabaseError: LocalizedError {
    case notAuthenticated
    case invalidConfiguration
    case invalidResponse
    case decodingFailed(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated. Please sign in."
        case .invalidConfiguration:
            return "Supabase configuration is invalid. Check your environment variables."
        case .invalidResponse:
            return "Received invalid response from server."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Main service for Supabase client interactions
/// Handles authentication, database queries, and session management
@MainActor
final class SupabaseService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var currentSession: Session?
    
    // MARK: - Private Properties
    
    private let client: SupabaseClient
    
    // MARK: - Initialization
    
    init() throws {
        // Read configuration from environment or Info.plist
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let url = URL(string: urlString),
              let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            throw SupabaseError.invalidConfiguration
        }
        
        // Initialize Supabase client
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                db: .init(
                    schema: "public",
                    decoder: DateFormatters.jsonDecoder,
                    encoder: DateFormatters.jsonEncoder
                ),
                auth: .init(
                    flowType: .pkce,
                    autoRefreshToken: true
                ),
                global: .init(
                    headers: ["X-Client-Info": "growthmap-ios/1.0.0"]
                )
            )
        )
        
        // Set up auth state listener
        Task {
            await observeAuthState()
        }
    }
    
    // MARK: - Auth State Management
    
    /// Observes authentication state changes
    private func observeAuthState() async {
        for await state in client.auth.authStateChanges {
            switch state {
            case .signedIn(let session):
                currentSession = session
                currentUser = session.user
                isAuthenticated = true
                
            case .signedOut:
                currentSession = nil
                currentUser = nil
                isAuthenticated = false
                
            case .initialSession(let session):
                if let session = session {
                    currentSession = session
                    currentUser = session.user
                    isAuthenticated = true
                }
                
            case .userUpdated(let session):
                currentSession = session
                currentUser = session.user
                
            case .tokenRefreshed(let session):
                currentSession = session
                
            default:
                break
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The created user
    func signUp(email: String, password: String) async throws -> User {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            guard let user = response.user else {
                throw SupabaseError.invalidResponse
            }
            
            return user
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated session
    func signIn(email: String, password: String) async throws -> Session {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            return session
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Get the current authenticated user
    /// - Returns: The current user or nil if not authenticated
    func getCurrentUser() async throws -> User? {
        do {
            let user = try await client.auth.user()
            return user
        } catch {
            // User not authenticated
            return nil
        }
    }
    
    /// Refresh the current session
    /// - Returns: The refreshed session
    func refreshSession() async throws -> Session {
        do {
            let session = try await client.auth.refreshSession()
            return session
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Profile Methods
    
    /// Fetch the current user's profile
    /// - Returns: User profile or nil if not found
    func fetchCurrentUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let profile: UserProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            return profile
        } catch {
            if error.localizedDescription.contains("404") {
                return nil
            }
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Create or update a user profile
    /// - Parameter profile: Profile to upsert
    /// - Returns: The created/updated profile
    func upsertProfile(_ profile: UserProfile) async throws -> UserProfile {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let updatedProfile: UserProfile = try await client
                .from("profiles")
                .upsert(profile)
                .select()
                .single()
                .execute()
                .value
            
            return updatedProfile
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Internal Access
    
    /// Provides access to the underlying Supabase client for advanced operations
    /// Use sparingly - prefer adding methods to this service instead
    var supabaseClient: SupabaseClient {
        client
    }
}
