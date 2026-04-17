# N4: Review

每个 task 完成后强制执行，**不可跳过任何阶段**。按以下顺序进行，上一阶段未通过不得进入下一阶段。

## 阶段 1：Spec Compliance Review（规格合规性）

派发专用 subagent，参照 `${CLAUDE_PLUGIN_ROOT}/skills/forge-implementer/spec-reviewer-prompt.md` 构建 prompt。

**目的：** 验证实现与规格严格一致——不多也不少。

传入：
- task 完整需求文本
- implementer 的实现报告

Subagent 必须**读实际代码**而非信任报告，逐条核查：
- 缺失的需求（漏做）
- 多余的实现（多做）
- 需求理解偏差（做错）

结果：
- ✅ Spec compliant → 进入阶段 2
- ❌ Issues: [具体问题 + file:line] → 派发 implementer subagent 修复 → 重新进入阶段 1

## 阶段 2：Codex Review（代码质量）

Spec Compliance 通过后，调用 `codex:rescue`：

- 传入**本 task 涉及的变更文件 diff**（不是整个 working tree）
- 要求审查代码质量、逻辑缺陷、安全问题（OWASP Top 10、注入、硬编码密钥等）
- 合理建议 → 派发 implementer subagent 修复后重新提交 Codex 复审
- 误报 → 记录忽略理由后通过

**额外检查项（Codex 审查时附加要求）：**
- 每个文件是否有单一职责和清晰接口
- 是否遵循 `.claude/rules/` 规范
- 本次变更是否导致文件过大（聚焦新增部分，不追溯历史）

两个阶段均通过 → 进入 N5。

## 红线

- 阶段 1（Spec）必须先于阶段 2（Codex）执行
- 任何阶段有未修复的问题时，禁止进入 N5
- 不得以 implementer 自审代替两阶段 review
