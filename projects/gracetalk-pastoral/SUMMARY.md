# gracetalk-pastoral 规范提炼

> GraceTalk 牧养祷告平台：FastAPI 后端（`api/`）+ Flutter App（`app/`）+ 管理后台 React/antd 6（`web/`）。真源：项目仓库 `AGENTS.md` + `doc/` 按模块 DESIGN 文档。

## 规范组织方式（特色：文档分层 + 需求仲裁链）

- `doc/` **按模块分目录**：`doc/api/`、`doc/web/`、`doc/app/`；命名模板 `<前缀>-<主题>-v<版本>.md`：`PRD-`（需求）、`DESIGN-`（设计）、`DB-`（数据库）、`API-`（接口）。
- 每个模块目录的 `DESIGN-<模块>-v1.0.md` 是**总览**（架构边界、全局规范、模块文档索引、待确认项），其余是子模块文档；**改动任一模块前必须先读该模块 DESIGN 总览**。
- **需求仲裁链**（歧义时依次）：① 用户最新明确指示 → ② 产品 Demo 原型行为 → ③ `doc/` 设计文档 → ④ 仍无法判断就在代码留清晰适配点并标注待确认项，**不臆造业务规则**。
- 通用规范（API/DB/Python）真源在工作区共享目录 `backend-shared-assets/docs/`，DESIGN 文档只做落地补充，冲突以共享规范为准。
- `doc/demo/` 是产品原型，**只读参考**，不在其上开发。

## 技术栈口径

| 模块 | 栈 |
| --- | --- |
| 后端 | Python 3.12 + FastAPI + SQLAlchemy 2.0 async（asyncmy）+ MySQL 8 + Alembic；uv + ruff + pytest |
| 移动端 | Flutter（iOS/Android/H5-PWA）；`http` + `shared_preferences`，路由与状态管理暂不引第三方框架 |
| 管理后台 | Ant Design 6（React 19）+ TypeScript + Vite；React Router + axios + zustand |

## 关键口径

- **游客登录**：以端侧设备标识建档，无邮箱无口令、卸载即丢（暂不支持升级为正式账号），见 `doc/api/DESIGN-鉴权与用户-v1.0.md`。
- **每日经文由后端大模型逐日生成、按日期落排期**：后台提前审阅未来 30 天、可重新生成/人工改写，后端按日期统一给出当天一条，端侧拉取后回退当天缓存/内置经文（端侧必须有兜底）。
- **免费额度与分级冷却**：每人每天 3 次免费告解（服务器自然日重置）、每次 30 分钟；超出后按次数分级冷却（5/10/20/30 分钟）。
- **匹配不消耗口径**：15 秒确认倒计时走完没进入 = 本次匹配作废、不消耗免费次数；只有真正进入聊天才扣次数。
- 后端容器化统一走 `deploy.sh`（`init`/`dev up`/`up --build`/`pull`/`health`），测试与生产**共用同一镜像**，差异只在 env 文件。
- H5/PWA 发布：`./tool/build_web.sh` 必填 `API_BASE_URL`，默认 `--base-href=/h5/`；本机/同内网手机调试要后端放行 CORS_ORIGINS。
