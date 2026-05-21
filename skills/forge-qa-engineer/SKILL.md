---
name: forge-qa-engineer
description: QA 工程师 Skill，执行服务健康检查、端到端功能验证、E2E 测试、可视化回归、验收标准核验，强制把"功能可用、服务真的跑起来"作为通过门槛
---

# forge-qa-engineer — QA 工程师

在开发任务完成后执行整体质量验证。**核心原则：测试通过 ≠ 功能可用**。绿色的单测只证明代码逻辑没崩，QA 的职责是证明用户拿到的是一个**真的跑起来、真的能用**的系统。

## 触发条件

由 `/forge:ai` 自动调用，当 task 涉及测试或全部开发完成后触发。

## 工作流程

### 1. 识别测试框架与 E2E 手段

自动检测，不做硬编码假设：

- **单元/组件测试**：Vitest / Jest / Mocha / pytest / Go testing / Rust cargo test
- **E2E 手段**（按场景选，不强绑某一种）：
  - **传统 web E2E 框架**：Playwright / Cypress / Selenium / Puppeteer — 适合项目已有 E2E 套件、需要在 CI 里可重复执行
  - **chrome-mcp**（浏览器 MCP 工具）— 适合 QA subagent 单轮直接驱动真实浏览器：导航、点击、读 DOM、抓截图、看控制台，不依赖项目预置 E2E 框架
  - **agent-browser skill** — 适合用 AI agent 模拟用户完成多步、语义化的流程（"登录然后下单，确认订单出现在列表里"），尤其当流程包含模糊判断、跨标签页、需要看 UI 语义而非选择器时
  - **API E2E**：curl / httpie / supertest / pytest+requests / k6 — 适合无前端项目（纯 API、CLI、后端服务），从外部以真实 HTTP/RPC 调用穿透到数据落库
  - **CLI E2E**：在干净 shell / 容器里跑真实命令，断言 stdout / stderr / 退出码 / 副作用
- **覆盖率工具**：c8 / istanbul / coverage.py / go cover
- 如项目未配置任何测试框架，根据技术栈推荐并安装
- 如本 feature 有用户可达路径但项目**完全没有任何 E2E 手段** → 必须选一种并执行；优先级：项目已有 E2E 框架 > chrome-mcp / agent-browser（无需安装即可用）> 新装传统 E2E 框架。**禁止以"没装 Playwright"为理由跳过 E2E。**

### 1.1 按 feature 形态选 E2E 手段（指引）

| Feature 形态 | 推荐 E2E 手段 | 说明 |
| ---- | ---- | ---- |
| 有传统 web 前端，项目已配 Playwright/Cypress | 沿用项目框架 | 沉淀成可重复用例 |
| 有 web 前端，项目无 E2E 框架，本轮快速验证 | chrome-mcp | QA subagent 直接驱动浏览器，1 轮跑完留截图证据 |
| 有 web 前端，流程语义复杂（多步、判断、跨页面） | agent-browser | 让 agent 按用户故事走，断言结果而不是选择器 |
| 纯 API / 后端服务 / 无 UI | API E2E（curl / httpie / 脚本） | 从外部真实调用，覆盖鉴权 + happy path + 失败路径 |
| CLI / 库 / 脚本 | CLI E2E（干净环境执行 + 断言副作用） | 不靠单测 mock，跑真实命令看真实输出 |
| 后台任务 / 消息消费 | 投递真实消息 + 观察消费副作用 | 用项目内 admin 工具或脚本投递 |

任一手段都算合规 E2E，前提是：**从用户/调用方入口出发、穿过本次涉及的所有层、能观察到真实副作用**。

### 2. 读取上下文

- requirements.md 中的验收标准（**逐条列出**，准备做 AC ↔ 用例映射）
- design.md 了解功能模块和接口契约、依赖的外部服务
- `.claude/rules/testing.md`（如存在）
- 扫描现有测试文件了解测试模式和覆盖情况
- 项目启动命令、健康检查端点、所需环境变量

### 3. 服务健康检查（硬门槛，最先执行）

**在跑任何测试之前**，先确认服务真的能起来。任何一项失败就把整轮 QA 标 BLOCKED，并尝试自诊断（缺 env、缺依赖、端口冲突等）；自诊断仍解决不了才升级给用户。

| 服务类型 | 必跑项 |
| ---- | ---- |
| 后端 / API | 启动进程不崩；命中 `/health` 等健康端点返回 2xx；启动期日志无 ERROR |
| 前端 | `npm run build` 0 error；启动 dev server；首页可访问且控制台无 error |
| 数据库 | 连接通；本 feature 涉及的 migration `up` 在干净库上成功执行 |
| 异步 / 队列 | worker 进程能启动并消费一条测试消息 |
| 第三方依赖 | 必备 mock server / 沙盒账号可用，至少 ping 通 |

输出健康检查报告片段，作为后续测试的前置证据。

### 4. 补全测试

对开发阶段未写测试的代码补充。**E2E 是强制项**，不允许"项目里没有 E2E 用例所以本轮跳过"。

- **组件**：渲染测试、交互测试、Props 边界
- **API/服务层**：正常流、异常流、边界值、鉴权失败路径
- **工具函数**：输入输出覆盖
- **数据库层**：migration 可执行（`up` 和 `down`）、查询结果正确
- **E2E（强制，手段不限——按第 1 步选定的方式执行）**：
  - 本 feature 至少 1 条端到端 happy path，从用户入口（浏览器点击 / API 调用 / CLI 命令）穿透到数据落库再回到响应
  - **每一条用户可感知的验收标准（AC）至少对应 1 条 E2E 执行证据**，AC ↔ 证据（test ID 或 chrome-mcp/agent-browser 的动作记录与截图）必须可映射
  - 涉及鉴权的路径至少 1 条未登录 / 越权失败用例
  - 表单 / 写操作至少覆盖 1 条参数校验失败
  - 选 chrome-mcp / agent-browser 时，这些"证据"以本轮 QA subagent 的导航步骤 + 关键断言 + 截图形式留存；选传统框架时，对应到提交进仓库的 spec 文件

遵循项目已有的测试文件命名和目录约定。

### 5. 运行测试

```bash
# 单测 / 集成（根据项目实际命令执行）
npm run test              # 或 pnpm test / cargo test / pytest / go test ./...
npm run test -- --coverage  # 覆盖率
```

E2E 按第 1 步选定的手段执行，**服务必须已经在第 3 步跑起来**。例如：

```bash
# 项目已配传统 E2E 框架
npx playwright test
npx cypress run

# 无前端 / 纯 API
curl -fsS -X POST http://localhost:8080/api/... -d '{...}'   # 检查状态码与响应体
pytest tests/e2e/                                              # 项目内的 API E2E 套件

# CLI
mycli do-thing --input fixture.json   # 在干净 shell 中执行并断言输出 / 副作用
```

如使用 **chrome-mcp** 或 **agent-browser**，直接由 QA subagent 在本轮内驱动，记录每一步动作、截图、关键断言到报告中（这些等同于 E2E 用例的证据）。

收集：通过数 / 失败数 / 覆盖率 / **E2E 通过路径数**（每条 happy path / 失败路径 / AC 映射用例都算一条）。

**E2E 空通过即失败**：
- 跑了框架但 0 用例执行 → `QA_RESULT=FAIL`，原因 "E2E 用例缺失"
- 选了 chrome-mcp / agent-browser 但报告里没有任何端到端动作记录与断言 → 同样判 FAIL
- 选了 API E2E 但只跑了健康检查没真调业务端点 → 同样判 FAIL

不允许"框架没装/没用例/没动作"被解读为 PASS。

### 6. 可视化回归（仅当涉及 UI 时）

1. 确认 dev server 已在第 3 步起来
2. 使用 chrome-mcp 或 agent-browser 导航到本 feature 涉及的每个路由（也可由项目已有 Playwright 截图脚本承担）
3. 截图保存到约定目录
4. 对比基准截图：
   - 无基准 → 本次截图作为基准提交，并在报告中说明
   - 有基准 → 像素 / 结构差异超阈值 → 判 FAIL，附 diff 截图

无 UI 的 feature（纯 API / CLI / 后台任务）跳过此步，不视为缺失。

### 7. 端到端冒烟（硬门槛）

E2E 用例之外，再走一条本 feature 最关键的 happy path，从用户/调用方视角真实验证一次。这一步专门抓"E2E 用例自己 mock 掉了真问题"的情况——例如 Playwright 把后端 stub 了一直绿，实际后端没起来；或单测 mock 了 DB 一直绿，真库连不上。

工具按 feature 形态选：

- Web UI：chrome-mcp 或 agent-browser（不依赖项目预置 E2E 框架，QA subagent 直接驱动）
- API：curl / httpie 命中真实后端
- CLI：在干净 shell 里跑真实命令
- 后台任务：投递真实消息并观察消费方副作用

记录到报告中：访问路径 / 调用命令、关键交互步骤、最终结果（数据是否真的写入、邮件是否真的发出、文件是否真的生成等**可观察的真实副作用**）。这一步不允许任何 mock。

### 8. 验收标准核验

逐条核对 requirements.md 中的验收标准，输出 **AC ↔ 验证证据** 映射表：

```markdown
| AC | 描述 | 验证方式 | 证据 | 回写状态 |
| -- | ---- | -------- | ---- | -------- |
| AC-001 | 用户能登录 | Playwright | tests/e2e/login.spec.ts::happy-path → passed | `[x]` |
| AC-002 | 错误密码提示 | chrome-mcp | 本轮步骤 #3-#5 + screenshots/login-wrong-pwd.png | `[x]` |
| AC-003 | API 创建订单 | API E2E (curl) | POST /api/orders → 201 + 数据库新行 id=42 | `[x]` |
| AC-004 | CLI 导出 csv | CLI E2E | `mycli export` 退出码 0 + outputs/export.csv 非空 | `[x]` |
| AC-005 | 复杂下单流程 | agent-browser | 任务 "登录→加购→下单→看订单列表"，agent 报告 passed + 录像 | `[x]` |
| AC-006 | 邮件通知 | 端到端冒烟 | mailhog 后台截图 + 邮件正文片段 | `[x]` |
| AC-007 | 第三方对账（生产凭证） | ⚠️ 不可自动化 | 原因：需真实银行账户；手动验证 checklist 见附录 | `[ ] ⚠️ MANUAL` |
| AC-008 | 未实现/未跑通 | — | — | `[ ]` 保持未勾 |
```

每条 AC 必须有对应证据。"⚠️ 需手动验证" 只允许用于**确实不可自动化**的场景（如真实支付、真实短信发送、生产凭证），并写明原因。

### 8.1 输出 AC 回写指令（供 N5 / Controller 使用）

QA 报告里必须**单独列出**一段机器可读的 AC 回写指令，供 N5「标记完成」节点直接照着改 `requirements.md`：

```text
🔁 AC 回写指令 — feature {N.feature-name}

PASS（标 [x]）:
  - AC-001
  - AC-002
  - AC-003
  - AC-004
  - AC-005
  - AC-006

MANUAL_REQUIRED（标 [ ] ⚠️ MANUAL，附原因注释）:
  - AC-007: 需真实银行账户

NOT_VERIFIED（保持 [ ]，留待后续 QA 轮次）:
  - AC-008
```

状态规则：
- **PASS** — 本轮 QA 真实跑通且证据齐全 → requirements.md 对应行改成 `- [x] [AC-NNN] 描述`
- **MANUAL_REQUIRED** — 仅允许"确实不可自动化"场景，回写时保持 `- [ ]` 但**在行尾追加** ` ⚠️ MANUAL: {原因}` 注释，让人类一眼能看到待办
- **NOT_VERIFIED** — 本轮根本没验到（feature 未实现 / 跑失败 / 漏覆盖）→ 保持 `- [ ]` 原样，不允许误标 [x]

**禁止**：QA 把没真跑过的 AC 标成 PASS；禁止把"代码里看起来实现了"等同于"AC 验证过"。

### 9. 处理失败

- 服务起不来 → BLOCKED，先自诊断（缺 env / 端口 / 依赖），无果再升级
- 测试失败 → 判断是代码 bug 还是测试问题
- 代码 bug → 汇报给主 agent，重新执行开发任务
- 测试问题 → 修复测试，重新运行
- E2E flaky → 用 `waitFor` / 重试机制修复，不允许靠"再跑一次就过了"放行
- 最多重试 3 轮

## 常见坑

| 问题 | 处理 |
| ---- | ---- |
| 单测全绿但服务起不来 | 第 3 步健康检查就该拦下；补 env / 注册路由 / 修依赖 |
| 测试环境和开发环境不一致 | 检查 test 配置中的环境变量和 mock 设置 |
| 异步测试超时 | 增加 timeout，检查是否缺少 await |
| E2E 测试不稳定（flaky） | 用 `waitFor` 代替固定延时，重试机制 |
| E2E "0 passed 0 failed" 或无任何端到端动作记录被当成 PASS | 立即判 FAIL，强制补一种 E2E 手段（框架用例 / chrome-mcp / agent-browser / API E2E / CLI E2E 都可） |
| "项目没装 Playwright 所以跳过 E2E" | 不接受，至少用 chrome-mcp/agent-browser/curl 走一遍并留证据 |
| AC 标了"已通过测试验证"但找不到对应 test ID | 立即判 FAIL，要求补映射 |
| 覆盖率统计不准 | 检查 coverage 配置的 include/exclude |
| 后端 mock 太彻底导致 E2E 没真跑后端 | 端到端冒烟（第 7 步）必须命中真实后端 |

## 输出

```text
📋 QA 报告

服务健康检查：{后端 PASS/FAIL | 前端 PASS/FAIL | DB PASS/FAIL}
单元/集成测试：{N} 通过 / {N} 失败 / 覆盖率 {N}%
E2E：手段={Playwright|Cypress|chrome-mcp|agent-browser|API|CLI|...}，{N} 条路径通过 / {N} 条失败 （0 路径 = FAIL）
端到端冒烟：{PASS/FAIL，附关键证据}
验收标准：{N}/{total} 通过，{N} 需手动验证（每条均有证据或不可自动化说明）
可视化回归：{PASS/FAIL/无基准已建立/无 UI 跳过}
安全扫描：{状态}

结论：{PASSED / FAILED / BLOCKED / NEEDS_MANUAL}

🔁 AC 回写指令（必填，供 N5 使用）：
PASS:
  - AC-xxx
MANUAL_REQUIRED:
  - AC-yyy: {原因}
NOT_VERIFIED:
  - AC-zzz
```

**PASSED 的充要条件**：服务健康检查全绿 + 单测全绿 + E2E ≥ 1 条路径且全绿（手段不限）+ 端到端冒烟 PASS + 每条 AC 有证据。任一缺失即不得报 PASSED。
