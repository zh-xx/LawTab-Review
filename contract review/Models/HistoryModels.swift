//
//  HistoryModels.swift
//  contract review
//
//  Created by Codex on 2025/10/24.
//

import Foundation

/// 历史记录条目，保存审核记录或草稿。
struct HistoryRecord: Codable, Equatable, Identifiable {
    enum Status: String, Codable, Equatable {
        case draft
        case completed
    }

    var id: UUID
    var title: String
    var status: Status
    var reviewResult: ReviewResult?
    var contractText: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         title: String,
         status: Status = .draft,
         reviewResult: ReviewResult? = nil,
         contractText: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.status = status
        self.reviewResult = reviewResult
        self.contractText = contractText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
    }

    mutating func applyReviewResult(_ result: ReviewResult,
                                    contractText: String,
                                    displayTitle: String? = nil) {
        reviewResult = result
        self.contractText = contractText
        if let displayTitle, displayTitle.isEmpty == false {
            title = displayTitle
        } else {
            title = result.documentName
        }
        status = .completed
        updatedAt = Date()
    }

    mutating func touch() {
        updatedAt = Date()
    }
}
