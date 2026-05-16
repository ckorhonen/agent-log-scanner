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
