//
//  StanceModels.swift
//  contract review
//
//  Created by Claude Code on 2025/10/24.
//

import Foundation

// MARK: - 立场识别相关数据模型

/// 合同当事人信息
struct ContractParty: Codable, Equatable {
    let name: String  // 当事人名称
    let role: String  // 角色（如：买方、卖方、承包人等）
    let description: String  // 描述
}

/// 单个立场选项及其策略
struct StanceOption: Codable, Equatable, Identifiable {
    let id: UUID
    let stance: String  // 立场描述（如："作为买方"、"作为卖方"）
    let description: String  // 立场说明
    let keyPoints: [String]  // 该立场下的关键要点
    let pros: [String]  // 优势
    let cons: [String]  // 劣势
    let suggestions: [String]  // 谈判建议

    init(stance: String,
         description: String,
         keyPoints: [String] = [],
         pros: [String] = [],
         cons: [String] = [],
         suggestions: [String] = []) {
        self.id = UUID()
        self.stance = stance
        self.description = description
        self.keyPoints = keyPoints
        self.pros = pros
        self.cons = cons
        self.suggestions = suggestions
    }
}

/// 立场识别结果
struct StanceIdentificationResult: Codable, Equatable {
    let parties: [ContractParty]  // 识别出的当事人
    let contractType: String  // 合同类型
    let primaryOption: StanceOption  // 主要立场选项
    let alternativeOptions: [StanceOption]  // 替代立场选项

    var allOptions: [StanceOption] {
        [primaryOption] + alternativeOptions
    }
}
