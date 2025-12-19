//
//  SettingsStore.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

struct SettingsStore {
    private let defaults: UserDefaults
    private let languageKey = "app_language"
    private let providerModeKey = "provider_mode"
    private let providerBaseURLKey = "provider_base_url"
    private let providerChatModelKey = "provider_chat_model"
    private let providerReasonerModelKey = "provider_reasoner_model"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 加载设置
    func load() -> Settings {
        let language: AppLanguage
        if let languageRaw = defaults.string(forKey: languageKey),
           let savedLanguage = AppLanguage(rawValue: languageRaw) {
            language = savedLanguage
        } else {
            language = .chinese  // 默认中文
        }

        let providerModeRaw = defaults.string(forKey: providerModeKey)
        let providerMode = providerModeRaw.flatMap(Settings.ProviderMode.init(rawValue:)) ?? .deepseek
        let baseURL = defaults.string(forKey: providerBaseURLKey) ?? Settings.Provider.deepseek.baseURL
        let chatModel = defaults.string(forKey: providerChatModelKey) ?? Settings.Provider.deepseek.chatModel
        let reasonerModel = defaults.string(forKey: providerReasonerModelKey) ?? Settings.Provider.deepseek.reasonerModel

        let provider = Settings.Provider(mode: providerMode,
                                         baseURL: baseURL,
                                         chatModel: chatModel,
                                         reasonerModel: reasonerModel)

        return Settings(language: language, provider: provider)
    }

    /// 保存设置
    func save(_ settings: Settings) {
        defaults.set(settings.language.rawValue, forKey: languageKey)
        defaults.set(settings.provider.mode.rawValue, forKey: providerModeKey)
        defaults.set(settings.provider.baseURL, forKey: providerBaseURLKey)
        defaults.set(settings.provider.chatModel, forKey: providerChatModelKey)
        defaults.set(settings.provider.reasonerModel, forKey: providerReasonerModelKey)
    }
}
