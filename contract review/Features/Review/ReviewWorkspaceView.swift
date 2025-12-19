//
//  ReviewWorkspaceView.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import SwiftUI
import UniformTypeIdentifiers
import WebKit
import AppKit

struct ReviewWorkspaceView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ReviewViewModel
    private var activeHistoryRecord: HistoryRecord?
    private var onPrepareForSubmission: () async -> UUID?
    private var onReviewStart: (String) -> Void
    private var onReviewSuccess: (ReviewResult, String) -> Void
    @State private var isImporterPresented = false
    @State private var selectedTab: WorkspaceTab = .submission

    private enum WorkspaceTab: Hashable {
        case submission
        case results
        case conversation
    }

    private var status: ReviewStatus {
        viewModel.status
    }

    private var supportedTypes: [UTType] {
        var types: [UTType] = [.plainText, .pdf]
        if let docx = UTType(filenameExtension: "docx") {
            types.append(docx)
        }
        return types
    }

    init(viewModel: ReviewViewModel,
         activeHistoryRecord: HistoryRecord? = nil,
         onPrepareForSubmission: @escaping () async -> UUID? = { nil },
         onReviewStart: @escaping (String) -> Void = { _ in },
         onReviewSuccess: @escaping (ReviewResult, String) -> Void = { _, _ in }) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.activeHistoryRecord = activeHistoryRecord
        self.onPrepareForSubmission = onPrepareForSubmission
        self.onReviewStart = onReviewStart
        self.onReviewSuccess = onReviewSuccess
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ReviewSubmissionView(viewModel: viewModel,
                                 isImporterPresented: $isImporterPresented,
                                 onViewResults: { selectedTab = .results },
                                 onPrepareForSubmission: onPrepareForSubmission)
                .tabItem {
                    Label(L.tabSubmit, systemImage: "tray.and.arrow.up")
                }
                .tag(WorkspaceTab.submission)

            ReviewResultsView(viewModel: viewModel,
                              onSelectFile: {
                                  selectedTab = .submission
                                  isImporterPresented = true
                              })
                .tabItem {
                    Label(L.tabResults, systemImage: "doc.text.magnifyingglass")
                }
                .tag(WorkspaceTab.results)

            // 合同对话标签页（常显）
            if case .success(let reviewResult) = status {
                ConversationView(contractText: activeHistoryRecord?.contractText ?? viewModel.loadedDocument?.text ?? "",
                                 reviewResult: reviewResult)
                    .tabItem {
                        Label(L.tabConversation, systemImage: "bubble.left.and.bubble.right")
                    }
                    .tag(WorkspaceTab.conversation)
            } else {
                // 未审核时显示占位符
                placeholderConversationView
                    .tabItem {
                        Label(L.tabConversation, systemImage: "bubble.left.and.bubble.right")
                    }
                    .tag(WorkspaceTab.conversation)
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: activeHistoryRecord?.id) { _, _ in
            selectedTab = .submission
        }
        .onAppear {
            viewModel.configure(with: appState)
        }
        .onChange(of: status) { oldValue, newValue in
            switch newValue {
            case .idle:
                if case .loading = oldValue {
                    selectedTab = .submission
                }
            case .loading(let documentName):
                selectedTab = .results
                onReviewStart(documentName)
            case .success(let result):
                if case .loading = oldValue {
                    let contractText = viewModel.loadedDocument?.text ?? activeHistoryRecord?.contractText ?? ""
                    onReviewSuccess(result, contractText)
                    selectedTab = .results
                } else if oldValue == .idle {
                    selectedTab = .results
                }
            case .failure:
                if case .loading = oldValue {
                    selectedTab = .results
                }
            }
        }
        .fileImporter(isPresented: $isImporterPresented,
                      allowedContentTypes: supportedTypes,
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.selectFile(url: url)
            case .failure(let error):
                viewModel.handleImporterFailure(error)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.isShowingSettings = true
                } label: {
                    Label(L.settingsButton, systemImage: "gear")
                }
                .help(L.openModelSettingsHint)
            }
        }
    }
}

// MARK: - 提交页

private struct ReviewSubmissionView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: ReviewViewModel
    @Binding var isImporterPresented: Bool
    var onViewResults: () -> Void
    var onPrepareForSubmission: () async -> UUID?

    @State private var activeStep: SubmissionStep = .file
    @State private var isTemplateManagerPresented = false
    @State private var hoveredTemplatePreview: String?

    private enum SubmissionStep: Int, CaseIterable, Identifiable {
        case file, position, requirements, confirm

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .file: return L.step1Title
            case .position: return L.step2Title
            case .requirements: return L.step3Title
            case .confirm: return L.step4Title
            }
        }

        var caption: String {
            switch self {
            case .file: return L.step1Caption
            case .position: return L.step2Caption
            case .requirements: return L.step3Caption
            case .confirm: return L.step4Caption
            }
        }

        var icon: String {
            switch self {
            case .file: return "doc.on.doc"
            case .position: return "person.text.rectangle"
            case .requirements: return "list.bullet.rectangle"
            case .confirm: return "checkmark.circle"
            }
        }
    }

    private enum StepVisualState {
        case completed
        case active
        case upcoming
        case blocked
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ReviewStatusSummary(status: viewModel.status)

                    if case .success = viewModel.status {
                        Button {
                            onViewResults()
                        } label: {
                            Label(L.tabResults, systemImage: "doc.text.magnifyingglass")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(alignment: .top, spacing: 24) {
                        stepsSidebar
                            .frame(width: 220)

                        VStack(alignment: .leading, spacing: 20) {
                            stepContent(for: activeStep)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .onAppear(perform: clampActiveStep)
            .onChange(of: viewModel.selectedFileURL) { _, _ in
                if hasSelectedFile {
                    activeStep = .position
                } else {
                    activeStep = .file
                }
            }
            .onChange(of: viewModel.preparationError) { _, error in
                if error != nil {
                    activeStep = .file
                }
            }
            .onChange(of: viewModel.reviewPosition) { _, _ in
                clampActiveStep()
            }
            .onChange(of: viewModel.isPreparingDocument) { _, _ in
                clampActiveStep()
            }
            .sheet(isPresented: $isTemplateManagerPresented) {
                TemplateManagerSheetView(isPresented: $isTemplateManagerPresented)
                    .environmentObject(appState)
            }

            Divider()
                .padding(.horizontal, -1)
            HStack {
                stepFooter(for: activeStep)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var hasSelectedFile: Bool {
        viewModel.selectedFileURL != nil
    }

    private var isDocumentReady: Bool {
        hasSelectedFile && !viewModel.isPreparingDocument && viewModel.preparationError == nil
    }

    private var trimmedPosition: String {
        viewModel.sanitizedReviewPosition.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasValidPosition: Bool {
        trimmedPosition.isEmpty == false
    }

    private var isReadyToSubmit: Bool {
        isDocumentReady && hasValidPosition
    }

    private var isReviewing: Bool {
        if case .loading = viewModel.status { return true }
        return false
    }

    private var stepsSidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(SubmissionStep.allCases) { step in
                let state = stepState(for: step)
                Button {
                    if canAccess(step: step) {
                        activeStep = step
                    }
                } label: {
                    stepRow(for: step, state: state)
                }
                .buttonStyle(.plain)
                .disabled(!canAccess(step: step))
                .opacity(state == .blocked ? 0.45 : 1.0)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
    }

    @ViewBuilder
    private func stepRow(for step: SubmissionStep, state: StepVisualState) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(stepBackgroundColor(for: state))
                    .frame(width: 32, height: 32)
                stepIcon(for: step, state: state)
                    .foregroundStyle(stepForegroundColor(for: state))
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(step.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func stepBackgroundColor(for state: StepVisualState) -> Color {
        switch state {
        case .completed: return Color.accentColor.opacity(0.16)
        case .active: return Color.accentColor
        case .upcoming: return Color(nsColor: .separatorColor).opacity(0.25)
        case .blocked: return Color(nsColor: .separatorColor).opacity(0.15)
        }
    }

    private func stepForegroundColor(for state: StepVisualState) -> Color {
        switch state {
        case .completed: return Color.accentColor
        case .active: return Color.white
        case .upcoming: return Color.secondary
        case .blocked: return Color.secondary.opacity(0.6)
        }
    }

    @ViewBuilder
    private func stepIcon(for step: SubmissionStep, state: StepVisualState) -> some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark")
        default:
            Image(systemName: step.icon)
        }
    }

    @ViewBuilder
    private func stepContent(for step: SubmissionStep) -> some View {
        switch step {
        case .file:
            fileSelectionContent
        case .position:
            positionContent
        case .requirements:
            requirementsContent
        case .confirm:
            confirmationContent
        }
    }

    private var fileSelectionContent: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L.step1Title)
                        .font(.title3.weight(.semibold))
                    Text(L.step1Description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let fileName = viewModel.selectedFileName {
                    Label(L.fileSelectedPrefix + fileName, systemImage: "checkmark.seal")
                        .font(.callout)
                    if let document = viewModel.loadedDocument {
                        Text(L.fileTypeLabel + "\(document.kind.displayName)" + L.charCountLabel + "\(document.characterCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label(L.noFileSelected, systemImage: "folder")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if viewModel.isPreparingDocument {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text(L.parsingFile)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = viewModel.preparationError {
                    Label(error.errorDescription ?? L.fileParseError,
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(Color.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label(L.selectFileButton, systemImage: "square.and.arrow.down.on.square")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)

                    if hasSelectedFile {
                        Button(L.reselectFileButton) {
                            isImporterPresented = true
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Label(L.contextLimitInfo, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var positionContent: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Text(L.stanceLabel)
                    .font(.title3.weight(.semibold))

                TextField(L.stancePlaceholder,
                          text: $viewModel.reviewPosition,
                          axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 520)

                Label(L.stanceInfo,
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var requirementsContent: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text(L.additionalRequirementsLabel + " " + L.stanceOptional)
                    .font(.title3.weight(.semibold))

                if !appState.templates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(L.templatePickerLabel)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Button(L.manageTemplatesButton) {
                                isTemplateManagerPresented = true
                            }
                            .buttonStyle(.link)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(appState.templates) { template in
                                Toggle(isOn: Binding(get: {
                                    viewModel.selectedTemplateIDs.contains(template.id)
                                }, set: { isOn in
                                    if isOn {
                                        viewModel.selectedTemplateIDs.insert(template.id)
                                    } else {
                                        viewModel.selectedTemplateIDs.remove(template.id)
                                    }
                                })) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .font(.body.weight(.medium))
                                        if let desc = template.description, desc.isEmpty == false {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .onHover { hovering in
                                    if hovering {
                                        let text = template.content.trimmingCharacters(in: .whitespacesAndNewlines)
                                        hoveredTemplatePreview = text.isEmpty ? nil : text
                                    } else {
                                        hoveredTemplatePreview = nil
                                    }
                                }
                            }
                        }

                        if let preview = hoveredTemplatePreview {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L.templatePreviewLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(preview)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.gray.opacity(0.04))
                            )
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: 520, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.gray.opacity(0.08))
                    )
                }

                TextField(L.additionalRequirementsPlaceholder,
                          text: $viewModel.additionalRequest,
                          axis: .vertical)
                    .lineLimit(5...10)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 520, minHeight: 150)

                Label(L.defaultWorkflowInfo,
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var confirmationContent: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text(L.confirmBeforeSubmit)
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(title: L.confirmFileLabel, detail: fileSummaryText, icon: "doc")
                    summaryRow(title: L.confirmStanceLabel, detail: trimmedPosition.isEmpty ? L.notFilled : trimmedPosition, icon: "person.text.rectangle")
                    summaryRow(title: L.confirmAdditionalLabel, detail: additionalSummaryText, icon: "list.bullet")
                }

                if viewModel.isPreparingDocument {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(L.parsingCompleteToSubmit)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = viewModel.preparationError {
                    Label(error.errorDescription ?? L.parseFailedReturnPrevious,
                          systemImage: "exclamationmark.octagon.fill")
                        .font(.callout)
                        .foregroundStyle(Color.orange)
                }
            }
        }
    }

    private var additionalSummaryText: String {
        let trimmed = trimmedCombinedAdditional
        return trimmed.isEmpty ? L.notAdded : trimmed
    }

    private var trimmedCombinedAdditional: String {
        viewModel.combinedAdditionalRequest.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func summaryRow(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func stepFooter(for step: SubmissionStep) -> some View {
        HStack {
            if let previous = previousStep(for: step) {
                Button(L.previousStepButton) {
                    activeStep = previous
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if step == .confirm {
                Button {
                    Task { @MainActor in
                        _ = await onPrepareForSubmission()
                        viewModel.submitReview()
                    }
                } label: {
                    Label(isReviewing ? L.submitting : L.startReviewButton,
                          systemImage: isReviewing ? "hourglass" : "paperplane.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isReadyToSubmit || isReviewing)
            } else if let next = nextStep(for: step) {
                Button(L.nextStepButton) {
                    activeStep = next
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance(from: step))
            }
        }
    }

    private func previousStep(for step: SubmissionStep) -> SubmissionStep? {
        switch step {
        case .file: return nil
        case .position: return .file
        case .requirements: return .position
        case .confirm: return .requirements
        }
    }

    private func nextStep(for step: SubmissionStep) -> SubmissionStep? {
        switch step {
        case .file: return .position
        case .position: return .requirements
        case .requirements: return .confirm
        case .confirm: return nil
        }
    }

    private func canAdvance(from step: SubmissionStep) -> Bool {
        switch step {
        case .file:
            return hasSelectedFile && viewModel.preparationError == nil
        case .position:
            return hasValidPosition
        case .requirements:
            return isDocumentReady && hasValidPosition
        case .confirm:
            return false
        }
    }

    private func canAccess(step: SubmissionStep) -> Bool {
        switch step {
        case .file:
            return true
        case .position:
            return hasSelectedFile && viewModel.preparationError == nil
        case .requirements:
            return hasSelectedFile && viewModel.preparationError == nil
        case .confirm:
            return isDocumentReady && hasValidPosition
        }
    }

    private func isStepCompleted(_ step: SubmissionStep) -> Bool {
        switch step {
        case .file:
            return isDocumentReady
        case .position:
            return hasValidPosition
        case .requirements:
            if activeStep.rawValue > SubmissionStep.requirements.rawValue {
                return true
            }
            return trimmedCombinedAdditional.isEmpty == false
        case .confirm:
            return false
        }
    }

    private func stepState(for step: SubmissionStep) -> StepVisualState {
        guard canAccess(step: step) else { return .blocked }
        if step == activeStep { return .active }
        return isStepCompleted(step) ? .completed : .upcoming
    }

    private var fileSummaryText: String {
        if let error = viewModel.preparationError {
            return error.errorDescription ?? L.parseFailed
        }
        if viewModel.isPreparingDocument {
            return L.parsing
        }
        if let name = viewModel.selectedFileName {
            if let document = viewModel.loadedDocument {
                return "\(name)" + L.fileSeparator + "\(document.kind.displayName)" + L.fileSeparator + L.charCountLabel.trimmingCharacters(in: .whitespaces) + " \(document.characterCount)"
            } else {
                return name
            }
        }
        return L.notSelected
    }

    private func clampActiveStep() {
        if !hasSelectedFile {
            activeStep = .file
            return
        }

        if viewModel.preparationError != nil {
            activeStep = .file
            return
        }

        if !hasValidPosition && activeStep.rawValue >= SubmissionStep.requirements.rawValue {
            activeStep = .position
            return
        }

        if (!isDocumentReady || !hasValidPosition) && activeStep == .confirm {
            activeStep = hasValidPosition ? .requirements : .position
        }
    }
}

// MARK: - 结果页

private struct ReviewResultsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: ReviewViewModel
    var onSelectFile: () -> Void
    @State private var selectedTab: ResultTab = .flowchart

    enum ResultTab: CaseIterable {
        case flowchart, overview, foundation, business, legal, summary

        var title: String {
            switch self {
            case .flowchart: return L.resultTabMermaid
            case .overview: return L.resultTabOverview
            case .foundation: return L.resultTabFoundation
            case .business: return L.resultTabBusiness
            case .legal: return L.resultTabLegal
            case .summary: return L.resultTabSummary
            }
        }

        var icon: String {
            switch self {
            case .flowchart: return "squares.below.rectangle"
            case .overview: return "doc.text"
            case .foundation: return "checkmark.seal"
            case .business: return "briefcase.fill"
            case .legal: return "building.columns"
            case .summary: return "person.2.wave.2"
            }
        }
    }

    var body: some View {
        Group {
            switch viewModel.status {
            case .idle:
                idleState
            case .loading(let documentName):
                loadingState(documentName: documentName)
            case .success(let result):
                successState(result: result)
            case .failure(let error):
                failureState(error: error)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var idleState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L.noReviewTask)
                .font(.headline)
            Text(L.goToSubmitHint)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func loadingState(documentName: String) -> some View {
        VStack(spacing: 16) {
            ProgressView(L.reviewingDocument + "\(documentName)…")
            Text(L.reviewingHint)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func successState(result: ReviewResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.reviewCompleted)
                            .font(.title3.weight(.semibold))
                        Text(L.documentTypeLabel + "\(result.documentKind.displayName)" + L.charCountResultLabel + "\(result.characterCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(L.reviewTimeLabel + "\(result.reviewedAt.formatted(.dateTime.year().month().day().hour().minute()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker(L.resultTypeLabel, selection: $selectedTab) {
                            ForEach(ResultTab.allCases, id: \.self) { tab in
                                Label(tab.title, systemImage: tab.icon)
                                    .tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Group {
                            switch selectedTab {
                            case .flowchart:
                                MermaidSectionView(content: result.outputs.mermaidFlowchart)
                                    .frame(minHeight: 260)
                            case .overview:
                                MarkdownWebView(markdown: result.outputs.contractOverview)
                            case .foundation:
                                MarkdownWebView(markdown: result.outputs.foundationAudit)
                            case .business:
                                MarkdownWebView(markdown: result.outputs.businessAudit)
                            case .legal:
                                MarkdownWebView(markdown: result.outputs.legalAudit)
                            case .summary:
                                MarkdownWebView(markdown: result.outputs.auditSummary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
                    }
                }
            }
            .padding(24)
        }
    }

    private func failureState(error: ReviewError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color.orange)
            Text(L.reviewFailed)
                .font(.headline)
            Text(error.errorDescription ?? L.unknownError)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            HStack(spacing: 12) {
                Button(L.retryButton) {
                    viewModel.retry()
                }
                .buttonStyle(.borderedProminent)

                Button(L.reselectFileButton) {
                    viewModel.reset()
                    onSelectFile()
                }
                if case .missingAPIKey = error {
                    Button(L.settingsButton) {
                        appState.isShowingSettings = true
                    }
                }
            }
        }
    }
}

// MARK: - 复用视图

private struct ReviewStatusSummary: View {
    @EnvironmentObject private var appState: AppState
    let status: ReviewStatus

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    Circle()
                        .fill(iconColor.gradient)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
    }

    private var title: String {
        _ = appState.settings.language  // trigger refresh on language change
        switch status {
        case .idle:
            return L.waitingForUpload
        case .loading:
            return L.reviewInProgress
        case .success:
            return L.reviewCompleted
        case .failure:
            return L.reviewFailed
        }
    }

    private var message: String {
        _ = appState.settings.language  // trigger refresh on language change
        switch status {
        case .idle:
            return L.waitingForReview
        case .loading(let name):
            return L.reviewingContract + name + L.reviewExpectedTime
        case .success:
            return L.reviewResultGenerated
        case .failure(let error):
            return error.errorDescription ?? L.unknownErrorRetry
        }
    }

    private var iconName: String {
        switch status {
        case .idle:
            return "doc.badge.plus"
        case .loading:
            return "clock.arrow.circlepath"
        case .success:
            return "checkmark.seal.fill"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .idle:
            return .gray
        case .loading:
            return .blue
        case .success:
            return .green
        case .failure:
            return .orange
        }
    }

    private var backgroundGradient: LinearGradient {
        let base = iconColor.opacity(0.25)
        return LinearGradient(colors: [base, Color(nsColor: .controlBackgroundColor)],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
}

private struct CardContainer<Content: View>: View {
    var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(nsColor: .textBackgroundColor),
                        Color(nsColor: .textBackgroundColor).opacity(0.85)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
        )
    }
}

private struct MermaidSectionView: View {
    var content: String
    @State private var isZoomPresented = false

    var body: some View {
        if let graph = normalizedMermaid {
            MermaidWebView(mermaidDiagram: graph, layout: .inline)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Button {
                        isZoomPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.18))
                            )
                    }
                    .buttonStyle(.plain)
                    .help(L.viewLargeDiagram)
                    .padding(10)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15))
                )
                .sheet(isPresented: $isZoomPresented) {
                    MermaidZoomSheet(mermaidDiagram: graph)
                }
        } else {
            Text(L.noMermaidDiagram)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 40)
        }
    }

    private var normalizedMermaid: String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if trimmed.hasPrefix("```") {
            let lines = trimmed.components(separatedBy: "\n")
            let filtered = lines.filter { line in
                let lower = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return !(lower == "```" || lower == "```mermaid")
            }
            let graph = filtered.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return graph.isEmpty ? nil : graph
        } else {
            return trimmed
        }
    }
}

private struct MermaidZoomSheet: View {
    var mermaidDiagram: String
    @Environment(\.dismiss) private var dismiss
    @State private var magnification: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(L.resultTabMermaid)
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        magnification = max(0.5, magnification - 0.2)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .help(L.zoomOut)

                    Slider(value: $magnification, in: 0.5...3.0)
                        .frame(width: 160)

                    Button {
                        magnification = min(3.0, magnification + 0.2)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .help(L.zoomIn)

                    Button {
                        magnification = 1.0
                    } label: {
                        Text("100%")
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                    }
                    .buttonStyle(.bordered)
                    .help(L.resetZoom)
                }
                Spacer()
                Button(L.closeButton) { dismiss() }
            }
            .padding(16)
            Divider()
            MermaidWebView(mermaidDiagram: mermaidDiagram, layout: .zoom, magnification: magnification)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 620)
    }
}

private enum MermaidWebViewLayout {
    case inline
    case zoom
}

private struct MermaidWebView: NSViewRepresentable {
    var mermaidDiagram: String
    var layout: MermaidWebViewLayout
    var magnification: CGFloat = 1.0

    func makeCoordinator() -> Coordinator { Coordinator(layout: layout) }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.userContentController.add(context.coordinator, name: "contentHeight")

        let webView = PassthroughWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = layout == .zoom
        if layout == .zoom {
            webView.magnification = magnification
        }
        if let scrollView = webView.enclosingScrollView {
            scrollView.hasVerticalScroller = layout == .zoom
            scrollView.hasHorizontalScroller = layout == .zoom
            scrollView.autohidesScrollers = true
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        context.coordinator.attach(webView: webView)
        webView.loadHTMLString(html(for: mermaidDiagram, layout: layout), baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html(for: mermaidDiagram, layout: layout), baseURL: nil)
        if layout == .zoom {
            let point = NSPoint(x: nsView.bounds.midX, y: nsView.bounds.midY)
            nsView.allowsMagnification = true
            nsView.setMagnification(magnification, centeredAt: point)
        }
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "contentHeight")
    }

    private func html(for diagram: String, layout: MermaidWebViewLayout) -> String {
        let escaped = diagram
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
        let localScriptTag: String
        if let localScriptBase64 = bundledMermaidBase64 {
            localScriptTag = """
            <script>
                const mermaidSource = atob('\(localScriptBase64)');
                (function(){eval(mermaidSource);})();
            </script>
            """
        } else {
            localScriptTag = """
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            """
        }

        let overflow = (layout == .zoom) ? "auto" : "hidden"
        let padding = (layout == .zoom) ? "24px" : "12px"
        let svgSizing = (layout == .zoom)
            ? "svg { max-width: none !important; height: auto !important; }"
            : "svg { max-width: 100% !important; height: auto !important; }"

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <style>
                :root { color-scheme: light dark; }
                html, body {
                    margin: 0;
                    padding: 0;
                    background-color: transparent;
                    overflow: \(overflow);
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
                }
                .container { padding: \(padding); }
                .mermaid {
                    background: transparent;
                    border-radius: 12px;
                    padding: 8px;
                }
                \(svgSizing)
                .node rect, .node polygon, .node ellipse {
                    rx: 10px;
                    ry: 10px;
                    filter: drop-shadow(0 8px 18px rgba(0,0,0,0.08));
                }
                .node .label {
                    padding: 12px 14px;
                    font-size: 13px;
                    font-weight: 500;
                    line-height: 1.4;
                    max-width: 240px;
                }
                .node text {
                    font-size: 13px;
                    font-weight: 500;
                    line-height: 1.4;
                }
            </style>
            \(localScriptTag)
            <script>
                function sendHeight() {
                    const height = document.documentElement.scrollHeight;
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.contentHeight) {
                        window.webkit.messageHandlers.contentHeight.postMessage(height);
                    }
                }

                function toRGB(color) {
                    if (!color) return null;
                    const hex = color.trim().toLowerCase();
                    const hexMatch = hex.match(/^#([a-f0-9]{3}|[a-f0-9]{6})$/i);
                    if (hexMatch) {
                        let h = hexMatch[1];
                        if (h.length === 3) h = h.split("").map(c => c + c).join("");
                        const intVal = parseInt(h, 16);
                        return {
                            r: (intVal >> 16) & 255,
                            g: (intVal >> 8) & 255,
                            b: intVal & 255
                        };
                    }
                    const rgbMatch = color.match(/^rgb\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*\\)$/i);
                    if (rgbMatch) {
                        return {
                            r: parseInt(rgbMatch[1], 10),
                            g: parseInt(rgbMatch[2], 10),
                            b: parseInt(rgbMatch[3], 10)
                        };
                    }
                    return null;
                }

                function darker(color, factor = 0.8) {
                    const rgb = toRGB(color);
                    if (!rgb) return null;
                    const clamp = v => Math.max(0, Math.min(255, Math.round(v)));
                    const r = clamp(rgb.r * factor);
                    const g = clamp(rgb.g * factor);
                    const b = clamp(rgb.b * factor);
                    return `#${[r, g, b].map(v => v.toString(16).padStart(2, "0")).join("")}`;
                }

                function harmonizeStrokes() {
                    document.querySelectorAll('.node rect, .node polygon, .node ellipse').forEach(el => {
                        let fill = el.getAttribute('fill');
                        if (!fill || fill === 'none') {
                            const cs = getComputedStyle(el);
                            fill = cs ? cs.fill : null;
                        }
                        if (!fill || fill === 'none') return;
                        const strokeColor = darker(fill);
                        if (!strokeColor) return;
                        el.setAttribute('stroke', strokeColor);
                        el.style.stroke = strokeColor;
                        el.setAttribute('stroke-width', '1.6px');
                        el.style.strokeWidth = '1.6px';
                    });
                }

                function harmonizeEdges() {
                    const letterColor = new Map(); // A -> stroke
                    document.querySelectorAll('.node').forEach(node => {
                        const shape = node.querySelector('rect, polygon, ellipse');
                        if (!shape || !node.id) return;
                        let fill = shape.getAttribute('fill');
                        if (!fill || fill === 'none') {
                            const cs = getComputedStyle(shape);
                            fill = cs ? cs.fill : null;
                        }
                        if (!fill || fill === 'none') return;
                        const stroke = darker(fill);
                        if (!stroke) return;
                        const match = node.id.match(/flowchart-([^-]+)/);
                        if (match && match[1]) {
                            letterColor.set(match[1], stroke);
                        }
                    });

                    const applyColor = (path, color) => {
                        path.setAttribute('stroke', color);
                        path.style.setProperty('stroke', color, 'important');
                        const marker = path.getAttribute('marker-end');
                        if (marker) {
                            const idMatch = marker.match(/#(.*)$/);
                            if (idMatch) {
                                const markerEl = document.getElementById(idMatch[1]);
                                if (markerEl) {
                                    markerEl.querySelectorAll('path').forEach(m => {
                                        m.setAttribute('fill', color);
                                        m.style.setProperty('fill', color, 'important');
                                    });
                                }
                            }
                        }
                    };

                    const colorForTokens = (tokens) => {
                        const targetToken = tokens.find(c => c.startsWith('LE-'));
                        const sourceToken = tokens.find(c => c.startsWith('LS-'));
                        const targetKey = targetToken ? targetToken.replace(/^LE-/, '') : null;
                        const sourceKey = sourceToken ? sourceToken.replace(/^LS-/, '') : null;
                        return (targetKey && letterColor.get(targetKey)) || (sourceKey && letterColor.get(sourceKey)) || null;
                    };

                    const edgePaths = Array.from(document.querySelectorAll('.edgePaths path'));
                    const edgeColors = edgePaths.map(path => {
                        const cls = (path.className.baseVal || path.className || '').split(/\\s+/);
                        const color = colorForTokens(cls);
                        if (color) applyColor(path, color);
                        return color;
                    });

                    // Keep edge labels as Mermaid defaults to avoid mismatched mapping
                }

                window.addEventListener('DOMContentLoaded', () => {
                    mermaid.initialize({
                        startOnLoad: true,
                        securityLevel: 'loose',
                        theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'
                    });
                    const code = `\(escaped)`;
                    document.getElementById('diagram').textContent = code;
                    mermaid.run({ querySelector: '.mermaid' }).then(() => {
                        harmonizeStrokes();
                        harmonizeEdges();
                        setTimeout(sendHeight, 40);
                    });
                });
                window.addEventListener('resize', () => setTimeout(sendHeight, 40));
                setTimeout(sendHeight, 200);
            </script>
        </head>
        <body>
            <div class="container">
                <div class="mermaid" id="diagram"></div>
            </div>
        </body>
        </html>
        """
    }

    private var bundledMermaidBase64: String? {
        guard let url = Bundle.main.url(forResource: "mermaid.min", withExtension: "js", subdirectory: "Resources/Web"),
              let data = try? Data(contentsOf: url),
              data.count > 1024 else { return nil }
        if let placeholder = String(data: data, encoding: .utf8),
           placeholder.contains("[Mermaid Placeholder]") {
            return nil
        }
        return data.base64EncodedString()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var heightConstraint: NSLayoutConstraint?
        private let layout: MermaidWebViewLayout

        init(layout: MermaidWebViewLayout) {
            self.layout = layout
        }

        func attach(webView: WKWebView) {
            if layout == .inline, heightConstraint == nil {
                let constraint = webView.heightAnchor.constraint(equalToConstant: 280)
                constraint.priority = .defaultHigh
                constraint.isActive = true
                heightConstraint = constraint
            }
            webView.wantsLayer = true
            webView.layer?.backgroundColor = NSColor.clear.cgColor
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard layout == .inline else { return }
            updateHeight(for: webView)
        }

        func updateHeight(for webView: WKWebView) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                if let value = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.heightConstraint?.constant = max(value, 200)
                    }
                }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "contentHeight" else { return }
            guard layout == .inline else { return }
            let raw = (message.body as? CGFloat) ?? CGFloat((message.body as? Double) ?? 0.0)
            guard raw > 0 else { return }
            DispatchQueue.main.async {
                self.heightConstraint?.constant = max(raw, 200)
            }
        }
    }
}

#if os(macOS)
private struct MarkdownWebView: NSViewRepresentable {
    var markdown: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.userContentController.add(context.coordinator, name: "contentHeight")
        let webView = PassthroughWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.translatesAutoresizingMaskIntoConstraints = false
        context.coordinator.attach(webView: webView)
        webView.loadHTMLString(html(for: markdown), baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html(for: markdown), baseURL: nil)
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "contentHeight")
    }

    private func html(for markdown: String) -> String {
        let data = markdown.data(using: .utf8) ?? Data()
        let base64 = data.base64EncodedString()

        let markedScriptTag: String
        if let base64Marked = bundledScriptBase64(named: "marked.min") {
            markedScriptTag = """
            <script>
                const markedSource = atob('\(base64Marked)');
                (function(){eval(markedSource);})();
            </script>
            """
        } else {
            markedScriptTag = """
            <script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js"></script>
            """
        }

        let domPurifyScriptTag: String
        if let base64Purify = bundledScriptBase64(named: "dompurify.min") {
            domPurifyScriptTag = """
            <script>
                const purifySource = atob('\(base64Purify)');
                (function(){eval(purifySource);})();
            </script>
            """
        } else {
            domPurifyScriptTag = """
            <script src="https://cdn.jsdelivr.net/npm/dompurify@3.0.6/dist/purify.min.js"></script>
            """
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <style>
                :root { color-scheme: light dark; }
                html, body {
                    margin: 0;
                    padding: 0;
                    background-color: transparent;
                    overflow: hidden;
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", sans-serif;
                    font-size: 13px;
                    line-height: 1.45;
                    color: rgba(20, 20, 20, 0.92);
                }
                @media (prefers-color-scheme: dark) {
                    body { color: rgba(235, 235, 245, 0.86); }
                }
                .container { padding: 6px; }
                h1, h2, h3, h4 { margin-top: 18px; margin-bottom: 10px; }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 12px 0;
                    font-size: 12.5px;
                    overflow: hidden;
                    border-radius: 12px;
                }
                th, td {
                    border: 1px solid rgba(120, 120, 120, 0.2);
                    padding: 9px 11px;
                    text-align: left;
                    vertical-align: top;
                    word-break: break-word;
                    white-space: normal;
                }
                th { background: rgba(120, 120, 120, 0.12); font-weight: 600; }
                tr:nth-child(even) td { background: rgba(120, 120, 120, 0.06); }
                ul, ol { padding-left: 20px; margin: 8px 0 12px 0; line-height: 1.5; }
                blockquote {
                    border-left: 3px solid rgba(120, 120, 120, 0.35);
                    padding-left: 12px;
                    margin: 12px 0;
                    font-style: italic;
                }
                code {
                    font-family: "SFMono-Regular", "SF Mono", Menlo, monospace;
                    background: rgba(120, 120, 120, 0.12);
                    padding: 2px 4px;
                    border-radius: 6px;
                }
                pre code {
                    display: block;
                    padding: 14px;
                    border-radius: 12px;
                    overflow-x: auto;
                }
                hr {
                    border: none;
                    border-top: 1px solid rgba(120, 120, 120, 0.2);
                    margin: 18px 0;
                }
                a { color: #0a84ff; text-decoration: none; }
                a:hover { text-decoration: underline; }
            </style>
            \(domPurifyScriptTag)
            \(markedScriptTag)
        </head>
        <body>
            <div class="container" id="content"></div>
            <script>
                function decodeBase64Unicode(str) {
                    const binary = atob(str);
                    const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
                    return new TextDecoder('utf-8').decode(bytes);
                }
                function sendHeight() {
                    const height = document.documentElement.scrollHeight;
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.contentHeight) {
                        window.webkit.messageHandlers.contentHeight.postMessage(height);
                    }
                }
                const markdown = decodeBase64Unicode('\(base64)');
                const renderer = new marked.Renderer();
                renderer.table = (header, body) => {
                    const temp = document.createElement('table');
                    temp.innerHTML = header + body;
                    const rows = Array.from(temp.rows);
                    const colWeights = [];
                    rows.forEach(row => {
                        Array.from(row.cells).forEach((cell, idx) => {
                            const length = cell.textContent.trim().length;
                            colWeights[idx] = (colWeights[idx] || 0) + Math.max(length, 4);
                            if (length <= 3) {
                                cell.classList.add('compact-cell');
                            }
                        });
                    });
                    const total = colWeights.reduce((a, b) => a + b, 0) || 1;
                    rows.forEach(row => {
                        Array.from(row.cells).forEach((cell, idx) => {
                            const weight = colWeights[idx] || 1;
                            const percent = Math.max(8, Math.round((weight / total) * 100));
                            cell.style.width = percent + '%';
                        });
                    });
                    return temp.outerHTML;
                };
                marked.setOptions({ renderer, gfm: true, breaks: false, mangle: false, headerIds: false });
                const html = marked.parse(markdown || '（无内容）');
                document.getElementById('content').innerHTML = DOMPurify.sanitize(html);
                document.querySelectorAll('td.compact-cell').forEach(cell => {
                    cell.style.whiteSpace = 'nowrap';
                });
                sendHeight();
                window.addEventListener('resize', () => setTimeout(sendHeight, 30));
                setTimeout(sendHeight, 120);
            </script>
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var heightConstraint: NSLayoutConstraint?

        func attach(webView: WKWebView) {
            if heightConstraint == nil {
                let constraint = webView.heightAnchor.constraint(equalToConstant: 200)
                constraint.priority = .defaultHigh
                constraint.isActive = true
                heightConstraint = constraint
            }
            webView.wantsLayer = true
            webView.layer?.backgroundColor = NSColor.clear.cgColor
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateHeight(for: webView)
        }

        func updateHeight(for webView: WKWebView) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                if let value = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.heightConstraint?.constant = max(value, 160)
                    }
                }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "contentHeight" else { return }
            let value = (message.body as? CGFloat) ?? CGFloat((message.body as? Double) ?? 0.0)
            guard value > 0 else { return }
            DispatchQueue.main.async {
                self.heightConstraint?.constant = max(value, 160)
            }
        }
    }

    private func bundledScriptBase64(named resource: String) -> String? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "js", subdirectory: "Resources/Web"),
              let data = try? Data(contentsOf: url),
              data.count > 256 else { return nil }
        if let placeholder = String(data: data, encoding: .utf8),
           placeholder.contains("[Placeholder]") {
            return nil
        }
        return data.base64EncodedString()
    }

}
#endif

#if os(macOS)
private final class PassthroughWebView: WKWebView {
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        nextResponder?.scrollWheel(with: event)
    }
}
#endif

// MARK: - 对话占位符

private var placeholderConversationView: some View {
    VStack(spacing: 12) {
        Image(systemName: "bubble.right.dashed")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)
        Text(L.pleaseReviewFirst)
            .font(.headline)
            .foregroundStyle(.secondary)
        Text(L.discussAfterReview)
            .font(.callout)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .multilineTextAlignment(.center)
    .background(Color(nsColor: .windowBackgroundColor))
}

#Preview {

    ReviewWorkspaceView(viewModel: ReviewViewModel())
        .environmentObject(AppState())
}
