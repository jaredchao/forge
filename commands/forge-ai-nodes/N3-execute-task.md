# N3: 执行 Task

## 开始标记

```text
🔨 Task {T-编号}: {任务描述} ~{预估时间}
   Feature {F}/{总F} | 任务 {N}/{总数}
```

## 工种匹配 → 具名 subagent

根据任务涉及的工种，优先派发对应的**具名 subagent**（`subagent_type`，自带工具沙箱与 `model: sonnet`）：

| 工种 | subagent_type | 内部加载的 skill |
| ---- | ------------- | ---------------- |
| 平台/基建 | `forge-platform-engineer` | `forge-platform-engineer` |
| 前端 | `forge-frontend-engineer` | `forge-frontend-engineer` |
| 后端/API | `forge-backend-engineer` | `forge-backend-engineer` |
| 数据库 | `forge-database-engineer` | `forge-database-engineer` |
| 合约 | `forge-contract-engineer` | `forge-contract-engineer` |
| QA/测试 | `forge-qa-engineer`（通常由 N6 触发） | `forge-qa-engineer` |
| 无匹配工种 | `forge-implementer`（通用兜底，见下方说明） | — |

**平台/基建工种覆盖（语言无关）**：项目初始化、多模块/workspace 搭建、依赖与构建系统配置、lint/format 工具、Docker、CI/CD、env 脚手架、发布工具——无论 Node、Java、Python、Go、Rust、.NET 等。**这类「脚手架/初始化」任务一律派 `forge-platform-engineer`（它会先探测语言生态再用对应工具链），不再落 implementer 兜底。**

具名 subagent 第一步会强制 `Skill` 加载同名 skill，无需主流程再手动指定 skill。

> 关于兜底：`forge-implementer` 是 **skill/prompt 模板名，不是具名 agent**。真正无任何工种匹配时，`subagent_type` 填 **`general-purpose`**，并用 `implementer-prompt.md` 构建 prompt——不要传 `subagent_type: forge-implementer`（无此 agent，会报错）。

## 模型选择

具名工种 subagent 已自带 `model: sonnet`。下表用于**无匹配工种 → 走 `forge-implementer` 兜底**时，由主流程为 implementer 选模型：

| 任务特征 | 模型 |
| -------- | ---- |
| 明确 spec，改 1-2 文件 | fast（最便宜） |
| 跨文件集成，有判断逻辑 | 标准模型 |
| 架构设计、需要广泛理解 | 最强模型 |

## Router 细判 → 派发路径 + 门禁档

对每个 task，Controller **判一次、一次出三样**：执行路径、工种、门禁档（Fast/Standard/Full，风险信号定义见 N4）。N2 注入的 Memory 高危经验**抬高难度**。

| 路径 | 触发 | 怎么做 |
| ---- | ---- | ---- |
| **Inline** | 微小：≤1 文件 · 改动 ≲20 行 · 低风险 · 单工种 · 无依赖 | Controller **不派 subagent**，自己 inline 加载对应工种 skill 写完（省冷启动），做完照走 N4。**高风险绝不 inline。** |
| **Single** | 中等 · 单工种 · 有判断逻辑 | Agent 工具派 **1 个**具名工种 subagent（默认路径） |
| **Serial** | 多 task 但有依赖 / 改同一文件 | 串行逐个派单 subagent |
| **Swarm** | 复杂 · 多工种/跨模块 · 无依赖可并行 | 多工种 subagent 各自**独立 worktree 并行**（≤3–4），Controller 收口合并（worktree 前置见 N2） |

判完在起始标记追加：`🧭 Router: {inline|single|serial|swarm} · {Fast|Standard|Full} — {理由}`，并写入 RUN_STATE 的 `route` 字段（cc-monitor 可显示）。

> **Inline 红线**：只给真·微小活——它会用实现细节污染主 Claude 上下文，所以严格卡边界，超过即降为 Single。**高风险禁 inline、禁降级**（与 N4 红线一致）。无论哪条路径，结果都**回 Queen（Controller）收口**再进 N4。

## 派发前：写 RUN_STATE

派发 subagent（或 Inline 自己动手）前，Controller 先把 RUN_STATE.md 活动任务更新为：`feature` / `task` = 当前 task，`stage: IMPLEMENTING`，`route` = Router 路径，`updated` = 当前时间。这样即使中断，N2 也能据此中段恢复。**这是 Controller 的写动作，不是 subagent 的。**

## 派发 Subagent

**Single / Serial / Swarm 路径**：使用 Agent 工具派发上表匹配到的具名 subagent，**不直接执行任务**。无匹配工种时退回 `forge-implementer`（general-purpose），参照 `${CLAUDE_PLUGIN_ROOT}/skills/forge-implementer/implementer-prompt.md` 构建 prompt。

**Inline 路径**：Controller 自己加载对应工种 skill（`Skill` 工具）inline 实现，不派 subagent；完成后同样进 N4。仅限 Router 判为 Inline 的微小、低风险 task。

派发 prompt（Inline 时为 Controller 自己的执行上下文）都须备齐以下内容（不让 subagent 漫读文件）：

- task 完整文本（从 tasks.md 提取，逐字传入）
- 场景上下文（当前 feature 位置、依赖、架构背景）
- 代码项目路径
- 相关 design.md 模块设计摘要
- **N2 检索注入的 Memory 命中经验**（`memory/{slug}.md` 与本 task 相关的踩坑/决策/复用）+ LESSONS.md 如有

> **单写入者提醒**：派发 prompt 中必须明确告知 subagent **禁止修改任何 specs/状态文件**（`tasks.md`、`requirements.md`、`RUN_STATE.md`、`STATUS.md`、`LESSONS.md`、`memory/`），结论一律通过最终回报返回，由 Controller 落盘。

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
4. 以上均无效 → 置 RUN_STATE `stage: BLOCKED`（写明 reason 与精确 recovery 指令），暂停上报用户

**永远不要：** 忽略 escalation、强制同一模型重试而不做任何改变。
