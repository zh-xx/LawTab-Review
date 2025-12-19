//
//  SettingsSheetView.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import SwiftUI

private enum SettingsTab: String, CaseIterable, Identifiable {
    case basic
    case language
    case updates
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: return L.settingsTabBasic
        case .language: return L.settingsTabLanguage
        case .updates: return L.settingsTabUpdates
        case .about: return L.settingsTabAbout
        }
    }
}

struct SettingsSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isCheckingUpdate = false
    @State private var updateAlert: UpdateAlert?
    @State private var selectedTab: SettingsTab = .basic
    private let updateChecker = UpdateChecker()
    private let tabMinHeight: CGFloat = 240
    private let tabContentInset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            tabPicker
                .frame(maxWidth: .infinity, alignment: .leading)
            tabContainer
                .frame(maxWidth: .infinity, alignment: .leading)
            if let inlineMessage = viewModel.inlineMessage {
                InlineMessageView(inlineMessage: inlineMessage)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !viewModel.testResults.isEmpty {
                TestResultsView(testResults: viewModel.testResults)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            actionBar
        }
        .padding(24)
        .frame(minWidth: 520)
        .onAppear {
            viewModel.load(from: appState)
        }
        .alert(updateAlert?.title ?? L.checkForUpdatesButton, isPresented: Binding(
            get: { updateAlert != nil },
            set: { if !$0 { updateAlert = nil } }
        )) {
            if case .available(let info) = updateAlert {
                Button(L.downloadButton) {
                    openDownloadLink(info.download)
                }
                Button(L.cancelButton, role: .cancel) { }
            } else {
                Button(L.okButton, role: .cancel) { }
            }
        } message: {
            Text(updateAlert?.message ?? "")
        }
    }
}

private extension SettingsSheetView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.settingsTitle)
                .font(.title2.weight(.semibold))
            Text(L.current == .chinese ? "配置你的接口与偏好，连接任意 OpenAI 兼容服务。" : "Configure endpoints and preferences, connect to any OpenAI-compatible service.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(SettingsTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .basic:
            basicTab
        case .language:
            languageTab
        case .updates:
            updatesTab
        case .about:
            aboutTab
        }
    }

    var tabContainer: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(height: tabMinHeight)
            tabContent
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var basicTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L.apiKeyLabel)
                    .font(.headline)
                SecureField("sk-...", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .monospaced()
                Text(L.defaultDeepseekNotice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.08))
            )

            platformLinkSection

            Toggle(isOn: Binding(get: {
                viewModel.providerMode == .custom
            }, set: { isCustom in
                viewModel.providerMode = isCustom ? .custom : .deepseek
            })) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.customProviderToggle)
                        .font(.headline)
                    Text(L.customProviderHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.providerMode == .custom {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent(L.baseURLLabel) {
                        TextField("https://api.openai.com/v1", text: $viewModel.baseURL)
                            .textFieldStyle(.roundedBorder)
                            .monospaced()
                    }
                    LabeledContent(L.chatModelLabel) {
                        TextField("gpt-4o-mini", text: $viewModel.chatModel)
                            .textFieldStyle(.roundedBorder)
                            .monospaced()
                    }
                    LabeledContent(L.reasonerModelLabel) {
                        TextField("gpt-4o-mini", text: $viewModel.reasonerModel)
                            .textFieldStyle(.roundedBorder)
                            .monospaced()
                    }

                    HStack {
                        Button {
                            viewModel.providerMode = .deepseek
                            viewModel.baseURL = Settings.Provider.deepseek.baseURL
                            viewModel.chatModel = Settings.Provider.deepseek.chatModel
                            viewModel.reasonerModel = Settings.Provider.deepseek.reasonerModel
                        } label: {
                            Text(L.restoreDefaultProviderButton)
                        }
                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.gray.opacity(0.08))
                )
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L.current == .chinese ? "当前使用内置 DeepSeek 配置。" : "Using built-in DeepSeek configuration.")
                        .font(.subheadline)
                    Text("\(Settings.Provider.deepseek.baseURL) · \(Settings.Provider.deepseek.chatModel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.gray.opacity(0.06))
                )
            }

        }
    }

    var languageTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            languageSection
        }
    }

    var aboutTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            metadataSection
        }
    }

    var updatesTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            updateSection
        }
    }

    var platformLinkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.body)
                    .foregroundStyle(.blue)

                HStack(spacing: 0) {
                    Text(L.deepseekApplyPrefix)
                        .font(.callout)
                    Button(action: openPlatform) {
                        HStack(spacing: 2) {
                            Text(L.current == .chinese ? "官方链接" : "official link")
                                .underline()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    Text(L.current == .chinese ? "进行操作。" : ".")
                        .font(.callout)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.blue.opacity(0.08))
            )
        }
    }

    var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(L.languageLabel, selection: $viewModel.language) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            Text(L.current == .chinese ? "选择后点击保存生效。" : "Choose language and click Save to apply.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.08))
        )
    }

    var metadataSection: some View {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        let copyright = info["NSHumanReadableCopyright"] as? String ?? "Copyright © 2025 Jicheng. All rights reserved."
        let emailAddress = "zh-xx@foxmail.com"

        return VStack(alignment: .leading, spacing: 6) {
            Text(L.versionInfoSection)
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Version \(version)")
                    .font(.subheadline)
                Text("Build \(build)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(copyright)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let emailURL = URL(string: "mailto:\(emailAddress)") {
                HStack(spacing: 4) {
                    Image(systemName: "envelope")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link(emailAddress, destination: emailURL)
                        .font(.caption)
                }
            }
        }
    }

    var updateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.checkForUpdatesButton)
                .font(.headline)
            Button {
                checkForUpdates()
            } label: {
                if isCheckingUpdate {
                    Label(L.checkingUpdates, systemImage: "clock.arrow.2.circlepath")
                        .font(.subheadline)
                } else {
                    Label(L.checkForUpdatesButton, systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(isCheckingUpdate)

            Text(L.current == .chinese ? "保持应用最新以获得最新的模型兼容性与修复。" : "Stay updated for compatibility and fixes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    var actionBar: some View {
        HStack {
            Button(role: .cancel) {
                isPresented = false
            } label: {
                Text(L.closeButton)
            }

            Spacer()

            Button(L.testConnectionButton) {
                Task {
                    await viewModel.testConnection()
                }
            }
            .disabled(!viewModel.canTestConnection)

            Button(L.saveButton) {
                if viewModel.saveChanges() {
                    isPresented = false
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!viewModel.hasChanges || !viewModel.hasProviderInputs)
        }
    }

    func openPlatform() {
        if let url = URL(string: Settings.platformURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func checkForUpdates() {
        guard !isCheckingUpdate else { return }
        isCheckingUpdate = true

        Task {
            do {
                let status = try await updateChecker.checkForUpdate()
                await MainActor.run {
                    switch status {
                    case .upToDate:
                        updateAlert = .upToDate
                    case .updateAvailable(let info):
                        updateAlert = .available(info)
                    }
                }
            } catch {
                await MainActor.run {
                    updateAlert = .failure(error.localizedDescription)
                }
            }

            await MainActor.run {
                isCheckingUpdate = false
            }
        }
    }

    func openDownloadLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct InlineMessageView: View {
    let inlineMessage: SettingsViewModel.InlineMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: inlineMessage.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(inlineMessage.isError ? Color.red : Color.green)
            Text(inlineMessage.description)
                .font(.callout)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(inlineMessage.isError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        )
    }
}

private struct TestResultsView: View {
    let testResults: [ModelTestResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.current == .chinese ? "测试结果" : "Test Results")
                .font(.headline)
            ForEach(testResults) { result in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.modelName)
                            .font(.body.weight(.medium))
                        Text(result.statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(result.displayText)
                        .font(.headline)
                        .foregroundStyle(result.isSuccess ? .green : .orange)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(result.isSuccess ? Color.green.opacity(0.08) : Color.orange.opacity(0.08))
                )
            }
        }
    }
}

#Preview {
    SettingsSheetView(isPresented: .constant(true))
        .environmentObject(AppState())
}

private enum UpdateAlert {
    case upToDate
    case available(UpdateInfo)
    case failure(String)

    var title: String {
        switch self {
        case .upToDate, .available:
            return L.checkForUpdatesButton
        case .failure:
            return L.updateCheckFailedTitle
        }
    }

    var message: String {
        switch self {
        case .upToDate:
            return L.noUpdateMessage
        case .available(let info):
            let template = L.current == .chinese ? "发现新版本 \(info.latest)\n\n\(info.notes)" : "New version \(info.latest) available\n\n\(info.notes)"
            return template
        case .failure(let reason):
            return L.current == .chinese ? "无法完成更新检查：\(reason)" : "Unable to check for updates: \(reason)"
        }
    }
}
