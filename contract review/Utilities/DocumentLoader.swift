//
//  DocumentLoader.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation
import PDFKit
import AppKit

struct DocumentLoader {
    private let tokenEstimator = TokenEstimator()

    /// 解析用户选择的文件，返回完整文本及元数据。
    /// - Parameters:
    ///   - url: 用户选中的沙盒 URL。
    ///   - maxEstimatedTokenCount: 允许的最大 token 预估值；若为 `nil` 则不限制。
    func loadDocument(from url: URL, maxEstimatedTokenCount: Int?) throws -> LoadedDocument {
        guard let kind = detectDocumentKind(for: url) else {
            let ext = url.pathExtension
            if ext.isEmpty {
                throw ReviewError.invalidFileType
            } else {
                throw ReviewError.unsupportedFileType(ext)
            }
        }

        let rawText: String
        switch kind {
        case .plainText:
            rawText = try loadPlainText(from: url)
        case .pdf:
            rawText = try loadPDF(from: url)
        case .docx:
            rawText = try loadDocx(from: url)
        }

        let sanitizedText = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard sanitizedText.isEmpty == false else {
            throw ReviewError.emptyDocument
        }

        let characterCount = sanitizedText.count
        let estimatedTokens = tokenEstimator.estimateTokens(for: sanitizedText)

        if let limit = maxEstimatedTokenCount, estimatedTokens > limit {
            throw ReviewError.documentTooLarge(estimatedTokens: estimatedTokens, limit: limit)
        }

        return LoadedDocument(kind: kind,
                              text: sanitizedText,
                              characterCount: characterCount,
                              estimatedTokenCount: estimatedTokens)
    }
}

private extension DocumentLoader {
    func detectDocumentKind(for url: URL) -> DocumentKind? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt":
            return .plainText
        case "pdf":
            return .pdf
        case "docx":
            return .docx
        case "":
            return nil
        default:
            return nil
        }
    }

    func loadPlainText(from url: URL) throws -> String {
        do {
            var usedEncoding = String.Encoding.utf8
            return try String(contentsOf: url, usedEncoding: &usedEncoding)
        } catch {
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                throw ReviewError.fileReadFailed
            }
        }
    }

    func loadPDF(from url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw ReviewError.unsupportedFileType(url.pathExtension)
        }

        var components: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let content = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  content.isEmpty == false else {
                continue
            }
            components.append(content)
        }

        guard components.isEmpty == false else {
            throw ReviewError.emptyDocument
        }

        return components.joined(separator: "\n\n")
    }

    func loadDocx(from url: URL) throws -> String {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.officeOpenXML
        ]

        do {
            let attributed = try NSAttributedString(url: url,
                                                    options: options,
                                                    documentAttributes: nil)
            return attributed.string
        } catch {
            throw ReviewError.fileReadFailed
        }
    }
}

private extension DocumentLoader {
    struct TokenEstimator {
        /// 依据经验公式粗略估算 tokens 数量，避免提前截断。
        func estimateTokens(for text: String) -> Int {
            guard text.isEmpty == false else { return 0 }
            let scalarCount = text.unicodeScalars.count
            let estimate = Double(scalarCount) / 3.8
            return max(1, Int(estimate.rounded(.toNearestOrEven)))
        }
    }
}
