#!/usr/bin/env bash
# dev.sh — 本地开发启动脚本
# 用 --plugin-dir 加载本仓库（当前版本），改动即时生效，无需走 marketplace。
#
# 用法:
#   ./dev.sh                # 在 forge 插件目录下启动 Claude Code 开发会话
#   ./dev.sh /path/to/proj  # 同时 cd 到目标项目目录再启动（便于跑 /forge:ai 等）
#
# 进会话后:
#   /plugin list      确认 forge 来自 --plugin-dir
#   /reload-plugins   改了 agents/commands/plugin.json 后重新加载（改 SKILL.md 文本会自动生效）

set -euo pipefail

# 解析脚本自身所在目录（即插件根），无论从哪里调用都正确
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 前置检查：claude CLI 是否存在
if ! command -v claude >/dev/null 2>&1; then
  echo "❌ 未找到 claude CLI，请先安装 Claude Code。" >&2
  exit 1
fi

# 前置检查：是否是合法插件目录
if [[ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
  echo "❌ $PLUGIN_DIR 不是有效插件目录（缺 .claude-plugin/plugin.json）。" >&2
  exit 1
fi

VERSION="$(grep -m1 '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | sed -E 's/.*"version" *: *"([^"]+)".*/\1/')"
echo "🔨 加载本地 forge 插件 v${VERSION}"
echo "   插件目录: $PLUGIN_DIR"

# 可选：第一个参数作为工作目录（被测项目）
if [[ $# -ge 1 ]]; then
  TARGET_DIR="$1"
  if [[ ! -d "$TARGET_DIR" ]]; then
    echo "❌ 目标目录不存在: $TARGET_DIR" >&2
    exit 1
  fi
  echo "   工作目录: $(cd "$TARGET_DIR" && pwd)"
  cd "$TARGET_DIR"
fi

echo
exec claude --dangerously-skip-permissions --plugin-dir "$PLUGIN_DIR"
