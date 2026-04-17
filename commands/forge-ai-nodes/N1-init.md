# N1: 初始化

1. 从 `$ARGUMENTS` 提取 **项目仓库路径**，记为 `PROJECT_DIR`
2. 扫描 `{PROJECT_DIR}/docs/specs/` 下所有编号目录（`1.xxx/`、`2.xxx/`），按编号排列
3. 每个 feature 目录须含 requirements.md、design.md、tasks.md
4. 加载 `{PROJECT_DIR}/.claude/CLAUDE.md` + `{PROJECT_DIR}/.claude/rules/`
5. 加载 `{PROJECT_DIR}/docs/specs/LESSONS.md`（架构决策和踩坑记录，开发时必须参考）
6. 验证 `PROJECT_DIR` 存在且可访问
