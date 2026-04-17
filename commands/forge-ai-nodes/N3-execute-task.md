# N3: 执行 Task

## 开始标记

```text
🔨 Task {T-编号}: {任务描述} ~{预估时间}
   Feature {F}/{总F} | 任务 {N}/{总数}
```

## Skill 匹配

根据任务涉及的工种查找可用的 `forge-*` skills：

- 前端 → `forge-frontend-engineer`
- 数据库 → `forge-database-engineer`
- 合约 → `forge-contract-engineer`
- QA/测试 → `forge-qa-engineer`
- 没有匹配 → 使用通用 implementer

## 模型选择

| 任务特征 | 模型 |
| -------- | ---- |
| 明确 spec，改 1-2 文件 | fast（最便宜） |
| 跨文件集成，有判断逻辑 | 标准模型 |
| 架构设计、需要广泛理解 | 最强模型 |

## 派发 Implementer Subagent

使用 Agent 工具（general-purpose 或匹配的 forge-* skill）派发，**不直接执行任务**。
参照 `${CLAUDE_PLUGIN_ROOT}/skills/forge-implementer/implementer-prompt.md` 构建 prompt，将以下内容完整传入：

- task 完整文本（从 tasks.md 提取，不让 subagent 自己读文件）
- 场景上下文（当前 feature 位置、依赖、架构背景）
- 代码项目路径
- 相关 design.md 模块设计摘要
- LESSONS.md 中与本 task 相关的记录

## 处理 Subagent 状态

**DONE** → 进入 N4 Review。

**DONE_WITH_CONCERNS** → 读取 concerns 内容：
- 涉及正确性或范围 → 先解决 concerns，再进 N4
- 仅为观察性说明 → 记录后进 N4

**NEEDS_CONTEXT** → 补充缺失信息后重新派发同一 task。

**BLOCKED** → 按顺序评估：
1. 补充上下文后重新派发
2. 换更强模型重新派发
3. 将 task 拆为更小粒度后分别派发
4. 以上均无效 → 暂停，上报用户

**永远不要：** 忽略 escalation、强制同一模型重试而不做任何改变。
