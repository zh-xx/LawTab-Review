//
//  ReviewViewModel.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {
    @Published private(set) var status: ReviewStatus = .idle
    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var selectedFileName: String?
    @Published private(set) var lastRunAt: Date?
    @Published private(set) var loadedDocument: LoadedDocument?
    @Published private(set) var isPreparingDocument = false
    @Published private(set) var preparationError: ReviewError?
    @Published var reviewPosition: String = L.defaultStancePrompt
    @Published var additionalRequest: String = ""
    @Published var selectedTemplateIDs: Set<UUID> = []

    private weak var appState: AppState?
    private var reviewTask: Task<Void, Never>?
    private var preparationTask: Task<Void, Never>?
    private var pendingSubmissionAfterPreparation = false

    func configure(with appState: AppState) {
        self.appState = appState
    }

    func selectFile(url: URL) {
        reviewTask?.cancel()
        preparationTask?.cancel()
        status = .idle
        selectedFileURL = url
        selectedFileName = url.lastPathComponent
        loadedDocument = nil
        preparationError = nil
        pendingSubmissionAfterPreparation = false

        preparationTask = Task { [weak self] in
            await self?.prepareDocument(for: url)
        }
    }

    func retry() {
        guard selectedFileURL != nil else { return }
        submitReview()
    }

    func submitReview() {
        if case .loading = status {
            return
        }
        guard preparationError == nil else { return }

        if loadedDocument == nil, let url = selectedFileURL {
            pendingSubmissionAfterPreparation = true
            if isPreparingDocument == false {
                preparationTask?.cancel()
                preparationTask = Task { [weak self] in
                    await self?.prepareDocument(for: url)
                }
            }
            return
        }

        guard let url = selectedFileURL, let document = loadedDocument else { return }

        pendingSubmissionAfterPreparation = false
        reviewTask?.cancel()
        reviewTask = Task {
            await runReview(using: document, originalURL: url)
        }
    }

    func reset() {
        reviewTask?.cancel()
        preparationTask?.cancel()
        status = .idle
        selectedFileURL = nil
        selectedFileName = nil
        lastRunAt = nil
        loadedDocument = nil
        isPreparingDocument = false
        preparationError = nil
        pendingSubmissionAfterPreparation = false
    }

    func handleImporterFailure(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
            return
        }
        status = .failure(.serviceError(message: error.localizedDescription))
    }

    /// 将历史记录的审核结果加载到当前视图模型，用于回看或继续对话。
    func displayHistoryRecord(_ record: HistoryRecord) {
        reviewTask?.cancel()
        preparationTask?.cancel()
        selectedFileURL = nil
        loadedDocument = nil
        preparationError = nil
        isPreparingDocument = false
        pendingSubmissionAfterPreparation = false

        if let result = record.reviewResult {
            status = .success(result)
            selectedFileName = result.documentName
            lastRunAt = result.reviewedAt
        } else {
            status = .idle
            selectedFileName = nil
            lastRunAt = nil
        }
    }

    var combinedAdditionalRequest: String {
        let manual = additionalRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let appState else { return manual }
        let selected = appState.templates.filter { selectedTemplateIDs.contains($0.id) }
            .map { $0.content.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let components = selected + (manual.isEmpty ? [] : [manual])
        return components.joined(separator: "\n\n")
    }

    var sanitizedReviewPosition: String {
        let trimmed = reviewPosition.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return L.defaultStancePrompt
        }
        return trimmed
    }
}

private extension ReviewViewModel {
    func prepareDocument(for url: URL) async {
        guard let appState else {
            preparationError = .serviceError(message: "内部状态未准备就绪。")
            isPreparingDocument = false
            return
        }

        isPreparingDocument = true

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let document = try appState.documentLoader.loadDocument(from: url,
                                                                    maxEstimatedTokenCount: appState.reviewService.configuration.maxInputTokens)
            loadedDocument = document
            preparationError = nil
        } catch is CancellationError {
            // 用户取消选择或重新选择文件时结束
        } catch let reviewError as ReviewError {
            preparationError = reviewError
            loadedDocument = nil
        } catch {
            preparationError = .serviceError(message: error.localizedDescription)
            loadedDocument = nil
        }

        isPreparingDocument = false

        if pendingSubmissionAfterPreparation,
           preparationError == nil,
           loadedDocument != nil {
            pendingSubmissionAfterPreparation = false
            submitReview()
        } else if preparationError != nil {
            pendingSubmissionAfterPreparation = false
        }
    }

    func runReview(using document: LoadedDocument, originalURL url: URL) async {
        guard let appState else {
            status = .failure(.serviceError(message: "内部状态未准备就绪。"))
            return
        }

        let fileName = url.lastPathComponent
        status = .loading(documentName: fileName)
        loadedDocument = document

        do {
            let result = try await appState.reviewService.performReview(for: document,
                                                                        documentName: fileName,
                                                                        position: sanitizedReviewPosition,
                                                                        additionalRequest: combinedAdditionalRequest,
                                                                        settings: appState.settings,
                                                                        credentials: appState.credentials)
            status = .success(result)
            lastRunAt = result.reviewedAt
        } catch is CancellationError {
            // 忽略取消
        } catch let reviewError as ReviewError {
            status = .failure(reviewError)
        } catch {
            status = .failure(.serviceError(message: error.localizedDescription))
        }
    }

}
