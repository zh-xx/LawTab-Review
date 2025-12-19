//
//  AppPaths.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

enum AppPaths {
    static let containerDirectoryName = "LawTabReview"
    static let legacyContainerDirectoryName = "ContractReview"
    static let credentialsFileName = "credentials.json"
    static let historyFileName = "history.json"
    static let templatesFileName = "templates.json"

    /// `~/Library/Application Support/LawTabReview`
    static var applicationSupportDirectory: URL {
        let base = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        return base.appendingPathComponent(containerDirectoryName, isDirectory: true)
    }

    static var legacyApplicationSupportDirectory: URL {
        let base = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        return base.appendingPathComponent(legacyContainerDirectoryName, isDirectory: true)
    }

    static var credentialsFileURL: URL {
        applicationSupportDirectory.appendingPathComponent(credentialsFileName, isDirectory: false)
    }

    static var historyFileURL: URL {
        applicationSupportDirectory.appendingPathComponent(historyFileName, isDirectory: false)
    }

    static var templatesFileURL: URL {
        applicationSupportDirectory.appendingPathComponent(templatesFileName, isDirectory: false)
    }

    /// 确保应用支持目录与凭证文件所在父目录存在。
    static func ensureApplicationDirectoriesExist() throws {
        let fm = FileManager()
        let directory = applicationSupportDirectory
        if !fm.fileExists(atPath: directory.path) {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
        try migrateLegacyFilesIfNeeded()
    }

    private static func migrateLegacyFilesIfNeeded() throws {
        let fm = FileManager()
        let legacyDir = legacyApplicationSupportDirectory
        guard fm.fileExists(atPath: legacyDir.path) else { return }

        let mappings: [(from: URL, to: URL)] = [
            (legacyDir.appendingPathComponent(credentialsFileName), credentialsFileURL),
            (legacyDir.appendingPathComponent(historyFileName), historyFileURL),
            (legacyDir.appendingPathComponent(templatesFileName), templatesFileURL),
        ]

        for mapping in mappings {
            guard fm.fileExists(atPath: mapping.from.path) else { continue }
            guard fm.fileExists(atPath: mapping.to.path) == false else { continue }
            try fm.copyItem(at: mapping.from, to: mapping.to)
        }
    }
}
