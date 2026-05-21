# N5: 标记完成

**强制，不可跳过。** 遗漏会导致断点恢复时重复执行任务。

本节点要标两类东西：**tasks.md 的任务 checkbox**（每个 task 后都跑）和 **requirements.md 的 AC checkbox**（仅在 N6 QA 返回 PASS / MANUAL_REQUIRED 后跑）。

## 步骤 A：标 tasks.md（每个 task 后必跑）

1. 用 Edit 工具打开 tasks.md，找到当前任务对应的行
2. 将 `- [ ]` 改为 `- [x]`，**仅改 checkbox，不改其他内容**
3. **立即验证**：改完后重新读取 tasks.md，确认该任务确实已标记为 `[x]`

```diff
- - [ ] T-007: 安装依赖 ~5min
+ - [x] T-007: 安装依赖 ~5min
```

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
- `/clear` 之前必须确认 tasks.md 和 requirements.md 两处标记都已写入

## LESSONS.md

如有值得记录的内容追加到 `{PROJECT_DIR}/docs/specs/LESSONS.md`：

- 架构决策及理由、踩坑记录、跨 feature 影响、环境/依赖特殊处理

不记录常规开发、显而易见的事情。格式：`## {日期} — {Feature名} / {Task标题}`

## 输出进度

```text
✅ Feature {F}/{总F} | 任务 {N}/{总数} — {标题}
🔍 AI review: {结果} | 🤖 Codex review: {结果}
📊 Feature {done}/{total} | 总体 {done_f}/{total_f}
🎯 AC 回写: {N} 标 [x] / {N} 标 ⚠️ MANUAL / {N} 保持 [ ]   (无 N6 触发时省略此行)
```
