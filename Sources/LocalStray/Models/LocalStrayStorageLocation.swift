import Foundation

/// Canonical user-owned storage locations.
public enum LocalStrayStorageLocation {
    public static let applicationSupportDirectoryName = "LocalStray"
    public static let defaultSandboxDirectoryName = "stray-sandbox"
    public static let runtimeExecutableName = "qwen-prime-runtime"
    public static let skillsDirectoryName = "skills"
    public static let workspaceSkillsDirectoryName = ".localstray"

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

    public static func defaultSandboxDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(defaultSandboxDirectoryName, isDirectory: true)
    }

    public static func userSkillsDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        currentApplicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent(skillsDirectoryName, isDirectory: true)
    }

    public static func workspaceSkillsDirectory(workspaceURL: URL) -> URL {
        workspaceURL.standardizedFileURL
            .appendingPathComponent(
                workspaceSkillsDirectoryName,
                isDirectory: true
            )
            .appendingPathComponent(skillsDirectoryName, isDirectory: true)
    }
}
