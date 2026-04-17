# Forge Plugin

PRD-driven automated development system for Claude Code.

## Installation

### Method 1: Clone to Plugins Directory

```bash
git clone https://github.com/jaredchao/forge.git ~/.claude/plugins/forge
```

### Method 2: Symlink (for development)

```bash
cd ~/.claude/plugins
ln -s /path/to/forge forge
```

### Method 3: Claude Code CLI (when published)

```bash
claude plugin install forge
```

## Verification

After installation, verify the plugin is loaded:

```bash
claude plugin list
```

You should see `forge` in the list.

## Available Commands

Once installed, these commands are available in Claude Code:

- `/forge:prd` - Generate specs from PRD
- `/forge:ai` - Execute automated development
- `/forge:init` - Initialize project structure

## Quick Test

```bash
# Create a test project
mkdir test-forge && cd test-forge

# Initialize
/forge:init

# Add a simple PRD
echo "# Feature: Hello World\nBuild a hello world app" > docs/prd/hello.md

# Generate specs
/forge:prd .

# Check generated specs
ls docs/specs/
```

## Troubleshooting

### Plugin not found
- Ensure the plugin is in `~/.claude/plugins/forge/`
- Check that `.claude-plugin/plugin.json` exists
- Restart Claude Code

### Commands not working
- Verify plugin.json syntax is valid
- Check command files exist in `commands/`
- Review Claude Code logs for errors

### Path resolution issues
- Ensure all internal paths use `${CLAUDE_PLUGIN_ROOT}`
- Check that skill files exist in `skills/`

## Development

To modify the plugin:

1. Edit files in your local clone
2. Changes take effect immediately (no restart needed for most changes)
3. Test with `/forge:*` commands
4. Submit PR when ready

## Support

- Main README: [../README.md](../README.md)
- Issues: [GitHub Issues](https://github.com/jaredchao/forge/issues)
- Docs: [../docs/](../docs/)

## Version

Current version: 1.0.0

See [CHANGELOG.md](../CHANGELOG.md) for version history.
