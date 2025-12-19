//
//  PromptTemplates.swift
//  contract review
//
//  AI 提示词模板管理器 - 支持中英双语
//

import Foundation

/// AI 提示词模板管理器
struct PromptTemplates {

    // MARK: - System Prompt

    static func systemPrompt(language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            你是一名资深律师,负责审核合同条款并识别潜在风险。请在输出中包含核心风险、建议修改点和总体结论,适度精炼,输出中文。
            """
        case .english:
            return """
            You are a senior lawyer responsible for reviewing contract terms and identifying potential risks. Include core risks, suggested amendments, and overall conclusions in your output. Keep it concise and output in English.
            """
        }
    }

    // MARK: - Mermaid Flowchart Generation

    static func mermaid(documentText: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            从合同文本如下所示内容中提取完整的业务交易流程,生成 mermaid 格式的 flowchart 流程图。

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            ## 提取要求:

            ### 1. 流程完整性
            - 覆盖从合同签订到履约完成的全生命周期
            - 包含正常履约流程、违约处理流程、合同解除情况
            - 体现甲乙双方的互动关系和权责

            ### 2. 信息精确性
            - **时间节点**:提取具体时间要求(X个工作日、X小时等)和触发条件
            - **金额数据**:提取具体金额和比例(如30%预付款、总额等)
            - **数量规格**:提取货物/服务的具体数量、型号、规格
            - **地点信息**:提取具体的交付地点、验收地点等
            - **标准条件**:提取验收标准、质量要求、技术指标等
            - **信息限制**:所有提取的信息必须来自合同文本,保持信息的精准性

            ### 3. 节点内容格式
            - 每个节点用方括号包含主要行为
            - 节点内多项信息用 `<br>` 换行分隔
            - 连接线上标注触发条件和时间要求,格式:`|条件说明|`。如合同中无该节点的时间要求和触发条件,则在连接线上标注"?"

            ### 4. 流程逻辑
            - 用 `-->` 表示正常流向
            - 体现分支决策点(如验收合格/不合格)
            - 包含并行流程(如风险转移与所有权转移)
            - 展现违约后果的递进关系(轻微违约→严重违约→解除合同)

            ### 5. 视觉样式
            在流程图末尾添加样式定义:
            - 正常履约节点:`style [节点ID] fill:#e7f0ff`(柔和淡蓝)
            - 违约相关节点:`style [节点ID] fill:#fff4d6`(柔和浅黄)
            - 合同解除节点:`style [节点ID] fill:#f2b1b6`(略深珊瑚红)
            - 正常完成节点:`style [节点ID] fill:#d8eddf`(略深柔和绿)

            ## 输出格式:
            - 仅输出 mermaid 代码,以 `flowchart TD` 开头,确保输出端可以直接进行 mermaid 渲染
            - 不包含任何解释文字或代码块标记
            - 确保语法正确,可直接渲染
            """
        case .english:
            return """
            Extract the complete business transaction flow from the contract text below and generate a mermaid flowchart.

            --- Contract Content ---
            \(documentText)
            --- End of Contract ---

            ## Requirements:

            ### 1. Process Completeness
            - Cover the full lifecycle from contract signing to fulfillment completion
            - Include normal fulfillment process, breach handling, and contract termination scenarios
            - Reflect the interaction and responsibilities of both parties

            ### 2. Information Accuracy
            - **Time Points**: Extract specific time requirements (X business days, X hours, etc.) and trigger conditions
            - **Amount Data**: Extract specific amounts and percentages (e.g., 30% advance payment, total amount)
            - **Quantity Specs**: Extract specific quantities, models, and specifications of goods/services
            - **Location Info**: Extract specific delivery locations, acceptance locations, etc.
            - **Standard Conditions**: Extract acceptance standards, quality requirements, technical indicators
            - **Information Constraint**: All extracted information must come from the contract text, maintaining precision

            ### 3. Node Content Format
            - Each node contains the main action in square brackets
            - Separate multiple items within a node with `<br>`
            - Label connecting lines with trigger conditions and time requirements, format: `|condition description|`. If no time requirement or trigger condition exists, label with "?"

            ### 4. Process Logic
            - Use `-->` for normal flow direction
            - Show decision points (e.g., acceptance pass/fail)
            - Include parallel processes (e.g., risk transfer and ownership transfer)
            - Show breach consequence progression (minor breach → major breach → contract termination)

            ### 5. Visual Styling
            Add style definitions at the end of the flowchart:
            - Normal fulfillment nodes: `style [nodeID] fill:#e7f0ff` (soft light blue)
            - Breach-related nodes: `style [nodeID] fill:#fff4d6` (soft pale yellow)
            - Contract termination nodes: `style [nodeID] fill:#f2b1b6` (slightly deeper coral red)
            - Normal completion nodes: `style [nodeID] fill:#d8eddf` (slightly deeper soft green)

            ## Output Format:
            - Output only mermaid code, starting with `flowchart TD`, ensuring it can be directly rendered
            - Do not include any explanatory text or code block markers
            - Ensure correct syntax for direct rendering
            """
        }
    }

    // MARK: - Contract Overview

    static func contractOverview(documentText: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            根据下述合同文本,客观总结合同的基本内容,为法务人员提供快速了解合同概况的结构化信息。**仅做客观描述,不进行任何法律风险评估或审核建议。**

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            ## 输出格式要求:

            ### 一、合同基本信息
            | 项目 | 内容 |
            |------|------|
            | 合同名称 | [提取合同标题或约定名称] |
            | 合同类型 | [如:买卖合同、服务合同、租赁合同等] |
            | 合同当事人 | 甲方:[名称、地址]<br>乙方:[名称、地址] |
            | 签订时间 | [合同签署日期] |
            | 合同期限 | [起止时间或履行期限] |
            | 合同金额 | [总金额及币种,如有分期说明分期安排] |

            ### 二、业务模式概述
            **简要描述:**[用1-2段话概括该合同的核心业务内容,说明甲乙双方的基本交易关系]

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
            **甲方主要权利义务:**
            - [列出甲方的主要权利]
            - [列出甲方的主要义务]
            **乙方主要权利义务:**
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
            **风险分担:**
            - [不可抗力条款]
            - [风险转移节点]
            - [损失承担约定]
            **特殊约定:**
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
            - [按时间顺序列出合同履行的关键节点,如签约、付款、交付、验收等时间安排]

            ## 输出要求:
            1. **客观性**:仅提取和描述合同条款内容,不添加主观判断或法律意见
            2. **完整性**:涵盖合同的主要条款,如某项内容合同中未约定则标注"未约定"
            3. **准确性**:忠实反映合同原文内容,重要条款可适当引用原文关键表述
            4. **简洁性**:根据合同复杂程度控制篇幅,保持表达简洁明了
            5. **结构性**:严格按照上述格式输出,便于法务人员快速定位关键信息
            """
        case .english:
            return """
            Based on the contract text below, objectively summarize the basic content of the contract to provide legal professionals with structured information for a quick understanding. **Only provide objective descriptions without any legal risk assessment or review recommendations.**

            --- Contract Content ---
            \(documentText)
            --- End of Contract ---

            ## Output Format Requirements:

            ### I. Basic Contract Information
            | Item | Content |
            |------|---------|
            | Contract Name | [Extract contract title or agreed name] |
            | Contract Type | [e.g., Sales Contract, Service Contract, Lease Agreement, etc.] |
            | Parties | Party A: [Name, Address]<br>Party B: [Name, Address] |
            | Signing Date | [Contract signing date] |
            | Contract Term | [Start and end dates or performance period] |
            | Contract Amount | [Total amount and currency, specify installment arrangements if applicable] |

            ### II. Business Model Overview
            **Brief Description:** [Summarize the core business content of this contract in 1-2 paragraphs, explaining the basic transaction relationship between parties]

            ### III. Core Terms Elements
            #### 3.1 Transaction Elements
            | Element | Specific Content |
            |---------|------------------|
            | Subject Matter/Services | [Specific description of goods, services, or other subject matter] |
            | Quantity & Specifications | [Quantity, model, technical parameters, etc.] |
            | Price Structure | [Unit price, total price, price adjustment mechanism, etc.] |
            | Payment Method | [Payment ratio, payment milestones, payment method] |
            | Delivery Method | [Delivery location, delivery time, delivery standards] |

            #### 3.2 Rights and Obligations Allocation
            **Party A's Main Rights and Obligations:**
            - [List Party A's main rights]
            - [List Party A's main obligations]
            **Party B's Main Rights and Obligations:**
            - [List Party B's main rights]
            - [List Party B's main obligations]

            #### 3.3 Performance Guarantee Terms
            | Term Type | Specific Provisions |
            |-----------|-------------------|
            | Breach Liability | [Consequences of Party A's breach, Party B's breach] |
            | Guarantee Measures | [Security deposit, guarantee methods, etc.] |
            | Acceptance Standards | [Acceptance procedures, standards, dispute resolution] |
            | Quality Assurance | [Warranty period, warranty responsibilities, after-sales service] |

            #### 3.4 Risk Allocation and Special Provisions
            **Risk Allocation:**
            - [Force majeure clause]
            - [Risk transfer point]
            - [Loss bearing agreement]
            **Special Provisions:**
            - [Intellectual property clause]
            - [Confidentiality clause]
            - [Exclusivity provisions]
            - [Other special conditions or restrictions]

            #### 3.5 Dispute Resolution and Contract Termination
            | Item | Provisions |
            |------|-----------|
            | Dispute Resolution | [Negotiation, mediation, arbitration, litigation and jurisdiction] |
            | Contract Amendment | [Amendment conditions and procedures] |
            | Contract Termination | [Termination conditions, procedures, consequences] |
            | Applicable Law | [Applicable laws and regulations] |

            ### IV. Key Time Milestones
            - [List key milestones in contract performance chronologically, such as signing, payment, delivery, acceptance, etc.]

            ## Output Requirements:
            1. **Objectivity**: Only extract and describe contract terms without adding subjective judgments or legal opinions
            2. **Completeness**: Cover main contract terms; mark "Not Specified" if content is missing
            3. **Accuracy**: Faithfully reflect original contract content; quote key expressions from original text where appropriate
            4. **Conciseness**: Control length based on contract complexity while maintaining clear expression
            5. **Structure**: Strictly follow the above format for easy navigation by legal professionals
            """
        }
    }

    // MARK: - Foundation Audit

    static func foundationAudit(documentText: String, position: String, additionalRequest: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            # 角色设定
            请作为一名具有多年经验的合同法律顾问,根据你的审核立场「\(position)」和用户额外的审核要求「\(additionalRequest)」,对合同文本进行以下四个方面的基础审核,不要遗漏任何一个审查点:

            合同全文如下:
            \(documentText)

            # 基础审查要点
            1. 文本准确性:
               - 检查所有关键词、术语拼写是否正确
               - 核对所有数字、金额、比例是否准确(特别注意大小写金额是否一致)
               - 检查日期表述是否精确(避免使用"近期"、"尽快"等模糊词语)
            2. 格式规范性:
               - 检查标点符号使用是否规范
               - 审核条款编号是否有序连贯,是否存在重复编号
               - 检查排版是否整洁,有无明显格式错误
               - 确认签署处是否留有足够空间
            3. 语言表述清晰性:
               - 检查是否存在语法错误或表述不清的句子
               - 识别有歧义或模糊的描述,特别是关于时间、数量、质量的表述
               - 检查专业术语使用是否准确
            4. 文本一致性:
               - 检查同一概念在合同不同部分的称谓是否一致(如产品名称、型号等)
               - 核对合同内部引用条款编号是否准确
               - 确认前后条款是否存在逻辑冲突
               - 检查附件与正文是否一致

            # 输出要求
            1. 以表格方式输出;
            2. 表格的行标题依次为:序号、问题类型、原文表述、风险原因、修订建议、风险等级;
            3. 问题类型应为文本准确性、格式规范性、语言表述清晰性、文本一致性中择一;
            4. 风险等级为高中低,各行按照风险从高到低进行排序,同时要以红黄蓝的 emoji 表情标注;
            5. 原文表述应用引号表明原文准确内容,并说明具体的章、节、条、款、项(如有);
            6. 本节点仅进行这四方面的审核,无需对业务条款和法律条款的要点进行审核;
            7. 在表格之下总结表格中的高风险事项,除表格和总结外,无需输出其他内容。
            """
        case .english:
            return """
            # Role Definition
            As an experienced contract legal advisor, based on your review stance "\(position)" and the user's additional review requirements "\(additionalRequest)", conduct a foundation audit on the contract text in the following four aspects, without omitting any review points:

            Full contract text:
            \(documentText)

            # Foundation Review Points
            1. Text Accuracy:
               - Check if all keywords and terms are spelled correctly
               - Verify all numbers, amounts, and percentages are accurate (pay special attention to consistency between numeric and written amounts)
               - Check if date expressions are precise (avoid vague terms like "soon", "in the near future")
            2. Format Compliance:
               - Check if punctuation is used properly
               - Review if clause numbering is sequential and coherent, check for duplicate numbering
               - Check if layout is neat with no obvious formatting errors
               - Confirm if signature areas have sufficient space
            3. Language Clarity:
               - Check for grammatical errors or unclear expressions
               - Identify ambiguous or vague descriptions, especially regarding time, quantity, and quality
               - Verify if professional terminology is used accurately
            4. Text Consistency:
               - Check if the same concept uses consistent terminology throughout the contract (e.g., product names, models)
               - Verify if internal cross-references to clause numbers are accurate
               - Confirm no logical conflicts exist between clauses
               - Check if appendices are consistent with main text

            # Output Requirements
            1. Output in table format;
            2. Table headers in order: No., Issue Type, Original Text, Risk Reason, Amendment Suggestion, Risk Level;
            3. Issue Type should be one of: Text Accuracy, Format Compliance, Language Clarity, Text Consistency;
            4. Risk Level should be High/Medium/Low, rows sorted from high to low risk, marked with red/yellow/blue emoji;
            5. Original Text should quote the exact content with quotation marks and specify chapter, section, article, clause, item (if applicable);
            6. This review only covers these four aspects, no need to review business terms or legal terms;
            7. Summarize high-risk items below the table; output only the table and summary, nothing else.
            """
        }
    }

    // MARK: - Business Audit

    static func businessAudit(documentText: String, position: String, additionalRequest: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            # 角色设定
            请作为一名具有多年经验的合同法律顾问,根据你的审核立场「\(position)」和用户额外的审核要求「\(additionalRequest)」,对合同文本进行以下六个方面的业务条款审核,不要遗漏任何一个审查点:

            合同全文如下:
            \(documentText)

            # 业务条款审查要点
            1. 合同标的条款:
               - 标的物或服务的描述是否清晰完整
               - 标的物或服务的数量是否明确
               - 标的物的质量标准或服务标准是否明确
               - 标的物的技术指标或性能要求是否明确
               - 标的物的包装要求是否明确
               - 标的物的检验或验收标准是否明确
               - 标的物的售后服务是否明确
            2. 合同交付条款:
               - 交付时间是否明确
               - 交付地点是否明确
               - 交付方式是否明确
               - 交付风险转移是否明确
               - 交付后的验收程序是否明确
               - 交付时是否有特殊要求(设备安装、调试等)
            3. 合同价款条款:
               - 价格构成是否明确(单价、总价、计算方式)
               - 计价方式是否明确(按件、按时间、按工作量等)
               - 货币单位是否明确,汇率问题是否考虑(跨境交易)
               - 价税是否分离,税费承担是否明确
               - 付款方式是否明确(一次性、分期、质保金)
               - 付款节点是否与履行进度匹配
               - 付款条件是否明确且可操作
               - 付款凭证与发票约定是否清晰
            4. 合同履行条款:
               - 履行时间是否明确具体(避免"合理时间"等模糊表述)
               - 履行地点是否具体明确
               - 履行方式是否详细描述(交付方式、包装要求、运输方式)
               - 履行程序是否结构化说明(每个步骤的具体操作)
               - 权利转移点是否明确(所有权转移时间)
               - 风险转移点是否明确(风险责任承担时间)
               - 履行中的通知义务是否明确规定
            5. 权利义务条款:
               - 主要权利是否全面列举,无遗漏
               - 是否存在隐含的弃权条款
               - 豁免条款是否合理(特别是不可抗力范围)
               - 主要义务是否无遗漏,履行标准是否明确
               - 义务的合理性与可执行性
               - 后合同义务是否明确(如保密延续期限)
               - 从权利义务是否明确(附属于主权利的权利义务)
            6. 知识产权条款:
               - 现有知识产权归属是否明确
               - 合同履行过程中产生的知识产权归属是否明确
               - 知识产权使用权范围、目的、期限是否明确
               - 知识产权转让与许可条件是否清晰
               - 知识产权保护与维护责任如何分配
               - 保密与竞争限制期限、范围是否合理

            # 输出要求
            1. 以表格方式输出;
            2. 表格的行标题依次为:序号、问题类型、原文表述、风险原因、修订建议、风险等级;
            3. 问题类型应为六个业务条款审核要点中择一;
            4. 风险等级为高中低,各行按照风险从高到低进行排序,同时要以红黄蓝的 emoji 表情标注;
            5. 原文表述应用引号表明原文准确内容,并说明具体的章、节、条、款、项(如有);
            6. 本节点仅进行这六方面的审核,无需对其他方面进行审核;
            7. 在表格之下总结表格中的高风险事项,除表格和总结外,无需输出其他内容。
            """
        case .english:
            return """
            # Role Definition
            As an experienced contract legal advisor, based on your review stance "\(position)" and the user's additional review requirements "\(additionalRequest)", conduct a business terms audit on the contract text in the following six aspects, without omitting any review points:

            Full contract text:
            \(documentText)

            # Business Terms Review Points
            1. Subject Matter Terms:
               - Is the description of goods or services clear and complete
               - Is the quantity of goods or services specified
               - Are quality standards or service standards clearly defined
               - Are technical specifications or performance requirements clear
               - Are packaging requirements specified
               - Are inspection or acceptance standards clear
               - Are after-sales services specified
            2. Delivery Terms:
               - Is delivery time clearly specified
               - Is delivery location clearly specified
               - Is delivery method clearly specified
               - Is risk transfer upon delivery clear
               - Are acceptance procedures after delivery clear
               - Are there special requirements at delivery (equipment installation, commissioning, etc.)
            3. Price Terms:
               - Is price structure clear (unit price, total price, calculation method)
               - Is pricing method clear (per item, per time, per workload, etc.)
               - Is currency clearly specified, is exchange rate considered (for cross-border transactions)
               - Are price and tax separated, is tax liability clear
               - Is payment method clear (lump sum, installments, retention)
               - Do payment milestones match performance progress
               - Are payment conditions clear and operable
               - Are payment vouchers and invoice provisions clear
            4. Performance Terms:
               - Is performance time specific (avoid vague terms like "reasonable time")
               - Is performance location specific and clear
               - Is performance method described in detail (delivery method, packaging requirements, transportation method)
               - Is performance procedure explained systematically (specific operations for each step)
               - Is the point of rights transfer clear (ownership transfer time)
               - Is the point of risk transfer clear (risk liability assumption time)
               - Are notification obligations during performance clearly specified
            5. Rights and Obligations Terms:
               - Are main rights comprehensively listed without omission
               - Are there implied waiver clauses
               - Are exemption clauses reasonable (especially force majeure scope)
               - Are main obligations listed without omission, are performance standards clear
               - Reasonableness and enforceability of obligations
               - Are post-contract obligations clear (e.g., confidentiality continuation period)
               - Are ancillary rights and obligations clear (rights and obligations attached to main rights)
            6. Intellectual Property Terms:
               - Is ownership of existing intellectual property clear
               - Is ownership of intellectual property generated during contract performance clear
               - Are scope, purpose, and duration of intellectual property usage rights clear
               - Are conditions for intellectual property transfer and licensing clear
               - How is responsibility for intellectual property protection and maintenance allocated
               - Are confidentiality and competition restriction periods and scopes reasonable

            # Output Requirements
            1. Output in table format;
            2. Table headers in order: No., Issue Type, Original Text, Risk Reason, Amendment Suggestion, Risk Level;
            3. Issue Type should be one of the six business terms review points;
            4. Risk Level should be High/Medium/Low, rows sorted from high to low risk, marked with red/yellow/blue emoji;
            5. Original Text should quote the exact content with quotation marks and specify chapter, section, article, clause, item (if applicable);
            6. This review only covers these six aspects, no need to review other aspects;
            7. Summarize high-risk items below the table; output only the table and summary, nothing else.
            """
        }
    }

    // MARK: - Legal Audit

    static func legalAudit(documentText: String, position: String, additionalRequest: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            # 角色设定
            请作为一名具有多年经验的合同法律顾问,根据你的审核立场「\(position)」和用户额外的审核要求「\(additionalRequest)」,对合同文本进行以下十个方面的法律条款审核,不要遗漏任何一个审查点:

            合同全文如下:
            \(documentText)

            # 法律条款审查要点
            1. 生效条款:
               - 合同成立与生效是否有明确区分
               - 生效条件是否明确(签署即生效、附条件生效、附期限生效)
               - 生效条件的可行性是否考虑
               - 生效前的法律责任如何安排
            2. 违约责任条款:
               - 重点审核:违约行为的定义是否明确全面(迟延履行、质量不合格、拒绝履行等)
               - 违约责任形式是否明确(继续履行、采取补救、赔偿损失、支付违约金)
               - 违约金比例是否合理(既不过高具惩罚性,也不过低难以弥补损失)
               - 违约责任是否对双方公平(注意违约金比例是否对等)
               - 违约责任的计算方式是否明确
            3. 合同变更、解除、终止条款:
               - 变更条件是否明确(哪些情况下可以变更)
               - 变更程序是否规范(书面变更、通知方式、签署程序)
               - 解除条件是否合理(法定解除条件、约定解除条件)
               - 解除程序的操作性(通知方式、时间限制)
               - 终止条件的明确性(何种情况下自动终止)
               - 存续条款的合理性(哪些条款在合同终止后继续有效)
               - 终止后的权利义务安排(清算、资料返还等)
            4. 法律适用条款:
               - 适用法律是否明确(具体到哪个国家/地区的法律)
               - 所选法律的合理性(与合同标的、履行地的关联)
               - 是否与强制性规定冲突(履行地法律的强制性规定)
               - 选择的法律在实际纠纷中的可适用性与可执行性
            5. 保密条款:
               - 保密信息范围是否明确定义
               - 保密期限是否明确且合理
               - 例外情况是否合理且有限定
               - 违反保密义务的责任是否明确
            6. 不可抗力条款:
               - 不可抗力事件定义是否合理(避免将可控因素纳入)
               - 通知义务是否明确(时间、方式、证明材料)
               - 责任减免条件是否公平合理
               - 不可抗力事件持续的后续处理措施是否明确
            7. 争议解决条款:
               - 争议解决方式选择是否明确(协商、诉讼、仲裁)
               - 管辖地点或仲裁机构是否明确
               - 是否存在争议解决方式冲突(同时约定仲裁和诉讼)
               - 适用法律选择是否与争议解决方式匹配
            8. 送达条款:
               - 送达方式是否明确(当面送达、邮寄、电子邮件等)
               - 送达地址或联系方式是否准确完整
               - 送达时间和生效条件是否明确
               - 地址变更通知义务是否明确
            9. 授权条款:
               - 授权人员身份是否明确具体
               - 授权范围和权限是否清晰界定
               - 授权期限是否合理规定
               - 撤销或变更授权的机制是否完善
            10. 其他法律条款:
                - 解释规则是否明确(条款冲突处理原则)
                - 签订时间和地点是否明确
                - 条款的独立性是否明确(部分无效不影响整体)

            # 输出要求
            1. 以表格方式输出;
            2. 表格的行标题依次为:序号、问题类型、原文表述、风险原因、修订建议、风险等级;
            3. 问题类型应为十个法律条款审核要点中择一;
            4. 风险等级为高中低,各行按照风险从高到低进行排序,同时要以红黄蓝的 emoji 表情标注;
            5. 原文表述应用引号表明原文准确内容,并说明具体的章、节、条、款、项(如有);
            6. 本节点仅进行这十方面的审核,无需对其他方面进行审核;
            7. 在表格之下总结表格中的高风险事项,除表格和总结外,无需输出其他内容。
            """
        case .english:
            return """
            # Role Definition
            As an experienced contract legal advisor, based on your review stance "\(position)" and the user's additional review requirements "\(additionalRequest)", conduct a legal terms audit on the contract text in the following ten aspects, without omitting any review points:

            Full contract text:
            \(documentText)

            # Legal Terms Review Points
            1. Effectiveness Terms:
               - Is there clear distinction between contract formation and effectiveness
               - Are effectiveness conditions clear (effective upon signing, conditional effectiveness, time-based effectiveness)
               - Is feasibility of effectiveness conditions considered
               - How are legal responsibilities arranged before effectiveness
            2. Breach Liability Terms:
               - Key review: Is definition of breach comprehensive (delayed performance, quality non-compliance, refusal to perform, etc.)
               - Are forms of breach liability clear (continued performance, remedial measures, damages, penalty payment)
               - Is penalty ratio reasonable (neither too high as punitive nor too low to cover losses)
               - Is breach liability fair to both parties (check if penalty ratios are balanced)
               - Is calculation method of breach liability clear
            3. Contract Amendment, Termination, and Dissolution Terms:
               - Are amendment conditions clear (under what circumstances can amendments be made)
               - Are amendment procedures standardized (written amendment, notification method, signing procedure)
               - Are termination conditions reasonable (statutory termination, agreed termination)
               - Operability of termination procedures (notification method, time limits)
               - Clarity of dissolution conditions (under what circumstances automatic dissolution occurs)
               - Reasonableness of surviving clauses (which clauses remain valid after contract termination)
               - Arrangement of rights and obligations after termination (settlement, data return, etc.)
            4. Applicable Law Terms:
               - Is applicable law clearly specified (specific country/region's law)
               - Reasonableness of chosen law (connection with contract subject matter and place of performance)
               - Does it conflict with mandatory provisions (mandatory provisions of the law at place of performance)
               - Applicability and enforceability of chosen law in actual disputes
            5. Confidentiality Terms:
               - Is scope of confidential information clearly defined
               - Is confidentiality period clear and reasonable
               - Are exceptions reasonable and limited
               - Is liability for breach of confidentiality obligations clear
            6. Force Majeure Terms:
               - Is definition of force majeure events reasonable (avoid including controllable factors)
               - Are notification obligations clear (time, method, supporting documents)
               - Are liability exemption conditions fair and reasonable
               - Are follow-up measures for continued force majeure events clear
            7. Dispute Resolution Terms:
               - Is dispute resolution method clearly chosen (negotiation, litigation, arbitration)
               - Is jurisdiction location or arbitration institution clearly specified
               - Are there conflicts in dispute resolution methods (simultaneous provision for arbitration and litigation)
               - Does applicable law choice match dispute resolution method
            8. Service Terms:
               - Is service method clear (personal service, mail, email, etc.)
               - Is service address or contact information accurate and complete
               - Are service time and effectiveness conditions clear
               - Is obligation to notify address changes clear
            9. Authorization Terms:
               - Is identity of authorized personnel clearly specified
               - Are scope and authority of authorization clearly defined
               - Is authorization period reasonably specified
               - Is mechanism for revocation or amendment of authorization complete
            10. Other Legal Terms:
                - Are interpretation rules clear (principles for handling clause conflicts)
                - Are signing time and location clear
                - Is independence of clauses clear (partial invalidity does not affect the whole)

            # Output Requirements
            1. Output in table format;
            2. Table headers in order: No., Issue Type, Original Text, Risk Reason, Amendment Suggestion, Risk Level;
            3. Issue Type should be one of the ten legal terms review points;
            4. Risk Level should be High/Medium/Low, rows sorted from high to low risk, marked with red/yellow/blue emoji;
            5. Original Text should quote the exact content with quotation marks and specify chapter, section, article, clause, item (if applicable);
            6. This review only covers these ten aspects, no need to review other aspects;
            7. Summarize high-risk items below the table; output only the table and summary, nothing else.
            """
        }
    }

    // MARK: - Audit Summary

    static func auditSummary(documentText: String, position: String, detailedFindings: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            请您扮演法律专业人员,基于合同内容如下以及详细审核意见,为业务部门起草一份简洁回复。

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            --- 详细审核意见 ---
            \(detailedFindings)
            --- 详细审核意见结束 ---

            回复内容需包含两个自然段落:

            # 第一段:合同核心内容概述
            请用一段连贯的文字概括本合同的核心内容。说明合同性质(例如:这是一份为期三年的设备采购框架协议),并清晰描述基本的业务模式,重点包括:交易的是什么货物或服务、合同总金额、具体的支付方式与节奏、以及关键的时间节点。在叙述中,请根据我方的审核立场「\(position)」,使用"我方"、"对方"或具体的公司名称来指代合同各方,避免使用"甲方、乙方"的表述。

            # 第二段:主要风险提示
            请用另一段文字集中说明审核中发现的主要风险(需完全依据详细审核意见)。写作时,请先以一句总述性语句开头(例如:"经审核,本合同存在以下几项主要风险需提请关注:"),然后使用数字序号(如1. 2. 3.)分项列出各项风险,数量根据实际情况而定。每项风险应简要说明其类型、具体内容、可能造成的影响以及建议的关注程度。

            # 整体要求:
            - 回复使用 Markdown 格式。第一段文字加粗,第二段无需加粗,但应使用序号(如1. 2. 3.)分项列出各项风险。
            - 语言需简洁、专业、清晰,直接呈现最终内容,无需出现"第一部分"、"第二部分"等引导性词语。
            - 确保立场正确,表述符合我方利益。
            """
        case .english:
            return """
            As a legal professional, based on the contract content below and detailed review findings, draft a concise reply for the business department.

            --- Contract Content ---
            \(documentText)
            --- End of Contract ---

            --- Detailed Review Findings ---
            \(detailedFindings)
            --- End of Detailed Review ---

            The reply should contain two natural paragraphs:

            # First Paragraph: Contract Core Content Overview
            Summarize the core content of this contract in a coherent paragraph. Describe the contract nature (e.g., "This is a three-year equipment procurement framework agreement"), and clearly describe the basic business model, focusing on: what goods or services are being traded, total contract amount, specific payment methods and schedule, and key time milestones. In the narrative, based on our review stance "\(position)", use "our party", "the other party", or specific company names to refer to the contract parties, avoiding expressions like "Party A, Party B".

            # Second Paragraph: Main Risk Alerts
            In another paragraph, concentrate on explaining the main risks found during the review (must be entirely based on detailed review findings). When writing, start with a summary statement (e.g., "Upon review, this contract has the following main risks requiring attention:"), then list each risk using numbered items (e.g., 1. 2. 3.), with the quantity depending on actual circumstances. Each risk item should briefly explain its type, specific content, potential impact, and recommended level of attention.

            # Overall Requirements:
            - Use Markdown format for the reply. Bold the first paragraph, do not bold the second paragraph, but use numbered items (e.g., 1. 2. 3.) to list each risk.
            - Language should be concise, professional, and clear, directly presenting the final content without introductory phrases like "Part One", "Part Two".
            - Ensure correct stance and expressions aligned with our party's interests.
            """
        }
    }

    // MARK: - Identify Stance (Currently Chinese only, as it's used for user input assistance)

    static func identifyStance(documentText: String, language: AppLanguage) -> String {
        switch language {
        case .chinese:
            return """
            请分析以下合同文本,识别合同中的当事人和合同类型,并为用户推荐可能的立场选项。

            --- 合同内容 ---
            \(documentText)
            --- 合同内容结束 ---

            ## 分析要求:

            ### 1. 当事人识别
            - 识别合同中的各方当事人(甲方、乙方等)
            - 提取当事人名称、身份特征
            - 分析各方可能的角色定位(买方/卖方/服务提供商/服务接收方等)

            ### 2. 合同类型识别
            - 确定合同的基本类型(买卖合同、服务合同、承包合同、租赁合同等)
            - 总结核心交易内容

            ### 3. 立场分析
            根据合同性质和当事人身份,推荐:
            - 主要立场选项(如"作为买方/甲方"或"作为卖方/乙方")
            - 该立场下的关键考量点
            - 各立场的优劣势对比
            - 针对该立场的初步谈判建议

            ## 输出格式:

            ### 合同当事人
            - 甲方:[名称和身份特征]
            - 乙方:[名称和身份特征]

            ### 合同类型
            [具体合同类型名称及核心交易内容]

            ### 推荐立场选项
            #### 选项1:[立场描述]
            - 描述:[该立场的含义和采取方式]
            - 关键要点:[该立场下应关注的要点,用数字列表]
            - 优势:[采取该立场的优势,用数字列表]
            - 劣势:[采取该立场的劣势,用数字列表]
            - 谈判建议:[针对该立场的谈判策略和建议]

            #### 选项2:[立场描述]
            [同上格式]

            ## 整体要求:
            - 分析必须基于合同文本的实际内容
            - 立场推荐应该客观中立,给出平衡的选项对比
            - 输出使用中文,格式清晰易读
            """
        case .english:
            return """
            Please analyze the following contract text, identify the parties and contract type, and recommend possible stance options for the user.

            --- Contract Content ---
            \(documentText)
            --- End of Contract ---

            ## Analysis Requirements:

            ### 1. Party Identification
            - Identify all parties in the contract (Party A, Party B, etc.)
            - Extract party names and characteristics
            - Analyze possible roles of each party (buyer/seller/service provider/service recipient, etc.)

            ### 2. Contract Type Identification
            - Determine the basic type of contract (sales contract, service contract, construction contract, lease agreement, etc.)
            - Summarize the core transaction content

            ### 3. Stance Analysis
            Based on contract nature and party identities, recommend:
            - Main stance options (e.g., "As buyer/Party A" or "As seller/Party B")
            - Key considerations under each stance
            - Comparison of advantages and disadvantages of each stance
            - Preliminary negotiation suggestions for each stance

            ## Output Format:

            ### Contract Parties
            - Party A: [Name and characteristics]
            - Party B: [Name and characteristics]

            ### Contract Type
            [Specific contract type and core transaction content]

            ### Recommended Stance Options
            #### Option 1: [Stance description]
            - Description: [Meaning and approach of this stance]
            - Key Points: [Points to focus on under this stance, numbered list]
            - Advantages: [Advantages of taking this stance, numbered list]
            - Disadvantages: [Disadvantages of taking this stance, numbered list]
            - Negotiation Suggestions: [Negotiation strategies and suggestions for this stance]

            #### Option 2: [Stance description]
            [Same format as above]

            ## Overall Requirements:
            - Analysis must be based on actual contract text content
            - Stance recommendations should be objective and neutral, providing balanced option comparisons
            - Output in English with clear and readable format
            """
        }
    }
}
