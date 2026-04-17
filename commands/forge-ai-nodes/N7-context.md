# N7: 上下文管理

## task 完成后（Subagent 执行模式）

Subagent 天然拥有隔离的上下文，**task 间无需 `/clear`**。

Controller（主 Claude）在 task 间只需：
1. 读取下一个 task 的描述
2. 从 LESSONS.md 提取与下一 task 相关的记录
3. 构建 subagent prompt 并派发

若 Controller 自身上下文达 **80%** → 执行 `/compact` 后继续。

## feature 完成后

执行 `/clear`，然后重新加载：
- 下一个 feature 的 specs（requirements.md、design.md、tasks.md）
- `{PROJECT_DIR}/docs/specs/LESSONS.md`
- 代码项目的 `.claude/CLAUDE.md` + `.claude/rules/`

全程自动继续，无需等待用户指令。

## task 执行中（非 Subagent 场景）

如某 task 由 Controller 直接执行（无匹配 skill 且任务极小），上下文达 80% → 执行 `/compact` 后继续当前 task。
