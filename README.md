# Agent Log Scanner

A macOS app for introspecting Claude Code sessions. Browse, search, and analyze your Claude Code conversations to extract learnings and improve future agent performance.

## Features

- **Session Browser**: Navigate all your Claude Code sessions from `~/.claude/projects/`
- **Conversation Viewer**: Read full conversation transcripts with tool calls and results
- **Statistics Dashboard**: View message counts, tool usage breakdown, session duration, and errors
- **AI-Powered Analysis**: Analyze sessions using Codex (GPT-5.2) or Claude to get actionable suggestions
- **CLAUDE.md Integration**: Apply suggestions directly to your project or global CLAUDE.md files
- **Analysis Persistence**: Saved analyses reload automatically when revisiting sessions

## Requirements

- macOS 14.0+
- Xcode 15.0+ (for building)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

### For Analysis Features

One or both of:
- **Codex CLI** (default): `npm install -g @openai/codex`
- **Claude CLI**: Install from [Claude Code](https://claude.ai/code)

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/ckorhonen/agent-log-scanner.git
cd agent-log-scanner

# Generate Xcode project
xcodegen generate

# Build and run
xcodebuild -scheme AgentLogScanner -configuration Release build

# Or open in Xcode
open AgentLogScanner.xcodeproj
```

## Usage

1. Launch the app
2. Browse sessions in the sidebar (sorted by most recent)
3. Filter by project using the dropdown
4. Click a session to view the full conversation
5. Click the "Analyze" button to get AI-powered suggestions
6. Use the dropdown to switch between Codex and Claude for analysis
7. Apply suggestions to your CLAUDE.md files with one click

## Architecture

```
Sources/
├── App/
│   ├── AgentLogScannerApp.swift    # App entry point
│   └── AppState.swift              # Global state management
├── Models/
│   ├── Session.swift               # Session data models
│   ├── Message.swift               # Message and content blocks
│   ├── AnalysisSuggestion.swift    # Analysis result models
│   └── AnalysisProvider.swift      # Provider enum (Codex/Claude)
├── Services/
│   ├── SessionStore.swift          # Session discovery and parsing
│   ├── ClaudeAnalyzer.swift        # Claude CLI integration
│   ├── CodexAnalyzer.swift         # Codex CLI integration
│   ├── CLAUDEMDManager.swift       # CLAUDE.md file operations
│   └── AnalysisStore.swift         # Analysis persistence
└── Views/
    ├── Sidebar/                    # Session list and filtering
    ├── Detail/                     # Conversation viewer
    └── Analysis/                   # Analysis results UI
```

## Development

### Running Tests

```bash
# Run all tests
xcodebuild -scheme AgentLogScanner test

# Run only unit tests
xcodebuild -scheme AgentLogScanner test -only-testing:AgentLogScannerTests

# Run only UI tests
xcodebuild -scheme AgentLogScanner test -only-testing:AgentLogScannerUITests
```

### Regenerating Project

After modifying `project.yml`:

```bash
xcodegen generate
```

## Analysis Providers

### Codex (Default)

Uses OpenAI's GPT-5.2 with maximum reasoning effort (`xhigh`) for thorough analysis. Requires the Codex CLI and an OpenAI API key or ChatGPT subscription.

### Claude

Uses Claude's analysis capabilities via the Claude CLI. Requires Claude Code to be installed and authenticated.

Both providers use the same analysis prompt to identify:
- User preferences
- Workflow patterns
- Tool inefficiencies
- Error prevention opportunities
- Knowledge gaps

## License

MIT License

Copyright (c) 2025 Chris Korhonen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
