# Contributing to Forge

Thank you for your interest in contributing to Forge! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, inclusive, and constructive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/jaredchao/forge/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Claude Code version and OS
   - Relevant logs or screenshots

### Suggesting Features

1. Check [Discussions](https://github.com/jaredchao/forge/discussions) for similar ideas
2. Create a new discussion or issue describing:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative approaches considered
   - Example use cases

### Submitting Changes

#### 1. Fork and Clone

```bash
git clone https://github.com/jaredchao/forge.git
cd forge
```

#### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

#### 3. Make Changes

- Follow existing code style and conventions
- Update documentation if needed
- Add examples for new features
- Test your changes thoroughly

#### 4. Commit

Use conventional commit format:

```bash
git commit -m "feat: add support for multi-repo projects"
git commit -m "fix: resolve path resolution issue in N3"
git commit -m "docs: update README with new examples"
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

#### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear description of changes
- Link to related issues
- Screenshots/examples if applicable

## Development Guidelines

### File Structure

```
forge/
├── commands/              # Command definitions
│   ├── prd.md
│   ├── ai.md
│   └── forge-ai-nodes/   # Workflow nodes
├── skills/               # Specialized agents
│   ├── forge-implementer/
│   ├── forge-frontend-engineer/
│   └── forge-qa-engineer/
├── .claude-plugin/       # Plugin metadata
│   └── plugin.json
└── docs/                 # Documentation
```

### Command Files

- Use clear markdown structure
- Include step-by-step instructions
- Document all parameters and options
- Provide examples

### Skills

- Each skill in its own directory
- Include SKILL.md with description and usage
- Provide prompt templates if needed
- Document expected inputs/outputs

### Documentation

- Keep README.md up to date
- Update CHANGELOG.md for all changes
- Add examples for new features
- Use clear, concise language

## Testing

Before submitting:

1. Test your changes with a real project
2. Verify all commands work as expected
3. Check that documentation is accurate
4. Ensure no breaking changes (or document them)

### Manual Testing Checklist

- [ ] `/forge:init` creates correct structure
- [ ] `/forge:prd` generates valid specs
- [ ] `/forge:ai` executes tasks successfully
- [ ] Change management works (`--change` flag)
- [ ] Review stages function properly
- [ ] LESSONS.md is updated correctly

## Plugin Development

### Using `${CLAUDE_PLUGIN_ROOT}`

Always use `${CLAUDE_PLUGIN_ROOT}` for internal file references:

```markdown
Read `${CLAUDE_PLUGIN_ROOT}/skills/forge-implementer/prompt.md`
```

Never use hardcoded paths like `~/.claude/`.

### Command Namespacing

Commands in `commands/` are automatically prefixed with plugin name:
- `commands/prd.md` → `/forge:prd`
- `commands/ai.md` → `/forge:ai`

### Plugin Manifest

Update `.claude-plugin/plugin.json` when adding commands or skills:

```json
{
  "commands": [
    {
      "name": "new-command",
      "description": "Description here"
    }
  ]
}
```

## Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, your PR will be merged
4. Your contribution will be credited in CHANGELOG.md

## Questions?

- Open a [Discussion](https://github.com/jaredchao/forge/discussions)
- Ask in PR comments
- Check existing issues and documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Forge!
