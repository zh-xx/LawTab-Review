//
//  ReviewModels.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

/// 支持的合同文档类型。
enum DocumentKind: String, CaseIterable, Codable, Equatable {
    case plainText = "TXT"
    case pdf = "PDF"
    case docx = "DOCX"

    var displayName: String {
        switch self {
        case .plainText: return "TXT 文本"
        case .pdf: return "PDF"
        case .docx: return "Word (DOCX)"
        }
    }
}

/// 经过解析后的合同文档内容。
struct LoadedDocument: Equatable {
    var kind: DocumentKind
    var text: String
    var characterCount: Int
    var estimatedTokenCount: Int
}

/// 审核的整体状态。
enum ReviewStatus: Equatable {
    case idle
    case loading(documentName: String)
    case success(ReviewResult)
    case failure(ReviewError)
}

/// 经过大模型生成的结构化审核内容。
struct ReviewOutputs: Codable, Equatable {
    var mermaidFlowchart: String
    var contractOverview: String
    var foundationAudit: String
    var businessAudit: String
    var legalAudit: String
    var detailedFindings: String
    var auditSummary: String
}

/// 审核结果的整体表达。
struct ReviewResult: Codable, Equatable, Identifiable {
    var id: UUID
    var documentName: String
    var documentKind: DocumentKind
    var characterCount: Int
    var estimatedTokenCount: Int
    var reviewedAt: Date
    var outputs: ReviewOutputs
    var conversations: ConversationCollection = ConversationCollection()  // 对话历史（当前会话）

    init(id: UUID = UUID(),
         documentName: String,
         documentKind: DocumentKind,
         characterCount: Int,
         estimatedTokenCount: Int,
         reviewedAt: Date = .init(),
         outputs: ReviewOutputs,
         conversations: ConversationCollection = ConversationCollection()) {
        self.id = id
        self.documentName = documentName
        self.documentKind = documentKind
        self.characterCount = characterCount
        self.estimatedTokenCount = estimatedTokenCount
        self.reviewedAt = reviewedAt
        self.outputs = outputs
        self.conversations = conversations
    }
}

/// 审核过程中可能出现的错误。
enum ReviewError: LocalizedError, Equatable {
    case invalidFileType
    case unsupportedFileType(String)
    case fileReadFailed
    case emptyDocument
    case documentTooLarge(estimatedTokens: Int, limit: Int)
    case missingReviewPosition
    case missingAPIKey
    case invalidAPIEndpoint
    case serviceError(message: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return L.errorInvalidFileType
        case .unsupportedFileType(let ext):
            return L.errorUnsupportedFileType(ext)
        case .fileReadFailed:
            return L.errorFileReadFailed
        case .emptyDocument:
            return L.errorEmptyDocument
        case .documentTooLarge(let estimatedTokens, let limit):
            return L.errorDocumentTooLarge(estimatedTokens: estimatedTokens, limit: limit)
        case .missingReviewPosition:
            return L.errorMissingReviewPosition
        case .missingAPIKey:
            return L.errorMissingAPIKey
        case .invalidAPIEndpoint:
            return L.errorInvalidAPIEndpoint
        case .serviceError(let message):
            return message
        case .decodingFailed:
            return L.errorDecodingFailed
        }
    }
}
