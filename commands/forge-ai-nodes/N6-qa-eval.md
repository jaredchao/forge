# N6: QA 与安全评估

AI 动态决策是否触发 `forge-qa-engineer`（功能质量）与 `forge-security-engineer`（安全专项），不按固定间隔。两者是并列的质量门，安全专项规则见本文末「安全专项」段。

## 分级（跟随 N4 档位）

QA / 安全的深度跟随 N4 判出的档位：

- **Fast**：一般**不触发** QA（纯内部小改）；除非命中下方「必须触发」。
- **Standard**：按下方评分 / 必触发决定；**E2E 仅当本 task 含用户可达入口**才作硬条件。
- **Full**（高风险）：**必触发**完整 QA + 安全专项，E2E 与安全审计都跑满。

下面的评分与必触发，是 Standard / Full 的判定细则。

## 评分（1-5 分，总分 ≥ 8 触发）

| 维度 | 1 分 | 5 分 |
| ---- | ---- | ---- |
| 变更范围 | 单文件小改动 | 跨多模块/多项目 |
| 风险等级 | 纯 UI 文案 | 数据库/支付/认证 |
| 累积变更 | 上次 QA 后 1 个 task | 上次 QA 后 5+ 个 task |
| 功能边界 | 模块内部实现 | 完整用户可感知功能 |

## 必须触发（无需打分）

- 当前 feature 所有 task 完成
- API 接口变更
- 数据库 migration
- 认证/授权/支付逻辑
- **新增或修改用户可达路由 / UI 交互 / CLI 命令**（任何用户可感知的入口）
- **新增或修改服务启动配置 / 依赖注入 / 环境变量**（直接影响"服务能否跑起来"）
- 连续 5 个 task 未触发过 QA

## 跳过

- 纯文档/注释/配置格式
- 仅新增类型定义（未实现）
- 上一个 task 刚触发过 QA 且当前变更极小

## 触发格式

```text
🧪 触发 QA — 原因: {理由}
   累积变更: {N} 个 task | 风险评估: {总分}
```

## 执行方式

触发后，Controller 先把 RUN_STATE `stage` 置为 `QA`（中断后 N2 可从此处续跑，直接重新触发 QA），再以 subagent 方式派发 `forge-qa-engineer`：

1. 注入上下文：当前 feature 的 prd.md / design.md / tasks.md 路径、触发原因、服务启动命令、健康检查端点、所需环境变量
2. Subagent 严格按 `forge-qa-engineer` 工作流执行：**先服务健康检查 → 再补测试 → 再跑测试 → 再 E2E + 端到端冒烟 → 再 AC 映射核验**
3. 返回 `QA_RESULT: PASS | FAIL | BLOCKED | MANUAL_REQUIRED`

**PASS 的硬条件**（Controller 必须核对，subagent 报告 PASS 但缺任一项即降级为 FAIL）：

基础（所有触发 QA 的 task 都要）：
- 服务健康检查全绿
- 单测 / 集成测试全绿
- 端到端冒烟 PASS（命中真实后端，非纯 mock）
- 每条 AC 都有明确证据或不可自动化说明

条件项 —— 仅当本 task 含**用户可达入口**（新增/改 路由 / UI 交互 / CLI / 对外 API）：
- E2E ≥ 1 用例且全绿（0 用例不算 PASS）

> 纯内部逻辑 / 无新可达入口的后端改动：**E2E 不作硬条件**（有则跑、无则不阻塞），单测 + 集成 + 冒烟即可。这样小改动不被 E2E 拖慢，用户能感知的入口仍被 E2E 兜住。

## 结果处理

| 结果 | 后续 |
| ---- | ---- |
| PASS | 提取 QA 报告里的「🔁 AC 回写指令」 → 透传给 N5 完成 AC 回写 → 继续 N7 |
| FAIL | 读取失败详情 → 派发修复 task → 重新触发 QA（最多 3 轮）。AC 不回写。 |
| BLOCKED | **先让 QA subagent 自诊断**（缺 env / 端口冲突 / 依赖缺失 / 启动命令错），尝试修复并重启服务；自诊断 2 轮无果，才升级给用户并附诊断报告。**不允许直接把"启动服务器"踢回用户。** AC 不回写。 |
| MANUAL_REQUIRED | 输出手动测试清单（含每条不可自动化 AC 的原因）；将 PASS 部分的 AC 透传给 N5 回写为 `[x]`，MANUAL_REQUIRED 部分透传给 N5 回写为 `[ ] ⚠️ MANUAL: {原因}`；等待用户对手动 AC 的人工确认 |

## AC 回写透传格式

Controller 从 QA 报告里提取「🔁 AC 回写指令」段，原样转发给 N5（不裁剪、不改写），由 N5 执行 `requirements.md` 的 Edit。Controller 自己**不直接动** requirements.md，避免与 N5 的写入冲突。

---

## 安全专项（forge-security-engineer）

安全是与 QA 并列的一等关卡，不混在 Codex 的顺带检查里。命中下列**高风险**变更时，Controller 额外派发 `forge-security-engineer` subagent：

### 必须触发

- 认证 / 授权 / 会话 / 令牌逻辑
- 支付 / 资金 / 计费
- 智能合约（任何链上资金流向或权限变更）
- 新增或修改**对外暴露的接口**（公网 API、webhook、文件上传、反序列化入口）
- 处理敏感数据（PII、密钥、凭证）的新增路径

可与 QA 并行派发（两者互不依赖）。纯前端文案、内部纯计算、仅类型定义 → 跳过。

### 执行方式

1. 注入上下文：本 feature 范围、**本次变更文件 diff/清单**、代码项目路径
2. subagent 按其工作流执行：`forge-code-reviewer` **代码级审计**（OWASP / 越权 / 密钥 / 注入）
3. 返回 `SECURITY_RESULT: PASS | FINDINGS | BLOCKED` + 结构化报告

> **动态扫描（METATRON）默认关**：常规只做代码级审计（快、无外部依赖）。只有当 prompt **显式提供了已部署目标地址**、且需要上线前渗透时，才追加 `forge-security` 动态扫描——这步慢（nikto 等可能数分钟），不进每个 task 的默认路径。

### 落盘（单写入者：Controller 写）

Controller 把 subagent 回报的报告**原样写入** `docs/specs/security/{N}.{feature-name}.md`（subagent 不自己写）。

### 结果处理

| 结果 | 后续 |
| ---- | ---- |
| PASS | 记录报告路径，继续 N7 |
| FINDINGS | 按严重度派发修复 task（High/Critical 必修）→ 修复后重新派发安全审查（最多 3 轮）。未清零前**禁止进入 N8 完成** |
| BLOCKED | 让 subagent 自诊断（缺扫描环境/目标不可达）；自诊断无果升级用户并附诊断，不擅自跳过 |

> 红线：命中「必须触发」却跳过安全专项，等同跳过质量门，禁止。High/Critical 未修复禁止收尾。
