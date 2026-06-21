# /forge:retro — 迭代复盘

> **这是一个 command，不是 skill。** 注入即指令，直接执行，不要去找名为 `forge-retro` 的 skill。
> 通常在 `/forge:run` 收尾后手动运行做复盘；也可随时单独运行。

`$ARGUMENTS` — 项目仓库路径（记为 `PROJECT_DIR`）；**未提供则取当前工作目录（cwd）**。可选 `--feature {N}.{feature-name}` 只复盘单个 feature。

在一轮开发收尾后（通常 `/forge:ai` 已置 `STATUS.md` 为 `READY_TO_RELEASE`）做结构化复盘，把过程经验沉淀进 `LESSONS.md`，并对规格与流程提出改进。**只读 + 追加 LESSONS，不改业务代码。**

## Step 1: 收集本轮事实

读取（单一事实源，不依赖记忆）：

- `docs/specs/STATUS.md` — 各 feature 进度与阶段
- 各 `docs/specs/{N}.{feature}/tasks.md` — 完成、`[CHANGED]`、`[DROPPED]` 分布
- 各 `requirements.md` — AC 通过 / `⚠️ MANUAL` / 未验情况
- `docs/specs/security/*.md` — 安全发现与修复结论
- `docs/specs/RUN_STATE.md` — 是否有遗留 BLOCKED
- Git log（本轮范围）— 返工次数、热点文件

## Step 2: 复盘维度

- **交付**：计划 vs 实际任务数、变更/废弃比例、预估时间偏差
- **质量门**：Spec/Codex/QA/安全各拦下了什么、误报率、返工最多的环节
- **踩坑**：阻塞点、环境问题、依赖问题及其根因
- **规格质量**：哪些 `[CHANGED]` 源于 PRD/需求拆解不到位（可回推 `/forge:prd` 的拆分粒度）

## Step 3: 沉淀与改进

1. 把有长期价值的经验**追加**到 `docs/specs/LESSONS.md`（格式：`## {日期} — 复盘 / {范围}`），不记流水账
2. 给出可执行改进建议，分三类：
   - 规格层（requirements/design/tasks 怎么拆更好）
   - 流程层（节点/质量门/触发条件怎么调）
   - 工程层（依赖、环境、CI 怎么固化）

## Step 4: 输出复盘报告

```text
📊 迭代复盘 — {范围}

交付: 计划 {N} / 实际 {N} 任务 | 变更 {N} | 废弃 {N}
质量门: Spec {拦截/返工} | QA {pass/fail} | 安全 {findings}
Top 踩坑:
1. {根因} → {改进}
2. ...

已沉淀 LESSONS: {N} 条
改进建议: 规格 {N} / 流程 {N} / 工程 {N}
```

## 约束

- 只读分析 + 追加 `LESSONS.md`，**不改** tasks/requirements/RUN_STATE/STATUS（这些由 `/forge:ai` 主流程维护）
- 复盘建议供人审，不自动改流程文件
