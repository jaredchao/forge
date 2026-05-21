# N6: QA 评估

AI 动态决策是否触发 `forge-qa-engineer`，不按固定间隔。

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

触发后，Controller 以 subagent 方式派发 `forge-qa-engineer`：

1. 注入上下文：当前 feature 的 prd.md / design.md / tasks.md 路径、触发原因、服务启动命令、健康检查端点、所需环境变量
2. Subagent 严格按 `forge-qa-engineer` 工作流执行：**先服务健康检查 → 再补测试 → 再跑测试 → 再 E2E + 端到端冒烟 → 再 AC 映射核验**
3. 返回 `QA_RESULT: PASS | FAIL | BLOCKED | MANUAL_REQUIRED`

**PASS 的硬条件**（Controller 必须核对，subagent 报告 PASS 但缺任一项即降级为 FAIL）：
- 服务健康检查全绿
- 单测 / 集成测试全绿
- E2E ≥ 1 用例且全绿（0 用例不算 PASS）
- 端到端冒烟 PASS（命中真实后端，非纯 mock）
- 每条 AC 都有明确证据或不可自动化说明

## 结果处理

| 结果 | 后续 |
| ---- | ---- |
| PASS | 提取 QA 报告里的「🔁 AC 回写指令」 → 透传给 N5 完成 AC 回写 → 继续 N7 |
| FAIL | 读取失败详情 → 派发修复 task → 重新触发 QA（最多 3 轮）。AC 不回写。 |
| BLOCKED | **先让 QA subagent 自诊断**（缺 env / 端口冲突 / 依赖缺失 / 启动命令错），尝试修复并重启服务；自诊断 2 轮无果，才升级给用户并附诊断报告。**不允许直接把"启动服务器"踢回用户。** AC 不回写。 |
| MANUAL_REQUIRED | 输出手动测试清单（含每条不可自动化 AC 的原因）；将 PASS 部分的 AC 透传给 N5 回写为 `[x]`，MANUAL_REQUIRED 部分透传给 N5 回写为 `[ ] ⚠️ MANUAL: {原因}`；等待用户对手动 AC 的人工确认 |

## AC 回写透传格式

Controller 从 QA 报告里提取「🔁 AC 回写指令」段，原样转发给 N5（不裁剪、不改写），由 N5 执行 `requirements.md` 的 Edit。Controller 自己**不直接动** requirements.md，避免与 N5 的写入冲突。
