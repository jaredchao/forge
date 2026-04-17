# Changelog

All notable changes to the Forge plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/jaredchao/forge/releases/tag/v1.0.0
