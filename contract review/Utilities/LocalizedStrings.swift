//
//  LocalizedStrings.swift
//  contract review
//
//  本地化字符串管理器 - 支持中英双语切换
//

import Foundation

/// 本地化字符串管理器
/// 使用方式: L.current = .english 切换语言后，所有文本自动更新
struct L {
    /// 当前语言设置
    static var current: AppLanguage = .chinese

    // MARK: - Tab 标题
    static var tabSubmit: String {
        current == .chinese ? "提交合同" : "Submit Contract"
    }

    static var tabResults: String {
        current == .chinese ? "审核结果" : "Review Results"
    }

    static var tabConversation: String {
        current == .chinese ? "合同对话" : "Contract Q&A"
    }

    // MARK: - 提交页面 - 步骤标题
    static var step1Title: String {
        current == .chinese ? "1. 选择合同文件" : "1. Select Contract File"
    }

    static var step2Title: String {
        current == .chinese ? "2. 确定审核立场" : "2. Define Review Stance"
    }

    static var step3Title: String {
        current == .chinese ? "3. 补充审核要求" : "3. Additional Requirements"
    }

    static var step4Title: String {
        current == .chinese ? "4. 确认并提交" : "4. Confirm & Submit"
    }

    // MARK: - 提交页面 - 按钮
    static var selectFileButton: String {
        current == .chinese ? "选择文件" : "Select File"
    }

    static var reselectFileButton: String {
        current == .chinese ? "重新选择" : "Reselect"
    }

    static var previousStepButton: String {
        current == .chinese ? "上一步" : "Previous"
    }

    static var nextStepButton: String {
        current == .chinese ? "下一步" : "Next"
    }

    static var startReviewButton: String {
        current == .chinese ? "开始审核" : "Start Review"
    }

    static var returnToSubmitButton: String {
        current == .chinese ? "返回提交" : "Back to Submit"
    }

    // MARK: - 提交页面 - 表单标签
    static var stanceLabel: String {
        current == .chinese ? "审核立场" : "Review Stance"
    }

    static var stancePlaceholder: String {
        current == .chinese ? "例如: 作为甲方、乙方、法务顾问..." : "e.g., As Party A, Party B, Legal Advisor..."
    }

    static var defaultStancePrompt: String {
        current == .chinese ? "公平立场（可编辑）" : "Neutral/fair stance (editable)"
    }

    static var additionalRequirementsLabel: String {
        current == .chinese ? "额外审核要求" : "Additional Requirements"
    }

    static var additionalRequirementsPlaceholder: String {
        current == .chinese ? "例如: 重点关注付款条款、违约责任..." : "e.g., Focus on payment terms, breach liability..."
    }

    // MARK: - 提交页面 - 状态提示
    static var noFileSelected: String {
        current == .chinese ? "未选择文件" : "No file selected"
    }

    static var fileSelectedPrefix: String {
        current == .chinese ? "已选择: " : "Selected: "
    }

    static var supportedFormats: String {
        current == .chinese ? "支持 TXT / PDF / DOCX 格式" : "Supports TXT / PDF / DOCX formats"
    }

    static var stanceRequired: String {
        current == .chinese ? "审核立场为必填项" : "Review stance is required"
    }

    static var stanceOptional: String {
        current == .chinese ? "(选填)" : "(Optional)"
    }

    // MARK: - 提交页面 - 步骤描述
    static var step1Caption: String {
        current == .chinese ? "支持 TXT / PDF / DOCX" : "Supports TXT / PDF / DOCX"
    }

    static var step2Caption: String {
        current == .chinese ? "描述你在合同中的角色" : "Describe your role in the contract"
    }

    static var step3Caption: String {
        current == .chinese ? "选填，记录特别关注点" : "Optional, note special concerns"
    }

    static var step4Caption: String {
        current == .chinese ? "核对信息后开始审核" : "Review info before starting"
    }

    static var step1Description: String {
        current == .chinese ? "支持 TXT、PDF、DOCX，解析完成后即可进入下一步。" : "Supports TXT, PDF, DOCX. Proceed after parsing."
    }

    static var fileTypeLabel: String {
        current == .chinese ? "类型：" : "Type: "
    }

    static var charCountLabel: String {
        current == .chinese ? " · 字符数 " : " · Characters: "
    }

    static var parsingFile: String {
        current == .chinese ? "正在解析文件，请稍候..." : "Parsing file, please wait..."
    }

    static var fileParseError: String {
        current == .chinese ? "文件解析失败，请重新选择。" : "File parsing failed, please reselect."
    }

    static var contextLimitInfo: String {
        current == .chinese ? "若文件超出模型上下文，将在解析阶段提示。" : "If file exceeds context, you'll be notified during parsing."
    }

    static var stanceInfo: String {
        current == .chinese ? "审核立场会作为提示词的一部分传递给所有子任务。" : "Review stance will be included in all subtask prompts."
    }

    static var defaultWorkflowInfo: String {
        current == .chinese ? "保留为空时，我们将按照默认工作流执行。" : "If left empty, default workflow will be used."
    }

    static var confirmBeforeSubmit: String {
        current == .chinese ? "提交前确认" : "Confirm Before Submit"
    }

    static var notFilled: String {
        current == .chinese ? "未填写" : "Not filled"
    }

    static var notAdded: String {
        current == .chinese ? "未补充" : "Not added"
    }

    static var parsingCompleteToSubmit: String {
        current == .chinese ? "正在解析文件，解析完成后可提交。" : "Parsing file, submit after completion."
    }

    static var parseFailedReturnPrevious: String {
        current == .chinese ? "文件解析失败，请返回上一步重新选择。" : "Parsing failed, return to previous step to reselect."
    }

    static var submitting: String {
        current == .chinese ? "正在提交..." : "Submitting..."
    }

    static var parseFailed: String {
        current == .chinese ? "解析失败" : "Parse failed"
    }

    static var parsing: String {
        current == .chinese ? "正在解析..." : "Parsing..."
    }

    static var notSelected: String {
        current == .chinese ? "未选择" : "Not selected"
    }

    static var fileSeparator: String {
        current == .chinese ? " | " : " | "
    }

    static var noFileSelected_full: String {
        current == .chinese ? "尚未选择文件" : "No file selected yet"
    }

    // MARK: - 提交页面 - 确认信息
    static var confirmFileLabel: String {
        current == .chinese ? "文件名称" : "File Name"
    }

    static var confirmStanceLabel: String {
        current == .chinese ? "审核立场" : "Review Stance"
    }

    static var confirmAdditionalLabel: String {
        current == .chinese ? "额外要求" : "Additional Requirements"
    }

    static var confirmNone: String {
        current == .chinese ? "无" : "None"
    }

    // MARK: - 结果页面 - Tab 标题
    static var resultTabMermaid: String {
        current == .chinese ? "业务流程图" : "Business Flow"
    }

    static var resultTabOverview: String {
        current == .chinese ? "合同概要" : "Overview"
    }

    static var resultTabFoundation: String {
        current == .chinese ? "基础审核" : "Foundation Review"
    }

    static var resultTabBusiness: String {
        current == .chinese ? "业务条款" : "Business Terms"
    }

    static var resultTabLegal: String {
        current == .chinese ? "法律条款" : "Legal Terms"
    }

    static var resultTabSummary: String {
        current == .chinese ? "审核概要" : "Summary"
    }

    // MARK: - 结果页面 - 状态提示
    static var waitingForUpload: String {
        current == .chinese ? "等待上传合同..." : "Waiting for contract upload..."
    }

    static var reviewInProgress: String {
        current == .chinese ? "审核进行中..." : "Review in progress..."
    }

    static var reviewCompleted: String {
        current == .chinese ? "审核完成" : "Review completed"
    }

    static var reviewFailed: String {
        current == .chinese ? "审核失败" : "Review failed"
    }

    static var progressPrefix: String {
        current == .chinese ? "进度: " : "Progress: "
    }

    // MARK: - 结果页面 - 错误提示
    static var errorOccurred: String {
        current == .chinese ? "发生错误" : "Error occurred"
    }

    static var noResultsYet: String {
        current == .chinese ? "暂无审核结果" : "No results yet"
    }

    static var loadingContent: String {
        current == .chinese ? "加载中..." : "Loading..."
    }

    static var renderingMermaid: String {
        current == .chinese ? "正在渲染流程图..." : "Rendering diagram..."
    }

    // MARK: - 结果页面 - 额外提示
    static var noReviewTask: String {
        current == .chinese ? "暂无审核任务" : "No review task"
    }

    static var goToSubmitHint: String {
        current == .chinese ? "请先在「提交合同」标签页填写审核立场并选择文件。" : "Please fill in review stance and select file in Submit Contract tab."
    }

    static var reviewingDocument: String {
        current == .chinese ? "正在审核 " : "Reviewing "
    }

    static var reviewingHint: String {
        current == .chinese ? "请稍候，模型正在按工作流生成流程图、概要与风险表。" : "Please wait, model is generating flowchart, overview and risk tables."
    }

    static var documentTypeLabel: String {
        current == .chinese ? "文档类型：" : "Document Type: "
    }

    static var charCountResultLabel: String {
        current == .chinese ? " ｜ 字符数 " : " | Characters: "
    }

    static var reviewTimeLabel: String {
        current == .chinese ? "审核时间：" : "Review Time: "
    }

    static var resultTypeLabel: String {
        current == .chinese ? "结果类型" : "Result Type"
    }

    static var retryReviewButton: String {
        current == .chinese ? "重新审核" : "Retry Review"
    }

    static var changeFileButton: String {
        current == .chinese ? "更换文件" : "Change File"
    }

    static var retryButton: String {
        current == .chinese ? "重试" : "Retry"
    }

    static var unknownError: String {
        current == .chinese ? "发生未知错误。" : "An unknown error occurred."
    }

    static var unknownErrorRetry: String {
        current == .chinese ? "发生未知错误，请重试或检查设置。" : "An unknown error occurred, please retry or check settings."
    }

    static var openSettingsButton: String {
        current == .chinese ? "打开设置" : "Open Settings"
    }

    static var openModelSettingsHint: String {
        current == .chinese ? "打开模型和接口设置" : "Open model and API settings"
    }

    static var noMermaidDiagram: String {
        current == .chinese ? "未检测到可渲染的 Mermaid 流程图。" : "No renderable Mermaid diagram detected."
    }

    static var viewLargeDiagram: String {
        current == .chinese ? "放大查看" : "View larger"
    }

    static var zoomIn: String {
        current == .chinese ? "放大" : "Zoom in"
    }

    static var zoomOut: String {
        current == .chinese ? "缩小" : "Zoom out"
    }

    static var resetZoom: String {
        current == .chinese ? "重置" : "Reset"
    }

    // MARK: - 对话页面
    static var conversationTitle: String {
        current == .chinese ? "对话" : "Conversation"
    }

    static var conversation: String {
        current == .chinese ? "对话" : "Conversation"
    }

    static var startConversation: String {
        current == .chinese ? "开始对话" : "Start Conversation"
    }

    static var askAIAboutContract: String {
        current == .chinese ? "向 AI 提问关于此合同的任何问题" : "Ask AI anything about this contract"
    }

    static var copyContent: String {
        current == .chinese ? "复制内容" : "Copy Content"
    }

    static var copiedToast: String {
        current == .chinese ? "已复制" : "Copied"
    }

    static var jumpToLatest: String {
        current == .chinese ? "跳到最新" : "Jump to latest"
    }

    static var searchConversations: String {
        current == .chinese ? "搜索对话" : "Search conversations"
    }

    static var renameConversation: String {
        current == .chinese ? "重命名对话" : "Rename conversation"
    }

    static var rename: String {
        current == .chinese ? "重命名" : "Rename"
    }

    static var cancel: String {
        current == .chinese ? "取消" : "Cancel"
    }

    static var delete: String {
        current == .chinese ? "删除" : "Delete"
    }

    static var confirmDeleteConversationTitle: String {
        current == .chinese ? "确认删除该对话？" : "Delete this conversation?"
    }

    static var confirmDeleteConversationMessage: String {
        current == .chinese ? "此操作不可撤销。" : "This action cannot be undone."
    }

    static var assistantName: String {
        current == .chinese ? "AI" : "AI"
    }

    static var youName: String {
        current == .chinese ? "你" : "You"
    }

    static var stopGenerating: String {
        current == .chinese ? "停止生成" : "Stop generating"
    }

    static var dismiss: String {
        current == .chinese ? "知道了" : "Dismiss"
    }

    static var suggestedQuestionsTitle: String {
        current == .chinese ? "你可以试试问：" : "Try asking:"
    }

    static var suggestionPaymentRisk: String {
        current == .chinese ? "这份合同的付款节点和付款风险是什么？" : "What are the payment milestones and risks?"
    }

    static var suggestionBreach: String {
        current == .chinese ? "违约责任是否对我方不利？有哪些修改建议？" : "Are breach liabilities unfavorable? Any edits?"
    }

    static var suggestionTermination: String {
        current == .chinese ? "解除/终止条款有哪些坑？" : "Any pitfalls in termination clauses?"
    }

    static var aiPreparingContent: String {
        current == .chinese ? "（AI正在准备内容）" : "(AI is preparing content)"
    }

    static var sendMessageHelp: String {
        current == .chinese ? "发送消息 (Return)\n换行 (Shift+Return)" : "Send message (Return)\nNew line (Shift+Return)"
    }

    static func messageCount(_ count: Int) -> String {
        current == .chinese ? "\(count) 条消息" : "\(count) message\(count == 1 ? "" : "s")"
    }

    static var deleteConversation: String {
        current == .chinese ? "删除对话" : "Delete Conversation"
    }

    static var inputPlaceholder: String {
        current == .chinese ? "询问任何问题..." : "Ask any question..."
    }

    static var sendButton: String {
        current == .chinese ? "发送" : "Send"
    }

    static var aiThinking: String {
        current == .chinese ? "AI 思考中..." : "AI thinking..."
    }

    static var aiReplyLabel: String {
        current == .chinese ? "✨ AI 回复" : "✨ AI Reply"
    }

    static var newConversationButton: String {
        current == .chinese ? "新建对话" : "New Conversation"
    }

    static var emptyReplyPlaceholder: String {
        current == .chinese ? "（AI 回复为空，请稍后重试）" : "(Empty reply, please try again)"
    }

    static var shortcutHint: String {
        current == .chinese ? "按 ⌘ + Enter 发送" : "Press ⌘ + Enter to send"
    }

    static var pleaseReviewFirst: String {
        current == .chinese ? "请先审核合同" : "Please review contract first"
    }

    static var discussAfterReview: String {
        current == .chinese ? "完成审核后即可在此与 AI 讨论合同内容" : "You can discuss the contract with AI after review"
    }

    static var waitingForReview: String {
        current == .chinese ? "填写审核立场后，可选择合同文件开始审核。" : "Fill in review stance, then select file to start review."
    }

    static var reviewingContract: String {
        current == .chinese ? "模型正在分析 " : "Model is analyzing "
    }

    static var reviewExpectedTime: String {
        current == .chinese ? "，预计几分钟内完成。" : ", expected to complete in a few minutes."
    }

    static var reviewResultGenerated: String {
        current == .chinese ? "审核结果已生成，可前往「审核结果」标签查看详细内容。" : "Review results generated, view details in Review Results tab."
    }

    // MARK: - 历史记录页面
    static var historyTitle: String {
        current == .chinese ? "历史记录" : "History"
    }

    static var searchPlaceholder: String {
        current == .chinese ? "搜索..." : "Search..."
    }

    static var searchContractsPlaceholder: String {
        current == .chinese ? "搜索合同文件" : "Search contracts"
    }

    static var deleteButton: String {
        current == .chinese ? "删除" : "Delete"
    }

    static var deleteRecordButton: String {
        current == .chinese ? "删除记录" : "Delete Record"
    }

    static var noHistoryRecords: String {
        current == .chinese ? "暂无历史记录" : "No history records"
    }

    static var noMatchingRecords: String {
        current == .chinese ? "未找到匹配的记录" : "No matching records"
    }

    static var historyEmptyHint: String {
        current == .chinese ? "完成一次合同审核后将在此显示。" : "Records will appear here after completing a contract review."
    }

    static var searchEmptyHint: String {
        current == .chinese ? "换个关键词再试试。" : "Try different keywords."
    }

    static var newReviewButton: String {
        current == .chinese ? "新建审阅" : "New Review"
    }

    static var draftStatus: String {
        current == .chinese ? "草稿" : "Draft"
    }

    // MARK: - 设置页面
    static var settingsTitle: String {
        current == .chinese ? "设置" : "Settings"
    }

    static var settingsButton: String {
        current == .chinese ? "设置" : "Settings"
    }

    static var apiSettingsSection: String {
        current == .chinese ? "API 设置" : "API Settings"
    }

    static var languageSettingsSection: String {
        current == .chinese ? "语言设置" : "Language Settings"
    }

    static var languageLabel: String {
        current == .chinese ? "界面语言" : "Interface Language"
    }

    static var apiKeyLabel: String {
        current == .chinese ? "API Key" : "API Key"
    }

    static var apiKeyPlaceholder: String {
        current == .chinese ? "输入你的 API Key" : "Enter your API Key"
    }

    static var defaultDeepseekNotice: String {
        current == .chinese ? "默认使用 DeepSeek API。" : "DeepSeek API is used by default."
    }

    static var baseURLLabel: String {
        current == .chinese ? "Base URL" : "Base URL"
    }

    static var modelLabel: String {
        current == .chinese ? "模型" : "Model"
    }

    static var chatModelLabel: String {
        current == .chinese ? "审核模型" : "Review Model"
    }

    static var reasonerModelLabel: String {
        current == .chinese ? "对话模型" : "Conversation Model"
    }

    static var testConnectionButton: String {
        current == .chinese ? "测试连接" : "Test Connection"
    }

    static var saveButton: String {
        current == .chinese ? "保存" : "Save"
    }

    static var closeButton: String {
        current == .chinese ? "关闭" : "Close"
    }

    static var applyKeysHint: String {
        current == .chinese ? "前往 DeepSeek 平台申请 API Key 或充值" : "Apply for API Key or recharge at DeepSeek Platform"
    }

    static var deepseekApplyPrefix: String {
        current == .chinese ? "申请 DeepSeek API Key 或充值，请点击" : "To apply for a DeepSeek API Key or recharge, click"
    }

    static var testingConnection: String {
        current == .chinese ? "测试中..." : "Testing..."
    }

    static var connectionSuccess: String {
        current == .chinese ? "连接成功！" : "Connection successful!"
    }

    static var connectionFailed: String {
        current == .chinese ? "连接失败" : "Connection failed"
    }

    static var settingsTabBasic: String {
        current == .chinese ? "模型" : "Models"
    }

    static var settingsTabLanguage: String {
        current == .chinese ? "语言" : "Language"
    }

    static var settingsTabUpdates: String {
        current == .chinese ? "更新" : "Updates"
    }

    static var settingsTabAbout: String {
        current == .chinese ? "关于" : "About"
    }

    static var customProviderToggle: String {
        current == .chinese ? "使用自定义 OpenAI 兼容服务" : "Use custom OpenAI-compatible provider"
    }

    static var customProviderHint: String {
        current == .chinese ? "填写 Base URL、模型名，适配 OpenAI 接口（/v1/chat/completions）。" : "Fill Base URL and model names for OpenAI-style /v1/chat/completions endpoints."
    }

    static var restoreDefaultProviderButton: String {
        current == .chinese ? "恢复 DeepSeek 默认" : "Restore DeepSeek defaults"
    }

    static var templatePickerLabel: String {
        current == .chinese ? "选择已保存的补充审核要求" : "Choose saved additional requirements"
    }

    static var templatePreviewLabel: String {
        current == .chinese ? "预览" : "Preview"
    }

    static var templatesTitle: String {
        current == .chinese ? "审核要求模板" : "Requirement Templates"
    }

    static var templateNameLabel: String {
        current == .chinese ? "名称" : "Name"
    }

    static var templateContentLabel: String {
        current == .chinese ? "内容" : "Content"
    }

    static var templateDescriptionLabel: String {
        current == .chinese ? "备注（可选）" : "Notes (optional)"
    }

    static var addTemplateButton: String {
        current == .chinese ? "新增模板" : "Add Template"
    }

    static var saveTemplateButton: String {
        current == .chinese ? "保存模板" : "Save Template"
    }

    static var deleteTemplateButton: String {
        current == .chinese ? "删除" : "Delete"
    }

    static var manageTemplatesButton: String {
        current == .chinese ? "管理模板" : "Manage Templates"
    }

    // MARK: - 设置页面 - 版本信息
    static var versionInfoSection: String {
        current == .chinese ? "版本信息" : "Version Info"
    }

    static var currentVersionLabel: String {
        current == .chinese ? "当前版本" : "Current Version"
    }

    static var checkForUpdatesButton: String {
        current == .chinese ? "检查更新" : "Check for Updates"
    }

    static var checkingUpdates: String {
        current == .chinese ? "检查中..." : "Checking..."
    }

    static var updateAvailableTitle: String {
        current == .chinese ? "发现新版本" : "Update Available"
    }

    static var updateAvailableMessage: String {
        current == .chinese ? "有新版本可用，是否前往下载？" : "A new version is available. Download now?"
    }

    static var noUpdateTitle: String {
        current == .chinese ? "已是最新版本" : "Up to Date"
    }

    static var noUpdateMessage: String {
        current == .chinese ? "当前已是最新版本。" : "You're using the latest version."
    }

    static var updateCheckFailedTitle: String {
        current == .chinese ? "检查失败" : "Check Failed"
    }

    static var updateCheckFailedMessage: String {
        current == .chinese ? "无法检查更新，请稍后重试。" : "Unable to check for updates. Please try again later."
    }

    static var downloadButton: String {
        current == .chinese ? "前往下载" : "Download"
    }

    static var cancelButton: String {
        current == .chinese ? "取消" : "Cancel"
    }

    static var okButton: String {
        current == .chinese ? "好的" : "OK"
    }

    // MARK: - 快捷键
    static var shortcutSettings: String {
        current == .chinese ? "⌘ + ," : "⌘ + ,"
    }

    // MARK: - 文档类型显示名
    static func documentTypeName(_ type: String) -> String {
        switch type.lowercased() {
        case "txt":
            return current == .chinese ? "文本文件" : "Text File"
        case "pdf":
            return current == .chinese ? "PDF 文档" : "PDF Document"
        case "docx", "doc":
            return current == .chinese ? "Word 文档" : "Word Document"
        default:
            return current == .chinese ? "未知类型" : "Unknown Type"
        }
    }

    // MARK: - 错误消息
    static var errorInvalidFileType: String {
        current == .chinese ? "文件类型识别失败。" : "Failed to identify file type."
    }

    static func errorUnsupportedFileType(_ ext: String) -> String {
        current == .chinese ? "暂不支持导入 \(ext.uppercased()) 文件，请选择 TXT/PDF/DOCX。" : "Importing \(ext.uppercased()) files is not supported. Please select TXT/PDF/DOCX."
    }

    static var errorFileReadFailed: String {
        current == .chinese ? "读取文件失败，请确认文件未被占用或已授予读取权限。" : "Failed to read file. Please ensure the file is not in use and you have read permission."
    }

    static var errorEmptyDocument: String {
        current == .chinese ? "文件内容为空，无法进行审核。" : "File content is empty and cannot be reviewed."
    }

    static func errorDocumentTooLarge(estimatedTokens: Int, limit: Int) -> String {
        current == .chinese ? "文件内容过长（预估 \(estimatedTokens) tokens），已超过当前模型可处理上限 \(limit)。请拆分文档或更换模型。" : "File content is too long (estimated \(estimatedTokens) tokens), exceeding the model's limit of \(limit). Please split the document or use a different model."
    }

    static var errorMissingReviewPosition: String {
        current == .chinese ? "请先填写审核立场，再执行审核。" : "Please fill in review stance before starting the review."
    }

    static var errorMissingAPIKey: String {
        current == .chinese ? "请先在设置中填写有效的 API Key。" : "Please fill in a valid API Key in Settings first."
    }

    static var errorInvalidAPIEndpoint: String {
        current == .chinese ? "API Base URL 无效，请在设置中检查填写是否正确。" : "API Base URL is invalid. Please check your settings."
    }

    static var errorDecodingFailed: String {
        current == .chinese ? "解析模型响应失败。" : "Failed to parse model response."
    }
}
