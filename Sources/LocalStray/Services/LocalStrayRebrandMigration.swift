import Foundation

/// Imports Qwen Prime user data once without modifying the original files.
public enum LocalStrayRebrandMigration {
    public static let legacyBundleIdentifier = "app.dech.qwenprime"

    private static let migrationMarker = "localStrayRebrandMigration.v1"
    private static let migratedRelativePaths = [
        "conversations",
        "runtime.json",
        "skills"
    ]

    public static func migrateIfNeeded(
        userDefaults: UserDefaults = .standard,
        legacyUserDefaults: UserDefaults? = UserDefaults(
            suiteName: legacyBundleIdentifier
        ),
        legacyApplicationSupportDirectory: URL? = nil,
        applicationSupportDirectory: URL? = nil,
        legacySandboxDirectory: URL? = nil,
        sandboxDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        guard !userDefaults.bool(forKey: migrationMarker) else { return }

        let legacyDirectory = legacyApplicationSupportDirectory
            ?? LocalStrayStorageLocation.legacyApplicationSupportDirectory(
                fileManager: fileManager
            )
        let currentDirectory = applicationSupportDirectory
            ?? LocalStrayStorageLocation.currentApplicationSupportDirectory(
                fileManager: fileManager
            )
        migrateUserDefaults(
            from: legacyUserDefaults,
            to: userDefaults,
            legacySkillsDirectory: legacyDirectory
                .appendingPathComponent("skills", isDirectory: true),
            currentSkillsDirectory: currentDirectory
                .appendingPathComponent("skills", isDirectory: true)
        )
        try migrateFiles(
            from: legacyDirectory,
            to: currentDirectory,
            fileManager: fileManager
        )
        let legacySandbox = legacySandboxDirectory
            ?? LocalStrayStorageLocation.legacyDefaultSandboxDirectory(
                fileManager: fileManager
            )
        let currentSandbox = sandboxDirectory
            ?? LocalStrayStorageLocation.defaultSandboxDirectory(
                fileManager: fileManager
            )
        try copyMissingItems(
            from: legacySandbox,
            to: currentSandbox,
            fileManager: fileManager
        )
        userDefaults.set(true, forKey: migrationMarker)
    }

    public static func legacyRuntimeExecutableURL(
        fileManager: FileManager = .default
    ) -> URL? {
        let executable = LocalStrayStorageLocation.legacyApplicationSupportDirectory(
            fileManager: fileManager
        )
            .appendingPathComponent("runtime/bin/qwen-prime-runtime")
        return fileManager.isExecutableFile(atPath: executable.path) ? executable : nil
    }

    private static func migrateUserDefaults(
        from legacyUserDefaults: UserDefaults?,
        to userDefaults: UserDefaults,
        legacySkillsDirectory: URL,
        currentSkillsDirectory: URL
    ) {
        guard let legacyUserDefaults else { return }
        for key in AppPersistenceKey.rebrandMigratable
            where userDefaults.object(forKey: key.rawValue) == nil {
            guard let legacyValue = legacyUserDefaults.object(forKey: key.rawValue) else {
                continue
            }
            userDefaults.set(legacyValue, forKey: key.rawValue)
        }
        migrateEnabledSkillIDs(
            from: legacyUserDefaults,
            to: userDefaults,
            legacySkillsDirectory: legacySkillsDirectory,
            currentSkillsDirectory: currentSkillsDirectory
        )
    }

    private static func migrateEnabledSkillIDs(
        from legacyUserDefaults: UserDefaults,
        to userDefaults: UserDefaults,
        legacySkillsDirectory: URL,
        currentSkillsDirectory: URL
    ) {
        let key = AppPersistenceKey.enabledAgentSkillIDs.rawValue
        guard userDefaults.object(forKey: key) == nil,
              let legacyIDs = legacyUserDefaults.stringArray(forKey: key) else {
            return
        }
        let legacyPrefix = "user:\(legacySkillsDirectory.standardizedFileURL.path)"
        let currentPrefix = "user:\(currentSkillsDirectory.standardizedFileURL.path)"
        let migratedIDs = legacyIDs.map { id in
            guard id.hasPrefix(legacyPrefix) else { return id }
            return currentPrefix + id.dropFirst(legacyPrefix.count)
        }
        userDefaults.set(migratedIDs, forKey: key)
    }

    private static func migrateFiles(
        from legacyDirectory: URL,
        to currentDirectory: URL,
        fileManager: FileManager
    ) throws {
        for relativePath in migratedRelativePaths {
            try copyMissingItems(
                from: legacyDirectory.appendingPathComponent(relativePath),
                to: currentDirectory.appendingPathComponent(relativePath),
                fileManager: fileManager
            )
        }
    }

    /// Copies legacy user data into an empty location or fills only missing
    /// entries, leaving both the legacy source and current user changes intact.
    private static func copyMissingItems(
        from source: URL,
        to destination: URL,
        fileManager: FileManager
    ) throws {
        guard fileManager.fileExists(atPath: source.path) else { return }
        guard fileManager.fileExists(atPath: destination.path) else {
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try fileManager.copyItem(at: source, to: destination)
            return
        }
        guard isDirectory(source), isDirectory(destination) else { return }
        let children = try fileManager.contentsOfDirectory(
            at: source,
            includingPropertiesForKeys: nil,
            options: []
        )
        for child in children {
            try copyMissingItems(
                from: child,
                to: destination.appendingPathComponent(child.lastPathComponent),
                fileManager: fileManager
            )
        }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(
            forKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        ) else {
            return false
        }
        return values.isDirectory == true && values.isSymbolicLink != true
    }
}
