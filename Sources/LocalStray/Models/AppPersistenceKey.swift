import Foundation

/// Keys persisted in the application preferences domain.
public enum AppPersistenceKey: String, CaseIterable, Sendable {
    case appPreferences = "appPreferences.v1"
    case autoScroll
    case customPromptPresets
    case defaultAgentModeEnabled
    case defaultSystemPrompt
    case defaultThinkingEnabled
    case enabledAgentSkillIDs
    case expandThinkingByDefault
    case isAgentPreviewEnabled
    case isMCPServerEnabled
    case isWorkspaceInstructionsEnabled
    case mcpServerDisplayName
    case mcpServerEndpoint
    case mcpServerProfiles
    case workspaceSecurityScopedBookmarks

    /// Carries user-owned state forward only when Local Stray has no value yet.
    static let rebrandMigratable: [Self] = [
        .appPreferences,
        .autoScroll,
        .customPromptPresets,
        .defaultAgentModeEnabled,
        .defaultSystemPrompt,
        .defaultThinkingEnabled,
        .expandThinkingByDefault,
        .isAgentPreviewEnabled,
        .isMCPServerEnabled,
        .isWorkspaceInstructionsEnabled,
        .mcpServerDisplayName,
        .mcpServerEndpoint,
        .mcpServerProfiles,
        .workspaceSecurityScopedBookmarks
    ]
}
