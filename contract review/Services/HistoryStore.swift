//
//  HistoryStore.swift
//  contract review
//
//  Created by Codex on 2025/10/24.
//

import Foundation

actor HistoryStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            return encoder
        }()
        self.decoder = {
            let decoder = JSONDecoder()
            return decoder
        }()
    }

    func load() throws -> [HistoryRecord] {
        try AppPaths.ensureApplicationDirectoriesExist()
        let fm = FileManager()
        guard fm.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([HistoryRecord].self, from: data)
    }

    func save(_ records: [HistoryRecord]) throws {
        try ensureDirectoryExists()
        let data = try encoder.encode(records)
        try data.write(to: fileURL, options: [.atomic])
        try FileManager().setAttributes([.posixPermissions: NSNumber(value: 0o600)], ofItemAtPath: fileURL.path)
    }

    private func ensureDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        let fm = FileManager()
        if !fm.fileExists(atPath: directoryURL.path) {
            try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
    }
}
