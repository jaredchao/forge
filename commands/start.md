# /forge:start — 把需求变成可执行规格（入口 1/3）

> **这是一个 command，不是 skill。** 注入即指令，直接按下面编排执行，不要去找名为 `forge-start` 的 skill。

`$ARGUMENTS` — 项目路径（记为 `PROJECT_DIR`）；未提供则取当前工作目录（cwd）。可附带变更描述。

这是规格设置的**统一入口**：Controller 自动判断要做哪些内部步骤（初始化 / 新建规格 / 需求变更 / 大需求拆分），用户不必区分 init/prd。

## 自动编排

1. **项目上下文**：若 `{PROJECT_DIR}/.claude/` 不存在 → 先初始化（细则见 `${CLAUDE_PLUGIN_ROOT}/commands/init.md`），生成 `CLAUDE.md` + `rules/`。已存在则跳过。
2. **读需求**：读 `{PROJECT_DIR}/docs/prd/`。为空 → 提示用户先放入需求文档并停止。
3. **新建 vs 变更（自动判断）**：
   - `docs/specs/` 下尚无对应 feature → **新建模式**：按 `${CLAUDE_PLUGIN_ROOT}/commands/prd.md` 的「新建模式」生成 `requirements/design/tasks`。
   - 已有对应 specs 且本次是对其调整（`$ARGUMENTS` 含变更描述，或 prd 内容已更新）→ **变更模式**：按 prd.md 的「变更模式」做版本化更新，**保留已完成任务**。
   - 拿不准是哪种 → 暂停问用户一句再继续。
4. **大需求自动拆分**：若需求明显跨多个模块（单个 `tasks.md` 会超 ~15 个任务）→ 按 prd.md 的拆解原则拆成**多个 feature 目录**（如 `2.user-auth-login`、`3.user-auth-register`），各自生成三件套，保证单个 specs 上下文可控。小需求跳过。

## 开放问题确认

沿用 prd 的 Step 5.5：需求模糊 / 技术分歧大 / 缺关键信息（目标平台、第三方选型、权限支付等）时，**先暂停问清再生成**，不自行假设。

## 输出

```text
✅ 规格已就绪（{新建|变更}）
📂 Feature: {列出 N.name}
📋 任务: {N} 个 · 预估 ~{时间}
➡️ 下一步：/forge:run 开始自动开发 · /forge:status 随时看进度
```
