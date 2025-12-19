//
//  HistoryController.swift
//  contract review
//
//  Created by Codex on 2025/10/24.
//

import Foundation
import Combine

@MainActor
final class HistoryController: ObservableObject {
    @Published private(set) var records: [HistoryRecord] = []

    private let store: HistoryStore

    init(store: HistoryStore? = nil) {
        if let store {
            self.store = store
        } else {
            self.store = HistoryStore(fileURL: AppPaths.historyFileURL)
        }
        Task {
            await loadFromDisk()
        }
    }

    var isEmpty: Bool {
        records.isEmpty
    }

    func loadFromDisk() async {
        do {
            let loaded = try await store.load()
            records = sortRecords(loaded)
        } catch {
            // TODO: 记录日志；当前忽略加载失败
        }
    }

    @discardableResult
    func createDraftRecord(title: String = "新的审阅") async -> HistoryRecord {
        let record = HistoryRecord(title: title)
        records.insert(record, at: 0)
        records = sortRecords(records)
        await persist()
        return record
    }

    func updateTitle(id: UUID, title: String) async {
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return
        }
        var record = records[index]
        record.title = Self.displayTitle(for: title)
        record.touch()
        records[index] = record
        await persist()
    }

    func applyReviewResult(id: UUID,
                           reviewResult: ReviewResult,
                           contractText: String) async {
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            return
        }
        var result = reviewResult
        if result.conversations.sessions.isEmpty {
            result.conversations = ConversationCollection(sessions: [
                ConversationSession(title: "对话1")
            ])
        }
        records[index].applyReviewResult(result,
                                         contractText: contractText,
                                         displayTitle: Self.displayTitle(for: result.documentName))
        records = sortRecords(records)
        await persist()
    }

    func updateReviewResult(id: UUID,
                            mutate: (inout ReviewResult) -> Void) async {
        guard let index = records.firstIndex(where: { $0.reviewResult?.id == id }) else {
            return
        }

        if records[index].reviewResult == nil {
            return
        }

        mutate(&records[index].reviewResult!)
        records[index].touch()
        records = sortRecords(records)
        await persist()
    }

    func deleteRecord(id: UUID) async {
        records.removeAll { $0.id == id }
        await persist()
    }

    private func persist() async {
        let currentRecords = records
        do {
            try await store.save(currentRecords)
        } catch {
            // TODO: 记录日志；当前忽略持久化失败
        }
    }

    private func sortRecords(_ records: [HistoryRecord]) -> [HistoryRecord] {
        records.sorted { lhs, rhs in
            lhs.updatedAt > rhs.updatedAt
        }
    }

    private static func displayTitle(for fileName: String) -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return fileName }
        let withoutExt = (trimmed as NSString).deletingPathExtension
        return withoutExt.isEmpty ? trimmed : withoutExt
    }
}
