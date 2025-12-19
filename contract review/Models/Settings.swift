//
//  Settings.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

/// 应用语言枚举
enum AppLanguage: String, Codable, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"

    var displayName: String {
        switch self {
        case .chinese: return "简体中文"
        case .english: return "English"
        }
    }
}

/// 用户可配置的接口设置。
struct Settings: Codable, Equatable {
    struct Provider: Codable, Equatable {
        var mode: ProviderMode
        var baseURL: String
        var chatModel: String
        var reasonerModel: String

        static let deepseek = Provider(mode: .deepseek,
                                       baseURL: "https://api.deepseek.com",
                                       chatModel: "deepseek-chat",
                                       reasonerModel: "deepseek-reasoner")
    }

    enum ProviderMode: String, Codable, CaseIterable {
        case deepseek
        case custom
    }

    static let platformURL = "https://platform.deepseek.com/"  // API 充值和申请链接

    // 用户可配置项
    var language: AppLanguage
    var provider: Provider

    init(language: AppLanguage = .chinese,
         provider: Provider = .deepseek) {
        self.language = language
        self.provider = provider
    }

    // Convenience accessors
    var apiBaseURL: String { provider.baseURL }
    var chatModelName: String { provider.chatModel }
    var reasonerModelName: String { provider.reasonerModel }
    var isUsingCustomProvider: Bool { provider.mode == .custom }
}

/// 与接口交互所需的敏感凭证。
struct Credentials: Equatable {
    var apiKey: String

    init(apiKey: String = "") {
        self.apiKey = apiKey
    }

    var isEmpty: Bool {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
