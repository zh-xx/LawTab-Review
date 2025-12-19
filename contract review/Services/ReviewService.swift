//
//  ReviewService.swift
//  contract review
//
//  Created by Codex on 2025/10/18.
//

import Foundation

struct ReviewService {
    struct Configuration {
        /// 允许的最大输入 token 预估值，nil 表示不限制。
        var maxInputTokens: Int?
        var responseTemperature: Double

        init(maxInputTokens: Int? = nil, responseTemperature: Double = 0.2) {
            self.maxInputTokens = maxInputTokens
            self.responseTemperature = responseTemperature
        }
    }

    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    let configuration: Configuration

    init(session: URLSession = .shared, configuration: Configuration = Configuration()) {
        self.session = session
        self.configuration = configuration
        self.jsonEncoder = {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.withoutEscapingSlashes]
            return encoder
        }()
        self.jsonDecoder = JSONDecoder()
    }

    /// 调用模型，获取审核结果。
    func performReview(for document: LoadedDocument,
                       documentName: String,
                       position: String,
                       additionalRequest: String,
                       settings: Settings,
                       credentials: Credentials) async throws -> ReviewResult {
        guard !credentials.isEmpty else {
            throw ReviewError.missingAPIKey
        }

        let sanitizedPosition = position.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitizedPosition.isEmpty == false else {
            throw ReviewError.missingReviewPosition
        }

        let rawRequest = additionalRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultAdditionalRequest = settings.language == .chinese ? "无额外审核要求" : "No additional review requirements"
        let sanitizedRequest = rawRequest.isEmpty ? defaultAdditionalRequest : rawRequest

        // 获取当前语言
        let language = settings.language

        // Step 1-5: 内容生成（并行执行，互不依赖）
        async let mermaidFlow: String = requestStage(
            .mermaid,
            prompt: PromptTemplates.mermaid(documentText: document.text, language: language),
            temperature: 0.7,
            settings: settings,
            credentials: credentials
        )

        async let contractOverview: String = requestStage(
            .overview,
            prompt: PromptTemplates.contractOverview(documentText: document.text, language: language),
            temperature: 0.7,
            settings: settings,
            credentials: credentials
        )

        async let foundationAudit: String = requestStage(
            .foundation,
            prompt: PromptTemplates.foundationAudit(documentText: document.text,
                                                   position: sanitizedPosition,
                                                   additionalRequest: sanitizedRequest,
                                                   language: language),
            temperature: 0.7,
            settings: settings,
            credentials: credentials
        )

        async let businessAudit: String = requestStage(
            .business,
            prompt: PromptTemplates.businessAudit(documentText: document.text,
                                                 position: sanitizedPosition,
                                                 additionalRequest: sanitizedRequest,
                                                 language: language),
            temperature: 0.7,
            settings: settings,
            credentials: credentials
        )

        async let legalAudit: String = requestStage(
            .legal,
            prompt: PromptTemplates.legalAudit(documentText: document.text,
                                              position: sanitizedPosition,
                                              additionalRequest: sanitizedRequest,
                                              language: language),
            temperature: 0.7,
            settings: settings,
            credentials: credentials
        )

        let (mermaidFlowResult,
             contractOverviewResult,
             foundationAuditResult,
             businessAuditResult,
             legalAuditResult) = try await (
                mermaidFlow,
                contractOverview,
                foundationAudit,
                businessAudit,
                legalAudit
             )

        let detailedFindings = [foundationAuditResult, businessAuditResult, legalAuditResult]
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .joined(separator: "\n\n")

        // Step 6: 审核意见概要
        let summaryPrompt = PromptTemplates.auditSummary(documentText: document.text,
                                                        position: sanitizedPosition,
                                                        detailedFindings: detailedFindings,
                                                        language: language)
        let auditSummary = try await requestStage(
            .summary,
            prompt: summaryPrompt,
            temperature: 0.7,
            settings: settings,
            credentials: credentials
        )

        let outputs = ReviewOutputs(mermaidFlowchart: mermaidFlowResult,
                                    contractOverview: contractOverviewResult,
                                    foundationAudit: foundationAuditResult,
                                    businessAudit: businessAuditResult,
                                    legalAudit: legalAuditResult,
                                    detailedFindings: detailedFindings,
                                    auditSummary: auditSummary)

        return ReviewResult(documentName: documentName,
                            documentKind: document.kind,
                            characterCount: document.characterCount,
                            estimatedTokenCount: document.estimatedTokenCount,
                            reviewedAt: .init(),
                            outputs: outputs)
    }

    /// 发送轻量请求验证 API Key 与 Base URL 是否可用。
    /// - Parameter modelName: 指定要测试的模型名称（如 "deepseek-chat" 或 "deepseek-reasoner"）
    func testConnection(modelName: String, settings: Settings, credentials: Credentials) async throws {
        let prompt = """
        这是一条接口连通性测试请求，请仅回复"连接成功"，无需展开分析。
        """
        _ = try await sendRequest(prompt: prompt,
                                  temperature: 0.0,
                                  modelName: modelName,
                                  settings: settings,
                                  credentials: credentials)
    }

    /// 向 AI 提问关于合同的问题（用于对话功能）
    /// - Parameters:
    ///   - question: 用户的问题
    ///   - context: 合同原文和审核结果的上下文
    ///   - conversationHistory: 最近的对话消息历史（用于保持上下文）
    ///   - credentials: API 凭证
    /// - Returns: AI 的回复
    func askConversationQuestion(question: String,
                                 context: String,
                                 conversationHistory: [ConversationMessage],
                                 settings: Settings,
                                 credentials: Credentials) async throws -> String {
        guard !credentials.isEmpty else {
            throw ReviewError.missingAPIKey
        }

        let messages = buildConversationMessages(question: question,
                                                 context: context,
                                                 history: conversationHistory)

        let response = try await sendConversationRequest(messages: messages,
                                                         temperature: 0.7,
                                                         modelName: settings.reasonerModelName,
                                                         settings: settings,
                                                         credentials: credentials)
        return response
    }

    /// 向 AI 提问关于合同的问题（支持流式输出和思考过程）
    /// - Parameters:
    ///   - question: 用户的问题
    ///   - context: 合同原文和审核结果的上下文
    ///   - conversationHistory: 最近的对话消息历史
    ///   - credentials: API 凭证
    ///   - onThinking: 思考过程回调
    ///   - onResponse: 响应文本回调（逐字）
    func askConversationQuestionWithStreaming(question: String,
                                             context: String,
                                             conversationHistory: [ConversationMessage],
                                             settings: Settings,
                                             credentials: Credentials,
                                             onThinking: @escaping (String) -> Void,
                                             onResponse: @escaping (String) -> Void) async throws {
        guard !credentials.isEmpty else {
            throw ReviewError.missingAPIKey
        }

        let messages = buildConversationMessages(question: question,
                                                 context: context,
                                                 history: conversationHistory)

        try await sendConversationRequestWithStreaming(messages: messages,
                                                       temperature: 0.7,
                                                       modelName: settings.reasonerModelName,
                                                       settings: settings,
                                                       credentials: credentials,
                                                       onThinking: onThinking,
                                                       onResponse: onResponse)
    }

    /// 自动识别合同中的当事人和立场选项
    /// - Parameters:
    ///   - document: 加载的合同文档
    ///   - credentials: API 凭证
    ///   - language: 语言设置
    /// - Returns: 立场识别结果，包含当事人信息和可选的立场选项
    func identifyStance(for document: LoadedDocument,
                       settings: Settings,
                       credentials: Credentials,
                       language: AppLanguage = .chinese) async throws -> StanceIdentificationResult {
        guard !credentials.isEmpty else {
            throw ReviewError.missingAPIKey
        }

        let prompt = PromptTemplates.identifyStance(documentText: document.text, language: language)

        let response = try await sendRequest(prompt: prompt,
                                            temperature: 0.3,
                                            modelName: settings.reasonerModelName,
                                            settings: settings,
                                            credentials: credentials,
                                            language: language)

        // 解析 AI 响应并构建 StanceIdentificationResult
        // 由于 AI 返回的是文本，我们需要从中提取结构化信息
        let result = parseStanceResponse(response)
        return result
    }

    /// 解析立场识别的 AI 响应
    private func parseStanceResponse(_ response: String) -> StanceIdentificationResult {
        // 解析 AI 返回的文本格式，按照 Prompts.identifyStance 的输出格式
        let lines = response.split(separator: "\n").map(String.init)

        // MARK: - 1. 识别当事人
        var parties: [ContractParty] = []
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // 查找"合同当事人"部分
            if line.contains("合同当事人") {
                i += 1
                // 解析后续的当事人信息
                while i < lines.count {
                    let partyLine = lines[i].trimmingCharacters(in: .whitespaces)

                    // 检查是否是新的部分（如"合同类型"）
                    if partyLine.contains("合同类型") || partyLine.contains("推荐立场") {
                        break
                    }

                    // 解析当事人行（如"- 甲方：xxx"）
                    if partyLine.starts(with: "-") || partyLine.starts(with: "•") {
                        let content = partyLine.dropFirst().trimmingCharacters(in: .whitespaces)

                        // 按冒号分割
                        if let colonIndex = content.firstIndex(of: ":") ?? content.firstIndex(of: "：") {
                            let name = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                            let description = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                            // 判断角色
                            var role = "一方"
                            if name.contains("甲方") {
                                role = "甲方"
                            } else if name.contains("乙方") {
                                role = "乙方"
                            } else if name.contains("买方") {
                                role = "买方"
                            } else if name.contains("卖方") {
                                role = "卖方"
                            }

                            parties.append(ContractParty(
                                name: name,
                                role: role,
                                description: description
                            ))
                        }
                    }

                    i += 1
                }
                continue
            }

            i += 1
        }

        // 如果没有识别出当事人，使用默认值
        if parties.isEmpty {
            parties = [
                ContractParty(name: "甲方", role: "甲方", description: "合同一方当事人"),
                ContractParty(name: "乙方", role: "乙方", description: "合同另一方当事人")
            ]
        }

        // MARK: - 2. 识别合同类型
        var contractType = "通用合同"
        i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.contains("合同类型") {
                i += 1
                // 获取合同类型信息（下一行）
                if i < lines.count {
                    let typeInfo = lines[i].trimmingCharacters(in: .whitespaces)
                    if !typeInfo.isEmpty && !typeInfo.contains("合同") {
                        contractType = typeInfo
                    } else if typeInfo.contains("买卖") || typeInfo.contains("销售") {
                        contractType = "买卖合同"
                    } else if typeInfo.contains("服务") {
                        contractType = "服务合同"
                    } else if typeInfo.contains("租赁") {
                        contractType = "租赁合同"
                    } else if typeInfo.contains("承包") {
                        contractType = "承包合同"
                    } else {
                        contractType = typeInfo
                    }
                }
                break
            }

            i += 1
        }

        // 备选：从整个响应中检测合同类型
        if contractType == "通用合同" {
            if response.contains("买卖") || response.contains("销售") {
                contractType = "买卖合同"
            } else if response.contains("服务") {
                contractType = "服务合同"
            } else if response.contains("租赁") {
                contractType = "租赁合同"
            } else if response.contains("承包") {
                contractType = "承包合同"
            }
        }

        // MARK: - 3. 解析立场选项
        var stanceOptions: [StanceOption] = []
        i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // 查找立场选项（如"#### 选项1："或"选项1："）
            if line.contains("选项") && (line.contains("：") || line.contains(":")) {
                // 提取选项标题
                var stanceTitle = line
                    .replacingOccurrences(of: "###", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .trimmingCharacters(in: .whitespaces)

                // 移除编号（如"选项1："）
                if let colonIndex = stanceTitle.firstIndex(of: ":") ?? stanceTitle.firstIndex(of: "：") {
                    stanceTitle = String(stanceTitle[stanceTitle.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                }

                var description = ""
                var keyPoints: [String] = []
                var pros: [String] = []
                var cons: [String] = []
                var suggestions: [String] = []

                i += 1

                // 解析该选项下的内容
                var currentSection = "" // 记录当前在哪个部分（描述、关键要点等）

                while i < lines.count {
                    let contentLine = lines[i].trimmingCharacters(in: .whitespaces)

                    // 检查是否进入新选项或新部分
                    if contentLine.contains("选项") && (contentLine.contains("：") || contentLine.contains(":")) {
                        // 进入新选项
                        break
                    }

                    if contentLine.contains("合同类型") || contentLine.contains("推荐立场") {
                        // 进入新主要部分
                        break
                    }

                    // 识别子部分
                    if contentLine.contains("描述：") || contentLine.contains("描述：") {
                        currentSection = "description"
                        // 提取描述内容
                        if let colonIndex = contentLine.firstIndex(of: ":") ?? contentLine.firstIndex(of: "：") {
                            description = String(contentLine[contentLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                        }
                    } else if contentLine.contains("关键要点") {
                        currentSection = "keyPoints"
                    } else if contentLine.contains("优势") && !contentLine.contains("劣势") {
                        currentSection = "pros"
                    } else if contentLine.contains("劣势") || contentLine.contains("缺点") {
                        currentSection = "cons"
                    } else if contentLine.contains("建议") || contentLine.contains("谈判建议") {
                        currentSection = "suggestions"
                    } else if !contentLine.isEmpty && (contentLine.starts(with: "-") || contentLine.starts(with: "•") || contentLine.starts(with: "1.") || contentLine.starts(with: "2.")) {
                        // 提取列表项
                        let item = contentLine.dropFirst(2).trimmingCharacters(in: .whitespaces)

                        if !item.isEmpty {
                            switch currentSection {
                            case "keyPoints":
                                keyPoints.append(String(item))
                            case "pros":
                                pros.append(String(item))
                            case "cons":
                                cons.append(String(item))
                            case "suggestions":
                                suggestions.append(String(item))
                            default:
                                break
                            }
                        }
                    }

                    i += 1
                }

                // 创建立场选项
                if !stanceTitle.isEmpty {
                    stanceOptions.append(StanceOption(
                        stance: stanceTitle,
                        description: description.isEmpty ? "该立场下的权益保护方案" : description,
                        keyPoints: keyPoints.isEmpty ? ["根据合同内容分析"] : keyPoints,
                        pros: pros.isEmpty ? ["保护自身权益"] : pros,
                        cons: cons.isEmpty ? ["需要谨慎应对"] : cons,
                        suggestions: suggestions.isEmpty ? ["建议协商解决"] : suggestions
                    ))
                }

                continue
            }

            i += 1
        }

        // 如果没有解析出立场选项，使用默认值
        if stanceOptions.isEmpty {
            let primaryOption = StanceOption(
                stance: "作为甲方",
                description: "以甲方身份参与合同谈判，优先保护自身权益",
                keyPoints: ["明确权益和责任", "争取有利条款"],
                pros: ["议价权较强", "条款相对宽松"],
                cons: ["需承担风险", "面临强硬要求"],
                suggestions: ["明确核心条款", "制定谈判策略"]
            )

            let alternativeOption = StanceOption(
                stance: "作为乙方",
                description: "以乙方身份参与合同谈判，平衡各方权益",
                keyPoints: ["保护合理权益", "明确义务范围"],
                pros: ["可限制无理要求", "支付条款相对有利"],
                cons: ["面临强势谈判", "可能遭遇压力"],
                suggestions: ["提出合理诉求", "灵活协商"]
            )

            stanceOptions = [primaryOption, alternativeOption]
        }

        // 构建最终结果
        let primaryOption = stanceOptions.first ?? StanceOption(
            stance: "默认立场",
            description: "根据合同分析"
        )

        let alternativeOptions = stanceOptions.count > 1 ? Array(stanceOptions.dropFirst()) : []

        return StanceIdentificationResult(
            parties: parties,
            contractType: contractType,
            primaryOption: primaryOption,
            alternativeOptions: alternativeOptions
        )
    }

    private func buildConversationMessages(question: String,
                                          context: String,
                                          history: [ConversationMessage]) -> [ChatCompletionPayload.Message] {
        var messages: [ChatCompletionPayload.Message] = []

        // 系统提示
        let systemPrompt = """
        你是一名资深律师，专门协助用户理解和分析合同条款。
        用户将针对合同提出各种问题，你需要基于提供的合同原文和审核结果来回答。
        回答时要专业、准确，并指出具体的条款位置。

        以下是合同的原文和审核结果，请在回答时参考这些信息：

        \(context)
        """

        messages.append(.init(role: "system", content: systemPrompt))

        // 添加对话历史
        for msg in history {
            messages.append(.init(role: msg.role, content: msg.content))
        }

        // 当前问题
        messages.append(.init(role: "user", content: question))

        return messages
    }

    private func sendConversationRequest(messages: [ChatCompletionPayload.Message],
                                        temperature: Double,
                                        modelName: String,
                                        settings: Settings,
                                        credentials: Credentials) async throws -> String {
        guard let url = makeCompletionsURL(baseURL: settings.apiBaseURL) else {
            throw ReviewError.invalidAPIEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatCompletionPayload(model: modelName,
                                            messages: messages,
                                            temperature: temperature)
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewError.serviceError(message: "无效的服务器响应。")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let message = try? decodeAPIError(from: data) {
                throw ReviewError.serviceError(message: message)
            } else {
                throw ReviewError.serviceError(message: "服务返回错误：HTTP \(httpResponse.statusCode)。")
            }
        }

        guard let completion = try? jsonDecoder.decode(ChatCompletionResponse.self, from: data),
              let text = completion.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              text.isEmpty == false else {
            throw ReviewError.decodingFailed
        }

        return text
    }

    /// 发送对话请求（支持流式输出）
    private func sendConversationRequestWithStreaming(messages: [ChatCompletionPayload.Message],
                                                      temperature: Double,
                                                      modelName: String,
                                                      settings: Settings,
                                                      credentials: Credentials,
                                                      onThinking: @escaping (String) -> Void,
                                                      onResponse: @escaping (String) -> Void) async throws {
        guard let url = makeCompletionsURL(baseURL: settings.apiBaseURL) else {
            throw ReviewError.invalidAPIEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")

        // 添加 stream: true 参数
        let payloadData = try jsonEncoder.encode(ChatCompletionPayload(model: modelName,
                                                                       messages: messages,
                                                                       temperature: temperature))
        var jsonObject = try JSONSerialization.jsonObject(with: payloadData) as! [String: Any]
        jsonObject["stream"] = true
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)

        let (asyncBytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewError.serviceError(message: "无效的服务器响应。")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ReviewError.serviceError(message: "服务返回错误：HTTP \(httpResponse.statusCode)。")
        }

        // 处理流式响应
        var thinkingBuffer = ""
        var totalDataLines = 0
        var totalThinkingChunks = 0
        var totalResponseChunks = 0

        print("DEBUG ReviewService: 开始处理流式响应")

        for try await line in asyncBytes.lines {
            // 跳过空行
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            // 检查是否是 data: 前缀
            guard trimmedLine.hasPrefix("data: ") else { continue }

            totalDataLines += 1

            let jsonStr = String(trimmedLine.dropFirst(6))  // 移除 "data: " 前缀

            // 检查是否是结束标记
            if jsonStr == "[DONE]" {
                print("DEBUG ReviewService: 收到 [DONE] 标记，totalDataLines: \(totalDataLines)")
                break
            }

            // 解析 JSON
            guard let data = jsonStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  !choices.isEmpty else {
                continue
            }

            // 获取第一个 choice 对象
            let choiceObj = choices[0]

            // 从 choice 中提取 delta 对象
            guard let delta = choiceObj["delta"] as? [String: Any] else {
                // 如果没有 delta，这一行没有有效内容，跳过
                continue
            }

            // 调试：打印 delta 的所有信息
            if totalDataLines <= 5 {
                print("DEBUG ReviewService: Line \(totalDataLines) - delta keys: \(delta.keys.sorted())")
                for (key, value) in delta.sorted(by: { $0.key < $1.key }) {
                    print("DEBUG ReviewService: delta[\(key)] = \(String(describing: value))")
                }
            }

            // 检查思考内容
            if let reasoning = delta["reasoning_content"] as? String, !reasoning.isEmpty {
                thinkingBuffer += reasoning
                totalThinkingChunks += 1
                // 每积累一定字符就回调一次
                if thinkingBuffer.count > 20 {
                    print("DEBUG ReviewService: 调用 onThinking，长度: \(thinkingBuffer.count)")
                    onThinking(thinkingBuffer)
                    thinkingBuffer = ""
                }
            }

            // 检查回复内容（content 可能在不同的字段中）
            var contentStr: String? = nil

            // 首先尝试 "content" 字段
            if let content = delta["content"], !(content is NSNull) {
                if let str = content as? String, !str.isEmpty {
                    contentStr = str
                }
            }

            // 如果 content 为空，尝试 "message" 字段（某些API版本使用）
            if contentStr == nil, let message = delta["message"], !(message is NSNull) {
                if let str = message as? String, !str.isEmpty {
                    contentStr = str
                }
            }

            // 如果 message 为空，尝试 "text" 字段
            if contentStr == nil, let text = delta["text"], !(text is NSNull) {
                if let str = text as? String, !str.isEmpty {
                    contentStr = str
                }
            }

            // 处理找到的内容
            if let contentStr = contentStr {
                // 输出剩余思考内容
                if !thinkingBuffer.isEmpty {
                    print("DEBUG ReviewService: 调用 onThinking（剩余），长度: \(thinkingBuffer.count)")
                    onThinking(thinkingBuffer)
                    thinkingBuffer = ""
                }
                // 逐字输出回复
                print("DEBUG ReviewService: 调用 onResponse，长度: \(contentStr.count)")
                totalResponseChunks += 1
                onResponse(contentStr)
            }
        }

        print("DEBUG ReviewService: 流式响应处理完成，totalDataLines: \(totalDataLines), thinkingChunks: \(totalThinkingChunks), responseChunks: \(totalResponseChunks)")

        // 输出剩余的思考内容
        if !thinkingBuffer.isEmpty {
            print("DEBUG ReviewService: 调用 onThinking（最后）")
            onThinking(thinkingBuffer)
        }
    }
}

private extension ReviewService {
    func sendRequest(prompt: String,
                     temperature: Double,
                     settings: Settings,
                     credentials: Credentials) async throws -> String {
        return try await sendRequest(prompt: prompt,
                                     temperature: temperature,
                                     modelName: settings.chatModelName,
                                     settings: settings,
                                     credentials: credentials,
                                     language: settings.language)
    }

    func sendRequest(prompt: String,
                     temperature: Double,
                     modelName: String,
                     settings: Settings,
                     credentials: Credentials,
                     language: AppLanguage = .chinese) async throws -> String {
        guard let url = makeCompletionsURL(baseURL: settings.apiBaseURL) else {
            throw ReviewError.invalidAPIEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(credentials.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatCompletionPayload(model: modelName,
                                            messages: [
                                                .init(role: "system", content: PromptTemplates.systemPrompt(language: language)),
                                                .init(role: "user", content: prompt)
                                            ],
                                            temperature: temperature)
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewError.serviceError(message: "无效的服务器响应。")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let message = try? decodeAPIError(from: data) {
                throw ReviewError.serviceError(message: message)
            } else {
                throw ReviewError.serviceError(message: "服务返回错误：HTTP \(httpResponse.statusCode)。")
            }
        }

        guard let completion = try? jsonDecoder.decode(ChatCompletionResponse.self, from: data),
              let text = completion.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              text.isEmpty == false else {
            throw ReviewError.decodingFailed
        }

        return text
    }

    func makeCompletionsURL(baseURL: String) -> URL? {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmedBase) else {
            return nil
        }

        var normalizedPath = components.path
        if normalizedPath.hasSuffix("/") {
            normalizedPath.removeLast()
        }
        normalizedPath += "/chat/completions"
        components.path = normalizedPath
        return components.url
    }

    func decodeAPIError(from data: Data) throws -> String? {
        guard !data.isEmpty else { return nil }
        return try? jsonDecoder.decode(APIErrorEnvelope.self, from: data).error.message
    }
}

private extension ReviewService {
    enum Stage {
        case mermaid, overview, foundation, business, legal, summary

        var displayName: String {
            switch self {
            case .mermaid: return "流程图生成"
            case .overview: return "合同概要"
            case .foundation: return "基础审核"
            case .business: return "业务条款审核"
            case .legal: return "法律条款审核"
            case .summary: return "审核总结"
            }
        }
    }

    func requestStage(_ stage: Stage,
                      prompt: String,
                      temperature: Double,
                      settings: Settings,
                      credentials: Credentials) async throws -> String {
        do {
            return try await sendRequest(prompt: prompt,
                                         temperature: temperature,
                                         settings: settings,
                                         credentials: credentials)
        } catch let reviewError as ReviewError {
            throw stageAwareError(stage: stage, error: reviewError)
        } catch {
            throw ReviewError.serviceError(message: "「\(stage.displayName)」阶段失败：\(error.localizedDescription)")
        }
    }

    func stageAwareError(stage: Stage, error: ReviewError) -> ReviewError {
        switch error {
        case .serviceError(let message):
            return .serviceError(message: "「\(stage.displayName)」阶段失败：\(message)")
        case .invalidAPIEndpoint, .missingAPIKey, .missingReviewPosition,
             .documentTooLarge, .emptyDocument, .fileReadFailed,
             .invalidFileType, .unsupportedFileType, .decodingFailed:
            return error
        }
    }
}

private extension ReviewService {
    // MARK: - Legacy Prompts enum removed
    // 已迁移到 PromptTemplates.swift，支持多语言

    // 旧的 Prompts 枚举已被删除，所有提示词现在通过 PromptTemplates 管理
    /*
    enum Prompts {
        static let systemPrompt = """
        你是一名资深律师，负责审核合同条款并识别潜在风险。请在输出中包含核心风险、建议修改点和总体结论，适度精炼，输出中文。
        """

        static func mermaid(documentText: String) -> String {
            """
            从合同文本如下所示内容中提取完整的业务交易流程，生成 mermaid 格式的 flowchart 流程图。

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            ## 提取要求：

            ### 1. 流程完整性
            - 覆盖从合同签订到履约完成的全生命周期
            - 包含正常履约流程、违约处理流程、合同解除情况
            - 体现甲乙双方的互动关系和权责

            ### 2. 信息精确性
            - **时间节点**：提取具体时间要求（X个工作日、X小时等）和触发条件
            - **金额数据**：提取具体金额和比例（如30%预付款、总额等）
            - **数量规格**：提取货物/服务的具体数量、型号、规格
            - **地点信息**：提取具体的交付地点、验收地点等
            - **标准条件**：提取验收标准、质量要求、技术指标等
            - **信息限制**：所有提取的信息必须来自合同文本，保持信息的精准性

            ### 3. 节点内容格式
            - 每个节点用方括号包含主要行为
            - 节点内多项信息用 `<br>` 换行分隔
            - 连接线上标注触发条件和时间要求，格式：`|条件说明|`。如合同中无该节点的时间要求和触发条件，则在连接线上标注“？”

            ### 4. 流程逻辑
            - 用 `-->` 表示正常流向
            - 体现分支决策点（如验收合格/不合格）
            - 包含并行流程（如风险转移与所有权转移）
            - 展现违约后果的递进关系（轻微违约→严重违约→解除合同）

            ### 5. 视觉样式
            在流程图末尾添加样式定义：
            - 正常履约节点：`style [节点ID] fill:#e6e6fa`（淡紫色）
            - 违约相关节点：`style [节点ID] fill:#ffff99`（黄色）
            - 合同解除节点：`style [节点ID] fill:#ff6666`（红色）
            - 正常完成节点：`style [节点ID] fill:#90ee90`（淡绿色）

            ## 输出格式：
            - 仅输出 mermaid 代码，以 `flowchart TD` 开头，确保输出端可以直接进行 mermaid 渲染
            - 不包含任何解释文字或代码块标记
            - 确保语法正确，可直接渲染
            """
        }

        static func contractOverview(documentText: String) -> String {
            """
            根据下述合同文本，客观总结合同的基本内容，为法务人员提供快速了解合同概况的结构化信息。**仅做客观描述，不进行任何法律风险评估或审核建议。**

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            ## 输出格式要求：

            ### 一、合同基本信息
            | 项目 | 内容 |
            |------|------|
            | 合同名称 | [提取合同标题或约定名称] |
            | 合同类型 | [如：买卖合同、服务合同、租赁合同等] |
            | 合同当事人 | 甲方：[名称、地址]<br>乙方：[名称、地址] |
            | 签订时间 | [合同签署日期] |
            | 合同期限 | [起止时间或履行期限] |
            | 合同金额 | [总金额及币种，如有分期说明分期安排] |

            ### 二、业务模式概述
            **简要描述：**[用1-2段话概括该合同的核心业务内容，说明甲乙双方的基本交易关系]

            ### 三、核心条款要素
            #### 3.1 交易要素
            | 要素 | 具体内容 |
            |------|----------|
            | 标的物/服务内容 | [具体的货物、服务或其他标的描述] |
            | 数量规格 | [数量、型号、技术参数等] |
            | 价格构成 | [单价、总价、调价机制等] |
            | 支付方式 | [付款比例、付款节点、付款方式] |
            | 交付方式 | [交付地点、交付时间、交付标准] |

            #### 3.2 权利义务分配
            **甲方主要权利义务：**
            - [列出甲方的主要权利]
            - [列出甲方的主要义务]
            **乙方主要权利义务：**
            - [列出乙方的主要权利]
            - [列出乙方的主要义务]

            #### 3.3 履行保障条款
            | 条款类型 | 具体约定 |
            |----------|----------|
            | 违约责任 | [甲方违约后果、乙方违约后果] |
            | 担保措施 | [保证金、担保方式等] |
            | 验收标准 | [验收程序、验收标准、争议处理] |
            | 质量保证 | [质保期、质保责任、售后服务] |

            #### 3.4 风险分担与特殊约定
            **风险分担：**
            - [不可抗力条款]
            - [风险转移节点]
            - [损失承担约定]
            **特殊约定：**
            - [知识产权条款]
            - [保密条款]
            - [专有性约定]
            - [其他特殊条件或限制]

            #### 3.5 争议解决与合同终止
            | 项目 | 约定内容 |
            |------|----------|
            | 争议解决方式 | [协商、调解、仲裁、诉讼及管辖] |
            | 合同变更 | [变更条件和程序] |
            | 合同解除 | [解除条件、解除程序、解除后果] |
            | 适用法律 | [适用的法律法规] |

            ### 四、关键时间节点
            - [按时间顺序列出合同履行的关键节点，如签约、付款、交付、验收等时间安排]

            ## 输出要求：
            1. **客观性**：仅提取和描述合同条款内容，不添加主观判断或法律意见
            2. **完整性**：涵盖合同的主要条款，如某项内容合同中未约定则标注"未约定"
            3. **准确性**：忠实反映合同原文内容，重要条款可适当引用原文关键表述
            4. **简洁性**：根据合同复杂程度控制篇幅，保持表达简洁明了
            5. **结构性**：严格按照上述格式输出，便于法务人员快速定位关键信息
            """
        }

        static func foundationAudit(documentText: String,
                                     position: String,
                                     additionalRequest: String) -> String {
            """
            # 角色设定
            请作为一名具有多年经验的合同法律顾问，根据你的审核立场「\(position)」和用户额外的审核要求「\(additionalRequest)」，对合同文本进行以下四个方面的基础审核，不要遗漏任何一个审查点：

            合同全文如下：
            \(documentText)

            # 基础审查要点
            1. 文本准确性：
               - 检查所有关键词、术语拼写是否正确
               - 核对所有数字、金额、比例是否准确（特别注意大小写金额是否一致）
               - 检查日期表述是否精确（避免使用"近期"、"尽快"等模糊词语）
            2. 格式规范性：
               - 检查标点符号使用是否规范
               - 审核条款编号是否有序连贯，是否存在重复编号
               - 检查排版是否整洁，有无明显格式错误
               - 确认签署处是否留有足够空间
            3. 语言表述清晰性：
               - 检查是否存在语法错误或表述不清的句子
               - 识别有歧义或模糊的描述，特别是关于时间、数量、质量的表述
               - 检查专业术语使用是否准确
            4. 文本一致性：
               - 检查同一概念在合同不同部分的称谓是否一致（如产品名称、型号等）
               - 核对合同内部引用条款编号是否准确
               - 确认前后条款是否存在逻辑冲突
               - 检查附件与正文是否一致

            # 输出要求
            1. 以表格方式输出；
            2. 表格的行标题依次为：序号、问题类型、原文表述、风险原因、修订建议、风险等级；
            3. 问题类型应为文本准确性、格式规范性、语言表述清晰性、文本一致性中择一；
            4. 风险等级为高中低，各行按照风险从高到低进行排序，同时要以红黄蓝的 emoji 表情标注；
            5. 原文表述应用引号表明原文准确内容，并说明具体的章、节、条、款、项（如有）；
            6. 本节点仅进行这四方面的审核，无需对业务条款和法律条款的要点进行审核；
            7. 在表格之下总结表格中的高风险事项，除表格和总结外，无需输出其他内容。
            """
        }

        static func businessAudit(documentText: String,
                                  position: String,
                                  additionalRequest: String) -> String {
            """
            # 角色设定
            请作为一名具有多年经验的合同法律顾问，根据你的审核立场「\(position)」和用户额外的审核要求「\(additionalRequest)」，对合同文本进行以下六个方面的业务条款审核，不要遗漏任何一个审查点：

            合同全文如下：
            \(documentText)

            # 业务条款审查要点
            1. 合同标的条款：
               - 标的物或服务的描述是否清晰完整
               - 标的物或服务的数量是否明确
               - 标的物的质量标准或服务标准是否明确
               - 标的物的技术指标或性能要求是否明确
               - 标的物的包装要求是否明确
               - 标的物的检验或验收标准是否明确
               - 标的物的售后服务是否明确
            2. 合同交付条款：
               - 交付时间是否明确
               - 交付地点是否明确
               - 交付方式是否明确
               - 交付风险转移是否明确
               - 交付后的验收程序是否明确
               - 交付时是否有特殊要求（设备安装、调试等）
            3. 合同价款条款：
               - 价格构成是否明确（单价、总价、计算方式）
               - 计价方式是否明确（按件、按时间、按工作量等）
               - 货币单位是否明确，汇率问题是否考虑（跨境交易）
               - 价税是否分离，税费承担是否明确
               - 付款方式是否明确（一次性、分期、质保金）
               - 付款节点是否与履行进度匹配
               - 付款条件是否明确且可操作
               - 付款凭证与发票约定是否清晰
            4. 合同履行条款：
               - 履行时间是否明确具体（避免"合理时间"等模糊表述）
               - 履行地点是否具体明确
               - 履行方式是否详细描述（交付方式、包装要求、运输方式）
               - 履行程序是否结构化说明（每个步骤的具体操作）
               - 权利转移点是否明确（所有权转移时间）
               - 风险转移点是否明确（风险责任承担时间）
               - 履行中的通知义务是否明确规定
            5. 权利义务条款：
               - 主要权利是否全面列举，无遗漏
               - 是否存在隐含的弃权条款
               - 豁免条款是否合理（特别是不可抗力范围）
               - 主要义务是否无遗漏，履行标准是否明确
               - 义务的合理性与可执行性
               - 后合同义务是否明确（如保密延续期限）
               - 从权利义务是否明确（附属于主权利的权利义务）
            6. 知识产权条款：
               - 现有知识产权归属是否明确
               - 合同履行过程中产生的知识产权归属是否明确
               - 知识产权使用权范围、目的、期限是否明确
               - 知识产权转让与许可条件是否清晰
               - 知识产权保护与维护责任如何分配
               - 保密与竞争限制期限、范围是否合理

            # 输出要求
            1. 以表格方式输出；
            2. 表格的行标题依次为：序号、问题类型、原文表述、风险原因、修订建议、风险等级；
            3. 问题类型应为六个业务条款审核要点中择一；
            4. 风险等级为高中低，各行按照风险从高到低进行排序，同时要以红黄蓝的 emoji 表情标注；
            5. 原文表述应用引号表明原文准确内容，并说明具体的章、节、条、款、项（如有）；
            6. 本节点仅进行这六方面的审核，无需对其他方面进行审核；
            7. 在表格之下总结表格中的高风险事项，除表格和总结外，无需输出其他内容。
            """
        }

        static func legalAudit(documentText: String,
                               position: String,
                               additionalRequest: String) -> String {
            """
            # 角色设定
            请作为一名具有多年经验的合同法律顾问，根据你的审核立场「\(position)」和用户额外的审核要求「\(additionalRequest)」，对合同文本进行以下十个方面的法律条款审核，不要遗漏任何一个审查点：

            合同全文如下：
            \(documentText)

            # 法律条款审查要点
            1. 生效条款：
               - 合同成立与生效是否有明确区分
               - 生效条件是否明确（签署即生效、附条件生效、附期限生效）
               - 生效条件的可行性是否考虑
               - 生效前的法律责任如何安排
            2. 违约责任条款：
               - 重点审核：违约行为的定义是否明确全面（迟延履行、质量不合格、拒绝履行等）
               - 违约责任形式是否明确（继续履行、采取补救、赔偿损失、支付违约金）
               - 违约金比例是否合理（既不过高具惩罚性，也不过低难以弥补损失）
               - 违约责任是否对双方公平（注意违约金比例是否对等）
               - 违约责任的计算方式是否明确
            3. 合同变更、解除、终止条款：
               - 变更条件是否明确（哪些情况下可以变更）
               - 变更程序是否规范（书面变更、通知方式、签署程序）
               - 解除条件是否合理（法定解除条件、约定解除条件）
               - 解除程序的操作性（通知方式、时间限制）
               - 终止条件的明确性（何种情况下自动终止）
               - 存续条款的合理性（哪些条款在合同终止后继续有效）
               - 终止后的权利义务安排（清算、资料返还等）
            4. 法律适用条款：
               - 适用法律是否明确（具体到哪个国家/地区的法律）
               - 所选法律的合理性（与合同标的、履行地的关联）
               - 是否与强制性规定冲突（履行地法律的强制性规定）
               - 选择的法律在实际纠纷中的可适用性与可执行性
            5. 保密条款：
               - 保密信息范围是否明确定义
               - 保密期限是否明确且合理
               - 例外情况是否合理且有限定
               - 违反保密义务的责任是否明确
            6. 不可抗力条款：
               - 不可抗力事件定义是否合理（避免将可控因素纳入）
               - 通知义务是否明确（时间、方式、证明材料）
               - 责任减免条件是否公平合理
               - 不可抗力事件持续的后续处理措施是否明确
            7. 争议解决条款：
               - 争议解决方式选择是否明确（协商、诉讼、仲裁）
               - 管辖地点或仲裁机构是否明确
               - 是否存在争议解决方式冲突（同时约定仲裁和诉讼）
               - 适用法律选择是否与争议解决方式匹配
            8. 送达条款：
               - 送达方式是否明确（当面送达、邮寄、电子邮件等）
               - 送达地址或联系方式是否准确完整
               - 送达时间和生效条件是否明确
               - 地址变更通知义务是否明确
            9. 授权条款：
               - 授权人员身份是否明确具体
               - 授权范围和权限是否清晰界定
               - 授权期限是否合理规定
               - 撤销或变更授权的机制是否完善
            10. 其他法律条款：
                - 解释规则是否明确（条款冲突处理原则）
                - 签订时间和地点是否明确
                - 条款的独立性是否明确（部分无效不影响整体）

            # 输出要求
            1. 以表格方式输出；
            2. 表格的行标题依次为：序号、问题类型、原文表述、风险原因、修订建议、风险等级；
            3. 问题类型应为十个法律条款审核要点中择一；
            4. 风险等级为高中低，各行按照风险从高到低进行排序，同时要以红黄蓝的 emoji 表情标注；
            5. 原文表述应用引号表明原文准确内容，并说明具体的章、节、条、款、项（如有）；
            6. 本节点仅进行这十方面的审核，无需对其他方面进行审核；
            7. 在表格之下总结表格中的高风险事项，除表格和总结外，无需输出其他内容。
            """
        }

        static func auditSummary(documentText: String,
                                 position: String,
                                 detailedFindings: String) -> String {
            """
            请您扮演法律专业人员，基于合同内容如下以及详细审核意见，为业务部门起草一份简洁回复。

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            --- 详细审核意见 ---
            \(detailedFindings)
            --- 详细审核意见结束 ---

            回复内容需包含两个自然段落：

            # 第一段：合同核心内容概述
            请用一段连贯的文字概括本合同的核心内容。说明合同性质（例如：这是一份为期三年的设备采购框架协议），并清晰描述基本的业务模式，重点包括：交易的是什么货物或服务、合同总金额、具体的支付方式与节奏、以及关键的时间节点。在叙述中，请根据我方的审核立场「\(position)」，使用“我方”、“对方”或具体的公司名称来指代合同各方，避免使用“甲方、乙方”的表述。

            # 第二段：主要风险提示
            请用另一段文字集中说明审核中发现的主要风险（需完全依据详细审核意见）。写作时，请先以一句总述性语句开头（例如：“经审核，本合同存在以下几项主要风险需提请关注：”），然后使用数字序号（如1. 2. 3.）分项列出各项风险，数量根据实际情况而定。每项风险应简要说明其类型、具体内容、可能造成的影响以及建议的关注程度。

            # 整体要求：
            - 回复使用 Markdown 格式。第一段文字加粗，第二段无需加粗，但应使用序号（如1. 2. 3.）分项列出各项风险。
            - 语言需简洁、专业、清晰，直接呈现最终内容，无需出现“第一部分”、“第二部分”等引导性词语。
            - 确保立场正确，表述符合我方利益。
            """
        }

        static func identifyStance(documentText: String) -> String {
            """
            请分析以下合同文本，识别合同中的当事人和合同类型，并为用户推荐可能的立场选项。

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            ## 分析要求：

            ### 1. 当事人识别
            - 识别合同中的各方当事人（甲方、乙方等）
            - 提取当事人名称、身份特征
            - 分析各方可能的角色定位（买方/卖方/服务提供商/服务接收方等）

            ### 2. 合同类型识别
            - 确定合同的基本类型（买卖合同、服务合同、承包合同、租赁合同等）
            - 总结核心交易内容

            ### 3. 立场分析
            根据合同性质和当事人身份，推荐：
            - 主要立场选项（如"作为买方/甲方"或"作为卖方/乙方"）
            - 该立场下的关键考量点
            - 各立场的优劣势对比
            - 针对该立场的初步谈判建议

            ## 输出格式：

            ### 合同当事人
            - 甲方：[名称和身份特征]
            - 乙方：[名称和身份特征]

            ### 合同类型
            [具体合同类型名称及核心交易内容]

            ### 推荐立场选项
            #### 选项1：[立场描述]
            - 描述：[该立场的含义和采取方式]
            - 关键要点：[该立场下应关注的要点，用数字列表]
            - 优势：[采取该立场的优势，用数字列表]
            - 劣势：[采取该立场的劣势，用数字列表]
            - 谈判建议：[针对该立场的谈判策略和建议]

            #### 选项2：[立场描述]
            [同上格式]

            ## 整体要求：
            - 分析必须基于合同文本的实际内容
            - 立场推荐应该客观中立，给出平衡的选项对比
            - 输出使用中文，格式清晰易读
            """
        }
    }
    */
}

private extension ReviewService {
    struct ChatCompletionPayload: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct ChatMessage: Decodable {
                let content: String
            }

            let message: ChatMessage
        }

        let choices: [Choice]
    }

    struct APIErrorEnvelope: Decodable {
        struct APIError: Decodable {
            let message: String
        }

        let error: APIError
    }
}
