# /forge:run — 自动执行当前任务（入口 2/3）

> **这是一个 command，不是 skill。** 注入即指令，直接执行，不要去找名为 `forge-run` 的 skill。

`$ARGUMENTS` — 项目路径（记为 `PROJECT_DIR`）；未提供则取当前工作目录（cwd）。

自动开发：从 `RUN_STATE.md` 续跑当前任务，跑完一个继续下一个，直到全部 feature 完成。
**完整流程与规则（N1–N8、恢复校验、分级门禁、单写入者、并行 worktree 前置）见 `${CLAUDE_PLUGIN_ROOT}/commands/ai.md`，按其流程图逐节点执行。**

## 默认行为

- 无活动任务 → 从第一个未完成 task 开始走 N1→N8。
- `RUN_STATE` 有活动任务（中断恢复）→ 先做 N2 现场校验，再从对应 `stage` **中段续跑**，不重做已完成的部分。
- 全程自动推进，feature 间自动继续，无需用户逐步确认（暂停规则见 ai.md 全局规则）。

## 高级用法（可选，常规不用）

- 限定单个 feature：`/forge:run --feature {N}.{feature-name}`
- 定点重入某阶段：`/forge:run --stage {implement|verify|review|qa}`

二者语义与 `ai.md` 的「Feature-scoped 模式」「Stage 定点重入模式」一致——`$ARGUMENTS` 含这些 flag 时按 ai.md 对应章节处理。

## 输出

进度按 N5 / N8 的格式滚动；全部完成后置 `STATUS.phase = READY_TO_RELEASE`，并提示用 `/forge:status` 查看、`/forge:retro` 复盘。
