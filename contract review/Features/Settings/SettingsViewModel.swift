//
//  SettingsViewModel.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var language: AppLanguage = .chinese
    @Published var providerMode: Settings.ProviderMode = .deepseek
    @Published var baseURL: String = Settings.Provider.deepseek.baseURL
    @Published var chatModel: String = Settings.Provider.deepseek.chatModel
    @Published var reasonerModel: String = Settings.Provider.deepseek.reasonerModel
    @Published var isTestingConnection = false
    @Published var testResults: [ModelTestResult] = []  // 两个模型的测试结果
    @Published var inlineMessage: InlineMessage?

    private weak var appState: AppState?

    func load(from appState: AppState) {
        self.appState = appState
        apiKey = appState.credentials.apiKey
        language = appState.settings.language
        providerMode = appState.settings.provider.mode
        baseURL = appState.settings.provider.baseURL
        chatModel = appState.settings.provider.chatModel
        reasonerModel = appState.settings.provider.reasonerModel
        testResults = []
        inlineMessage = nil
    }

    var hasChanges: Bool {
        guard let appState else { return true }
        let trimmedKey = sanitizedAPIKey
        let pendingProvider = effectiveProvider
        let storedProvider = normalized(appState.settings.provider)
        return trimmedKey != appState.credentials.apiKey
        || pendingProvider != storedProvider
        || language != appState.settings.language
    }

    var canTestConnection: Bool {
        !sanitizedAPIKey.isEmpty
        && hasProviderInputs
        && !isTestingConnection
    }

    var hasProviderInputs: Bool {
        switch providerMode {
        case .deepseek:
            return true
        case .custom:
            return sanitizedBaseURL.isEmpty == false
            && sanitizedChatModel.isEmpty == false
            && sanitizedReasonerModel.isEmpty == false
        }
    }

    func saveChanges() -> Bool {
        guard let appState else {
            inlineMessage = .error("内部状态未准备就绪，请稍后重试。")
            return false
        }

        guard hasProviderInputs else {
            inlineMessage = .error("请填写 Base URL、审核模型和对话模型后再保存。")
            return false
        }

        do {
            let newSettings = Settings(language: language,
                                       provider: effectiveProvider)
            try appState.updateCredentials(Credentials(apiKey: sanitizedAPIKey))
            appState.updateSettings(newSettings)
            inlineMessage = .success("设置已保存。")
            testResults = []
            return true
        } catch {
            inlineMessage = .error("保存失败：\(error.localizedDescription)")
            return false
        }
    }

    /// 并行测试两个模型的连接
    func testConnection() async {
        guard let appState else {
            inlineMessage = .error("内部状态未准备就绪，请稍后重试。")
            return
        }

        isTestingConnection = true
        inlineMessage = nil
        testResults = []

        let credentials = Credentials(apiKey: sanitizedAPIKey)
        let settings = Settings(language: language,
                                provider: effectiveProvider)

        // 并行测试两个模型
        async let chatTest = testModel(settings.chatModelName, settings: settings, credentials: credentials, appState: appState)
        async let reasonerTest = testModel(settings.reasonerModelName, settings: settings, credentials: credentials, appState: appState)

        let (chatResult, reasonerResult) = await (chatTest, reasonerTest)

        testResults = [chatResult, reasonerResult]
        isTestingConnection = false
    }

    private func testModel(_ modelName: String, settings: Settings, credentials: Credentials, appState: AppState) async -> ModelTestResult {
        do {
            try await appState.reviewService.testConnection(modelName: modelName,
                                                            settings: settings,
                                                            credentials: credentials)
            return ModelTestResult(modelName: modelName, status: .success(Date()))
        } catch {
            let message: String
            if let reviewError = error as? ReviewError, let description = reviewError.errorDescription {
                message = description
            } else {
                message = error.localizedDescription
            }
            return ModelTestResult(modelName: modelName, status: .failure(message))
        }
    }
}

// MARK: - Test Result Types

struct ModelTestResult: Identifiable {
    let id = UUID()
    let modelName: String
    let status: TestStatus

    enum TestStatus: Equatable {
        case success(Date)
        case failure(String)
    }

    var isSuccess: Bool {
        if case .success = status { return true }
        return false
    }

    var displayText: String {
        switch status {
        case .success:
            return "✓"
        case .failure:
            return "✗"
        }
    }

    var statusDescription: String {
        switch status {
        case .success:
            return "连接成功"
        case .failure(let message):
            return "失败：\(message)"
        }
    }
}

extension SettingsViewModel {
    enum InlineMessage: Equatable {
        case success(String)
        case error(String)

        var description: String {
            switch self {
            case .success(let text), .error(let text):
                return text
            }
        }

        var isError: Bool {
            if case .error = self { return true } else { return false }
        }
    }
}

private extension SettingsViewModel {
    var sanitizedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedChatModel: String {
        chatModel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedReasonerModel: String {
        reasonerModel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var effectiveProvider: Settings.Provider {
        switch providerMode {
        case .deepseek:
            return .deepseek
        case .custom:
            return Settings.Provider(mode: .custom,
                                     baseURL: sanitizedBaseURL,
                                     chatModel: sanitizedChatModel,
                                     reasonerModel: sanitizedReasonerModel)
        }
    }

    func normalized(_ provider: Settings.Provider) -> Settings.Provider {
        Settings.Provider(mode: provider.mode,
                          baseURL: provider.baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
                          chatModel: provider.chatModel.trimmingCharacters(in: .whitespacesAndNewlines),
                          reasonerModel: provider.reasonerModel.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
