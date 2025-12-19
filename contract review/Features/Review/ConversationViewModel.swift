//
//  ConversationViewModel.swift
//  contract review
//
//  Created by Claude Code on 2025/10/24.
//

import Foundation
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    // 对话集合（所有对话会话）
    @Published var conversations: ConversationCollection = ConversationCollection()

    // 当前选中的对话 ID
    @Published var selectedConversationID: UUID?

    // 当前对话的输入框内容
    @Published var inputMessage: String = ""

    // API 调用状态
    @Published var isWaitingResponse = false
    @Published var apiError: String?

    // 思考过程和流式输出
    @Published var thinkingText: String = ""  // 正在思考的文本
    @Published var isThinking = false  // 是否正在思考

    private weak var appState: AppState?
    private var conversationTask: Task<Void, Never>?
    private var reviewResultID: UUID?

    // MARK: - Context 数据（来自审核）
    private var contractText: String = ""
    private var reviewResults: ReviewResult?

    func configure(with appState: AppState,
                   contractText: String,
                   reviewResults: ReviewResult) {
        self.appState = appState
        self.contractText = contractText
        self.reviewResults = reviewResults
        self.reviewResultID = reviewResults.id

        var incomingConversations = reviewResults.conversations
        if incomingConversations.sessions.isEmpty {
            let session = incomingConversations.createNewSession(title: "对话1")
            selectedConversationID = session.id
        } else {
            if let currentID = selectedConversationID,
               incomingConversations.getSession(id: currentID) != nil {
                selectedConversationID = currentID
            } else {
                selectedConversationID = incomingConversations.sessions.first?.id
            }
        }
        conversations = incomingConversations
        self.reviewResults?.conversations = incomingConversations
    }

    /// 创建新对话
    func createNewConversation() {
        let newTitle = "对话\(conversations.sessions.count + 1)"
        let session = conversations.createNewSession(title: newTitle)
        selectedConversationID = session.id
        inputMessage = ""
        apiError = nil
        reviewResults?.conversations = conversations
        persistConversations()
    }

    /// 删除对话
    func deleteConversation(id: UUID) {
        conversations.deleteSession(id: id)
        if selectedConversationID == id {
            selectedConversationID = conversations.sessions.first?.id
        }
        reviewResults?.conversations = conversations
        persistConversations()
    }

    func renameConversation(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        guard let index = conversations.getSessionIndex(id: id) else { return }
        conversations.sessions[index].title = trimmed
        conversations.sessions[index].updatedAt = Date()
        reviewResults?.conversations = conversations
        persistConversations()
    }

    /// 获取当前选中的对话
    var currentConversation: ConversationSession? {
        guard let id = selectedConversationID else { return nil }
        return conversations.getSession(id: id)
    }

    /// 发送消息并获取回复
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        guard let id = selectedConversationID,
              var conversation = conversations.getSession(id: id),
              let appState = appState else {
            return
        }

        let userMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        inputMessage = ""

        // 如果这是第一条消息，生成对话标题
        let isFirstMessage = conversation.messages.isEmpty

        // 将用户消息添加到对话
        conversation.addMessage(ConversationMessage(role: "user", content: userMessage))

        // 如果是第一条消息，使用 AI 生成标题（取前20个字符或第一句）
        if isFirstMessage {
            let titleText = userMessage.count > 20
                ? String(userMessage.prefix(20)) + "..."
                : userMessage
            conversation.title = titleText
        }

        if let index = conversations.getSessionIndex(id: id) {
            conversations.sessions[index] = conversation
        }

        // 更新选中对话的引用
        selectedConversationID = id
        reviewResults?.conversations = conversations

        // 异步调用 AI 获取回复
        conversationTask?.cancel()
        conversationTask = Task {
            await getAIResponse(for: userMessage, conversationID: id, appState: appState)
        }
    }

    func cancelResponse() {
        conversationTask?.cancel()
        conversationTask = nil
        isWaitingResponse = false
        isThinking = false
        thinkingText = ""
    }

    /// 从 AI 获取回复（支持流式输出）
    private func getAIResponse(for userMessage: String, conversationID: UUID, appState: AppState) async {
        isWaitingResponse = true
        apiError = nil
        thinkingText = ""
        isThinking = false

        defer {
            isWaitingResponse = false
        }

        guard let conversation = conversations.getSession(id: conversationID),
              let sessionIndex = conversations.getSessionIndex(id: conversationID) else {
            return
        }

        do {
            // 构建上下文
            let context = buildContext(for: conversation)

            // 先添加一条空的 assistant 消息，后续通过流式回调更新
            var mutableConversation = conversation
            let assistantMessage = ConversationMessage(role: "assistant", content: "")
            mutableConversation.addMessage(assistantMessage)
            conversations.sessions[sessionIndex] = mutableConversation

            // 记录助手消息的索引，方便后续更新
            let assistantMessageIndex = mutableConversation.messages.count - 1

            // 调用 AI 的流式版本
            try await appState.reviewService.askConversationQuestionWithStreaming(
                question: userMessage,
                context: context,
                conversationHistory: conversation.getRecentMessages(limit: 6),
                settings: appState.settings,
                credentials: appState.credentials,
                onThinking: { [weak self] thinkingChunk in
                    Task { @MainActor in
                        guard let self = self else { return }

                        // 暂时存储在 thinkingText 中，稍后会保存到消息
                        self.thinkingText += thinkingChunk
                        self.isThinking = true
                    }
                },
                onResponse: { [weak self] responseChunk in
                    Task { @MainActor in
                        guard let self = self else { return }

                        // 更新最后一条 assistant 消息
                        if self.conversations.sessions.count > sessionIndex,
                           self.conversations.sessions[sessionIndex].messages.count > assistantMessageIndex {
                            var sess = self.conversations.sessions[sessionIndex]
                            var updatedMsg = sess.messages[assistantMessageIndex]
                            let newContent = updatedMsg.content + responseChunk

                            // 同时保存思考内容
                            let thinkingToSave = self.thinkingText

                            updatedMsg = ConversationMessage(
                                id: updatedMsg.id,
                                role: updatedMsg.role,
                                content: newContent,
                                thinkingContent: thinkingToSave,
                                timestamp: updatedMsg.timestamp
                            )
                            sess.messages[assistantMessageIndex] = updatedMsg
                            self.conversations.sessions[sessionIndex] = sess
                            self.reviewResults?.conversations = self.conversations
                        }
                    }
                }
            )

            // 完成后清空思考文本
            thinkingText = ""
            isThinking = false
            reviewResults?.conversations = conversations
            persistConversations()
        } catch is CancellationError {
            apiError = nil
        } catch let error as ReviewError {
            apiError = error.errorDescription ?? error.localizedDescription
            // 删除空的 assistant 消息
            if let index = conversations.getSessionIndex(id: conversationID),
               conversations.sessions.count > index,
               conversations.sessions[index].messages.last?.role == "assistant" && conversations.sessions[index].messages.last?.content.isEmpty == true {
                var sess = conversations.sessions[index]
                sess.messages.removeLast()
                conversations.sessions[index] = sess
                reviewResults?.conversations = conversations
            }
            persistConversations()
        } catch {
            apiError = error.localizedDescription
            // 删除空的 assistant 消息
            if let index = conversations.getSessionIndex(id: conversationID),
               conversations.sessions.count > index,
               conversations.sessions[index].messages.last?.role == "assistant" && conversations.sessions[index].messages.last?.content.isEmpty == true {
                var sess = conversations.sessions[index]
                sess.messages.removeLast()
                conversations.sessions[index] = sess
                reviewResults?.conversations = conversations
            }
            persistConversations()
        }
    }

    /// 构建对话上下文（合同原文 + 审核结果）
    private func buildContext(for conversation: ConversationSession) -> String {
        var context = ""

        // 添加合同原文
        context += "--- 合同原文 ---\n"
        context += contractText
        context += "\n\n"

        // 添加审核结果摘要
        if let results = reviewResults {
            context += "--- 审核结果摘要 ---\n"
            context += "合同概要：\n\(results.outputs.contractOverview)\n\n"

            context += "基础审核：\n\(results.outputs.foundationAudit)\n\n"
            context += "业务条款审核：\n\(results.outputs.businessAudit)\n\n"
            context += "法律条款审核：\n\(results.outputs.legalAudit)\n\n"
            context += "审核总结：\n\(results.outputs.auditSummary)\n"
        }

        return context
    }

    /// 清空当前对话的所有消息
    func clearCurrentConversation() {
        guard let id = selectedConversationID,
              let index = conversations.getSessionIndex(id: id) else {
            return
        }

        conversations.sessions[index].messages = []
        reviewResults?.conversations = conversations
        persistConversations()
    }

    private func persistConversations() {
        guard let appState,
              let reviewResultID else {
            return
        }
        let snapshot = conversations
        Task {
            await appState.historyController.updateReviewResult(id: reviewResultID) { reviewResult in
                reviewResult.conversations = snapshot
            }
        }
    }
}
