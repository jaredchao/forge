---
name: forge-backend-engineer
description: 后端工程师 Skill，执行后端/API 开发任务，自动适配项目技术栈（Node.js/Go/Python/Rust/Java 等），覆盖接口、服务层、认证授权、数据访问和后端测试
---

# forge-backend-engineer — 后端工程师

执行后端/API 开发任务。自动识别项目技术栈，遵循项目 `.claude/rules/` 中的规范。

## 触发条件

由 `/forge:ai` 自动调用，当 task 涉及后端、API、服务层、认证授权、异步任务、Webhook、集成第三方服务或后端测试时触发。

## 工作流程

### 1. 识别技术栈

读取项目配置自动判断，不做硬编码假设：

- `package.json` → Node.js 框架（Express/Nest/Fastify/Koa/Hono/Next API 等）、ORM、验证库、测试框架
- `go.mod` → Go 框架（Gin/Echo/Fiber/chi 等）、数据库驱动、测试工具
- `pyproject.toml` / `requirements.txt` → Python 框架（FastAPI/Django/Flask 等）、ORM、测试工具
- `Cargo.toml` → Rust 框架（Axum/Actix/Rocket 等）、数据库 crate、测试工具
- `pom.xml` / `build.gradle` → Java/Kotlin 框架（Spring Boot 等）、持久化和测试依赖
- 配置文件 → 环境变量、路由注册、依赖注入、日志、OpenAPI/Swagger、数据库连接

### 2. 读取上下文

- `.claude/rules/backend-api.md`、`.claude/rules/security.md`、`.claude/rules/testing.md`、`.claude/rules/coding-style.md`（如存在）
- design.md 中当前任务相关的接口契约、服务设计、数据流和错误处理约定
- requirements.md 中的功能需求、验收标准、权限和安全要求
- 扫描现有后端目录，了解路由、controller、service、repository、model、middleware 的组织方式
- 检查已有 API 响应格式、错误码、日志、配置读取和测试模式，优先复用现有封装

### 3. 开发

**接口与契约：**

- 基于 design.md 中的接口契约实现，不擅自改变路径、方法、字段名、状态码或响应结构
- 如项目已有 OpenAPI/Swagger/GraphQL schema/protobuf，先更新契约文件，再实现代码
- 输入输出类型跟随项目既有 DTO/schema/model 命名和目录约定
- 对外接口必须包含明确的校验、错误响应和权限边界

**分层与复用：**

- 遵循项目已有分层，不把业务逻辑塞进路由处理函数
- controller/handler 负责协议适配，service/usecase 负责业务规则，repository/dao 负责数据访问
- 能复用现有 middleware、error helper、logger、config、database client 的不重复实现
- 新建公共后端工具时放入项目约定目录，保持单一职责和清晰接口

**校验与错误处理：**

- 使用项目已有验证库或框架能力（Zod/Joi/class-validator/Pydantic/validator 等）
- 区分用户输入错误、认证失败、权限不足、资源不存在、冲突、服务端错误
- 不泄露内部异常、SQL、密钥、第三方响应中的敏感字段
- 错误消息、错误码和 HTTP 状态码遵循项目现有约定

**认证、授权与安全：**

- 认证逻辑遵循项目已有 session/JWT/OAuth/API key/middleware 模式
- 授权检查放在明确边界，避免只依赖前端隐藏入口
- 不硬编码密钥、token、连接串或测试凭证
- 处理注入、越权、重放、CSRF/CORS、限流、文件上传、Webhook 签名等风险（按 task 涉及范围）

**数据访问：**

- 数据库 schema 或 migration 变更优先交给 `forge-database-engineer`；若当前 task 同时包含简单数据访问实现，必须遵循已有 ORM/query builder 模式
- 查询需要考虑分页、排序、索引、事务、一致性和 N+1 问题
- 不绕过 repository/dao 封装直接散落 SQL，除非项目既有风格如此
- 事务边界放在业务一致性需要的位置，并覆盖失败回滚场景

**异步任务与外部集成：**

- Webhook 必须校验签名或来源，具备幂等处理
- 队列/定时任务要有重试、超时、失败日志和可观测性
- 第三方 API 调用要处理超时、限流、错误码和部分失败
- 外部服务 mock/stub 应与项目测试风格一致

### 4. 测试

根据项目现有测试体系补充必要测试：

- handler/controller：请求参数、状态码、响应体、认证授权
- service/usecase：业务规则、边界条件、异常路径
- repository/dao：关键查询、事务、空结果、约束冲突
- contract/integration：API 契约、数据库集成、第三方服务 mock

测试应验证行为，不只验证 mock 被调用。涉及安全边界的 task 必须包含失败路径测试。

### 5. 验证

**第一层：静态 + 单测（必跑）**

```bash
# 根据项目实际命令执行
npm run lint
npm run typecheck
npm run test
go test ./...
pytest
cargo test
mvn test
```

如项目提供构建或 API 契约校验命令（OpenAPI schema 校验、protobuf 生成等），也一并执行。

**第二层：服务真的跑起来（硬门槛，不可跳过、不可用"单测全绿"替代）**

"测试通过" 只证明代码逻辑正确，不证明进程能启动、配置能读到、路由真的挂上、依赖真的能连。报 DONE 之前必须执行：

1. **启动服务进程**：用项目实际启动命令（`npm run dev` / `go run ./cmd/...` / `uvicorn` / `./gradlew bootRun` 等）拉起服务，**确认不在启动阶段崩溃**，捕获并消除启动期 error 日志
2. **健康检查命中**：调用 `/health`、`/ping`、`/readyz` 或项目约定的健康端点，返回 2xx
3. **本次变更的每个 endpoint 至少 1 条 happy path 真实调用**：用 curl / httpie / Postman / 内置 HTTP client（或项目已有的 API E2E 套件、chrome-mcp 后台请求、agent-browser）实打实发请求，记录请求 + 状态码 + 响应体；不允许只跑 supertest mock
4. **鉴权端点至少 1 条失败路径**：401 / 403 真的能返回
5. **依赖外部服务的接口**：至少跑通一次与本地或测试环境真实依赖（数据库、Redis、消息队列、第三方 mock server）的交互

任何一项失败、跳过或环境起不来 → 状态降为 BLOCKED 上报，不允许带着"服务没跑过"的实现继续走 N4 review。

## 常见坑

| 问题 | 处理 |
| ---- | ---- |
| 路由已实现但未注册 | 检查 router/module/app 注册入口 |
| DTO/schema 与运行时校验不一致 | 同步类型定义和验证规则 |
| 只测成功路径 | 补齐鉴权失败、参数错误、资源不存在、冲突等失败路径 |
| 在 handler 中堆业务逻辑 | 下沉到 service/usecase，handler 只做协议适配 |
| 忘记事务或幂等 | 对多写入、Webhook、队列任务明确事务和幂等键 |
| 环境变量缺失 | 更新 `.env.example` 或项目配置说明，不提交真实密钥 |
| 错误响应泄露内部信息 | 使用统一错误包装，记录内部日志但返回安全消息 |
| 数据库变更和代码不同步 | 确认 migration、model、repository、测试 fixture 同步更新 |

## 输出

- 创建/修改的文件列表
- 实现的接口、服务或后端能力摘要
- 测试内容和验证结果
- API 契约、环境变量或数据库变更说明（如有）
- 需要其他工种配合的事项
