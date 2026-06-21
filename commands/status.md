# /forge:status — 查看进度与下一步（入口 3/3）

> **这是一个 command，不是 skill。** 注入即指令，直接执行。**纯只读，不改任何文件。**

`$ARGUMENTS` — 项目路径（记为 `PROJECT_DIR`）；未提供则取当前工作目录（cwd）。

汇报当前进度，全部来自状态文件（不依赖记忆 / 聊天历史）。

## 步骤（只读）

1. 读 `{PROJECT_DIR}/docs/specs/STATUS.md`（全局 `phase` + 各 feature `done/total`）。不存在 → 提示「尚未 `/forge:start` 生成规格」。
2. 读 `{PROJECT_DIR}/docs/specs/RUN_STATE.md`（当前活动 `feature` / `task` / `stage`；`BLOCKED` 时读 `reason` / `recovery`）。
3. 读各 feature 的 `tasks.md`（`[x]` / `[ ]` / `[CHANGED]` / `[DROPPED]` 分布）与 `requirements.md` 的 AC 勾选（含 `⚠️ MANUAL`）。
4. 读 `{PROJECT_DIR}/docs/specs/security/`（若有：列报告与**未修复的 High/Critical**）。

## 输出

```text
📊 {项目名} — phase: {PLANNING | READY_TO_RUN | IN_PROGRESS | READY_TO_RELEASE}

📂 Feature 进度: {done}/{total}
   - 1.user-auth   5/5  ✅
   - 2.payment     2/7  🔄  当前 T-003 · stage REVIEWING

✅ AC: {已确认}/{总} · ⚠️ 待人工确认: {N}
🔒 安全: {无未修复 High/Critical | {N} 项待修，见 security/}

➡️ 下一步：{ /forge:run 继续开发 | /forge:start 调整需求(变更) | 全部完成，可发布 + /forge:retro 复盘 }
```

## 约束

- **纯只读**：不写 `STATUS` / `RUN_STATE` / `tasks` / `requirements` / 任何文件。
- 发现现场不一致（如 RUN_STATE 的活动任务在 tasks.md 里已 `[x]`，或 `stage=BLOCKED`）→ 如实指出，并提示 `/forge:run` 会在恢复时做现场校验处理。
