# Changelog

All notable changes to the Forge plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.0]: https://github.com/jaredchao/forge/releases/tag/v1.1.0
[1.0.0]: https://github.com/jaredchao/forge/releases/tag/v1.0.0
