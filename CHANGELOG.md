# Changelog

All notable changes to the Forge plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-06-18

### Added
- **🧠 自学习闭环（Learning Loop / Memory）**：新增结构化记忆 `docs/specs/memory/`（INDEX + 每条一文件，带 tags/type/scope frontmatter）。N2 是**读端**（按关键词检索注入 top-K 命中经验），N5 是**写端**（踩坑/决策/可复用封装写回 + 更新 INDEX）。闭环：本轮写的，下个 feature 在 N2 读到；命中高危经验抬高 Router 难度。单写入者 + PII 门同样管 memory；`LESSONS.md` 退为人读摘要。
- **🧭 Router 执行路由（与门禁档合一）**：N2 粗判 feature 难度、N3 细判每个 task，一次出「执行路径 + 工种 + 门禁档」并写入 RUN_STATE `route`。路径 `inline`（主 Claude 直接做，省冷启动，仅微小低风险）/ `single` / `serial` / `swarm`（独立 worktree 并行 ≤3–4）。高风险禁 inline、禁降级；始终回 Queen 收口。收敛了原先分散在 N2/N3/N4 的路由逻辑。
- **🛡️ PII 出站门（egress）**：N4 调 Codex 前、以及任何外发（外部 API / Telegram / Memory 写入）前强制脱敏（密钥/PII/内网址 → 占位，无法脱敏则暂停）；本地 subagent 互传不拦。
- **Codex 冲突仲裁（收窄版）**：reviewer 意见相左时以 Codex 为该次冲突裁判（不投票）；但仅收窄到「审查冲突」，不把 Spec/QA/安全放行权全收敛给 Codex。
- **3 入口收敛**：用户面只留 `/forge:start`（需求→规格，自动判断 init/新建/变更/大需求拆分）、`/forge:run`（自动续跑 N1–N8）、`/forge:status`（**新增**，只读汇报进度与下一步）。`init/prd/ai/map/ui/retro` 降为内部/高级命令，仍可单独调用（向后兼容别名）；`/forge:ai` 仍是 `/forge:run` 调用的 N1–N8 引擎。
- **运行态文件 `RUN_STATE.md`**（落在被开发项目的 `docs/specs/`）：记录活动任务与阶段生命周期（`IMPLEMENTING / VERIFYING / REVIEWING / QA / BLOCKED / DONE / IDLE`），支持**中段恢复**——断在审查/QA 时不再从头重做整个 task
- **恢复基线与现场校验**：N1 记录 `git_commit` / worktree 状态 / specs 指纹；N2 恢复前交叉校验 Git 现场与物料指纹，冲突即 BLOCKED 并给精确恢复指令，不盲目续跑（跨会话恢复不依赖聊天历史）
- **单写入者纪律**：明确只有主流程（Controller / N5）可写 `RUN_STATE.md` / `tasks.md` / `requirements.md` / `LESSONS.md`；所有 subagent 禁止写状态文件，结论仅通过回报返回

- **新增平台/基建工种** `forge-platform-engineer`（subagent + skill）：语言无关，专管项目初始化、多模块/workspace、依赖与构建系统、Docker、CI/CD、env 脚手架——先探测语言生态（Node/Java/Python/Go/Rust/.NET 等）再用对应工具链。N3 将「脚手架/初始化」类 task 直接映射到它，不再落 `forge-implementer` 兜底；并澄清兜底应填 `subagent_type: general-purpose`（`forge-implementer` 是模板名非 agent）
- **安全工种升为一等关卡**：新增 `forge-security-engineer` subagent（代码级安全审计，复用 `forge-code-reviewer`；有部署目标时追加 `forge-security`/METATRON 动态扫描）。N6 在命中高风险（认证/授权/支付/合约/对外接口/敏感数据）时与 QA 并列触发，报告落 `docs/specs/security/{N}.{feature}.md`，High/Critical 未修复禁止收尾
- **`--stage` 定点重入**：`/forge:ai --stage {implement|verify|review|qa}` 配合 RUN_STATE 直接跳到对应节点重跑某阶段，无需从头跑整个 task
- **`STATUS.md` 全局看板**：整体 phase（PLANNING/READY_TO_RUN/IN_PROGRESS/READY_TO_RELEASE）、各 feature 进度、物料清单
- **发布闭环**：N8 增收尾前校验 + Release Candidate 摘要 + `READY_TO_RELEASE` 态；新增 `/forge:retro` 迭代复盘命令
- **PROJECT_DIR 默认 cwd**：所有命令（ai/prd/init/map/ui/retro）在未提供路径参数时，`PROJECT_DIR` 默认取当前工作目录——`/forge:ai` 裸跑等价于 `/forge:ai .`，配合 `dev.sh` 已 cd 到项目即可直接用
- **命令防呆**：每个命令文件顶部声明「这是 command 不是 skill，注入即指令、直接执行」，避免模型把 `/forge:ai` 误当成需要 invoke 的 skill（修复无参裸跑时去找不存在的 `forge-ai` skill 的问题）

### Changed
- **分级门禁（提速）**：N4 按「风险×体量」判档——`Fast`（低风险/≤2文件/不跨模块）只跑 Codex 单段、不单独派 Spec Reviewer；`Standard` 跑两段；`Full`（高风险）两段 + N6 完整门。**高风险禁止降级**，「至少一道正确性审查」不可为零。
- **N6 条件化（提速）**：E2E 仅当 task 含**用户可达入口**才作 PASS 硬条件（纯内部后端改动不被 E2E 拖慢）；QA/安全深度跟随 N4 档位；**METATRON 动态扫描默认关**（常规只代码级审计，仅显式给部署目标时才追加）。
- N1：加载 STATUS.md 与 RUN_STATE.md 并记录恢复基线
- N2：新增「恢复校验 + 中段续跑」分支；并行新增 **git worktree 隔离硬前置**，不满足则降级串行（消除并行 subagent 互相踩工作树的隐患）
- N3：派发前写 `IMPLEMENTING`、BLOCKED 时写 RUN_STATE，派发 prompt 强制声明状态文件禁写
- N4：阶段1/2 分别写 `VERIFYING` / `REVIEWING`
- N5：落盘顺序改为 `DONE` → 打 `[x]` → 清 `IDLE` 并刷新基线 + 刷新 STATUS.md 进度
- N6：扩为「QA 与安全评估」，触发 QA 时写 `QA` 阶段，新增安全专项触发与落盘
- N8：增收尾前校验、Release Candidate 摘要与 `READY_TO_RELEASE`
- 5 个工种 subagent 与 implementer / spec-reviewer prompt 模板：补「禁止写状态文件」边界

## [1.1.0] - 2026-06-14

### Added
- 工种 subagent 层（`agents/`）：`forge-frontend-engineer`、`forge-backend-engineer`、`forge-database-engineer`、`forge-contract-engineer`、`forge-qa-engineer`，各自带工具沙箱与 `model: sonnet`，第一步强制 `Skill` 加载同名 skill
- 补齐 `forge-database-engineer` skill（此前 N3 已引用但缺失）
- 新增 `forge-contract-engineer` skill（解除 N3 对合约工种的悬空引用）
- 新增辅助 skill：`forge-spec-writer`、`forge-code-reviewer`、`forge-test-runner`、`forge-security`

### Changed
- N2：并行任务改为派发对应工种的具名 subagent（`subagent_type` = `forge-{工种}-engineer`），而非 general-purpose
- N3：工种匹配直接映射到具名 subagent（含合约 → `forge-contract-engineer`）；仅无匹配工种退回 `forge-implementer` 兜底；模型选择表改为仅用于 implementer 兜底（具名 subagent 自带模型）

## [1.0.0] - 2026-04-17

### Added
- Initial release of Forge plugin
- `/forge:prd` command for PRD-to-specs generation
- `/forge:ai` command for automated development execution
- `/forge:init` command for project structure initialization
- Support for requirement change management (`--change` flag)
- Multi-stage review system (Spec Compliance + Codex Quality)
- Specialized skills: forge-implementer, forge-frontend-engineer, forge-qa-engineer, forge-doc-syncer
- Automatic lessons learned documentation (LESSONS.md)
- Single repository mode with unified docs/ structure
- Version tracking for requirements and design changes
- Task dependency management and parallel execution
- Context management with subagent isolation

### Features
- PRD document parsing (supports .md, .txt, .pdf)
- Automatic project architecture detection
- Tech stack analysis from .claude/CLAUDE.md
- Coding rules integration from .claude/rules/
- Task breakdown with time estimation
- Spec compliance verification
- OWASP Top 10 security checks
- Automatic task marking and progress tracking

### Documentation
- Comprehensive README with quick start guide
- Command reference and usage examples
- Architecture overview and workflow diagrams
- Troubleshooting guide
- MIT License

## [Unreleased]

### Planned
- Support for multi-repository projects
- Additional specialized skills (mobile, DevOps, ML)
- Integration with project management tools (Jira, Linear)
- Visual progress dashboard
- Multi-language PRD support
- Automated E2E test generation
- Plugin marketplace publication
- Example projects and templates

---

[1.2.0]: https://github.com/jaredchao/forge/releases/tag/v1.2.0
[1.1.0]: https://github.com/jaredchao/forge/releases/tag/v1.1.0
[1.0.0]: https://github.com/jaredchao/forge/releases/tag/v1.0.0
