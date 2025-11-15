# Technical Debt Management & Quality Assurance Guidelines

## 1. Purpose  
This document prescribes the standards and processes to **prevent, manage and reduce technical debt** in our codebase. Any code change, whether produced by human or AI agent, must comply with these guidelines. The goal is to keep the system maintainable, testable, and robust.

## 2. Scope  
These guidelines apply to all parts of the codebase (backend Edge Functions, database schema, SwiftUI client, shared libraries). Each change must consider documentation, linting, testing, code review, and refactoring.

## 3. Mandatory Checks Before Merge  
For every pull request (or commit) the following must be validated:

| Check | Description |
|-------|-------------|
| Documentation Reviewed | ✅ The agent must read relevant official documentation (e.g., library/SDK docs) before writing code. |
| Static Analysis / Linting | ✅ Run linting tools (ESLint/TS, SwiftLint) and fix **all warnings** (except explicitly justified). |
| Type Safety & Typing | ✅ No use of `any` (TS) or force-unwraps (Swift) unless intentionally justified and commented. |
| Code Style & Conventions | ✅ Conform to project style guides (naming, file structure, layers). |
| Unit / Integration Tests | ✅ All new logic must include tests covering positive & negative paths. |
| Code Review | ✅ At least one peer (human) or designated agent must review the change. |
| Refactoring Consideration | ✅ If the change touches old code or “smelly” logic, refactor as part of the change or create a refactoring ticket. |
| Performance & Impact | ✅ Check for potential performance/dependency issues, ensure no unintended coupling. |

## 4. Documentation & Knowledge  
- Before implementing any new feature or module, **read the official documentation** of all libraries, frameworks, SDKs you will use.  
- Document **why** you chose an approach, not just **what** you implemented.  
- Maintain and update the architecture/design/integration docs when changes are made.  
- Technical debt often accumulates via missing or outdated docs (“documentation debt”).  [oai_citation:0‡Mendix](https://www.mendix.com/blog/what-is-technical-debt/?utm_source=chatgpt.com)  
- Use inline comments only to explain **why** something is done, not **what** (code should speak the “what”).

## 5. Testing Requirements  
- **Unit tests** must cover each public method, service, model transformation.  
- **Integration tests** must verify interactions (e.g., Edge Function → Supabase DB).  
- Test suites must run in CI and pass before merge.  
- Writing tests first (TDD) is encouraged: write the test defining expected behaviour, then implement code.  [oai_citation:1‡Wikipedia](https://en.wikipedia.org/wiki/Test-driven_development?utm_source=chatgpt.com)  
- Code changes must not decrease overall test coverage; any drop > 2% must come with valid reason and ticket to restore.  
- Tests should simulate edge error conditions, timeouts, invalid inputs.  

## 6. Linting & Static Analysis  
- Use ESLint + Prettier (TypeScript) and SwiftLint + SwiftFormat (Swift) with strict rules enabled.  
- No suppression of linting warnings without explicit justification (comment and ticket).  
- Static analysis tools help identify “code smells” & potential technical debt early.  [oai_citation:2‡vFunction](https://vfunction.com/blog/how-to-reduce-technical-debt/?utm_source=chatgpt.com)  
- Integrate lint check into CI as **blocking** step.

## 7. Refactoring & Clean-Code Practices  
- If a file/function is > 250 lines, or has > 3 responsibilities, split it.  
- Avoid duplicate logic; extract reusable utilities/services.  
- Naming must be descriptive and consistent.  
- Avoid “god objects” or over-coupling.  
- If you encounter “temporary workaround”, mark it via a ticket or comment “// TECH-DEBT: reason, ticket #”.  
- Refactoring is not optional—it is a scheduled part of development and debt repayment.  [oai_citation:3‡aviator.co](https://www.aviator.co/blog/technical-debt-and-the-role-of-refactoring/?utm_source=chatgpt.com)

## 8. Build & CI/CD Quality Gates  
- Every commit should trigger: build → lint → test → coverage → deployment (if applicable).  
- If any gate fails, the PR is blocked until fixed.  
- Add metrics to monitor: build time, test failures, code churn, hotspots.  
- Metrics help prioritize what tech-debt to pay down.  [oai_citation:4‡vFunction](https://vfunction.com/blog/how-to-reduce-technical-debt/?utm_source=chatgpt.com)

## 9. Prioritising Technical Debt  
- Treat tech-debt items as first-class backlog tasks.  
- Use the “pay interest” metaphor: if adding a feature becomes harder, it’s a signal to reduce debt.  [oai_citation:5‡vFunction](https://vfunction.com/blog/how-to-reduce-technical-debt/?utm_source=chatgpt.com)  
- At planning, allocate 10-20% of capacity for refactoring/cleanup.  
- Use criteria: risk, impact, effort to prioritise debt tasks.  [oai_citation:6‡XB Software](https://xbsoftware.com/blog/technical-debt-management-plan/?utm_source=chatgpt.com)  
- Document **intentional technical debt** (trade-offs made knowingly) and schedule its remediation.

## 10. Agent / AI-Coding Agent Instructions  
When you (the agent) write code or assist writing code, follow this checklist:

1. **Read documentation**: Before coding, fetch and summarise key points from the library/SDK docs.  
2. **Generate typed interfaces**: Use strict types/interfaces, no `any`.  
3. **Write test skeleton first**: Create test file describing expected behaviour.  
4. **Implement feature**: Write minimal code to satisfy test.  
5. **Refactor**: Clean up design, extract common logic if needed.  
6. **Run linters & tests**: Ensure no warnings, all tests pass.  
7. **Add documentation**: Update README/ABOUT-PROJECT/architecture docs if changed.  
8. **Mark any debt items**: If you make a shortcut (temporarily), annotate with `// TECH-DEBT` and file a ticket.  
9. **Submit for review**: Create PR, include checklist of checks above, mention impact on coverage.  
10. **Learn from reviews**: If reviewer finds issue, update code and tests accordingly.

## 11. Metrics to Monitor  
- Code coverage % (unit + integration)  
- Lint warnings/errors per commit  
- Issue backlog size for “TECH-DEBT” labelled tickets  
- Time spent on refactoring tasks vs new features  
- Cycle time for feature delivery (should not grow)  
- Build failure rate / rework rate  

## 12. Conclusion  
Technical debt is inevitable, but manageable. By institutionalising these practices and making quality non-negotiable, we protect the product’s longevity, maintainability, and the team’s velocity.  
Let’s build fast, but build to last.