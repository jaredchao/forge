# /forge:ai — 自动开发

> **这是一个 command，不是 skill。** 注入即指令——直接从下面的流程开始执行，**不要去查找或 invoke 任何名为 `forge-ai` / `forge:ai` 的 skill（不存在）**。各 `forge-*` skill 是流程中途派发 subagent 时才用的，不是本命令的入口。
> **内部引擎**——日常请用入口 `/forge:run`（它按本文件的 N1–N8 流程执行）。`/forge:ai` 作为别名/高级入口保留。

`$ARGUMENTS` — 项目仓库路径（记为 `PROJECT_DIR`）。单仓库模式：docs 与代码在同一仓库内。

**PROJECT_DIR 解析：** 取 `$ARGUMENTS` 中的路径参数；**若未提供路径（裸跑 `/forge:ai`，或只带 `--feature` / `--stage` 等 flag），PROJECT_DIR 默认取当前工作目录（cwd）**。即 `/forge:ai` 等价于 `/forge:ai .`。

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

按顺序判断：

1. `$ARGUMENTS` 含 `--stage` → 进入 **Stage 定点重入模式**（跳到「Stage 定点重入模式」章节），可与 `--feature` 组合
2. 否则以 `--feature` 开头 → 进入 Feature-scoped 模式
3. 否则 → 进入全量模式（默认行为）

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
┌─► [N2: 进入 Feature] ── 🧠 Memory 读端检索 → 🧭 Router 粗判 → 执行计划
│     │
│     ▼
│   ┌─► [N3: 执行 Task] ── 🧭 Router 细判 → inline/single/serial/swarm 派发
│   │     │
│   │     ▼
│   │   [N4: Review] ── 分级审查(Fast/Std/Full) → 🛡️ PII 出站门 → Codex(冲突仲裁)
│   │     │
│   │     ▼
│   │   [N5-A: 标 tasks.md] ── 当前 task 标 [x] → 🧠 Memory 写端
│   │     │
│   │     ▼
│   │   [N6: QA 与安全评估] ── 触发 forge-qa-engineer / forge-security-engineer
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

**执行策略：** 无依赖且属于不同代码项目的 task → 并行派发 Subagent；有依赖或修改同一模块 → 串行。**真并行的前置条件见 N2（必须 git worktree 隔离，否则降级串行）。**

---

## 状态文件总览（单写入者，仅 Controller 可写）

`/forge:ai` 维护三个层次的状态文件，构成断点恢复与全局观察的唯一事实源（不依赖聊天历史）：

| 文件 | 粒度 | 看什么 |
| ---- | ---- | ---- |
| `docs/specs/STATUS.md` | 全局 | 整体阶段、各 feature 进度、物料清单、当前活动任务 |
| `docs/specs/{N}.{feature}/tasks.md` | 任务 | 每个 task 的完成与变更生命周期（`[ ]/[x]/[CHANGED]/[DROPPED]`） |
| `docs/specs/RUN_STATE.md` | 现场 | 当前活动任务卡在哪个 stage + 恢复基线 |

外加 `requirements.md`（AC 状态）、`docs/specs/security/{N}.{feature}.md`（安全专项报告）、`docs/specs/memory/`（结构化记忆 + INDEX，自学习闭环的存储）。以上文件全部遵守**单写入者**纪律。

### STATUS.md 结构

```markdown
# STATUS — 项目全局看板（单写入者：仅 Controller 可写）

## 阶段
- phase: PLANNING | READY_TO_RUN | IN_PROGRESS | READY_TO_RELEASE
- updated: {ISO 时间}

## Feature 进度
| Feature | 任务 done/total | 状态 |
| ------- | --------------- | ---- |
| 1.user-auth | 5/5 | done |
| 2.payment   | 2/7 | doing |

## 当前活动
- 见 RUN_STATE.md（feature / task / stage）

## 物料清单
- 各 feature 的 requirements/design/tasks 是否齐备
```

## 运行态文件 RUN_STATE.md 与单写入者

为支持「中段恢复」和「跨会话不依赖聊天历史」，`/forge:ai` 维护一份运行态现场文件 `{PROJECT_DIR}/docs/specs/RUN_STATE.md`。它与 `tasks.md`（任务生命周期）、`requirements.md`（AC）共同构成断点恢复的唯一事实源。

### 单写入者纪律（硬约束）

**只有主流程（Controller，含 N3–N6 状态写入与 N5 落盘）可以写** `RUN_STATE.md`、`tasks.md`、`requirements.md`、`LESSONS.md`。**所有 subagent（implementer / 各工种 / reviewer / QA）一律禁止写这些文件**——它们只把结论通过最终回报返回，由 Controller 统一落盘。这样并行 subagent 不会互相踩状态，恢复时状态也始终自洽。

### 阶段生命周期（stage）

每个 task 在 RUN_STATE 中只有一个活动 stage，节点按下表推进：

| 节点 | 写入 stage | 含义 |
| ---- | ---------- | ---- |
| N3 派发前 | `IMPLEMENTING` | 已派发实现 subagent |
| N4 阶段1 | `VERIFYING` | Spec 合规审查中 |
| N4 阶段2 | `REVIEWING` | Codex 质量审查中 |
| N6 触发 | `QA` | QA 验证中 |
| N5 完成 | `DONE` → 清空为 `IDLE` | 已打 `[x]`，无活动任务 |
| 任意节点阻塞 | `BLOCKED` | 附 reason + 精确恢复指令 |

### RUN_STATE.md 结构

```markdown
# RUN_STATE — 运行态现场（单写入者：仅 Controller 可写）

## 恢复基线（N1 记录，N2 恢复时校验）
- git_commit: {HEAD 短哈希}
- git_worktree: clean | dirty

## 活动任务
- feature: {N}.{feature-name}
- task: {T-编号}
- stage: IMPLEMENTING | VERIFYING | REVIEWING | QA | BLOCKED | DONE | IDLE
- route: inline | single | serial | swarm    # N3 Router 判定的执行路径
- updated: {ISO 时间}

## 阻塞（stage=BLOCKED 时填，否则留空）
- reason: {原因}
- recovery: {精确恢复指令}
```

---

## 自学习闭环（Learning Loop）+ Router + 出站门

三件贯穿 N1–N8 的能力，细则在对应节点，这里是总览：

### 🧠 Learning Loop（Memory 读写闭环）
结构化历史经验存 `docs/specs/memory/`（`INDEX.md` + 每条一文件，带 tags/type frontmatter）。
- **读端（N2）**：进 feature 时按关键词检索 INDEX，注入 top-K（≤5）命中经验。
- **写端（N5）**：完成后把踩坑/决策/可复用封装写回 `memory/` 并更新 INDEX。
- 闭环：这次写的，下个 feature 在 N2 读到。命中的高危经验**抬高 Router 难度档**。
- 单写入者 + PII 出站门同样管 memory（绝不写入密钥/客户数据）。`LESSONS.md` 退为人读摘要。

### 🧭 Router（执行路由，与门禁档合一）
Controller（Queen）判难度选路径，**始终回 Queen 收口**，subagent 无权自决：
- **N2 粗判**（feature 级）：定整体计划（Inline 为主 / 串行 / 并行）。
- **N3 细判**（task 级）：一次出「执行路径 + 工种 + 门禁档」，写入 RUN_STATE `route`。
  - 路径：`inline`（主 Claude 直接做，省冷启动，仅微小低风险）/ `single` / `serial` / `swarm`（独立 worktree 并行 ≤3–4）。
  - 门禁档 Fast/Standard/Full 由此判定，N4/N6 按档执行。
- 红线：高风险禁 inline、禁降级。

### 🛡️ PII 出站门（egress）
在 N4 调 Codex、以及任何外发（外部 API / Telegram / Memory 写入）前**强制脱敏**——密钥/PII/内网址替换为占位，无法脱敏则暂停。本地 subagent 互传不拦。

---

## Feature-scoped 模式

当输入 `/forge:ai --feature {N}.{feature-name} {PROJECT_DIR}` 时执行。

### 参数解析

- `--feature` 后的第一个参数为 feature 标识，格式为 `{N}.{feature-name}`（如 `1.user-auth`），与 `docs/specs/` 下的目录名严格匹配。
- 最后一个参数为 `PROJECT_DIR`（项目仓库路径）；**省略则取 cwd**（如 `/forge:ai --feature 1.user-auth` 等价于在项目目录内对该 feature 执行）。
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

---

## Stage 定点重入模式

当输入含 `--stage` 时执行。用于**只重跑某个 task 的某一阶段**——典型场景：上次断在审查/QA，或人工修了代码想只重审，不想从头跑整个 task。

```bash
/forge:ai --stage {implement|verify|review|qa} [--feature {N}.{feature-name}] {PROJECT_DIR}
```

### 参数解析

- `--stage` 后取阶段名，映射到节点：

  | --stage | 入口节点 | 对应 RUN_STATE stage |
  | ------- | -------- | -------------------- |
  | `implement` | N3 重新派发实现 | IMPLEMENTING |
  | `verify` | N4 阶段1（Spec 合规） | VERIFYING |
  | `review` | N4 阶段2（Codex） | REVIEWING |
  | `qa` | N6 重新触发 QA / 安全专项 | QA |

- `--feature` 可选；省略时默认作用于 `RUN_STATE.md` 当前活动任务所属的 feature/task。
- 最后一个参数为 `PROJECT_DIR`；**省略则取 cwd**（如 `/forge:ai --stage review` 在项目目录内裸跑即可）。

### 执行规则

1. **N1 初始化**：照常加载上下文、RUN_STATE 与恢复基线。
2. **现场校验**（同 N2 恢复校验）：先校验 Git 现场（commit 一致 + worktree clean）；冲突则置 BLOCKED 并升级，不擅自重入。
3. **定位目标 task**：
   - 有 `--feature` → 取该 feature 中 RUN_STATE 的活动 task；无活动则取第一个未完成 task。
   - 无 `--feature` → 取 RUN_STATE 全局活动 task。
   - 找不到合法目标 → exit 非零并诊断。
4. **跳到入口节点**执行该阶段；阶段通过后**照常沿 N4→N5→N6→N7 流程继续往后跑**（重入只决定起点，不改变后续质量门）。
5. 写入对应 stage，落盘规则与全量模式一致（单写入者）。

### 兼容入口

`/forge:work`、`/forge:verify`、`/forge:review` 等便捷别名（若提供）只是提示对应的 `/forge:ai --stage` 命令，本身不直接执行或写状态——执行与落盘统一收口到 `/forge:ai`。

### 示例用法

```bash
# 只重跑当前活动任务的 Codex 审查阶段
/forge:ai --stage review ~/code/my-app

# 指定 feature，重跑其活动任务的 QA + 安全专项
/forge:ai --stage qa --feature 1.user-auth ~/code/my-app
```
