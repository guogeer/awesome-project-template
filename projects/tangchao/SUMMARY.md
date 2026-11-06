# tangchao (oxpay) 规范提炼

> OXPay 支付网关 + 管理端：ThinkPHP 8 后端（`backend_new/`）+ Vue 2 管理端（`web/`）+ ticker。真源：项目仓库 `AGENTS.md` + `doc/`。

## 项目结构口径

- `backend/` 是**已归档**的 ThinkPHP 5 项目，只做迁移参考与历史对照，**不在其中开发**。
- `backend_new/` 是迁移后的 ThinkPHP 8 项目（PHP >= 8.0），当前开发入口。
- 迁移对照旧实现时读 `backend/application/*`，改动落到 `backend_new/app/*`；注意 TP5→TP8 的命名空间、路由、中间件、ORM、配置、助手函数差异，**不机械复制旧代码**。

## 工作规则（精要、可复用）

- 修改前先看目标目录现有写法，保持仓库已有结构与风格。
- 改完自动跑格式化：前端 `npm run lint`（同时修复）；**后端禁用 pint**。
- 不提交 `vendor/`、`runtime/`、`node_modules/`、`dist/` 等生成产物。
- 接口联调要同时检查 `backend_new/route`、`backend_new/app/*`、`web/src` 三处调用方。
- 修改完成后跑与改动范围匹配的**最小验证命令**，并在结果中说明是否已验证。

## 关键踩坑（本项目最重要的一条）

- **支付验签必须基于请求原始 body（`$request->getContent()`）**，不要用 `request()->param()`：框架会把路由参数（如通知 URL 里的 `{gid}`）合并进 `param()` 污染签名拼接；写排查日志也要区分这两个来源。

## 部署口径（与 Docker/镜像相关）

- 本地构建镜像推阿里云 registry，服务器拉镜像（不走代码直传）；测试服用 `latest` 标签，日期+序号标签（`YYYYMMDD.N`）留给正式服。
- 打镜像用仓库自带 `doc/deploy/build-image.sh` 或一键 `deploy-test.sh`（按分支绑定环境、拒绝脏工作区）。
- PHP 代码改动随镜像生效；`docker compose pull` 必须前台执行（后台会被 session 清掉）。
