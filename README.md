# Forge - PRD-Driven Automated Development System

A Claude Code plugin that transforms Product Requirement Documents (PRDs) into production-ready code through AI-powered spec generation, automated task execution, and multi-stage quality review.

## Features

- **PRD to Specs**: Automatically generate technical specifications from requirement documents
- **AI-Driven Development**: Execute development tasks with specialized AI agents
- **Multi-Stage Review**: Spec compliance check + code quality review (Codex integration)
- **Change Management**: Support requirement changes with version tracking
- **Lessons Learned**: Automatic documentation of architectural decisions and gotchas
- **Single Repository Mode**: Unified docs and code structure

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) CLI or Desktop App
- Git repository for your project

### Install Plugin

```bash
# Clone this repository
git clone https://github.com/jaredchao/forge.git ~/.claude/plugins/forge

# Or install via Claude Code (when published)
claude plugin install forge
```

## Quick Start

Three steps, three commands.

### 1. Write your requirements

Drop your requirement docs into `docs/prd/`:

```
your-project/
└── docs/
    └── prd/
        └── feature.md
```

### 2. Generate specs

```bash
cd your-project
/forge:start
```

`start` initializes `.claude/` if needed, reads `docs/prd/`, and generates `requirements.md` + `design.md` + `tasks.md` under `docs/specs/{N}.{feature-name}/`. Re-running with an existing spec enters **change mode** (versioned requirement updates).

### 3. Auto-develop & track

```bash
/forge:run        # executes N1–N8 for every task, auto-resuming from RUN_STATE
/forge:status     # read-only: phase, progress, active task, next step
```

`run` dispatches discipline subagents, runs tiered review + QA + security gates, marks tasks done, and continues until every feature is implemented.

## Workflow

```
Requirements (docs/prd/)
    ↓
[/forge:start] → specs: requirements.md + design.md + tasks.md
    ↓
[/forge:run] → Automated Development (N1–N8)
    ↓
For each task (depth scales with risk × size):
  1. Dispatch the matching discipline subagent (platform/backend/…)
  2. Review — Fast: Codex only · Standard/Full: Spec + Codex
  3. QA + security gate (conditional: E2E only for user-facing surface)
  4. Mark done + record lessons → RUN_STATE / STATUS / tasks
    ↓
[/forge:status] anytime → Production-Ready Code
```

## Commands

Forge exposes **3 entrypoints**. Everything else is internal — the controller orchestrates it.

### `/forge:start` — turn requirements into specs

Put your requirement docs in `docs/prd/`, then run start. It auto-decides what's needed: initializes `.claude/` if missing, generates specs (new or **change** mode if specs already exist), and splits large requirements into modules.

```bash
/forge:start                       # runs in the current project dir
/forge:start "add WeChat login"    # change mode auto-detected when specs exist
```

### `/forge:run` — auto-develop

Executes the N1–N8 pipeline, auto-resuming the current task from `RUN_STATE.md` and continuing to the next until done.

```bash
/forge:run
/forge:run --feature 1.user-auth   # advanced: scope to one feature
/forge:run --stage review          # advanced: re-enter a single stage
```

### `/forge:status` — see progress

Read-only. Reports phase, per-feature progress, the active task/stage, security findings, and the suggested next step — all from the state files.

```bash
/forge:status
```

### Internal / advanced commands

These are orchestrated by the 3 entrypoints above; run them directly only when you want fine control: `/forge:init` (context only), `/forge:prd` (spec gen / `--change`), `/forge:ai` (the N1–N8 engine; `/forge:run` calls it), `/forge:retro` (retrospective).

## Specialized Skills

Forge includes specialized agents for different development tasks:

- **forge-implementer**: General-purpose fallback (dispatched as `general-purpose` for tasks that match no discipline)
- **forge-platform-engineer**: Project init & infra, language-agnostic (Node/Java/Python/Go/Rust/.NET…) — project scaffolding, multi-module/workspace, build & dependency systems, Docker, CI/CD, env scaffolding
- **forge-frontend-engineer**: React/Vue/frontend development
- **forge-backend-engineer**: Backend/API development
- **forge-database-engineer**: Data modeling, migrations, query optimization
- **forge-contract-engineer**: Smart contract development (EVM/Solana/Move)
- **forge-qa-engineer**: Testing and quality assurance
- **forge-security-engineer**: First-class security gate — code-level audit (OWASP) + optional dynamic scan, triggered by N6 on high-risk changes
- **forge-doc-syncer**: Documentation synchronization

Auxiliary skills (invoked on demand, not dispatched per task):

- **forge-spec-writer**: Requirement docs → requirements/design/tasks specs
- **forge-code-reviewer**: Two-round code review + security scan (Telegram alert on findings)
- **forge-test-runner**: Auto-generate and run unit/E2E tests + visual regression
- **forge-security**: METATRON-based penetration testing of deployment targets

Each engineering discipline (platform/frontend/backend/database/contract/qa/security) is also exposed as a **subagent** (`agents/forge-*-engineer`) with its own tool sandbox and `model: sonnet`. N2 dispatches them per-discipline for parallel work with natural context isolation; each subagent loads its skill as the single source of truth. Subagents are read-only on state files — only the controller writes specs/state (single-writer rule).

## Architecture

### Directory Structure

```
your-project/
├── docs/
│   ├── prd/                    # Input: requirement documents
│   │   └── feature-spec.md
│   └── specs/                  # Output: generated specs
│       ├── 1.user-auth/
│       │   ├── requirements.md # Functional requirements
│       │   ├── design.md       # Technical design
│       │   └── tasks.md        # Task breakdown
│       ├── 2.payment/
│       ├── STATUS.md           # Global board (single-writer)
│       ├── RUN_STATE.md        # Runtime state (single-writer; resume point)
│       ├── security/           # Security reports per feature
│       └── LESSONS.md          # Lessons learned
├── .claude/
│   ├── CLAUDE.md               # Project context
│   └── rules/                  # Coding standards
└── src/                        # Your code
```

### Review Process

Every task goes through two mandatory review stages:

1. **Spec Compliance Review**: Verifies implementation matches requirements exactly
2. **Codex Quality Review**: Checks code quality, security (OWASP Top 10), and best practices

Failed reviews trigger automatic fixes before proceeding.

### Checkpoint & Recovery (`RUN_STATE.md`)

Forge tracks a per-task lifecycle (`IMPLEMENTING → VERIFYING → REVIEWING → QA → DONE`) in `docs/specs/RUN_STATE.md`. Combined with `tasks.md` checkboxes and a recorded Git/spec-fingerprint baseline, this lets a re-run of `/forge:ai` **resume mid-task** (e.g. restart at the review stage instead of redoing the whole task) and verify the working tree still matches before continuing — recovery never relies on chat history.

`RUN_STATE.md`, `tasks.md`, `requirements.md`, and `LESSONS.md` follow a **single-writer** rule: only the controller writes them. Subagents return results and never touch state files, so parallel work can't corrupt the resume point.

## Configuration

### Project Context (`.claude/CLAUDE.md`)

Define your tech stack, architecture, and conventions:

```markdown
# Project: My App

## Tech Stack
- Frontend: React + TypeScript
- Backend: Node.js + Express
- Database: PostgreSQL

## Architecture
- Monorepo with pnpm workspaces
- REST API with OpenAPI specs
```

### Coding Rules (`.claude/rules/`)

Add project-specific rules:
- `security.md` - Security requirements
- `testing.md` - Test coverage standards
- `style.md` - Code style guidelines

## Examples

See `examples/` directory for sample projects:
- `examples/simple-webapp/` - Basic web application
- `examples/api-service/` - REST API service
- `examples/monorepo/` - Multi-package monorepo

## Advanced Usage

### Change Management

When requirements change:

```bash
/forge:prd --change 1.user-auth "Add OAuth2 support"
```

Forge will:
- Update `requirements.md` with version tracking
- Modify affected sections in `design.md`
- Mark changed/dropped/new tasks in `tasks.md`
- Preserve completed tasks

### Parallel Execution

Independent tasks are dispatched to parallel subagents — but only when each runs in an isolated `git worktree` so they can't clobber each other's working tree or muddy diff attribution. Without worktree isolation, Forge marks them as parallel candidates and falls back to serial execution.

### Context Management

- Subagents provide natural context isolation between tasks
- Controller executes `/compact` at 80% context usage
- `/clear` between features to reset context

## Troubleshooting

### "docs/prd/ not found"
Place your PRD documents in `{PROJECT_DIR}/docs/prd/` before running `/forge:prd`.

### "No code repository detected"
Ensure your project has `package.json`, `Cargo.toml`, `go.mod`, or `pyproject.toml`.

### Review failures
Check the review output for specific issues. Forge will automatically attempt fixes.

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- Issues: [GitHub Issues](https://github.com/jaredchao/forge/issues)
- Discussions: [GitHub Discussions](https://github.com/jaredchao/forge/discussions)

## Roadmap

- [ ] Support for more specialized skills (mobile, DevOps, ML)
- [ ] Integration with project management tools (Jira, Linear)
- [ ] Visual progress dashboard
- [ ] Multi-language PRD support
- [ ] Automated E2E test generation

---

Built with [Claude Code](https://claude.ai/code) | Powered by Claude 4.6
