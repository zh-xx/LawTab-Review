//
//  AppState.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var settings: Settings
    @Published var credentials: Credentials
    @Published var isShowingSettings = false
    @Published var templates: [RequirementTemplate]

    let settingsStore: SettingsStore
    let credentialsStorage: CredentialsStorage
    let reviewService: ReviewService
    let documentLoader: DocumentLoader
    let historyController: HistoryController
    let templateStore: TemplateStore

    init(settingsStore: SettingsStore? = nil,
         credentialsStorage: CredentialsStorage? = nil,
         reviewService: ReviewService? = nil,
         documentLoader: DocumentLoader? = nil,
         historyController: HistoryController? = nil,
         templateStore: TemplateStore? = nil) {
        let resolvedSettingsStore = settingsStore ?? SettingsStore()
        let resolvedCredentialsStorage = credentialsStorage ?? CredentialsStorage()
        let resolvedReviewService = reviewService ?? ReviewService()
        let resolvedDocumentLoader = documentLoader ?? DocumentLoader()
        let resolvedHistoryController = historyController ?? HistoryController()
        let resolvedTemplateStore = templateStore ?? TemplateStore()

        self.settingsStore = resolvedSettingsStore
        self.credentialsStorage = resolvedCredentialsStorage
        self.reviewService = resolvedReviewService
        self.documentLoader = resolvedDocumentLoader
        self.historyController = resolvedHistoryController
        self.templateStore = resolvedTemplateStore

        self.settings = resolvedSettingsStore.load()
        self.credentials = resolvedCredentialsStorage.loadCredentials()
        self.templates = resolvedTemplateStore.load()

        // 同步语言设置到本地化管理器
        L.current = self.settings.language
    }

    func updateSettings(_ settings: Settings) {
        self.settings = settings
        settingsStore.save(settings)
        // 同步语言设置
        L.current = settings.language
    }

    func updateCredentials(_ credentials: Credentials) throws {
        self.credentials = credentials
        if credentials.isEmpty {
            try credentialsStorage.clear()
        } else {
            try credentialsStorage.save(apiKey: credentials.apiKey)
        }
    }

    func updateTemplates(_ templates: [RequirementTemplate]) {
        self.templates = templates
        templateStore.save(templates)
    }
}
