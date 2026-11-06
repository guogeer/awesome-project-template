# 技术栈细则：Python 后端（FastAPI + SQLAlchemy）

> 复制到后端项目后按实情裁剪；通用风格见 `code-style.md`。

## 分层与职责

- **接口层（routes/api）只做**参数校验（Pydantic）、鉴权、调用 service、组装响应；不写业务逻辑、不直接操作 DB。
- **service 层**持有业务规则与事务边界：扣费、状态流转、幂等控制都在这里；接口层与 service 层共用同一个 session，避免半提交。
- **model 层**只定义结构与少量表级约束；跨表规则不写在 model 里。

## 事务与会话

- 一个请求一个 session，写操作在 service 内显式 `commit` / `rollback`；不做跨请求的长事务。
- 资金类写操作（扣费、退款、发放）**必须幂等**：唯一约束 + 业务键（如 `biz_id=<id>:refund`），靠 DB 约束兜底而不是"先查再写"。
- 批量写用批量语句，不要在循环里逐条 commit。

## 并发与锁

- 需要跨进程互斥时用 MySQL 会话级锁（`GET_LOCK`/`RELEASE_LOCK`），注意：**锁绑定连接会话**，异步代码必须保证获取与释放同一 loop / 同一连接；锁必须在 `finally` 里释放。
- 会话锁、死锁、连接池语义在 SQLite 单测里验证不到，改动后必须在真 MySQL 环境起服务验证（见 `testing.md` 第 5 节）。

## 状态字段

- 一张表同时有审计列 `status`（1=正常 2=禁用）与业务列 `task_status` 之类的同名前缀字段时，**业务判断只用业务列**；写成审计列不报错、恒假，是高频事故源。ORM 查询过滤同理（`Task.task_status == x`，不是 `Task.status == x`）。
- 派生状态（如 `gen_status`）逐表确认真源列名再写判断。

## 配置

- 配置收口在 `config.py`（pydantic Settings），环境差异靠 `.env.<环境>` 与启动注入；**禁止**在业务代码里读 `os.environ` 或写死域名/上游地址。
- 上游地址这类配置的"生效点"要写进文档：compose 默认值只是兜底，服务器 `.env` 显式覆盖才生效；改完必须重建容器（restart 不刷新环境变量）。
- 排查配置漂移：对比运行环境 `.env` 与 `env.<环境>.example` 的非敏感键差异（跳过含 KEY/SECRET/PASSWORD/TOKEN/DSN 的键）。

## 错误与日志

- 对外错误统一信封结构（code/message），**对外文案稳定可读**；根因（堆栈、上游请求/响应原文）落结构化日志。
- 关键链路（下单、支付、回调）日志含完整请求体与上游响应原文，便于事后排查；密钥与 token 脱敏。
- 排障口径写进 `AGENTS.md`：日志路径、关键字（如 `xxx failed:`）、别只看接口返回的通用文案。

## 迁移（Alembic）

- 迁移文件**只增不改**；提交信息 body 写明迁移版本与回滚注意。
- 新增列给默认值或允许 NULL，避免全表重建锁写。
