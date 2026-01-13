import Foundation

actor CodexAnalyzer {
    private let systemPrompt = """
    You are an expert at analyzing Claude Code sessions to extract learnings that improve future agent performance. You will receive:

    1. A conversation transcript between a human and Claude Code
    2. A summary of tool usage (tools called, success/failure)
    3. The current CLAUDE.md files (project-level and global)

    Your task is to identify actionable improvements and output them as discrete, atomic suggestions.

    ## Analysis Focus Areas

    ### 1. User Preferences
    - Communication style preferences (brevity, detail level, formatting)
    - Workflow preferences (ask first vs. act, verification steps)
    - Technology preferences (languages, frameworks, tools)

    ### 2. Workflow Patterns
    - Successful patterns that should be documented
    - Multi-step processes that worked well
    - Approval/confirmation patterns the user expects

    ### 3. Tool Inefficiencies
    - Tools called incorrectly (wrong parameters, wrong tool for job)
    - Repeated tool calls that could have been batched
    - Failed tool calls due to predictable issues
    - Tools that should have been used but weren't
    - Unnecessary tool calls (redundant reads, excessive searches)

    ### 4. Error Prevention
    - Mistakes made that could be prevented with a rule
    - Assumptions that led to errors
    - Edge cases that should be documented

    ### 5. Knowledge Gaps
    - Information the agent lacked that caused issues
    - Project-specific context that should be in CLAUDE.md
    - Conventions or patterns unique to this codebase

    ### 6. Skill/Agent Opportunities
    - Repetitive tasks that could be automated with a Claude Code skill
    - Complex multi-step workflows that would benefit from a dedicated agent
    - Domain-specific operations that need specialized handling
    - Tasks requiring external tool integration

    ## Output Format

    Return ONLY a JSON array of suggestions (no markdown, no explanation):

    [
      {
        "category": "preference|workflow|tool-usage|error-prevention|knowledge|skill",
        "target": "project|global",
        "suggestion": "The exact text to add to CLAUDE.md OR skill/agent definition",
        "reasoning": "Brief explanation of why this helps",
        "evidence": "Quote or reference from the session"
      }
    ]

    For skill suggestions, use category "skill" and include a complete skill definition in the suggestion field:
    - Skill name and description
    - When to trigger the skill
    - What the skill should do
    - Example prompts or commands

    ## Guidelines

    - Each suggestion should be self-contained and atomic
    - Write suggestions as instructions/rules, not observations
    - Prefer specific, actionable guidance over general advice
    - Don't duplicate rules already in the CLAUDE.md files
    - Prioritize suggestions that prevent repeated mistakes
    - For tool inefficiencies, write rules that prevent the specific mistake
    - For skills, only suggest when there's a clear pattern of repeated complex tasks
    - Return an empty array [] if no meaningful suggestions can be made
    """

    func analyze(session: Session, globalCLAUDEMD: String?, projectCLAUDEMD: String?) async throws -> [AnalysisSuggestion] {
        let transcript = buildTranscript(from: session)
        let toolSummary = buildToolSummary(from: session)

        let userPrompt = """
        ## Session Transcript

        \(transcript)

        ## Tool Usage Summary

        \(toolSummary)

        ## Current Project CLAUDE.md

        \(projectCLAUDEMD ?? "(No project CLAUDE.md found)")

        ## Current Global CLAUDE.md

        \(globalCLAUDEMD ?? "(No global CLAUDE.md found)")

        ---

        Analyze this session and provide suggestions to improve future Claude Code performance.
        """

        let response = try await invokeCodexCLI(systemPrompt: systemPrompt, userPrompt: userPrompt)
        return try parseSuggestions(from: response)
    }

    private func buildTranscript(from session: Session) -> String {
        var lines: [String] = []

        for message in session.messages {
            let role = message.role == .user ? "Human" : "Assistant"
            let text = message.textContent

            if !text.isEmpty {
                lines.append("[\(role)]")
                lines.append(text)
                lines.append("")
            }

            // Include tool call names without full payloads
            for tool in message.toolCalls {
                lines.append("[Tool: \(tool.name)]")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func buildToolSummary(from session: Session) -> String {
        var toolCounts: [String: Int] = [:]
        var errorTools: [String] = []

        for message in session.messages {
            for block in message.content {
                if case .toolUse(let tool) = block {
                    toolCounts[tool.name, default: 0] += 1
                }
                if case .toolResult(let result) = block {
                    if result.isError {
                        errorTools.append(result.toolUseId)
                    }
                }
            }
        }

        var lines: [String] = ["Tool calls by name:"]
        for (name, count) in toolCounts.sorted(by: { $0.value > $1.value }) {
            lines.append("- \(name): \(count)")
        }

        if !errorTools.isEmpty {
            lines.append("")
            lines.append("Failed tool calls: \(errorTools.count)")
        }

        return lines.joined(separator: "\n")
    }

    private func findCodexCLI() -> String? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path

        // Check common locations for codex
        let possiblePaths = [
            "\(home)/.local/bin/codex",
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex"
        ]

        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }

        // Check if installed via npm globally
        let npmGlobalPath = "\(home)/.npm-global/bin/codex"
        if fileManager.fileExists(atPath: npmGlobalPath) {
            return npmGlobalPath
        }

        // Check nvm versions
        let nvmVersionsPath = "\(home)/.nvm/versions/node"
        if let nvmVersions = try? fileManager.contentsOfDirectory(atPath: nvmVersionsPath) {
            for version in nvmVersions.sorted().reversed() {
                let codexPath = "\(nvmVersionsPath)/\(version)/bin/codex"
                if fileManager.fileExists(atPath: codexPath) {
                    return codexPath
                }
            }
        }

        return nil
    }

    private func invokeCodexCLI(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let codexPath = findCodexCLI() else {
            throw AnalysisError.cliError("Codex CLI not found. Install with: npm install -g @openai/codex")
        }

        // Create a temporary file for the prompt (to handle large prompts)
        let tempDir = FileManager.default.temporaryDirectory
        let promptFile = tempDir.appendingPathComponent("codex-prompt-\(UUID().uuidString).txt")

        let fullPrompt = """
        <system>
        \(systemPrompt)
        </system>

        \(userPrompt)
        """

        try fullPrompt.write(to: promptFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: promptFile) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: codexPath)

        // Use 'exec' subcommand for non-interactive use with GPT-5.2 and high reasoning effort
        process.arguments = [
            "exec",
            "--skip-git-repo-check",
            "-m", "gpt-5.2",
            "-c", "model_reasoning_effort=\"high\"",
            try String(contentsOf: promptFile, encoding: .utf8)
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw AnalysisError.cliError(errorString)
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw AnalysisError.invalidResponse
        }

        return output
    }

    private func parseSuggestions(from response: String) throws -> [AnalysisSuggestion] {
        // Find JSON array in response (model might include some text before/after)
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract JSON array from the response
        if let startIndex = jsonString.firstIndex(of: "["),
           let endIndex = jsonString.lastIndex(of: "]") {
            jsonString = String(jsonString[startIndex...endIndex])
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw AnalysisError.invalidResponse
        }

        do {
            let suggestions = try JSONDecoder().decode([AnalysisSuggestion].self, from: data)
            return suggestions
        } catch {
            print("Failed to parse suggestions: \(error)")
            print("Response was: \(response)")
            throw AnalysisError.parseError(error.localizedDescription)
        }
    }
}
