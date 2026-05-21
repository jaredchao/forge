# /forge:ai — 自动开发

`$ARGUMENTS` — 项目仓库路径（记为 `PROJECT_DIR`）。单仓库模式：docs 与代码在同一仓库内。

支持两种模式：全量执行和指定 Feature 执行。

```bash
# 全量模式 — 执行所有 Feature
/forge:ai ~/code/my-app
/forge:ai /path/to/project

# Feature-scoped 模式 — 仅执行指定 Feature
/forge:ai --feature {N}.{feature-name} {PROJECT_DIR}
/forge:ai --feature 1.user-auth ~/code/my-app
```

## 模式判断

如果 `$ARGUMENTS` 以 `--feature` 开头 → 进入 Feature-scoped 模式（跳到「Feature-scoped 模式」章节）
否则 → 进入全量模式（默认行为）

---

## 全量模式

执行所有 Feature，按顺序走完 N1-N8 完整流程。

```bash
/forge:ai ~/code/my-app
```

## 流程图

按此流程执行，到达每个节点时读取 `${CLAUDE_PLUGIN_ROOT}/commands/forge-ai-nodes/` 下对应的节点文件获取详细规则。

```text
START
  │
  ▼
[N1: 初始化] ── 解析输入、扫描 features、加载上下文
  │
  ▼
┌─► [N2: 进入 Feature] ── 读取 specs、分析依赖、输出执行计划
│     │
│     ▼
│   ┌─► [N3: 执行 Task] ── 匹配 skill → 派发 Implementer Subagent → 处理状态
│   │     │
│   │     ▼
│   │   [N4: Review] ── Spec Compliance → Codex Review（三段式）
│   │     │
│   │     ▼
│   │   [N5-A: 标 tasks.md] ── 当前 task 标 [x]、写 LESSONS.md
│   │     │
│   │     ▼
│   │   [N6: QA 评估] ── 评分决定是否触发 forge-qa-engineer
│   │     │
│   │     ▼
│   │   [N5-B: 回写 AC] ── QA 返回 PASS/MANUAL 时，按 AC 回写指令更新 requirements.md（其他情况跳过）
│   │     │
│   │     ▼
│   │   [N7: 上下文管理] ── 任务间无需 /clear（Subagent 天然隔离）
│   │     │
│   │     ▼
│   │   还有未完成 task? ──YES──┘
│   │     │
│   │    NO
│   │     │
│   │     ▼
│   └── Feature 完成 → /clear
│         │
│         ▼
│       还有下一个 Feature? ──YES──┘
│         │
│        NO
│         │
│         ▼
      [N8: 完成] ── 调用 forge-doc-syncer → 输出总结
        │
        ▼
       END
```

## 全局规则

**暂停：** 业务逻辑歧义、不确定的安全问题、破坏性变更、环境阻塞。
**不暂停：** 纯技术选型 — 选最优解直接执行。

**执行策略：** 无依赖且属于不同代码项目的 task → 并行派发 Subagent；有依赖或修改同一模块 → 串行。

---

## Feature-scoped 模式

当输入 `/forge:ai --feature {N}.{feature-name} {PROJECT_DIR}` 时执行。

### 参数解析

- `--feature` 后的第一个参数为 feature 标识，格式为 `{N}.{feature-name}`（如 `1.user-auth`），与 `docs/specs/` 下的目录名严格匹配。
- 最后一个参数为 `PROJECT_DIR`（项目仓库路径）。
- 在 Dashboard worktree 场景中，`PROJECT_DIR}` 指向 job worktree 根目录，`cwd` 设置为该 worktree 根目录。

### 执行规则

1. **N1 初始化**：与全量模式相同，扫描项目上下文、加载 `.claude/CLAUDE.md` 和规则文件。
2. **N2 进入 Feature**：
   - 仅读取指定 Feature 目录下的 `requirements.md`、`design.md`、`tasks.md`。
   - 不扫描其他 Feature 目录。
   - 如果指定 Feature 不存在（`docs/specs/{N}.{feature-name}/` 目录不存在），**立即 exit 非零**，输出诊断信息，不修改任何文件。
3. **N3 执行 Task**：
   - 仅执行该 Feature `tasks.md` 中**未完成的任务**（`[ ]`）。
   - 已完成的任务（`[x]`）自动跳过。
   - 如果所有任务均已完成，**exit 0** 并输出清晰的 no-op 消息（如 `Feature 1.user-auth 所有任务已完成，无需执行`）。
4. **N4-N7**：与全量模式相同，但范围仅限于当前 Feature。
5. **N8 完成**：
   - 仅总结当前 Feature 的执行结果。
   - 调用 `forge-doc-syncer` 时仅更新该 Feature 相关的文档。
   - 不处理其他 Feature。

### 与全量模式的差异

| 阶段 | 全量模式 | Feature-scoped 模式 |
|------|---------|---------------------|
| N2 | 遍历所有 Feature | 仅进入指定 Feature |
| N3 | 执行所有未完成 Task | 仅执行指定 Feature 的未完成 Task |
| N8 | 汇总所有 Feature | 仅汇总指定 Feature |
| 退出码 0 | 所有 Feature 处理完毕 | 指定 Feature 处理完毕 |

### 示例用法

```bash
# 执行单个 Feature（必须在项目仓库内执行）
/forge:ai --feature 1.user-auth ~/code/my-app

# 在 Dashboard job worktree 中执行
/forge:ai --feature 1.user-auth /path/to/job-worktree
```
