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

### 1. Initialize Project Structure

```bash
cd your-project
/forge:init
```

This creates:
```
your-project/
├── docs/
│   ├── prd/          # Place your PRD documents here
│   └── specs/        # Generated specs (auto-created)
└── .claude/
    ├── CLAUDE.md     # Project context
    └── rules/        # Coding standards
```

### 2. Generate Specs from PRD

Place your requirement document in `docs/prd/`, then:

```bash
/forge:prd ~/path/to/your-project
```

Forge will:
- Read PRD documents from `docs/prd/`
- Analyze project architecture and tech stack
- Generate `requirements.md`, `design.md`, and `tasks.md` in `docs/specs/{N}.{feature-name}/`

### 3. Execute Automated Development

```bash
/forge:ai ~/path/to/your-project
```

Forge will:
- Execute tasks sequentially with specialized agents
- Perform spec compliance review after each task
- Run Codex code quality review
- Mark completed tasks and record lessons learned
- Continue until all features are implemented

## Workflow

```
PRD Document
    ↓
[/forge:prd] → Generate Specs
    ↓
requirements.md + design.md + tasks.md
    ↓
[/forge:ai] → Automated Development
    ↓
For each task:
  1. Match specialized skill (frontend/backend/QA)
  2. Dispatch implementer subagent
  3. Spec compliance review
  4. Codex quality review
  5. Mark done + record lessons
    ↓
Production-Ready Code
```

## Commands

### `/forge:prd`

Generate development specifications from PRD documents.

**New Feature:**
```bash
/forge:prd ~/code/my-app
```

**Change Request:**
```bash
/forge:prd --change 1.user-auth "Add WeChat login support"
/forge:prd --change 2 "Update validation logic"
```

### `/forge:ai`

Execute automated development workflow.

```bash
/forge:ai ~/code/my-app
```

### `/forge:init`

Initialize Forge project structure (creates `docs/` and `.claude/` directories).

```bash
cd your-project
/forge:init
```

## Specialized Skills

Forge includes specialized agents for different development tasks:

- **forge-implementer**: General-purpose implementation
- **forge-frontend-engineer**: React/Vue/frontend development
- **forge-backend-engineer**: Backend/API development
- **forge-database-engineer**: Data modeling, migrations, query optimization
- **forge-contract-engineer**: Smart contract development (EVM/Solana/Move)
- **forge-qa-engineer**: Testing and quality assurance
- **forge-doc-syncer**: Documentation synchronization

Auxiliary skills (invoked on demand, not dispatched per task):

- **forge-spec-writer**: Requirement docs → requirements/design/tasks specs
- **forge-code-reviewer**: Two-round code review + security scan (Telegram alert on findings)
- **forge-test-runner**: Auto-generate and run unit/E2E tests + visual regression
- **forge-security**: METATRON-based penetration testing of deployment targets

Each engineering discipline (frontend/backend/database/contract/qa) is also exposed as a **subagent** (`agents/forge-*-engineer`) with its own tool sandbox and `model: sonnet`. N2 dispatches them per-discipline for parallel work with natural context isolation; each subagent loads its same-named skill as the single source of truth.

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

Tasks without dependencies are executed in parallel automatically.

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
