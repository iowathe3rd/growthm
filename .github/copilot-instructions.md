x# AI Coding Agent Instructions for GrowthMap AI

## Project Overview
GrowthMap AI is a goal-tracking iOS app that uses AI to break down user goals into skill trees and weekly sprints. The architecture is **iOS (SwiftUI) + Supabase backend (Edge Functions + PostgreSQL)**.

**Current Status**: Early development - boilerplate iOS app exists, Supabase config initialized, but core features (models, services, views) not yet implemented. You're building the MVP from scratch following strict architectural guidelines.

## Architecture & Technology Stack

### iOS Client (Swift 5.0, SwiftUI)
- **Pattern**: Strict MVVM architecture
  - Models: Data structures mirroring backend types (in `Models/`)
  - Services: Network/Supabase interaction layer (in `Services/`)
  - ViewModels: `ObservableObject` classes with `@Published` properties (in `ViewModels/`)
  - Views: Pure SwiftUI UI, minimal logic (in `Views/`)
- **Storage**: SwiftData for local caching (currently using placeholder `Item` model)
- **Navigation**: Native SwiftUI navigation (NavigationSplitView/NavigationStack)
- **Design System**: "Liquid Glass" style using `.ultraThinMaterial`, 44pt minimum touch targets, Apple HIG compliant

### Backend (Supabase)
- **Database**: PostgreSQL with Row Level Security (RLS) enforced on all tables
- **Auth**: Supabase Auth with JWT verification in Edge Functions
- **Edge Functions**: Deno-based TypeScript functions for AI logic (not yet implemented)
  - `create-growth-map` - Generates skill tree from user goal
  - `regenerate-sprint` - Adapts weekly tasks based on progress
  - `growth-report` - Progress reports
- **AI Integration**: OpenAI API calls from Edge Functions (see `supabase/config.toml` for OpenAI key config)

### Project Structure (Target State)
```
Growth Map/
├── Models/           # Goal.swift, SkillTree.swift, Sprint.swift, SprintTask.swift, UserProfile.swift
├── Services/         # SupabaseService.swift, GrowthMapAPI.swift
├── ViewModels/       # Per-screen ViewModels (e.g., OnboardingViewModel.swift)
├── Views/            # SwiftUI views + Views/Shared/Components/ for reusable UI
├── Style/            # Colors.swift, Typography.swift, LayoutConstants.swift
└── Utils/            # Extensions, helpers

supabase/
├── functions/
│   ├── _shared/     # types.ts, supabaseAdmin.ts, llmClient.ts, errorHandler.ts
│   ├── create-growth-map/
│   ├── regenerate-sprint/
│   └── growth-report/
└── migrations/       # SQL migration files
```

**Current Reality**: Only boilerplate files exist (`Growth_MapApp.swift`, `ContentView.swift`, `Item.swift`). Create structure as you implement features.

## Critical Coding Rules

### Swift/iOS Code
1. **No Force Unwraps**: Never use `!` - use `guard let` or `if let` with clear error handling
2. **Dependency Injection**: ViewModels receive Services via initializer for testability
3. **Async/Await**: All network calls use `async/await` with `do-catch` error handling
4. **SwiftLint/SwiftFormat**: Run before committing (configure with project rules)
5. **Accessibility**: Every interactive element needs `.accessibilityLabel()` and `.accessibilityHint()`
6. **No Hardcoded Values**: Import colors/sizes from `Style/` files

**ViewModel Pattern Example**:
```swift
@MainActor
class GoalsListViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService: SupabaseService
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }
    
    func loadGoals() async {
        isLoading = true
        do {
            goals = try await supabaseService.fetchGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

### TypeScript/Edge Functions Code
1. **Strict Typing**: No `any` - define interfaces in `_shared/types.ts`
2. **JWT Verification**: Every Edge Function must verify auth before business logic
3. **Service Role Key**: Only use in Edge Functions, NEVER expose to client
4. **Error Handling**: Use centralized `errorHandler.ts`, return `{ error: string }` JSON
5. **Function Naming**: Use kebab-case (e.g., `create-growth-map/`)
6. **Read Docs First**: Always consult official library docs before implementing (see GLOBALS.md §4)

**Edge Function Template**:
```typescript
import { serve } from "https://deno.land/std/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";
import type { GoalInput, SkillTreeOutput } from "../_shared/types.ts";

serve(async (req) => {
  try {
    // Verify JWT from Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Missing auth");
    
    const body: GoalInput = await req.json();
    // Business logic...
    const result: SkillTreeOutput = await generateSkillTree(body);
    
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  } catch (err) {
    return errorHandler(err);
  }
});
```

## Database Schema (Reference)
Key tables to implement in migrations:
- `profiles` - User profiles (links to Supabase Auth)
- `goals` - User goals (title, description, horizon_months, daily_minutes)
- `skill_trees` - JSON tree of skills per goal
- `sprints` - Weekly sprint iterations
- `sprint_tasks` - Individual tasks with completion status
- `progress_logs` - Historical progress tracking

**RLS Policy**: Every table must have policies enforcing `user_id = auth.uid()` for read/write.

## Development Workflow

### Local Development
1. **Supabase**: Run `supabase start` in project root (requires Docker)
2. **iOS**: Open `Growth Map.xcodeproj` in Xcode, build to simulator
3. **Tests**: Run XCTest suite via Xcode (Cmd+U) - write tests for ViewModels and Services
4. **Linting**: Run SwiftLint/SwiftFormat before commits

### Before Every PR/Commit
See `docs/GLOBALS.md` §3 for mandatory checklist:
- ✅ Read official documentation for new libraries
- ✅ No linting warnings (unless justified with `// TECH-DEBT:` comment)
- ✅ Strict typing (no `any` in TS, no force unwraps in Swift)
- ✅ Tests written for new logic (TDD encouraged)
- ✅ RLS policies updated if schema changes
- ✅ Update architecture docs if structure changes

## Design System Implementation

### Liquid Glass Visual Style
- Use `.ultraThinMaterial` or `.regularMaterial` for card backgrounds
- Rounded corners: 12-16pt radius
- Soft shadows with `.shadow(color: .black.opacity(0.1), radius: 8)`
- Minimal accent colors (primary: cyan/green)
- Typography hierarchy: `.title`, `.headline`, `.body` from `Typography.swift`
- Animations: Use `.transition(.opacity.combined(with: .move(edge: .bottom)))` for smooth transitions

**Example CardView Component**:
```swift
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}
```

## Data Models (TypeScript ↔ Swift Mapping)

Both platforms must use identical structures. Example:

**TypeScript** (`_shared/types.ts`):
```typescript
export interface Goal {
  id: string;
  user_id: string;
  title: string;
  description: string;
  horizon_months: number;
  daily_minutes: number;
  created_at: string; // ISO timestamp
}
```

**Swift** (`Models/Goal.swift`):
```swift
struct Goal: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let description: String
    let horizonMonths: Int
    let dailyMinutes: Int
    let createdAt: Date // Use DateFormatter with ISO8601
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case userId = "user_id"
        case horizonMonths = "horizon_months"
        case dailyMinutes = "daily_minutes"
        case createdAt = "created_at"
    }
}
```

## Key Implementation Notes

1. **Supabase Client Init**: Store API keys in Xcode environment variables or `.xcconfig` files, never commit
2. **Error Messages**: User-facing errors should be localized and helpful (not raw technical messages)
3. **Loading States**: Always show loading indicators during async operations
4. **Empty States**: Design empty state views for lists (e.g., "No goals yet - create your first one!")
5. **Tech Debt**: Mark shortcuts with `// TECH-DEBT: [reason], ticket #XXX` and file tracking issue

## Testing Strategy
- **Unit Tests**: ViewModels (mock Services), utility functions
- **Integration Tests**: Edge Functions (test against local Supabase)
- **UI Tests**: Critical user flows (onboarding, goal creation, task completion)
- **Coverage Target**: >80% for new code (see GLOBALS.md §11)

## Reference Documentation
- **Swift Guidelines**: See `docs/IOS-RULES.md` for detailed iOS patterns
- **Backend Guidelines**: See `docs/CODE-INSTRUCTION.md` for TypeScript/Supabase rules
- **Quality Standards**: See `docs/GLOBALS.md` for technical debt management
- **Project Vision**: See `docs/ABOUT.md` for product context

## Common Pitfalls to Avoid
1. ❌ Using service_role key in iOS app (security risk)
2. ❌ Skipping RLS policies on new tables
3. ❌ Force unwrapping optionals in Swift
4. ❌ Using `any` type in TypeScript
5. ❌ Hardcoding UI values instead of using Style/ constants
6. ❌ Implementing features without reading library docs first
7. ❌ Forgetting to add accessibility labels
8. ❌ Not writing tests for new logic

## When Starting New Work
1. Check if Models/Services/ViewModels already exist for the feature
2. If creating new files, follow the directory structure above
3. Read relevant sections of `docs/` for guidelines
4. Write interface/model definitions first (TypeScript + Swift)
5. Implement Service layer with proper error handling
6. Create ViewModel with @Published properties
7. Build SwiftUI View using Design System components
8. Write tests before marking feature complete
9. Run linters and validate against GLOBALS.md checklist

---

**Remember**: This is a quality-first project. Velocity is important, but not at the cost of maintainability. Follow TDD, document decisions, and refactor as you go. When in doubt, consult the docs/ folder.
