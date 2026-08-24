import Foundation

/// Canonical user-owned storage locations and one-time legacy counterparts.
public enum LocalStrayStorageLocation {
    public static let applicationSupportDirectoryName = "LocalStray"
    public static let legacyApplicationSupportDirectoryName = "QwenPrime"
    public static let defaultSandboxDirectoryName = "local-stray-sandbox"
    public static let legacyDefaultSandboxDirectoryName = "prime-sandbox"
    public static let workspaceSkillsDirectoryName = ".localstray"
    public static let legacyWorkspaceSkillsDirectoryName = ".qwenprime"

    public static func applicationSupportDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
    }

    public static func currentApplicationSupportDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent(
                applicationSupportDirectoryName,
                isDirectory: true
            )
    }

    public static func legacyApplicationSupportDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent(
                legacyApplicationSupportDirectoryName,
                isDirectory: true
            )
    }

    public static func defaultSandboxDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(defaultSandboxDirectoryName, isDirectory: true)
    }

    public static func legacyDefaultSandboxDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(
                legacyDefaultSandboxDirectoryName,
                isDirectory: true
            )
    }

    public static func userSkillsDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        currentApplicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("skills", isDirectory: true)
    }

    public static func workspaceSkillsDirectory(
        workspaceURL: URL,
        isLegacy: Bool = false
    ) -> URL {
        workspaceURL
            .appendingPathComponent(
                isLegacy
                    ? legacyWorkspaceSkillsDirectoryName
                    : workspaceSkillsDirectoryName,
                isDirectory: true
            )
            .appendingPathComponent("skills", isDirectory: true)
    }
}
