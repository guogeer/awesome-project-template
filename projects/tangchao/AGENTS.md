# AGENTS.md

## 项目概况

- `backend/` 是已归档的 ThinkPHP 5 项目，仅作为迁移参考和历史对照使用。
- `backend_new/` 是迁移后的 ThinkPHP 8 项目，是后端当前开发入口。
- `web/` 是 Vue 2 管理端项目。

## 后端约定

- 默认在 `backend_new/` 中开发、修复和验证后端功能。
- 不要在 `backend/` 中新增功能或修复业务逻辑，除非用户明确要求处理归档项目。
- 需要对照旧实现时，可以读取 `backend/application/*`，再把改动落到 `backend_new/app/*`。
- `backend_new/` 使用 PHP `>=8.0`、ThinkPHP `^8.0`、`topthink/think-multi-app`。
- 迁移代码时注意 ThinkPHP 5 到 ThinkPHP 8 的命名空间、路由、中间件、ORM、配置和助手函数差异，避免直接机械复制旧代码。

## 常用命令

后端：

```bash
cd backend_new
composer install
php think run
composer test
```

前端：

```bash
cd web
npm install
npm run dev
npm run lint
npm run build
```

## 工作规则

- 修改代码后自动运行对应的格式化命令：前端执行 `npm run lint`（会同时修复格式）。后端禁用 pint 格式化代码。
- 修改前先查看目标目录的现有写法，优先保持本仓库已有结构和风格。
- 不提交 `vendor/`、`runtime/`、`node_modules/`、`dist/` 等生成产物，除非用户明确要求。
- 涉及接口联调时，同时检查 `backend_new/route`、`backend_new/app/*` 和 `web/src` 中的调用方。
- 涉及迁移判断时，以 `backend_new/` 为准；`backend/` 只用于确认旧行为。
- 修改完成后尽量运行与改动范围匹配的最小验证命令，并在结果中说明是否已验证。

## 易错点约束

- **验签必须基于请求原始 body（`$request->getContent()`），不要用 `request()->param()`**。框架会把路由参数（如通知 URL 中的 `{gid}`）合并进 `param()`，污染签名拼接；写日志排查时也要区分 `param()` 与原始 body 两个来源。
