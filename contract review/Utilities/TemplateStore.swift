//
//  TemplateStore.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

struct TemplateStore {
    private let fileURL: URL

    init(fileURL: URL = AppPaths.templatesFileURL) {
        self.fileURL = fileURL
    }

    func load() -> [RequirementTemplate] {
        if FileManager.default.fileExists(atPath: fileURL.path) == false {
            try? AppPaths.ensureApplicationDirectoriesExist()
        }
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([RequirementTemplate].self, from: data)) ?? []
    }

    func save(_ templates: [RequirementTemplate]) {
        do {
            try AppPaths.ensureApplicationDirectoriesExist()
            let data = try JSONEncoder().encode(templates)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("TemplateStore save error: \(error)")
        }
    }
}
