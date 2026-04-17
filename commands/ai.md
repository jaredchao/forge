# /forge:ai — 自动开发

`$ARGUMENTS` — 项目仓库路径（记为 `PROJECT_DIR`）。单仓库模式：docs 与代码在同一仓库内。

```bash
/forge:ai ~/code/my-app
/forge:ai /path/to/project
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
│   │   [N5: 标记完成] ── tasks.md 标 [x]、写 LESSONS.md
│   │     │
│   │     ▼
│   │   [N6: QA 评估] ── 评分决定是否触发 forge-qa-engineer
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
