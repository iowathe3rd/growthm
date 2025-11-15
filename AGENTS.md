# Repository Guidelines

## Project Structure & Module Organization
The iOS client lives under the `Growth Map/` directory: `Growth_MapApp.swift` boots the SwiftUI scene, `ContentView.swift` is the placeholder UI, and the MVVM folders described in `docs/IOS-RULES.md` (Models, Services, ViewModels, Views, Style, Utils) keep layers separated. `supabase/` hosts the backend: `_shared/` capsuled helpers, individual edge-function folders (`create-growth-map`, `regenerate-sprint`, `growth-report`), and `migrations/` for SQL schema changes. Use `docs/` as the single source for architecture, coding, and onboarding guidance.

## Build, Test, and Development Commands
- `open Growth\ Map.xcodeproj` to launch Xcode and run the iOS target interactively.
- `xcodebuild -scheme "Growth Map" -destination 'platform=iOS Simulator,name=iPhone 15' build` to compile locally from the CLI.
- `xcodebuild -scheme "Growth Map" -destination 'platform=iOS Simulator,name=iPhone 15' test` to execute XCTest suites that live under the app’s `Tests/` directories.
- `supabase functions serve <function-name>` (from `supabase/functions/`) to smoke-test a function before deployment.
- `supabase functions deploy <function-name> --project-ref <ref>` to publish updates; the active `project-ref` sits in `supabase/config.toml`.

## Coding Style & Naming Conventions
Swift code follows MVVM, uses dependency injection into `ObservableObject` view models, avoids force unwraps, and sources constants from the `Style/` folder; run SwiftLint/SwiftFormat with the project rules (indentation=2, no unused imports) before committing. TypeScript edge functions rely on `_shared/types.ts`, strict typing (no `any`), centralized error handling, and kebab-case directories for each HTTP endpoint.

## Testing Guidelines
Write Swift tests with XCTest naming (`XxxTests`) alongside their targets (Services, ViewModels, Views). Future edge-function tests should mock Supabase/LLM clients, reuse `_shared` types, and run via `deno test --config supabase/functions/tsconfig.json`.

## Commit & Pull Request Guidelines
Match the concise, imperative style seen in history (`supabase init`, `Initial Commit`); mention the scope (`feat`, `fix`, etc.) and link issues. PRs need a descriptive summary, QA steps, linked issue(s), and screenshots when UI changes are visible.

## Backend & Configuration Tips
Keep secrets in environment variables and use only `_shared/supabaseAdmin.ts` for the service-role key; every request must verify the JWT per `docs/CODE-INSTRUCTION.md`. Enforce Row Level Security in migrations, document policy changes, and keep the `docs/` files current as decisions evolve.
