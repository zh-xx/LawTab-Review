//
//  UpdateChecker.swift
//  contract review
//
//  Created by Codex on 2025/10/25.
//

import Foundation

struct UpdateInfo: Decodable, Equatable {
    let latest: String
    let notes: String
    let download: String
}

enum UpdateStatus: Equatable {
    case upToDate
    case updateAvailable(UpdateInfo)
}

enum UpdateCheckerError: Error, LocalizedError {
    case invalidEndpoint
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "更新检查地址无效。"
        case .decodingFailed:
            return "返回的数据格式不正确。"
        }
    }
}

final class UpdateChecker {
    private let session: URLSession
    private let endpoint: URL?

    init(session: URLSession = .shared,
         endpoint: URL? = URL(string: "https://contract-review-omega.vercel.app/app-update.json")) {
        self.session = session
        self.endpoint = endpoint
    }

    func checkForUpdate() async throws -> UpdateStatus {
        guard let endpoint else {
            throw UpdateCheckerError.invalidEndpoint
        }

        let (data, _) = try await session.data(from: endpoint)
        let decoder = JSONDecoder()
        guard let info = try? decoder.decode(UpdateInfo.self, from: data) else {
            throw UpdateCheckerError.decodingFailed
        }

        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        if isVersion(info.latest, newerThan: current) {
            return .updateAvailable(info)
        } else {
            return .upToDate
        }
    }

    private func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        func components(from version: String) -> [Int] {
            version
                .split(separator: ".")
                .map { Int($0) ?? 0 }
        }

        let lhs = components(from: candidate)
        let rhs = components(from: current)

        for index in 0..<max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right {
                return left > right
            }
        }
        return false
    }
}
