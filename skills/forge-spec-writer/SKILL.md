---
name: forge-spec-writer
description: 将需求文档解析为结构化的 requirements.md、design.md、tasks.md，输出到项目 docs/specs/{N}.{feature-name}/ 目录，格式与 /forge:prd 一致
---

# forge-spec-writer — 需求规格生成器

将原始需求文档转化为可执行的开发规格。产出的目录结构与字段格式与 `/forge:prd` 完全一致，可被 `/forge:ai` 直接消费。

## 输入

调用者提供原始需求文本 `RAW_DOC`，以及项目根目录 `PROJECT_DIR`（默认当前目录）。

## 执行步骤

### 1. 探测项目架构类型

扫描项目根目录，判断架构类型：

- **Monorepo**: 存在 `pnpm-workspace.yaml`、`lerna.json`、`nx.json`、`turbo.json`，或根 `package.json` 含 `workspaces`，或存在 `packages/`、`apps/`、`libs/` 含独立 `package.json`
- **前后端分离**: 存在 `frontend/` + `backend/`（或 `client/` + `server/`、`web/` + `api/`），或多目录含不同语言的包管理文件
- **Web3/智能合约**（可叠加）: 存在 `hardhat.config.ts/js`、`foundry.toml`、`truffle-config.js`、`anchor.toml`，或 `contracts/`、`programs/` 目录含 `.sol`、`.rs`、`.vy` 文件，或依赖含 `hardhat`、`ethers`、`@openzeppelin/contracts`、`viem`、`wagmi`
- **单体应用**: 以上都不命中（默认）

记录为 `ARCH_TYPE`，支持组合（如 `monorepo+web3`、`separated+web3`、`web3`），并收集各模块/包/端的名称和路径。Web3 项目额外收集：合约框架、合约文件路径、链/网络配置、前端 Web3 集成库。

同时确定 `PROJECT_NAME`（项目名，kebab-case）。

### 2. 读取项目上下文

- 读取 `.claude/CLAUDE.md` 了解项目技术栈
- 读取 `.claude/rules/` 下所有规则文件，了解编码规范
- 根据 `ARCH_TYPE` 扫描对应目录结构，了解现有模块划分
- 检查 `{PROJECT_DIR}/docs/specs/` 目录下是否有已有的 feature specs（编号目录）

### 3. 分析需求

从 `RAW_DOC` 中提取：
- 功能目标（用户要做什么）
- 用户故事（作为 X，我想要 Y，以便 Z）
- 验收标准（怎样算完成）
- 约束条件（性能、安全、兼容性）
- 依赖（需要哪些外部服务或库）

**遇到以下情况暂停并向调用者澄清，不要自行臆测：** 功能歧义、多种技术路线需取舍、缺少关键上下文。

### 4. 推断 feature 名称

根据需求内容生成一个简洁的 kebab-case 英文名称，记为 `{feature-name}`，如 `user-auth`、`payment-checkout`。
此名称将在 Step 5 与序号拼接为 `{N}.{feature-name}/` 目录名，**故不要包含数字前缀或斜杠**。

### 5. 确定编号并创建 specs 目录

检查 `{PROJECT_DIR}/docs/specs/` 下已有的编号目录（如 `1.xxx/`、`2.xxx/`），取最大编号 +1 记为 `{N}`；若无任何编号目录，则 `{N} = 1`。

```
{PROJECT_DIR}/docs/specs/{N}.{feature-name}/
├── requirements.md
├── design.md
└── tasks.md
```

> **粒度控制**：单个 feature 的 tasks.md 控制在 **10-15 个任务以内**。如果需求过大，应拆成多个独立的编号 feature 目录（如 `2.user-auth-login`、`3.user-auth-register`），每个 feature 有自己的三件套，避免 `/forge:ai` 执行时上下文过大。

### 6. 生成 requirements.md

```markdown
# {Feature 名称} — 需求规格

## 概述

{一句话描述}

## 项目信息

- 项目名: {PROJECT_NAME}
- 架构类型: {ARCH_TYPE}

## 需求版本

| 日期         | 版本 | 说明     |
| ------------ | ---- | -------- |
| {YYYY-MM-DD} | v1   | 初始需求 |

## 用户故事

- 作为 {角色}，我想要 {功能}，以便 {价值}

## 功能需求

1. [F-001] {需求描述}
2. [F-002] {需求描述}

## 非功能需求

- 性能: {要求}
- 安全: {要求}
- 兼容性: {要求}

## 验收标准

- [ ] [AC-001] {标准描述}

## 依赖

- {外部服务/库}

## 开放问题

- {待确认事项}
```

### 7. 生成 design.md

读取 `.claude/rules/` 确保设计方案符合项目规范。按功能模块设计，每个模块说明涉及哪些层（前端、后端、数据库、合约等），具体分层根据项目实际架构决定。

```markdown
# {Feature 名称} — 技术设计

## 设计版本

| 日期         | 版本 | 说明     |
| ------------ | ---- | -------- |
| {YYYY-MM-DD} | v1   | 初始设计 |

## 项目架构

- 架构类型: {ARCH_TYPE}
- 涉及层: {根据项目实际情况列出}

## 功能模块设计

### 模块 1: {模块名}

{技术方案，遵循 .claude/rules/ 中的规范}

**涉及层及关键设计:**

{根据项目实际分层描述，如数据模型、API 接口、组件设计、合约接口等}

### 模块 2: {模块名}

...

## 接口契约

{API、RPC 等 — 根据项目类型决定}

## 数据模型

{数据表/模型/链上存储 — 根据项目类型决定}

## 安全考虑

{基于 .claude/rules/security.md 和项目特有的安全规范}

## 技术决策

| 决策 | 选项 | 理由 |
| ---- | ---- | ---- |
```

### 8. 生成 tasks.md

**按功能拆任务。** `/forge:ai` 执行时根据 design.md 自动判断每个任务涉及哪些层。任务排序遵循 `ARCH_TYPE` 对应的依赖顺序：

- **Monorepo** → 自底向上：shared/types → lib/db/api → app/web → 集成测试
- **前后端分离** → 契约先行：API 契约 → 后端实现 → 前端实现(可 mock) → 联调 → E2E
- **Web3** → 合约先行：合约接口 → 合约实现 → 合约测试+安全审查 → ABI 生成 → 前端 Web3 集成 → 部署测试网 → E2E
- **单体应用** → 按功能模块：基础设施 → 核心功能 → 测试与完善
- 支持叠加（如 `monorepo+web3`）：先按 Web3 顺序处理合约，再按基础架构处理其他模块

```markdown
# {Feature 名称} — 任务清单

## 任务版本

| 日期         | 版本 | 说明     |
| ------------ | ---- | -------- |
| {YYYY-MM-DD} | v1   | 初始任务 |

## 项目信息

- 项目名: {PROJECT_NAME}
- 架构类型: {ARCH_TYPE}
- specs 路径: {PROJECT_DIR}/docs/specs/{N}.{feature-name}/

## 任务列表

### 功能 1: {功能名}

- [ ] T-001: {任务描述} ~{预估时间}
- [ ] T-002: {任务描述} ~{预估时间}

### 功能 2: {功能名}

- [ ] T-003: {任务描述} ~{预估时间}

### 集成与测试

- [ ] T-010: 联调测试 ~{预估时间}
- [ ] T-011: E2E 测试 ~{预估时间}

## 依赖关系

- T-002 依赖 T-001

## 风险点

- {可能遇到的问题及应对}
```

**任务拆解原则：**

- 按功能拆，AI 执行时读 design.md 自动识别涉及哪些层
- 每个任务原子性，可独立完成和验证
- 按依赖关系排序（被依赖的先做）
- 预估完成时间（5min / 15min / 30min / 1h）
- 单个 tasks.md 控制在 10-15 个任务以内

## 输出

完成后报告：
- Feature 名称与编号 `{N}.{feature-name}`
- Specs 路径：`{PROJECT_DIR}/docs/specs/{N}.{feature-name}/`
- 总任务数和预估总时间
- 任何 Step 3 中记录的开放问题
