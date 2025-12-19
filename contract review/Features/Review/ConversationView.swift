//
//  ConversationView.swift
//  contract review
//
//  Created by Claude Code on 2025/10/24.
//

import SwiftUI

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @EnvironmentObject private var appState: AppState
    @State private var searchQuery: String = ""
    @State private var pendingDeleteConversationID: UUID?
    @State private var isRenamePresented = false
    @State private var renameConversationID: UUID?
    @State private var renameTitle: String = ""
    @State private var isAtBottom: Bool = true
    @State private var scrollViewportHeight: CGFloat = 0
    @State private var bottomSentinelMaxY: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    private let contractText: String
    private let reviewResult: ReviewResult

    init(contractText: String, reviewResult: ReviewResult) {
        self.contractText = contractText
        self.reviewResult = reviewResult
        _viewModel = StateObject(wrappedValue: ConversationViewModel())
    }

    var body: some View {
        HSplitView {
            conversationMainArea
            conversationListSidebar
        }
        .onAppear {
            configureViewModel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .onChange(of: reviewResult) { _, _ in configureViewModel() }
        .onChange(of: contractText) { _, _ in configureViewModel() }
        .confirmationDialog(L.confirmDeleteConversationTitle,
                            isPresented: Binding(get: { pendingDeleteConversationID != nil },
                                                 set: { if !$0 { pendingDeleteConversationID = nil } })) {
            Button(L.delete, role: .destructive) {
                if let id = pendingDeleteConversationID {
                    viewModel.deleteConversation(id: id)
                }
                pendingDeleteConversationID = nil
            }
            Button(L.cancel, role: .cancel) {
                pendingDeleteConversationID = nil
            }
        } message: {
            Text(L.confirmDeleteConversationMessage)
        }
        .sheet(isPresented: $isRenamePresented) {
            renameConversationSheet
        }
    }

    // MARK: - 主对话区域

    private var conversationMainArea: some View {
        VStack(spacing: 0) {
            // 顶部栏：对话标题
            HStack(spacing: 12) {
                Text(viewModel.currentConversation?.title ?? L.conversation)
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 1)
                    Spacer()
                }
            )

            messageListArea

            // 错误提示
            if let error = viewModel.apiError {
                BannerView(
                    icon: "exclamationmark.triangle.fill",
                    text: error,
                    tint: .orange,
                    actionTitle: L.dismiss
                ) {
                    viewModel.apiError = nil
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // 输入框
            inputArea
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 1)
                        Spacer()
                    }
                )
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - UI 组件

    private var messageListArea: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geo in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            if let conversation = viewModel.currentConversation {
                                if conversation.messages.isEmpty {
                                    emptyStateView
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 60)
                                } else {
                                    ForEach(conversation.messages, id: \.id) { message in
                                        ChatMessageRow(message: message) {
                                            copyToPasteboard(message.content)
                                        }
                                        .id(message.id)
                                    }
                                }
                            }

                            if viewModel.isThinking {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(L.aiThinking)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.15))
                                )
                                .frame(maxWidth: 720, alignment: .leading)
                                .id("thinking")
                            }

                            BottomSentinelView()
                                .id("bottom")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .background(
                            Color.clear
                                .preference(key: ScrollViewportHeightKey.self, value: geo.size.height)
                        )
                    }
                    .coordinateSpace(name: "conversationScroll")
                }

                if isAtBottom == false {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scrollProxy.scrollTo("bottom", anchor: .bottom)
                        }
                    } label: {
                        Label(L.jumpToLatest, systemImage: "arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(16)
                }
            }
            .frame(maxWidth: .infinity)
            .onPreferenceChange(ScrollViewportHeightKey.self) { scrollViewportHeight = $0 }
            .onPreferenceChange(BottomSentinelMaxYKey.self) { bottomSentinelMaxY = $0 }
            .onChange(of: bottomSentinelMaxY) { _, newValue in
                guard scrollViewportHeight > 0 else { return }
                let threshold: CGFloat = 40
                isAtBottom = newValue <= scrollViewportHeight + threshold
            }
            .onChange(of: viewModel.currentConversation?.messages.last?.id) { _, _ in
                guard isAtBottom else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollProxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L.startConversation)
                    .font(.title3.weight(.semibold))
                Text(L.askAIAboutContract)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Divider().opacity(0.4)

            Text(L.suggestedQuestionsTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                suggestionButton(L.suggestionPaymentRisk)
                suggestionButton(L.suggestionBreach)
                suggestionButton(L.suggestionTermination)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }

    private func suggestionButton(_ text: String) -> some View {
        Button {
            viewModel.inputMessage = text
            isInputFocused = true
        } label: {
            Label(text, systemImage: "sparkle")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private var inputArea: some View {
        HStack(spacing: 8) {
            TextField("", text: $viewModel.inputMessage, prompt: Text(L.inputPlaceholder))
                .textFieldStyle(.roundedBorder)
                .lineLimit(1)
                .disabled(viewModel.isWaitingResponse)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.sendMessage()
                }

            // 发送按钮
            Button(action: {
                if viewModel.isWaitingResponse {
                    viewModel.cancelResponse()
                } else {
                    viewModel.sendMessage()
                    isInputFocused = true
                }
            }) {
                Image(systemName: viewModel.isWaitingResponse ? "stop.fill" : "arrow.up")
            }
            .disabled(viewModel.isWaitingResponse == false && viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help(viewModel.isWaitingResponse ? L.stopGenerating : L.sendMessageHelp)
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    // MARK: - 侧边栏

    private var conversationListSidebar: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                TextField(L.searchConversations, text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Button(action: viewModel.createNewConversation) {
                    Label(L.newConversationButton, systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            List(selection: $viewModel.selectedConversationID) {
                ForEach(filteredSessions) { session in
                    conversationListItem(session)
                        .tag(session.id)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .frame(minWidth: 140, idealWidth: 180) // 用户可拖拽调整（HSplitView）
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func conversationListItem(_ session: ConversationSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(session.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Text(session.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let preview = session.messages.last?.content.trimmingCharacters(in: .whitespacesAndNewlines), preview.isEmpty == false {
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text(L.messageCount(session.messages.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button(L.renameConversation) {
                renameConversationID = session.id
                renameTitle = session.title
                isRenamePresented = true
            }
            Divider()
            Button(L.deleteConversation, role: .destructive) {
                pendingDeleteConversationID = session.id
            }
        }
    }

    private var filteredSessions: [ConversationSession] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return viewModel.conversations.sessions }
        return viewModel.conversations.sessions.filter { session in
            if session.title.localizedCaseInsensitiveContains(trimmed) { return true }
            let preview = session.messages.last?.content ?? ""
            return preview.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var renameConversationSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.renameConversation)
                .font(.headline)
            TextField("", text: $renameTitle)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button(L.cancel) {
                    isRenamePresented = false
                }
                Button(L.rename) {
                    if let id = renameConversationID {
                        viewModel.renameConversation(id: id, title: renameTitle)
                    }
                    isRenamePresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(minWidth: 360)
    }

    private func configureViewModel() {
        viewModel.configure(with: appState,
                            contractText: contractText,
                            reviewResults: reviewResult)
    }
}

private struct ChatMessageRow: View {
    var message: ConversationMessage
    var onCopy: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isAssistant {
                avatar
                messageBody
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                messageBody
                avatar
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    private var isAssistant: Bool { message.role == "assistant" }

    private var avatar: some View {
        Group {
            if isAssistant {
                Circle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text(L.assistantName.prefix(1))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    )
            } else {
                Circle()
                    .fill(Color.accentColor.opacity(0.9))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Text(L.youName.prefix(1))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
    }

    private var messageBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(isAssistant ? L.assistantName : L.youName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.9))
                Spacer()

                if isHovering {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L.copyContent)
                    .transition(.opacity)
                }
            }

            contentView
                .textSelection(.enabled)
                .frame(maxWidth: 720, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isAssistant ? Color.clear : Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var contentView: some View {
        let trimmed = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Text(L.aiPreparingContent)
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            let normalized = message.content.replacingOccurrences(of: "\r\n", with: "\n")
            let blocks = normalized.components(separatedBy: "\n\n")
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    let trimmedBlock = block.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedBlock.isEmpty {
                        EmptyView()
                    } else if let attributed = try? AttributedString(markdown: trimmedBlock, options: .init(interpretedSyntax: .full)) {
                        Text(attributed)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(trimmedBlock)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct ScrollViewportHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BottomSentinelMaxYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BottomSentinelView: View {
    var body: some View {
        Color.clear
            .frame(height: 1)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: BottomSentinelMaxYKey.self,
                                           value: geo.frame(in: .named("conversationScroll")).maxY)
                }
            )
    }
}

private struct BannerView: View {
    var icon: String
    var text: String
    var tint: Color
    var actionTitle: String
    var onAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            Button(actionTitle, action: onAction)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    // 创建示例数据用于预览
    let sampleOutputs = ReviewOutputs(
        mermaidFlowchart: "flowchart TD",
        contractOverview: "这是一份示例合同",
        foundationAudit: "基础审核：无问题",
        businessAudit: "业务审核：无问题",
        legalAudit: "法律审核：无问题",
        detailedFindings: "详细审查：无问题",
        auditSummary: "总结：合同无重大问题"
    )

    let sampleReviewResult = ReviewResult(
        documentName: "Sample Contract.txt",
        documentKind: .plainText,
        characterCount: 1000,
        estimatedTokenCount: 500,
        reviewedAt: Date(),
        outputs: sampleOutputs
    )

    ConversationView(contractText: "这是一份示例合同文本...", reviewResult: sampleReviewResult)
        .environmentObject(AppState())
        .frame(height: 500)
}
