# Agent Instructions

## Project Facts

Agent Log Scanner is a macOS SwiftUI app for browsing Claude Code session logs, viewing transcripts, and running Cloudflare Gateway/OpenAI or Claude analysis over sessions. The Xcode project is generated from `project.yml` with XcodeGen.

## Commands

- `xcodegen generate`: generate `AgentLogScanner.xcodeproj` from `project.yml`.
- `xcodebuild -scheme AgentLogScanner -configuration Release build`: build after generating the project.
- `xcodebuild -scheme AgentLogScanner test`: run the unit and UI test schemes after generating the project.
- `open AgentLogScanner.xcodeproj`: open the generated project in Xcode.

## Repository Map

- `Sources/App/`: app entry point and global state.
- `Sources/Models/`: session, message, analysis, and provider models.
- `Sources/Services/`: session parsing, Cloudflare Gateway/OpenAI and Claude analyzers, and persistence.
- `Sources/Views/`: SwiftUI views.
- `Tests/` and `UITests/`: generated-project test targets.

## Agent Workflow

- Run `xcodegen generate` before using Xcode or `xcodebuild` if `AgentLogScanner.xcodeproj` is missing or stale.
- Keep analysis-provider behavior explicit; this app writes suggestions back to agent instruction files.
- Treat session logs as potentially sensitive and avoid copying raw transcript content into durable docs unless requested.

## Validation and privacy boundaries

Use the checked-in `project.yml` as the XcodeGen source. It specifies Swift 5.9, Xcode 15-era tooling, and macOS 14. Generate the project when missing or stale, and regenerate after project structure/settings changes; inspect the generated project diff. The existing Xcode build/test commands cover unit and UI targets; narrow tests to the affected case first, then run the relevant target. No separate lint command is defined.

This application reads agent session logs and can call providers or apply instruction changes. Test parsing and UI against synthetic fixtures and disposable directories; launching it against a real home directory is not an inert smoke test. Do not inspect private sessions, expose log content, call providers, or apply global instruction updates solely to validate an unrelated change.

For Markdown-only work, check paths/links and `git diff --check -- <changed-paths>`. Finish authorized code changes through relevant tests and inspection, reporting any precise toolchain/runtime blocker and the remaining unverified behavior. Build success alone does not prove log correctness, provider behavior, or safe application of updates.

Complete the authorized change through relevant verification and repair of introduced failures. Resolve routine implementation choices directly; ask only for information or decisions that materially affect the result. If blocked, name the affected action and missing prerequisite, continue independent work, and close with changed paths, checks actually run, and unverified behavior.
