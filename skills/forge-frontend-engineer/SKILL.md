---
name: forge-frontend-engineer
description: 前端工程师 Skill，执行前端开发任务，自动适配项目技术栈（React/Vue/Svelte/Next.js 等），支持 Figma/Stitch 设计稿还原
---

# forge-frontend-engineer — 前端工程师

执行前端开发任务。自动识别项目技术栈，遵循项目 `.claude/rules/` 中的规范。

## 触发条件

由 `/forge:ai` 自动调用，当 task 涉及前端开发时触发。

## 工作流程

### 0. 设计稿检查

开发前先检查当前 task 或 design.md 中是否关联了设计稿：

- **有 Figma 链接** → 调用 `mcp__figma__get_figma_data` + `mcp__figma__download_figma_images` 获取设计数据和切图
- **有 Stitch 项目** → 调用 `mcp__stitch__get_screen` / `mcp__stitch__list_screens` 获取设计稿
- **没有设计稿** → 跳过，直接进入开发

**设计稿与业务的关系：**

- 设计稿存在且完整 → 按设计稿还原
- 设计稿存在但与业务需求有明显差距或缺失页面 → **提醒用户**设计稿与需求不一致的地方，然后根据已有设计稿继续完成功能，无需等待回复
- 没有设计稿 → 根据 design.md 和业务需求自行实现

### 1. 识别技术栈

读取项目配置自动判断，不做硬编码假设：

- `package.json` → 框架（React/Vue/Svelte/Next/Nuxt/Astro...）、UI 库、状态管理
- `tsconfig.json` / `jsconfig.json` → TS/JS、路径别名
- 样式方案 → Tailwind / CSS Modules / styled-components / UnoCSS 等
- 构建工具 → Vite / Webpack / Turbopack / esbuild

### 2. 读取上下文

- `.claude/rules/frontend.md`、`.claude/rules/coding-style.md`（如存在）
- design.md 中当前任务相关的模块设计
- 扫描 `src/` 了解现有组件结构和命名规律
- **重点扫描项目已有的 UI 组件库**（`components/ui/`、`components/common/` 等），了解哪些组件已封装可复用

### 3. 开发

**组件封装与复用（重要）：**

- 开发前先检查项目已有的 UI 组件库，能复用的绝不重写
- 新建通用 UI 组件时放入项目约定的公共组件目录，确保可被其他页面复用
- 业务组件和 UI 组件分层：UI 组件不含业务逻辑，业务组件组合 UI 组件
- 如果项目使用了第三方组件库（Ant Design/shadcn/Element/Radix 等），优先用库内组件，不自己造轮子

**Tailwind CSS（如项目使用）：**

- 检查 Tailwind 版本（v3 vs v4），全局样式封装方式不同：
  - **v3**：`@layer base/components/utilities` + `@apply` 在 `globals.css` 中
  - **v4**：CSS-first 配置，`@theme` 定义 design token，`@variant` 自定义变体
- 复用样式通过组件封装而非到处复制 class 字符串
- 主题色、间距、字体等通过 Tailwind config / CSS 变量统一管理，不硬编码具体值

**组件开发：**

- 遵循项目已有的组件模式（class/函数、选项式/组合式）
- Props/类型定义跟随项目约定
- 文件命名跟随项目已有规律

**状态管理：**

- 识别项目使用的方案（Redux/Zustand/Pinia/Vuex/Jotai...）
- 简单局部状态用框架原生方案
- 参考 design.md 中的状态流转设计

**API 调用：**

- 基于 design.md 中的接口契约
- 后端未就绪 → 先写 mock，标注 `// TODO: replace mock when API ready`
- 错误处理和 loading 状态

**路由：**

- 按 design.md 页面设计配置，遵循项目路由约定（file-based / config-based）

### 4. 验证

**第一层：静态 + 构建（必跑）**

```bash
# 根据项目实际命令执行
npm run lint
npm run typecheck
npm run build
```

**`npm run build` 必须 0 error 通过**——dev 能跑 ≠ 生产能 build，build 失败的代码不算完成。

**第二层：页面真的能用（硬门槛，不可跳过、不可用"组件单测过"替代）**

单测 + 构建通过 ≠ 用户能用。报 DONE 之前必须执行：

1. **启动 dev server**：`npm run dev` 或项目实际命令，确认不在启动阶段崩溃
2. **访问本次新增或修改的每个路由**：页面要真正渲染出来，**控制台无 error**（warning 评估后处理），网络面板里 API 请求按预期发出且后端正确响应。访问手段不限：项目预置 E2E 框架（Playwright/Cypress 等）、chrome-mcp（无需安装，QA/implementer 可直接驱动）、agent-browser（语义化模拟用户）或手动打开浏览器都可
3. **核心交互至少触发 1 次**：表单提交、按钮点击、列表加载、路由跳转等本次涉及的主交互，端到端串通一次——从点击到 UI 反馈、到 API 调用、到数据回显。同样可用上述任一手段；选哪种就记录哪种的证据（用例 ID / 动作日志 / 截图）
4. **后端尚未就绪的部分**：mock 也必须真的返回数据，页面在 mock 下能完整渲染；标注 `// TODO: replace mock when API ready`

任何一项失败、白屏、控制台报红、或 dev server 起不来 → 状态降为 BLOCKED 上报。"build 过了所以应该能跑" 不是验证。

## 常见坑

| 问题 | 处理 |
| ---- | ---- |
| 路径别名导致 import 报错 | 检查 tsconfig paths 和构建工具配置是否一致 |
| SSR/SSG 组件使用了 browser API | 加 `typeof window !== 'undefined'` 或动态导入 |
| 样式冲突 | 优先用项目约定的作用域方案，避免全局样式 |
| 第三方库类型缺失 | 检查 `@types/xxx`，必要时声明 `.d.ts` |
| Tailwind v3 和 v4 混用 | 检查版本，v4 不再用 `tailwind.config.js`，改用 CSS-first |
| 组件重复造轮子 | 开发前先搜索项目已有组件，grep 关键词 |
| 设计稿颜色/间距与 Tailwind token 不一致 | 扩展 theme 配置而非硬编码 hex 值 |

## 输出

- 创建/修改的文件列表
- 验证结果（lint + build）
- 设计稿还原情况（如有设计稿）
- 需要其他工种配合的事项
