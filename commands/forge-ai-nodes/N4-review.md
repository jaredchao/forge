# N4: Review（分级审查）

每个 task 完成后执行。**审查档位由 N3 Router 判定**（Fast/Standard/Full，与执行路径一起给出），本节点据档执行——但「至少一道正确性审查」不可为零，高风险不得降级。

## 审查档位（定义，供 N3 Router 与本节点共用）

风险信号与档位如下；N3 Router 据此判档并连同执行路径（inline/single/serial/swarm）一并给出，N4 按档执行：

**风险信号**
- 高：认证 / 授权 / 会话 / 支付 / 资金 / 合约 / 对外暴露接口 / 敏感数据（PII、密钥）/ DB 迁移
- 中：跨模块集成、共享契约或状态变更（schema、API 类型）、用户可达入口（路由 / UI / CLI）
- 低：模块内部实现、纯文档 / 注释 / 配置、仅类型定义、单文件小改

**档位**（取命中的最高档）

| 档位 | 条件 | N4 审查 | N6（详见 N6 文件） |
| ---- | ---- | ------- | ---- |
| **Fast** | 低风险 且 改 ≤2 文件 且 不跨模块 | 仅 Codex 单段（含 OWASP 顺带；**不**单独派 Spec Reviewer） | 一般不触发 |
| **Standard** | 中风险 / 跨文件 / 跨模块 / 契约变更 | 两段：Spec → Codex | 评分或必触发时跑；E2E 仅当含用户可达入口 |
| **Full** | 任一高风险信号 | 两段：Spec → Codex | 必触发完整 QA + 安全专项 |

> 档位只决定「跑哪些」，不降低「跑了的那道要严」。判档结果写进 N4 起始标记（便于 cc-monitor / 复盘观察）：`🔍 N4 {Fast|Standard|Full} — {判档理由}`。

## 阶段 1：Spec Compliance Review（仅 Standard / Full）

**Fast 档跳过本阶段**（规格偏差由阶段 2 的 Codex 顺带核对）。Standard / Full 执行：

进入本阶段前，Controller 把 RUN_STATE `stage` 置为 `VERIFYING`（中断后 N2 可从此处续跑，不重做实现）。

派发专用 subagent，参照 `${CLAUDE_PLUGIN_ROOT}/skills/forge-implementer/spec-reviewer-prompt.md` 构建 prompt。reviewer 同样遵守单写入者：**只读代码、只回报问题，不改任何 specs/状态文件**。

**目的：** 验证实现与规格严格一致——不多也不少。

传入：
- task 完整需求文本
- implementer 的实现报告

Subagent 必须**读实际代码**而非信任报告，逐条核查：
- 缺失的需求（漏做）
- 多余的实现（多做）
- 需求理解偏差（做错）

结果：
- ✅ Spec compliant → 进入阶段 2
- ❌ Issues: [具体问题 + file:line] → 派发 implementer subagent 修复 → 重新进入阶段 1

## 出站门：PII 脱敏（调外部前强制）

把内容送出本机 / 交第三方之前**强制过一道脱敏**。出站边界 = 调 `codex:rescue`、外部 API、Telegram、任何会被外部读取的写入。**本地 subagent 之间互传不拦**。

出站前扫描并拦截：
- 硬编码密钥 / token / `.env` 内容 / 私钥 / 连接串
- 客户真实数据（邮箱、手机号、身份证、地址等 PII）
- 内网地址 / 凭证 / 内部 URL

命中 → **脱敏后再出站**（占位替换，如 `sk-***`），输出标注 `🛡️ PII 出站拦截：脱敏 {n} 处`。**无法安全脱敏 → 暂停，不出站。**

> 下面阶段 2 传给 Codex 的 diff 必须先过本门；N5 的 Memory 写入、code-reviewer 的 Telegram 外发同样过本门。

## 阶段 2：Codex Review（所有档位都跑）

Fast 档**只跑这一段**，即「至少一道正确性审查」不可为零。进入前 Controller 把 RUN_STATE `stage` 置为 `REVIEWING`，再调用 `codex:rescue`：

- 传入**经 PII 出站门脱敏后**的、本 task 涉及的变更文件 diff（不是整个 working tree）
- 要求审查代码质量、逻辑缺陷、安全问题（OWASP Top 10、注入、硬编码密钥等）
- **Fast 档附加**：因为没有独立 Spec Reviewer，Codex 需额外核对「实现与 task 需求是否一致」（漏做 / 多做 / 做错）
- 合理建议 → 派发 implementer subagent 修复后重新提交 Codex 复审
- 误报 → 记录忽略理由后通过

**额外检查项（Codex 审查时附加要求）：**
- 每个文件是否有单一职责和清晰接口
- 是否遵循 `.claude/rules/` 规范
- 本次变更是否导致文件过大（聚焦新增部分，不追溯历史）

应跑的阶段均通过 → 进入 N5。

## 冲突仲裁（Codex 收窄仲裁）

当**多个 reviewer 结论冲突**、或 **AI 自审 / Spec 审查与 Codex 意见相左**时，以 **Codex 为该次冲突的裁判**——不投票、不取多数，Queen（Controller）按 Codex 结论收口。

> 收窄边界：Codex 只仲裁「**审查意见之间的冲突**」，**不**因此成为所有门的唯一放行权——Spec / QA / 安全各门仍各自独立把关，多道防线不塌。

## 红线

- **「至少一道正确性审查」不可为零**：Fast 至少 Codex 单段；Standard / Full 必须两段。
- **PII 出站门强制**：任何出站（Codex / 外部 API / Telegram）前必过脱敏，无法脱敏即暂停。
- **仲裁只收窄到审查冲突**：不得把 Spec/QA/安全的放行权全收敛给 Codex。
- **高风险 task 禁止降级**：命中任一高风险信号必须走 Full（两段 + N6 完整门），不得判为 Fast / Standard。
- 两段都跑时，阶段 1（Spec）必须先于阶段 2（Codex）。
- 任何**已跑**阶段有未修复问题时，禁止进入 N5。
- 不得以 implementer 自审代替应跑的 review。
