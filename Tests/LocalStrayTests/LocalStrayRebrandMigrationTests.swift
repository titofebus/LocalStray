import Foundation
import Testing

@testable import LocalStray

@Suite("Local Stray rebrand migration")
struct LocalStrayRebrandMigrationTests {
    @Test("Legacy state imports once without replacing Local Stray data")
    func importsLegacyStateWithoutOverwritingCurrentState() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "LocalStrayRebrandMigration-\(UUID().uuidString)",
            isDirectory: true
        )
        let legacyDirectory = root.appendingPathComponent("QwenPrime", isDirectory: true)
        let currentDirectory = root.appendingPathComponent("LocalStray", isDirectory: true)
        let legacySandbox = root.appendingPathComponent("prime-sandbox", isDirectory: true)
        let currentSandbox = root.appendingPathComponent("local-stray-sandbox", isDirectory: true)
        let legacySuiteName = "LegacyQwenPrime-\(UUID().uuidString)"
        let currentSuiteName = "LocalStray-\(UUID().uuidString)"
        let legacyDefaults = try #require(UserDefaults(suiteName: legacySuiteName))
        let currentDefaults = try #require(UserDefaults(suiteName: currentSuiteName))
        defer {
            legacyDefaults.removePersistentDomain(forName: legacySuiteName)
            currentDefaults.removePersistentDomain(forName: currentSuiteName)
            try? FileManager.default.removeItem(at: root)
        }

        legacyDefaults.set("legacy preferences", forKey: AppPersistenceKey.appPreferences.rawValue)
        legacyDefaults.set("legacy endpoint", forKey: AppPersistenceKey.mcpServerEndpoint.rawValue)
        currentDefaults.set("current endpoint", forKey: AppPersistenceKey.mcpServerEndpoint.rawValue)

        let legacyConversation = legacyDirectory
            .appendingPathComponent("conversations", isDirectory: true)
            .appendingPathComponent("legacy.json")
        let legacyRuntime = legacyDirectory.appendingPathComponent("runtime.json")
        let legacySkill = legacyDirectory
            .appendingPathComponent("skills", isDirectory: true)
            .appendingPathComponent("legacy-skill", isDirectory: true)
            .appendingPathComponent("SKILL.md")
        let legacySandboxFile = legacySandbox.appendingPathComponent("legacy.txt")
        let legacySandboxNestedFile = legacySandbox
            .appendingPathComponent("shared", isDirectory: true)
            .appendingPathComponent("legacy.txt")
        let currentSandboxFile = currentSandbox
            .appendingPathComponent("shared", isDirectory: true)
            .appendingPathComponent("current.txt")
        try FileManager.default.createDirectory(
            at: legacyConversation.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: legacySkill.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: legacySandboxNestedFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: currentSandboxFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("legacy conversation".utf8).write(to: legacyConversation)
        try Data("legacy runtime".utf8).write(to: legacyRuntime)
        try Data("legacy skill".utf8).write(to: legacySkill)
        try Data("legacy sandbox".utf8).write(to: legacySandboxFile)
        try Data("legacy nested sandbox".utf8).write(to: legacySandboxNestedFile)
        try Data("current sandbox".utf8).write(to: currentSandboxFile)
        let legacySkillID = "user:\(legacySkill.path)"
        let legacyWorkspaceSkillID = "workspace:/tmp/prime-sandbox/.qwenprime/skills/legacy/SKILL.md"
        legacyDefaults.set(
            [legacySkillID, legacyWorkspaceSkillID],
            forKey: AppPersistenceKey.enabledAgentSkillIDs.rawValue
        )

        try LocalStrayRebrandMigration.migrateIfNeeded(
            userDefaults: currentDefaults,
            legacyUserDefaults: legacyDefaults,
            legacyApplicationSupportDirectory: legacyDirectory,
            applicationSupportDirectory: currentDirectory,
            legacySandboxDirectory: legacySandbox,
            sandboxDirectory: currentSandbox
        )

        #expect(
            currentDefaults.string(forKey: AppPersistenceKey.appPreferences.rawValue)
                == "legacy preferences"
        )
        #expect(
            currentDefaults.string(forKey: AppPersistenceKey.mcpServerEndpoint.rawValue)
                == "current endpoint"
        )
        #expect(
            FileManager.default.fileExists(
                atPath: currentDirectory
                    .appendingPathComponent("conversations/legacy.json").path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: currentDirectory.appendingPathComponent("runtime.json").path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: currentDirectory
                    .appendingPathComponent("skills/legacy-skill/SKILL.md").path
            )
        )
        #expect(FileManager.default.fileExists(atPath: legacyConversation.path))
        #expect(
            currentDefaults.stringArray(
                forKey: AppPersistenceKey.enabledAgentSkillIDs.rawValue
            ) == [
                "user:\(currentDirectory.appendingPathComponent("skills/legacy-skill/SKILL.md").path)",
                legacyWorkspaceSkillID
            ]
        )
        #expect(
            try String(contentsOf: currentSandbox.appendingPathComponent("legacy.txt"))
                == "legacy sandbox"
        )
        #expect(
            try String(contentsOf: currentSandbox.appendingPathComponent("shared/legacy.txt"))
                == "legacy nested sandbox"
        )
        #expect(
            try String(contentsOf: currentSandboxFile) == "current sandbox"
        )
        #expect(FileManager.default.fileExists(atPath: legacySandboxFile.path))

        try LocalStrayRebrandMigration.migrateIfNeeded(
            userDefaults: currentDefaults,
            legacyUserDefaults: legacyDefaults,
            legacyApplicationSupportDirectory: legacyDirectory,
            applicationSupportDirectory: currentDirectory,
            legacySandboxDirectory: legacySandbox,
            sandboxDirectory: currentSandbox
        )

        #expect(
            currentDefaults.string(forKey: AppPersistenceKey.mcpServerEndpoint.rawValue)
                == "current endpoint"
        )
    }
}
