//
//  CredentialsStorage.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

struct CredentialsStorage {
    private let fileURL: URL

    init(fileURL: URL = AppPaths.credentialsFileURL) {
        self.fileURL = fileURL
    }

    func loadCredentials() -> Credentials {
        if FileManager.default.fileExists(atPath: fileURL.path) == false {
            try? AppPaths.ensureApplicationDirectoriesExist()
        }
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return Credentials()
        }
        return Credentials(apiKey: payload.apiKey)
    }

    func save(apiKey: String) throws {
        try AppPaths.ensureApplicationDirectoriesExist()
        let payload = Payload(apiKey: apiKey)
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o600)], ofItemAtPath: fileURL.path)
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}

private extension CredentialsStorage {
    struct Payload: Codable {
        let apiKey: String
    }
}
