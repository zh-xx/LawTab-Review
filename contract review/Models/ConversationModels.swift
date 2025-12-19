//
//  ConversationModels.swift
//  contract review
//
//  Created by Claude Code on 2025/10/24.
//

import Foundation

/// 单条消息
struct ConversationMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: String  // "user" 或 "assistant"
    let content: String
    var thinkingContent: String = ""  // AI的思考过程（仅限assistant消息）
    let timestamp: Date

    init(id: UUID = UUID(), role: String, content: String, thinkingContent: String = "", timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.thinkingContent = thinkingContent
        self.timestamp = timestamp
    }
}

/// 单个对话会话
struct ConversationSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String  // 对话标题，由第一条问题自动生成或用户自定义
    var messages: [ConversationMessage]
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "", messages: [ConversationMessage] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = Date()
    }

    /// 添加消息并更新 updatedAt
    mutating func addMessage(_ message: ConversationMessage) {
        messages.append(message)
        updatedAt = Date()
    }

    /// 获取对话的最后一条消息
    var lastMessage: ConversationMessage? {
        messages.last
    }

    /// 获取最近 N 条消息（用于上下文）
    func getRecentMessages(limit: Int = 10) -> [ConversationMessage] {
        Array(messages.suffix(limit))
    }
}

/// 对话容器（一个审核对应的所有对话）
struct ConversationCollection: Codable, Equatable {
    var sessions: [ConversationSession]

    init(sessions: [ConversationSession] = []) {
        self.sessions = sessions
    }

    /// 创建新对话
    mutating func createNewSession(title: String = "") -> ConversationSession {
        let session = ConversationSession(title: title)
        sessions.append(session)
        return session
    }

    /// 删除指定 ID 的对话
    mutating func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
    }

    /// 获取指定 ID 的对话
    func getSession(id: UUID) -> ConversationSession? {
        sessions.first { $0.id == id }
    }

    /// 获取指定 ID 的对话的索引
    func getSessionIndex(id: UUID) -> Int? {
        sessions.firstIndex { $0.id == id }
    }
}
