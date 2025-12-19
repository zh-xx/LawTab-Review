//
//  TemplateManagerSheetView.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import SwiftUI

struct TemplateManagerSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool

    @State private var draftName: String = ""
    @State private var draftDescription: String = ""
    @State private var draftContent: String = ""
    @State private var selectedTemplateID: UUID?
    @State private var listSelection: UUID?
    @State private var inlineMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .frame(minWidth: 820, minHeight: 540)
        .onAppear {
            if let first = appState.templates.first {
                loadTemplate(first)
                listSelection = first.id
            }
        }
    }
}

private extension TemplateManagerSheetView {
    var header: some View {
        HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text(L.templatesTitle)
                .font(.title3.weight(.semibold))
            Text(L.current == .chinese ? "管理常用的补充审核要求模板，提交时可快速勾选复用。" : "Manage reusable additional requirement templates for quick selection.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if let inlineMessage {
                Text(inlineMessage)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
            Spacer()
            Button(L.closeButton) {
                isPresented = false
            }
        }
    }

    var content: some View {
        HStack(alignment: .top, spacing: 16) {
            templateList
                .frame(width: 260)
            editor
        }
    }

    var templateList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L.current == .chinese ? "模板列表" : "Templates")
                    .font(.headline)
                Spacer()
                Button {
                    createAndSelectNew()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            if appState.templates.isEmpty {
                Text(L.current == .chinese ? "暂无模板，点击右上角 + 新建。" : "No templates yet. Click + to add.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List(selection: $listSelection) {
                    ForEach(appState.templates) { template in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.body.weight(.medium))
                            if let desc = template.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(template.id)
                    }
                }
                .listStyle(.inset)
                .onChange(of: listSelection) { _, newValue in
                    guard let id = newValue,
                          let template = appState.templates.first(where: { $0.id == id }) else { return }
                    loadTemplate(template)
                }
            }
        }
    }

    var editor: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(L.templateNameLabel, text: $draftName)
                .textFieldStyle(.roundedBorder)
            TextField(L.templateDescriptionLabel, text: $draftDescription)
                .textFieldStyle(.roundedBorder)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.05))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.gray.opacity(0.15))
                TextEditor(text: $draftContent)
                    .padding(8)
                    .frame(minHeight: 280)
                    .background(Color.clear)
            }
            HStack(spacing: 12) {
                Button(L.saveTemplateButton) {
                    saveTemplate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button(L.deleteTemplateButton) {
                    deleteTemplate()
                }
                .buttonStyle(.bordered)
                .disabled(selectedTemplateID == nil)
                .foregroundStyle(.red)

                Spacer()
            }
            .padding(.top, 4)
        }
    }

    func createNew() {
        selectedTemplateID = nil
        listSelection = nil
        draftName = ""
        draftDescription = ""
        draftContent = ""
        inlineMessage = nil
    }

    func createAndSelectNew() {
        let new = RequirementTemplate(name: L.current == .chinese ? "未命名模板" : "Untitled template", content: "", description: nil)
        var templates = appState.templates
        templates.append(new)
        appState.updateTemplates(templates)
        loadTemplate(new)
        selectedTemplateID = new.id
        listSelection = new.id
        inlineMessage = L.current == .chinese ? "已创建未命名模板，请编辑后保存。" : "Created untitled template. Edit and save."
    }

    func loadTemplate(_ template: RequirementTemplate) {
        selectedTemplateID = template.id
        listSelection = template.id
        draftName = template.name
        draftDescription = template.description ?? ""
        draftContent = template.content
    }

    func saveTemplate() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = draftDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !content.isEmpty else { return }

        var templates = appState.templates
        if let id = selectedTemplateID, let idx = templates.firstIndex(where: { $0.id == id }) {
            templates[idx].name = name
            templates[idx].content = content
            templates[idx].description = desc.isEmpty ? nil : desc
        } else {
            let new = RequirementTemplate(name: name, content: content, description: desc.isEmpty ? nil : desc)
            templates.append(new)
            selectedTemplateID = new.id
            listSelection = new.id
        }
        appState.updateTemplates(templates)
        inlineMessage = L.current == .chinese ? "模板已保存。" : "Template saved."
    }

    func deleteTemplate() {
        guard let id = selectedTemplateID else { return }
        var templates = appState.templates
        templates.removeAll { $0.id == id }
        appState.updateTemplates(templates)
        if let first = templates.first {
            loadTemplate(first)
        } else {
            createNew()
        }
        inlineMessage = L.current == .chinese ? "模板已删除。" : "Template deleted."
    }
}
