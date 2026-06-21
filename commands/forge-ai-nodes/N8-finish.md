# N8: 完成

所有 feature 的所有任务完成后：

## 1. 调用 forge-doc-syncer

调用 `forge-doc-syncer` skill 完成文档同步：

- README 精炼更新（架构 + 业务 + 快速开始）
- .claude/CLAUDE.md 和 rules/ 同步
- specs CHANGELOG 按日期生成
- 文档一致性验证

## 2. 收尾前校验（红线）

进入发布态前，Controller 必须确认：

- 所有 feature 的 tasks 全部 `[x]`（除显式 `[DROPPED]`）
- 无遗留 `stage: BLOCKED` 的活动任务
- 安全专项无未修复的 High/Critical 发现（见 `docs/specs/security/`）

任一不满足 → 不得置 READY_TO_RELEASE，回到对应节点处理。

## 3. 置发布态 + Release Candidate 摘要

- 把 `STATUS.md` 的 `phase` 置为 `READY_TO_RELEASE`，`RUN_STATE.md` 清为 `IDLE`
- 生成 Release Candidate 摘要（写入 STATUS.md 或单独 `docs/specs/RELEASE_NOTES.md`）：本轮新增/变更的 feature、关键技术决策、安全审查结论、已知手动验证项（`⚠️ MANUAL` 的 AC）

## 4. 输出总结

```text
🎉 全部完成 — READY_TO_RELEASE

📂 Features: {完成数}/{总数}
📋 总任务: {完成数}/{总数}
📝 文档同步: 已完成
🔒 安全专项: {N} 份报告，无未修复 High/Critical
⚠️ 待人工确认 AC: {N} 项

各 Feature 摘要:
- 1.{name}: {N} 个任务 ✅
- 2.{name}: {N} 个任务 ✅

下一步: 审查 Release Candidate 后可发布；运行 /forge:retro 做本轮复盘
```
