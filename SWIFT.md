# Swift Code Generation Guidelines for AI Agents

This document provides comprehensive guidelines to help AI agents generate high-quality, error-free Swift code that compiles and functions correctly.

## 1. Import Management

### 1.1 Framework Imports
- Always import required frameworks at the top of each file:
  - `import Foundation` - for basic types and functionality
  - `import Combine` - for `@Published`, `ObservableObject`, publishers, and subscribers
  - `import SwiftUI` - for UI elements and views
  - `import UIKit` - for UIKit components
  - `import CoreLocation` - for location services
  - `import AVFoundation` - for audio/video
  - `import CoreGraphics` - for graphics operations
  - `import Any third-party frameworks` used in the file

### 1.2 Import Order Convention
```
import Foundation          // Standard library
import Combine            // Reactive programming
import SwiftUI            // UI framework
import Supabase           // Third-party frameworks
import CustomModule       // Custom modules
```

### 1.3 Framework-Specific Requirements
- `@Published`, `@StateObject`, `@ObservedObject`, and `ObservableObject` require `import Combine`
- `@State`, `@Binding`, `View`, `NavigationView`, `List` require `import SwiftUI`
- `UIViewController`, `UIButton`, `UILabel` require `import UIKit`

## 2. Property Wrappers and Observability

### 2.1 ObservableObject Protocol
- Classes using `@Published` properties must conform to `ObservableObject` protocol
- Always add `import Combine` when using `ObservableObject`
- Example:
```swift
import Combine
import Foundation

final class MyService: ObservableObject {
    @Published var data: String = ""
}
```

### 2.2 @Published Properties
- Only declare `@Published` properties in classes that conform to `ObservableObject`
- Private properties with `@Published` won't be accessible from extensions
- Ensure `Combine` framework is imported

### 2.3 SwiftUI Property Wrappers
- `@State` for local view state (inside View structs)
- `@Binding` for two-way data binding between views
- `@EnvironmentObject` for shared objects across view hierarchy
- `@StateObject` for initializing observed objects (iOS 14+)
- `@ObservedObject` for injecting observed objects
- `@FetchRequest` for Core Data fetch requests

## 3. Asynchronous Programming

### 3.1 Async/Await Usage
- Only use `await` with functions marked as `async`
- Never use `await` with synchronous functions
- Properly chain async calls: `let result = try await asyncFunction()`
- Handle async calls in the correct context (inside async functions or with Task)

### 3.2 Error Handling
- Only use `try` with functions marked as `throws`
- Match throwing function calls with either `try`, `try?`, or `try!`
- Don't create empty `do-catch` blocks without throwing functions
- Use appropriate error handling patterns (`do-catch`, `try?`, `try!`)

### 3.3 Task Usage
```swift
// For creating async context
Task {
    await asyncFunction()
}

// For handling errors in async context
Task {
    do {
        try await throwingAsyncFunction()
    } catch {
        // Handle error
    }
}
```

## 4. Access Control and Scope

### 4.1 Property Accessibility
- Properties in extensions must have at least `internal` access to be available
- Private properties are not accessible in extensions
- Use `fileprivate` for file-level access
- Use `private` for type-level access

### 4.2 Extension Limitations
- Extensions cannot access private properties/methods of the extended type
- Properties needed in extensions should be `internal` (default) or more accessible
- Consider grouping related functionality in the main type instead of extensions when access is needed

## 5. Pattern Matching and Switch Statements

### 5.1 Correct Pattern Syntax
- Don't match error types against tuples or complex objects
- Use proper enum case syntax in switch statements
- Verify that all enum cases exist and match the expected type
- Example of correct pattern matching:
```swift
switch someValue {
case .caseName(let associatedValue):
    // Handle case
default:
    // Handle default
}
```

### 5.2 Supabase Auth State Changes
- Use correct syntax for auth state change events
- Don't try to match error types against auth change events
- Proper pattern matching for Supabase auth:
```swift
switch state {
case .signedIn(let session):
    // Handle signed in
case .signedOut:
    // Handle signed out
case .initialSession(let session):
    // Handle initial session
// ... other cases
}
```

## 6. Function Signatures and Parameters

### 6.1 Parameter Order
- Respect the order of parameters in function signatures
- For database clients, ensure correct parameter order (e.g., encoder before decoder in Supabase options)
- Double-check parameter labels match the function declaration

### 6.2 Return Types
- Ensure function return types are correctly specified
- Don't infer `()` return type unexpectedly
- Verify that functions return the expected type

## 7. Type Safety and Optionals

### 7.1 Optional Handling
- Use `if-let`, `guard-let` only with optional types
- Don't use conditional binding with non-optional values
- Understand the difference between optional and non-optional types

### 7.2 Type Inference
- Don't let Swift infer unexpected types (like `()` for functions)
- Explicitly specify types when inference might be incorrect
- Use type annotations to make intentions clear

## 8. Codable and JSON Handling

### 8.1 Codable Implementation
- Implement `CodingKeys` enum when property names don't match JSON keys
- Use correct `CodingKey` raw values (matching JSON structure)
- Handle optional properties with `decodeIfPresent`

### 8.2 JSON Decoding
- Use proper date formatters for date decoding
- Handle nested objects correctly
- Validate JSON structure matches Codable models

## 9. UI Development Patterns

### 9.1 SwiftUI Views
- Use `some View` as return type for view body
- Don't modify state directly in view body; use methods or actions
- Properly chain view modifiers with `.` notation
- Use appropriate lifecycle modifiers (`.onAppear`, `.onDisappear`)

### 9.2 State Management
- Use `@State` for simple local view state
- Use `@StateObject` for observed objects created in views
- Use `@ObservedObject` when object is passed to the view
- Use `@EnvironmentObject` for shared data across view hierarchy

## 10. Testing and Validation

### 10.1 Before Generating Code
- Verify all required imports are present
- Check property wrapper usage against protocol requirements
- Ensure async/await and try/catch usage is appropriate
- Validate access controls for extensions
- Confirm parameter order and function signatures

### 10.2 After Generating Code
- Verify the code compiles without errors
- Check that property wrappers have proper protocols
- Ensure all async operations are properly awaited
- Confirm error handling is appropriate
- Validate that all used types and functions exist

### 10.3 Common Error Prevention Checklist
- [ ] All needed imports are present
- [ ] ObservableObject protocol for classes with @Published
- [ ] Proper try/await usage with throwing/async functions
- [ ] Accessible properties for use in extensions
- [ ] Correct pattern matching syntax
- [ ] Correct parameter orders
- [ ] Proper handling of optional values
- [ ] Appropriate return types for functions
- [ ] Valid Codable implementations

## 11. Third-Party Libraries (Supabase Example)

### 11.1 API Usage
- Follow official documentation for method signatures
- Use correct parameter names and order
- Handle API response types properly
- Respect async/await patterns of the library

### 11.2 Error Handling
- Use library-specific error types appropriately
- Don't mix library error types with different contexts
- Follow library's recommended error handling patterns

## 12. Best Practices and Conventions

### 12.1 Naming Conventions
- Use Swift naming conventions (camelCase for properties/methods)
- Use PascalCase for types and enum cases
- Use descriptive names that clearly indicate purpose

### 12.2 Code Organization
- Group related functionality in appropriate extensions
- Use MARK comments to organize code sections
- Follow logical file organization patterns

### 12.3 Documentation
- Include documentation comments for public interfaces
- Use doc comment format with parameters and returns
- Keep documentation up-to-date with implementation changes

Following these guidelines will help AI agents generate Swift code that is syntactically correct, follows best practices, and compiles without common errors.