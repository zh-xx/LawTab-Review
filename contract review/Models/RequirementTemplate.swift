//
//  RequirementTemplate.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

struct RequirementTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var content: String
    var description: String?

    init(id: UUID = UUID(), name: String, content: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.content = content
        self.description = description
    }
}
