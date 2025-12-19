//
//  HistoryShellView.swift
//  contract review
//
//  Created by Codex on 2025/10/24.
//

import SwiftUI

struct HistoryShellView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var historyController: HistoryController
    @StateObject private var reviewViewModel = ReviewViewModel()

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchText: String = ""
    @State private var selectedRecordID: UUID?
    @State private var activeRecord: HistoryRecord?

    private var filteredRecords: [HistoryRecord] {
        let records = historyController.records
        guard searchText.isEmpty == false else {
            return records
        }
        return records.filter { record in
            record.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            ReviewWorkspaceView(viewModel: reviewViewModel,
                                activeHistoryRecord: activeRecord,
                                onPrepareForSubmission: prepareForSubmission,
                                onReviewStart: handleReviewStart,
                                onReviewSuccess: handleReviewSuccess)
                .environmentObject(appState)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear(perform: bootstrapSelectionIfNeeded)
        .onChange(of: selectedRecordID) { _, newValue in
            handleSelectionChange(newValue)
        }
        .onReceive(historyController.$records) { _ in
            synchronizeActiveRecord()
        }
    }

    private var sidebar: some View {
        List(selection: $selectedRecordID) {
            Section {
                Button(action: startNewReview) {
                    Label(L.newReviewButton, systemImage: "plus")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if filteredRecords.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(searchText.isEmpty ? L.noHistoryRecords : L.noMatchingRecords)
                            .font(.headline)
                        Text(searchText.isEmpty ? L.historyEmptyHint : L.searchEmptyHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                Section {
                    ForEach(filteredRecords) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title)
                                .font(.headline)
                                .lineLimit(1)
                            if record.status == .draft {
                                Text(L.draftStatus)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(Self.sidebarDateFormatter.string(from: record.updatedAt))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .tag(record.id)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteRecord(record.id)
                            } label: {
                                Label(L.deleteRecordButton, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L.historyTitle)
        .searchable(text: $searchText,
                    placement: .sidebar,
                    prompt: L.searchContractsPlaceholder)
    }

    private func startNewReview() {
        Task { @MainActor in
            let draft = await historyController.createDraftRecord()
            selectedRecordID = draft.id
            applyRecordIfNeeded(draft)
        }
    }

    private func handleSelectionChange(_ newValue: UUID?) {
        guard let newValue else {
            if isReviewInProgress {
                return
            }
            activeRecord = nil
            reviewViewModel.reset()
            return
        }
        guard let record = historyController.records.first(where: { $0.id == newValue }) else {
            return
        }
        applyRecordIfNeeded(record)
    }

    private func handleReviewStart(documentName: String) {
        Task { @MainActor in
            guard let currentID = selectedRecordID,
                  let record = historyController.records.first(where: { $0.id == currentID }) else {
                return
            }

            if record.status == .draft {
                await historyController.updateTitle(id: currentID, title: documentName)
            }
        }
    }

    private func handleReviewSuccess(result: ReviewResult, contractText: String) {
        Task { @MainActor in
            guard let currentID = selectedRecordID else { return }
            await historyController.applyReviewResult(id: currentID,
                                                      reviewResult: result,
                                                      contractText: contractText)
            synchronizeActiveRecord()
        }
    }

    private func bootstrapSelectionIfNeeded() {
        guard activeRecord == nil else { return }

        if let first = historyController.records.first {
            selectedRecordID = first.id
            applyRecordIfNeeded(first)
        }
    }

    private func synchronizeActiveRecord() {
        if selectedRecordID == nil,
           activeRecord == nil,
           let first = historyController.records.first {
            selectedRecordID = first.id
            applyRecordIfNeeded(first)
            return
        }
        guard let currentID = selectedRecordID,
              let record = historyController.records.first(where: { $0.id == currentID }) else {
            guard !isReviewInProgress else { return }
            if let first = historyController.records.first {
                selectedRecordID = first.id
                applyRecordIfNeeded(first)
            } else {
                reviewViewModel.reset()
            }
            return
        }
        applyRecordIfNeeded(record)
    }

    private var isReviewInProgress: Bool {
        if case .loading = reviewViewModel.status {
            return true
        }
        return false
    }

    private func applyRecordIfNeeded(_ record: HistoryRecord) {
        activeRecord = record
        guard !isReviewInProgress else { return }

        if let reviewResult = record.reviewResult {
            if case .success(let current) = reviewViewModel.status, current == reviewResult {
                return
            }
            reviewViewModel.displayHistoryRecord(record)
        } else {
            if case .idle = reviewViewModel.status {
                return
            }
            reviewViewModel.displayHistoryRecord(record)
        }
    }

    private func deleteRecord(_ id: UUID) {
        Task { @MainActor in
            await historyController.deleteRecord(id: id)
            if selectedRecordID == id {
                if isReviewInProgress {
                    // Review in progress, keep current state
                } else {
                    selectedRecordID = nil
                    activeRecord = nil
                    reviewViewModel.reset()
                }
            }
            synchronizeActiveRecord()
        }
    }

    private func prepareForSubmission() async -> UUID? {
        if let currentID = selectedRecordID,
           historyController.records.first(where: { $0.id == currentID }) != nil {
            return currentID
        }

        let draft = await historyController.createDraftRecord()
        await MainActor.run {
            selectedRecordID = draft.id
            applyRecordIfNeeded(draft)
        }
        return draft.id
    }

    private static let sidebarDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

#Preview {
    let appState = AppState()
    HistoryShellView()
        .environmentObject(appState)
        .environmentObject(appState.historyController)
}
