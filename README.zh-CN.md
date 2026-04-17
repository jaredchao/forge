# Forge - PRD 驱动的自动化开发系统

一个 Claude Code 插件，通过 AI 驱动的规格生成、自动化任务执行和多阶段质量审查，将产品需求文档（PRD）转化为生产就绪的代码。

## 特性

- **PRD 转规格**：从需求文档自动生成技术规格说明
- **AI 驱动开发**：使用专业 AI 代理执行开发任务
- **多阶段审查**：规格合规性检查 + 代码质量审查（Codex 集成）
- **变更管理**：支持需求变更并进行版本跟踪
- **经验总结**：自动记录架构决策和踩坑经验
- **单仓库模式**：统一的文档和代码结构

## 安装

### 前置要求

- [Claude Code](https://claude.ai/code) CLI 或桌面应用
- 项目的 Git 仓库

### 安装插件

```bash
# 克隆此仓库
git clone https://github.com/jaredchao/forge.git ~/.claude/plugins/forge

# 或通过 Claude Code 安装（发布后）
claude plugin install forge
```

## 快速开始

### 1. 初始化项目结构

```bash
cd your-project
/forge:init
```

这将创建：
```
your-project/
├── docs/
│   ├── prd/          # 在此放置 PRD 文档
│   └── specs/        # 生成的规格（自动创建）
└── .claude/
    ├── CLAUDE.md     # 项目上下文
    └── rules/        # 编码规范
```

### 2. 从 PRD 生成规格

将需求文档放入 `docs/prd/`，然后：

```bash
/forge:prd ~/path/to/your-project
```

Forge 将：
- 读取 `docs/prd/` 中的 PRD 文档
- 分析项目架构和技术栈
- 在 `docs/specs/{N}.{feature-name}/` 中生成 `requirements.md`、`design.md` 和 `tasks.md`

### 3. 执行自动化开发

```bash
/forge:ai ~/path/to/your-project
```

Forge 将：
- 使用专业代理按顺序执行任务
- 每个任务完成后进行规格合规性审查
- 运行 Codex 代码质量审查
- 标记已完成任务并记录经验教训
- 持续执行直到所有功能实现完成

## 工作流程

```
PRD 文档
    ↓
[/forge:prd] → 生成规格
    ↓
requirements.md + design.md + tasks.md
    ↓
[/forge:ai] → 自动化开发
    ↓
对每个任务：
  1. 匹配专业技能（前端/后端/QA）
  2. 派发实现者子代理
  3. 规格合规性审查
  4. Codex 质量审查
  5. 标记完成 + 记录经验
    ↓
生产就绪代码
```

## 命令

### `/forge:prd`

从 PRD 文档生成开发规格。

**新功能：**
```bash
/forge:prd ~/code/my-app
```

**变更请求：**
```bash
/forge:prd --change 1.user-auth "添加微信登录支持"
/forge:prd --change 2 "更新验证逻辑"
```

### `/forge:ai`

执行自动化开发工作流。

```bash
/forge:ai ~/code/my-app
```

### `/forge:init`

初始化 Forge 项目结构（创建 `docs/` 和 `.claude/` 目录）。

```bash
cd your-project
/forge:init
```

## 专业技能

Forge 包含针对不同开发任务的专业代理：

- **forge-implementer**：通用实现
- **forge-frontend-engineer**：React/Vue/前端开发
- **forge-qa-engineer**：测试和质量保证
- **forge-doc-syncer**：文档同步

## 架构

### 目录结构

```
your-project/
├── docs/
│   ├── prd/                    # 输入：需求文档
│   │   └── feature-spec.md
│   └── specs/                  # 输出：生成的规格
│       ├── 1.user-auth/
│       │   ├── requirements.md # 功能需求
│       │   ├── design.md       # 技术设计
│       │   └── tasks.md        # 任务分解
│       ├── 2.payment/
│       └── LESSONS.md          # 经验教训
├── .claude/
│   ├── CLAUDE.md               # 项目上下文
│   └── rules/                  # 编码规范
└── src/                        # 你的代码
```

### 审查流程

每个任务都要经过两个强制审查阶段：

1. **规格合规性审查**：验证实现是否完全符合需求
2. **Codex 质量审查**：检查代码质量、安全性（OWASP Top 10）和最佳实践

审查失败会触发自动修复后再继续。

## 配置

### 项目上下文（`.claude/CLAUDE.md`）

定义技术栈、架构和约定：

```markdown
# 项目：我的应用

## 技术栈
- 前端：React + TypeScript
- 后端：Node.js + Express
- 数据库：PostgreSQL

## 架构
- 使用 pnpm workspaces 的 Monorepo
- 带 OpenAPI 规范的 REST API
```

### 编码规则（`.claude/rules/`）

添加项目特定规则：
- `security.md` - 安全要求
- `testing.md` - 测试覆盖率标准
- `style.md` - 代码风格指南

## 示例

查看 `examples/` 目录中的示例项目：
- `examples/simple-webapp/` - 基础 Web 应用
- `examples/api-service/` - REST API 服务
- `examples/monorepo/` - 多包 Monorepo

## 高级用法

### 变更管理

当需求变更时：

```bash
/forge:prd --change 1.user-auth "添加 OAuth2 支持"
```

Forge 将：
- 更新 `requirements.md` 并进行版本跟踪
- 修改 `design.md` 中受影响的部分
- 在 `tasks.md` 中标记变更/删除/新增的任务
- 保留已完成的任务

### 并行执行

无依赖关系的任务会自动并行执行。

### 上下文管理

- 子代理在任务间提供天然的上下文隔离
- 控制器在上下文使用达到 80% 时执行 `/compact`
- 功能间执行 `/clear` 以重置上下文

## 故障排除

### "docs/prd/ not found"
在运行 `/forge:prd` 之前，请将 PRD 文档放入 `{PROJECT_DIR}/docs/prd/`。

### "No code repository detected"
确保项目中有 `package.json`、`Cargo.toml`、`go.mod` 或 `pyproject.toml`。

### 审查失败
查看审查输出以了解具体问题。Forge 会自动尝试修复。

## 贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解指南。

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)

## 支持

- 问题反馈：[GitHub Issues](https://github.com/jaredchao/forge/issues)
- 讨论交流：[GitHub Discussions](https://github.com/jaredchao/forge/discussions)

## 路线图

- [ ] 支持更多专业技能（移动端、DevOps、ML）
- [ ] 集成项目管理工具（Jira、Linear）
- [ ] 可视化进度仪表板
- [ ] 多语言 PRD 支持
- [ ] 自动化 E2E 测试生成

---

使用 [Claude Code](https://claude.ai/code) 构建 | 由 Claude 4.6 驱动
