# N1: 初始化

1. 从 `$ARGUMENTS` 提取 **项目仓库路径**，记为 `PROJECT_DIR`；**若 `$ARGUMENTS` 未提供路径（裸跑或只带 flag），`PROJECT_DIR` = 当前工作目录（cwd）**
2. 扫描 `{PROJECT_DIR}/docs/specs/` 下所有编号目录（`1.xxx/`、`2.xxx/`），按编号排列
3. 每个 feature 目录须含 requirements.md、design.md、tasks.md
4. 加载 `{PROJECT_DIR}/.claude/CLAUDE.md` + `{PROJECT_DIR}/.claude/rules/`
5. 加载 `{PROJECT_DIR}/docs/specs/LESSONS.md`（架构决策和踩坑记录，开发时必须参考）
6. 感知 **Memory**：检查 `{PROJECT_DIR}/docs/specs/memory/INDEX.md` 是否存在（结构化历史经验的检索入口，按 feature 在 N2 检索注入）。不存在则视为空记忆，不阻塞
7. 验证 `PROJECT_DIR` 存在且可访问

## 运行态与恢复基线

8. 加载 `{PROJECT_DIR}/docs/specs/STATUS.md`（全局看板，单写入者文件，schema 见 `commands/ai.md`）：
   - **不存在** → 由 Controller 据现有 specs 扫描结果创建：`phase: READY_TO_RUN`（已有未完成任务）或 `IN_PROGRESS`（已部分完成），填好各 feature 的 done/total 与物料清单
   - **存在** → 读取作为全局进度起点，后续由 N5/N8 刷新
9. 加载 `{PROJECT_DIR}/docs/specs/RUN_STATE.md`（运行态现场，单写入者文件，schema 见 `commands/ai.md`）：
   - **不存在** → 视为首次运行，本节点结束后由 Controller 创建一份 `stage: IDLE`、无活动任务的初始 RUN_STATE.md
   - **存在且有活动任务（stage ≠ IDLE/DONE）** → 进入恢复路径，交由 N2 做现场校验与中段续跑
10. 记录**恢复基线**（写入 RUN_STATE.md 的「恢复基线」段，供 N2 校验）：
   - `git_commit`：当前 `git rev-parse --short HEAD`
   - `git_worktree`：`git status --porcelain` 为空记 `clean`，否则 `dirty`
   - 基线是「上次主流程认定的可信现场」。**用 git 原生状态判断恢复期间是否有改动，不另算文件指纹**——specs 是 git 跟踪文件，commit 变或 worktree dirty 即已覆盖
