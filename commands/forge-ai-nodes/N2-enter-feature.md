# N2: 进入 Feature

1. 读取该 feature 的 requirements.md、design.md、tasks.md
2. 断点恢复：`[x]` 已完成 → 跳过，`[DROPPED]` → 跳过，`[CHANGED]` → 按更新后描述执行
3. 如该 feature 所有任务已完成 → 跳过，进入下一个 feature

## 恢复校验（RUN_STATE 有活动任务时强制）

当 N1 发现 RUN_STATE.md 存在活动任务（stage ∈ IMPLEMENTING/VERIFYING/REVIEWING/QA/BLOCKED）时，**先校验现场再决定动作，禁止盲目续跑或盲目重做**。校验只看 git 原生状态（specs 是 git 跟踪文件，无需另算指纹）：

1. **Git 现场**：当前 `git rev-parse --short HEAD` 与基线 `git_commit` 是否一致；`git status --porcelain` 是否仍 `clean`
2. **活动任务唯一**：RUN_STATE 的 `task` 在 tasks.md 中存在且仍为未完成

按校验结果分支：

| 校验结果 | 动作 |
| ---- | ---- |
| commit 一致 + worktree clean + stage 有效 | **中段续跑**：直接从该 stage 进入对应节点（见下表），不重做已通过阶段 |
| commit 变了 / worktree dirty（恢复期间有改动） | 核对改动是否落在本 feature 的 specs：动了 specs → 标 `[CHANGED]`，清旧结论与 stage，从 N3 重做；只动了代码且属本 task → 续跑前先核对 | 
| 活动任务不唯一 / 无法判定 | 置 `stage: BLOCKED`，输出诊断与精确恢复指令，升级用户，不擅自续跑 |
| stage=BLOCKED | 读取 RUN_STATE 里的 reason/recovery，先尝试自动恢复；无果再升级用户 |

### 中段续跑入口

| RUN_STATE stage | 续跑入口 |
| --------------- | -------- |
| IMPLEMENTING | 重新派发 N3 实现 subagent（实现可能未完成） |
| VERIFYING | 直接进 N4 阶段1（Spec 合规审查） |
| REVIEWING | 直接进 N4 阶段2（Codex 审查） |
| QA | 直接进 N6 重新触发 QA |
| DONE | 该 task 已完成但未清场 → 补打 `[x]` 并清 RUN_STATE 为 IDLE |

> 核心：恢复不依赖聊天历史，只由 RUN_STATE.md + tasks.md + Git 现场共同确定下一步。

## Learning Loop — Memory 读端（检索注入）

进入 feature、判难度前，Controller 先检索结构化历史经验注入上下文。这是**自学习闭环的「读」端**，对应 N5 的「写」端。

1. 读 `{PROJECT_DIR}/docs/specs/memory/INDEX.md`
2. 用本 feature 的关键词（模块名 / 技术栈 / 涉及的 API·schema / 已知风险）匹配 INDEX 行的 `tags` 与钩子
3. 命中条目读其 `memory/{slug}.md` 全文注入；**只取 top-K（≤5）最相关**，避免上下文膨胀
4. 无 `memory/` 或无命中 → 跳过，不阻塞

输出：`🧠 Memory 命中 {n} 条：{标题列表}`（0 条则 `🧠 Memory 无相关经验`）。

> 命中的经验会喂给下面的 Router 判难度——**历史高危踩坑会抬高难度档**。

## Router — 判难度与执行计划（feature 粗判）

每个 feature 进来时，Controller（Queen）**粗判一次整体难度**，定执行计划；注入的 Memory 经验参与判定。判完**始终回 Queen 收口**，subagent 无权自行决定路径。逐 task 的细判（具体派发路径 + 门禁档）在 N3。

| feature 难度 | 信号 | 整体计划 |
| ---- | ---- | ---- |
| 轻 | 全是单文件/低风险小改 | 多数 task 走 N3 的 **Inline** 路径（主 Claude 直接做），少派 subagent |
| 中 | 单/少量项目、有依赖、含共享 schema·API | N3 多走 **Single/Serial**，按依赖串行 |
| 重 | 多模块 + 多项目 + 高风险 / 大范围重构 | N3 走 **Swarm 并行**（独立 worktree），见下方执行计划 |

输出：`🧭 Router 粗判：{轻/中/重} — {一句理由} → 计划 {以 Inline 为主 / 串行 / 并行}`。

## 执行计划

分析 tasks.md 的依赖关系，自行决定串行或并行：

| 串行 | 并行 |
| ---- | ---- |
| 有显式依赖 | 无依赖 |
| 会修改同一文件/模块 | 分属不同代码项目 |
| 涉及共享状态定义（schema、API） | 天然隔离 |

并行时用 Agent 工具派发**对应工种的具名 subagent**（`subagent_type` = `forge-{工种}-engineer`，见 N3 工种映射），而非 general-purpose。每个 subagent 自带工具沙箱与 `model: sonnet`，上下文天然隔离。所有任务都有依赖时退化为全串行。

### 真并行的硬前置：worktree 隔离

并行 subagent 会同时改文件，**没有隔离就会互相踩工作树、污染 diff 归属**。因此真并行必须满足：

1. 每个并行 subagent 在**独立的 `git worktree`** 中作业（一个 task 一个 worktree），完成后由 Controller 收敛 diff、按归属合并回主工作树
2. 状态文件仍遵守**单写入者**：subagent 不写 RUN_STATE/tasks/requirements，只回报结果

**不满足 worktree 隔离时，并行降级为串行**（宁可慢也不要脏现场）。当前若未配置 worktree，N2 只输出「并行候选」，实际仍串行执行。

输出：

```text
📂 Feature {N}/{总数} — {feature名}
📋 执行计划：
  串行 1: T-001 → T-002
  并行 2: T-003 + T-004
  串行 3: T-005 ← 依赖 T-003, T-004
```
