---
name: forge-implementer
description: Implementer + Spec Reviewer subagent 模板库，供 /forge:ai 在 N3/N4 节点派发 subagent 时使用
---

# forge-implementer — Subagent 模板库

提供两个 prompt 模板，由 `/forge:ai` 的 Controller 在 N3 和 N4 节点调用。

## 模板文件

- `implementer-prompt.md` — N3 节点：派发执行 task 的 Subagent
- `spec-reviewer-prompt.md` — N4 阶段 1：派发验证规格合规性的 Subagent

## 使用原则

**Controller 负责：**
- 从 tasks.md 提取 task 完整文本（不让 subagent 自己读文件）
- 构建场景上下文（架构背景、依赖关系、相关 design.md 内容）
- 传入 LESSONS.md 中与当前 task 相关的记录
- 处理 subagent 返回的状态（DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT）

**Subagent 负责：**
- 在隔离上下文中执行单一 task
- 遵循 `.claude/rules/` 规范
- 完成后报告状态和发现

## 模型选择参考

| 任务特征 | 建议模型 |
| -------- | -------- |
| 明确 spec，改 1-2 文件 | fast |
| 跨文件集成，有判断逻辑 | standard |
| 架构设计、需要广泛理解 | opus |
