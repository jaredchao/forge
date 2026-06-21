# N5: 标记完成

**强制，不可跳过。** 遗漏会导致断点恢复时重复执行任务。

本节点由 **Controller（唯一状态写入者）** 执行，要标三类东西：**RUN_STATE.md 的 stage**、**tasks.md 的任务 checkbox**（每个 task 后都跑）和 **requirements.md 的 AC checkbox**（仅在 N6 QA 返回 PASS / MANUAL_REQUIRED 后跑）。subagent 不参与任何写入。

## 步骤 A：标 tasks.md（每个 task 后必跑）

1. 先把 RUN_STATE `stage` 置为 `DONE`（表示审查/QA 已全部通过，准备落盘）
2. 用 Edit 工具打开 tasks.md，找到当前任务对应的行
3. 将 `- [ ]` 改为 `- [x]`，**仅改 checkbox，不改其他内容**
4. **立即验证**：改完后重新读取 tasks.md，确认该任务确实已标记为 `[x]`
5. 清场：把 RUN_STATE 活动任务清为 `stage: IDLE`、无 `task`，并刷新「恢复基线」（git_commit / worktree / 指纹），作为下一 task 的可信起点
6. 刷新 `STATUS.md`：更新当前 feature 的 `done/total` 计数与状态（全部完成则该 feature 标 done）；若仍有未完成任务，`phase` 保持 `IN_PROGRESS`

```diff
- - [ ] T-007: 安装依赖 ~5min
+ - [x] T-007: 安装依赖 ~5min
```

> 顺序很关键：先 `DONE` 再打 `[x]` 再清 `IDLE`。任一步后中断，N2 都能据 stage 判断是「补打 [x]」还是「已干净」，不会重复执行整个 task。

## 步骤 B：回写 requirements.md 的 AC（仅在 N6 完成且返回 PASS / MANUAL_REQUIRED 后跑）

### 触发条件

只有从 N6 收到「🔁 AC 回写指令」段时才执行；普通 task 完成（未触发 QA）跳过本步骤。

### 执行规则

按 N6 透传的 AC 回写指令逐条 Edit `docs/specs/{N.feature-name}/requirements.md`：

| 指令分类 | 改法 |
| ---- | ---- |
| **PASS** | `- [ ] [AC-NNN] 描述` → `- [x] [AC-NNN] 描述`（仅改 checkbox） |
| **MANUAL_REQUIRED** | 保持 `- [ ]`，在**行尾追加** ` ⚠️ MANUAL: {原因}`（如已存在则更新原因） |
| **NOT_VERIFIED** | 不动，保持 `- [ ]` |

```diff
# PASS 示例
- - [ ] [AC-001] 用户可以用邮箱密码登录
+ - [x] [AC-001] 用户可以用邮箱密码登录

# MANUAL_REQUIRED 示例
- - [ ] [AC-007] 第三方对账成功
+ - [ ] [AC-007] 第三方对账成功 ⚠️ MANUAL: 需真实银行账户

# NOT_VERIFIED 示例：保持原样不动
  - [ ] [AC-008] 离线模式数据同步
```

### 立即验证

逐条 Edit 完之后**重新读 requirements.md**，对照 N6 指令逐项确认：
- 该标 [x] 的都已 [x]
- 该挂 ⚠️ MANUAL 的都有注释和原因
- 没有任何"本轮未验"的 AC 被误标 [x]

任何一条不一致 → 重新 Edit 直到完全匹配。

### 禁止

- 跳过 N6 自行猜测 AC 状态去回写
- 把"代码里看起来实现了"等同于 AC 通过
- 批量回写后不验证

## 关键约束

- 每完成一个 task **立即** 标 tasks.md，不批量、不延后
- AC 回写在 N6 结束后**立即** 跑（PASS / MANUAL_REQUIRED 时）
- Edit 失败则重试直到成功
- 状态写入是 **Controller 独占**的，subagent 永不写 RUN_STATE/tasks/requirements
- `/clear` 之前必须确认 tasks.md、requirements.md 两处标记与 RUN_STATE 清场（IDLE）都已写入

## Learning Loop — Memory 写端（结构化记忆）

**自学习闭环的「写」端，对应 N2 的「读」端。** 如有值得记录的内容（踩坑、难点、架构决策、可复用封装、环境特殊处理），由 Controller 写入结构化 Memory，**供未来 feature 在 N2 检索注入**。

**位置**：`{PROJECT_DIR}/docs/specs/memory/{kebab-slug}.md`，每条经验一个文件。
**索引**：写完在 `{PROJECT_DIR}/docs/specs/memory/INDEX.md` 追加一行：
`- [{标题}]({slug}.md) — {一句话钩子} | type:{类型} | tags:{tag1,tag2}`（N2 检索先扫这个索引）。

文件格式（frontmatter 让 N2 可按 feature/类型/标签检索）：

```markdown
---
title: {简短标题}
feature: {来源 feature 名}
type: pitfall | decision | reusable | env
tags: [{模块名/技术栈/错误类型，便于检索}]
scope: project
confidence: medium    # 被复用/再次验证后升 high
date: {YYYY-MM-DD}
---
**问题/场景**：…
**解法/结论**：…
**复用方式**：（reusable 类必填——别的 feature 怎么直接拿来用）
```

**写入纪律**：
- **单写入者**：只有 Controller 写 `memory/`；subagent 在回报里说「这条值得记」，由 Controller 决定并落盘。
- **PII 出站门同样管 memory**：写入前过一遍脱敏——**绝不把密钥/客户真实数据写进 memory**（尤其将来若同步到全局层会跨项目流动）。
- **去重**：已存在相近条目（同 tags/title）→ **更新该文件，不新建重复**。
- **记什么 / 不记什么**：记架构决策及理由、踩坑、跨 feature 影响、环境/依赖特殊处理、可复用封装；不记常规开发、显而易见的事。

> 兼容：`LESSONS.md` 仍可作为人读的滚动摘要保留；但**可被检索的经验以 `memory/` 为准**，新经验写 `memory/`。

## 输出进度

```text
✅ Feature {F}/{总F} | 任务 {N}/{总数} — {标题}
🔍 AI review: {结果} | 🤖 Codex review: {结果}
📊 Feature {done}/{total} | 总体 {done_f}/{total_f}
🎯 AC 回写: {N} 标 [x] / {N} 标 ⚠️ MANUAL / {N} 保持 [ ]   (无 N6 触发时省略此行)
```
