# AGENTS.md

本文件为本仓库（GraceTalk 牧养祷告项目）内 AI 编码代理的工作约束。

仓库边界：本仓库为独立 git 仓库（`git@gitcode.com:empiregame/gracetalk-pastoral.git`），所有 `git`、格式化、静态检查、测试命令都必须在本仓库目录内执行，不要在工作区根目录或其它仓库目录操作。

当前仓库依据：

- `doc/demo/GraceTalk-pastoral-demo/`：产品出的功能原型（H5 单页 Demo，含 `app.js`、`style.css`、`books/` 经文样例与 `README-测试说明.md`），用于对齐产品行为与页面流程。
- `doc/demo/GraceTalk-pastoral-demo/README-测试说明.md`：Demo 测试流程与「正式上线前需接入」清单。
- `doc/api/DESIGN-后端服务-v1.0.md`：后端服务设计约束总览（技术栈、架构边界、数据库 / API / Python 规范、开发约定、模块文档索引）。
- `doc/app/DESIGN-移动端-v1.0.md`：移动端（Flutter）设计约束总览（技术栈、平台范围、端侧边界、待确认项）。
- `doc/web/DESIGN-管理后台-v1.0.md`：管理后台（Ant Design 6）设计约束总览（技术栈、功能范围索引、权限与安全、审计、工程结构）。

`doc/demo/` 为产品原型，**只读参考**，不要在其上做开发；正式代码与文档不要放进该目录。

## 项目定位

GraceTalk 是一个面向基督徒的在线告解 / 牧养祷告平台，为用户提供私密、受保护的告解与灵性陪伴服务。

核心场景：用户进入应用、写下自己的告解内容、由平台匹配（真人牧师志愿者或 **AI 牧师**）进行一对一对话陪伴，对话结束后可捐助并预约下一次告解，同时提供圣经经文阅读功能。

本仓库负责该产品的完整实现：

- **后端服务**：用户、登录、告解匹配、会话、AI 牧师提示词、捐助与预约、每日经文的生成与排期等能力。
- **移动端 App**：iOS / Android 客户端（Flutter）。
- **管理后台**：权限管理（管理员 / 角色 / 菜单）、系统管理（审计日志）与运营中心（移动端用户管理、模型接入、AI 牧师提示词配置与批量导入、内容配置、真人牧师创建与陪谈台）。

平台定位为**非营利组织**（Demo 中明确对外声明），功能设计需体现隐私保护与服务属性。

## 文档导航与需求依据

| 模块 | 详细文档 | 技术栈摘要 |
| --- | --- | --- |
| 后端服务 | `doc/api/DESIGN-后端服务-v1.0.md` | Python 3.12 + MySQL 8 + Alembic |
| 移动端 | `doc/app/DESIGN-移动端-v1.0.md` | Flutter（iOS + Android） |
| 管理后台 | `doc/web/DESIGN-管理后台-v1.0.md` | Ant Design 6（React） |

- **改动任一模块前，必须先读取该模块目录下的 DESIGN 总览与相关模块文档**；AGENTS.md 不重复维护模块细节。
- 通用规范（API / DB / Python）的真源在工作区共享目录 `backend-shared-assets/docs/`；DESIGN 文档只做落地补充，冲突时以共享规范为准。
- 正式文档统一放在 `doc/` 下、**按模块分目录**：`doc/api/`（后端服务）、`doc/web/`（管理后台）、`doc/app/`（移动端）；命名模板 `<前缀>-<主题>-v<版本>.md`：需求 `PRD-`、概要/详细设计 `DESIGN-`、数据库设计 `DB-`、接口文档 `API-`。
- 每个模块目录内，`DESIGN-<模块>-v1.0.md` 是该模块**总览**（架构边界、全局规范、模块文档索引、待确认项），其余 `DESIGN-<子模块>-v1.0.md` 是**模块文档**（业务细节，目录名已表明模块，文件名不再重复模块前缀）；对应关系见总览的「模块文档索引」表与本文档「模块约束（索引）」。
- 当需求存在歧义或缺失时：
  1. 以用户最新明确指示为准。
  2. 其次以 `doc/demo/GraceTalk-pastoral-demo/` 原型行为为准。
  3. 再以 `doc/` 下设计文档为准。
  4. 仍无法判断时，在代码中保留清晰适配点，并在提交说明或任务记录中标注待确认项，不要臆造业务规则。

### Demo 逆向出的产品功能范围

以 Demo 行为为准，当前已知功能范围如下：

- **登录**：Facebook / Google OAuth、邮箱 + 密码登录与注册（Demo 中为本地演示，不连真实账号）；**游客登录**（iOS / Android / H5（PWA），以端侧设备标识建档，无邮箱无口令，卸载即丢、暂不支持升级为正式账号，见 `doc/api/DESIGN-鉴权与用户-v1.0.md`）。
- **首页 Home**：今日经文（Today's Verse，经文**由后端大模型逐日生成**、按日期落成排期，运营在后台「每日经文」页面提前审阅未来 30 天并按需重新生成 / 人工改写、**后端按日期统一给出当天一条**、端侧拉取后回退当天缓存 / 内置经文）、告解输入框、显示名称（支持随机昵称，昵称池由后台「随机昵称」页面维护、端侧拉取后本地兜底）、头像选择（头像库与默认头像由后台「头像管理」页面维护、端侧拉取后回退内置素材）、志愿者性别偏好（Male / Female / No preference）、隐私承诺、`Start confession`。
- **免费额度与冷却**：每人**每天** 3 次免费告解（按服务器自然日重置）、每次 30 分钟；当天超过后按次数分级冷却（第 3 次起冷却 5 / 10 / 20 / 30 分钟）。
- **匹配流程**：点击开始后进入 30 秒匹配动画，匹配成功展示牧师资料（头像、性别、等级、评分、地点、擅长标签）并起 **15 秒确认倒计时**，倒计时内点 `Enter chat` 才进入聊天并消耗一次免费次数；倒计时走完没进入则本次匹配作废、**不消耗次数**（可重新匹配或回首页）。
- **Talk**：**只展示最近的对话记录**（「Recent chats」是会话的唯一入口，进行中 + 已结束，按最近往来时间倒序；已结束的带 `Ended` 标识、进去只能回看或捐助）；**不展示**真人牧师 / AI 牧师联系人列表，发起陪谈统一走首页 `Start confession`；会话私密、限时 30 分钟。
- **AI 牧师**：每个 AI 牧师有独立 `id`、名称、头像、性别、风格（gentle / wise / direct）与 `systemPrompt`；对话请求约定 `{ message, companion, history }`，返回 `{ reply }`。
- **客服接管**：AI 会话可转人工客服（Demo 中为 mock）。
- **聊天**：30 分钟倒计时、打字中提示、用户在线状态（online / away / offline，5 分钟无操作转 away，切后台转 offline）、结束对话。
- **捐助与预约**：对话结束后可「Donate」或「Donate & book next confession」；捐助金额 USD 0–99；可指定未来日期与时间预约下一次告解；同一牧师同一时段不可重复预约；每个牧师的预约独立保存。
- **Bible**：书目与章节从约定目录读取；阅读器支持夜间模式、字号调节、目录跳转、翻页滑块、分享。
- **Me**：查看/编辑个人资料（昵称、头像、性别偏好、邮箱）、退出登录。

### 正式上线前必须接入（Demo README 明确列出）

- Facebook / Google OAuth 与邮箱密码系统（真实鉴权）。
- 真实志愿者资料、在线状态、匹配与聊天服务器。
- 支付平台、支付回调验证与捐助记录。
- 邮件服务与预约提醒任务。
- 权限控制、审计记录与隐私合规流程。

## 技术栈（摘要）

| 模块 | 技术栈 |
| --- | --- |
| 后端服务 | Python 3.12 + FastAPI + SQLAlchemy 2.0 async（asyncmy）+ MySQL 8 + Alembic；uv + ruff + pytest |
| 移动端 | Flutter（iOS + Android）；`http` + `shared_preferences`，路由与状态管理暂不引入第三方框架 |
| 管理后台 | Ant Design 6（React 19）+ TypeScript + Vite；React Router + axios + zustand |

细则、规范与约束见各模块 DESIGN 文档。

## 仓库结构

- `doc/`：正式需求 / 设计 / 接口 / 数据库文档，按模块分目录：`doc/api/`（后端服务）、`doc/web/`（管理后台）、`doc/app/`（移动端）；Demo 原型在 `doc/demo/`，只读。
- `api/`：后端服务（Python 3.12 + FastAPI + SQLAlchemy 2.0 async + Alembic，src 布局），Python 包名为 `gracetalk`。
- `web/`：管理后台（Vite + React + Ant Design 6），承载权限管理（管理员 / 角色 / 菜单）、系统管理（审计日志）与运营中心（用户管理、模型接入（OpenAI 兼容渠道与密钥）、AI 牧师配置）。
- `app/`：移动端 Flutter 工程（含 `android/`、`ios/`、`app/web/` 平台目录；`app/web/` 既承载本机 / 局域网 H5 调试，也是 PWA 发布资源的所在地，含 `sw.js`、`manifest.json` 与 `icons/`）。

各模块已初始化为可运行骨架，细化结构与横切约定见对应 DESIGN 文档。新增一级目录后应同步更新本文件。

### 常用命令

```bash
# 后端（api/）
./tool/dev_api.sh                            # 一键启动本地开发：确保 MySQL 容器 → uv sync → 迁移 → 热重载 API（默认 0.0.0.0:18000）
uv sync && uv run uvicorn gracetalk.main:app --reload --host 0.0.0.0 --port 18000
uv run ruff format . && uv run ruff check . --fix && uv run pytest

# 后端容器化（api/docker/，产物见 doc/api/DESIGN-部署与运维-v1.0.md）
./tool/dev_api.sh                            # 本地开发一键启动：默认复用宿主机 3306 已有 MySQL，探测不到才起 dev 容器，再拉起 API
./deploy.sh init && ./deploy.sh dev up       # 本地开发：只准备数据库（3306 已有实例时直接复用，不另起容器），API 命令行跑
./deploy.sh up --build                       # 生产（默认环境，读 docker/.env.prod）：api + MySQL 全容器部署
APP_ENV=test ./deploy.sh up --build          # 测试环境（读 docker/.env.test），可与生产共用同一镜像
./deploy.sh pull && ./deploy.sh up           # 生产：拉取 .env.prod 中 pin 版本的镜像后启动
APP_ENV=test ./deploy.sh health              # 环境由 APP_ENV 选择（默认 prod），-e <文件> 可显式指定
./build-image.sh -e .env -t 20260912.1 --push  # 打镜像并推送（测试/生产共用同一镜像）

# 管理后台（web/）
npm install && npm run dev
npm run lint && npm run build

# 移动端（app/）
flutter pub get && flutter analyze && flutter test
flutter run -d chrome --web-port=18080   # H5 调试（仅本机），需后端放行 CORS_ORIGINS
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=18080   # 同内网手机浏览器调试
./tool/dev_web.sh                        # 同上，且 lib/**/*.dart 变更后自动热重载（日志 /tmp/gracetalk-dev-18080.log）

# H5 / PWA 发布（产物 build/web，约束见 doc/app/DESIGN-PWA发布-v1.0.md）
API_BASE_URL=https://<host>/api/v1 ./tool/build_web.sh   # 默认 --base-href=/h5/，必填 API_BASE_URL
python3 tool/gen_pwa_icons.py            # 重新生成 app/web/icons/ 下的 PWA 图标
```

## 测试服发布流程（pay.nangua203.com）

入口 `https://test-grace-talk.globaloxpay.com`：H5 在 `/h5/`、后台在 `/admin/`、接口在 `/api/`（Nginx 规则见 `api/docker/nginx/gracetalk.conf`）。
服务器部署目录 `~/gracetalk/` 是仓库 `api/docker/` 的副本（非 git 仓库）。**应用配置随镜像分发**：
容器启动后按 `DOTENV_FILE=/app/docker/.env.test` 加载**镜像内**的 `docker/.env.test`（即仓库里那份），
部署主机不需要为应用变量单独维护 `.env`；`~/gracetalk/.env.test` 只服务 compose 插值（`APP_IMAGE`、端口、
内置 MySQL 口令），与仓库那份同源、可随 rsync 一起上传（本地开发的 `.env` 仍不上传）。
改应用配置（含 `API_SECRET`、数据库连接串）必须改仓库里的 `docker/.env.test` 并**重新构建镜像**，
只改服务器上的文件不再生效。容器化与镜像参数细节见 `doc/api/DESIGN-部署与运维-v1.0.md`，
H5 缓存与发版约束见 `doc/app/DESIGN-PWA发布-v1.0.md`。

1. 本机构建三件产物

```bash
# H5 / PWA（默认 --base-href=/h5/；BUILD_NUMBER 写入 build/web/version.json，
# Service Worker 据此切分缓存，每次发布必须递增，否则用户拿不到新版本）
cd app && API_BASE_URL=https://test-grace-talk.globaloxpay.com/api/v1 BUILD_NUMBER=20260917.1 ./tool/build_web.sh

# 管理后台（--base=/admin/ 必须与 Nginx 的 /admin/ 前缀一致；
# 本机安全删除工具拦截 vite 清空 dist 时，先 rm -rf dist 再构建）
cd web && npm run build -- --base=/admin/

# 后端镜像（配置随镜像分发：构建前确认 docker/.env.test 已是本环境生效值，-t 的标签
# 与 .env.test 的 APP_IMAGE 保持一致；--push-latest 额外推 :latest，需已 docker login ACR）
cd api && ./docker/build-image.sh -e docker/.env.test -t <新标签> --platform linux/amd64 --push --push-latest
```

2. 上传到服务器（静态目录属 root，必须 `--rsync-path="sudo rsync"`；
   不要用管道截断 rsync 输出，否则会掩盖失败退出码与 sudo 兜底分支）

```bash
rsync -a --delete -e "ssh -i ~/.ssh/guo-web-test.pem" --rsync-path="sudo rsync" \
  app/build/web/ ubuntu@pay.nangua203.com:/var/www/gracetalk/
rsync -a --delete -e "ssh -i ~/.ssh/guo-web-test.pem" --rsync-path="sudo rsync" \
  web/dist/ ubuntu@pay.nangua203.com:/var/www/gracetalk-admin/
# .env.test 随仓库同步（只服务 compose 插值）；本地开发的 .env 与另两份仍不上传
rsync -av --exclude 'data/' --exclude 'backup/' --include '.env.test' --exclude '.env*' \
  -e "ssh -i ~/.ssh/guo-web-test.pem" api/docker/ ubuntu@pay.nangua203.com:~/gracetalk/
```

3. 服务器切版本并重启（容器入口自动跑 `alembic upgrade head`；`deploy.sh` 按 `APP_ENV=test`
   自动把容器内 `DOTENV_FILE` 设为 `/app/docker/.env.test`）

```bash
cd ~/gracetalk
sed -i 's|^APP_IMAGE=.*|APP_IMAGE=registry.cn-hangzhou.aliyuncs.com/guogeer/gracetalk-api:<新标签>|' .env.test
APP_ENV=test ./deploy.sh pull     # 按 .env.test 里的 APP_IMAGE 拉镜像
APP_ENV=test ./deploy.sh up       # 应用配置由容器从镜像内 .env.test 加载
```

> 切版本只需改 `~/gracetalk/.env.test` 的 `APP_IMAGE`（仓库里那份同步改，保持同源）；
> 不再需要 `cp -a .env.test .env.test.bak-<旧标签>` 这类备份——应用配置不在主机文件里，
> 回滚靠镜像标签而非 env 文件。

4. 验收

```bash
curl https://test-grace-talk.globaloxpay.com/api/v1/health/ready
curl https://test-grace-talk.globaloxpay.com/h5/version.json      # build_number 应为本次版本号
curl -o /dev/null -w '%{http_code}\n' https://test-grace-talk.globaloxpay.com/h5/       # 200
curl -o /dev/null -w '%{http_code}\n' https://test-grace-talk.globaloxpay.com/h5/sw.js  # 200
curl -o /dev/null -w '%{http_code}\n' https://test-grace-talk.globaloxpay.com/admin/    # 200
```

回滚：把 `~/gracetalk/.env.test` 的 `APP_IMAGE` 改回旧标签后 `pull && up -d`（应用配置跟着镜像一起回滚）；
静态产物侧没有版本目录，回滚需保留旧构建产物（或重新构建旧提交）后再 rsync。

## 模块约束（索引）

各模块的详细设计约束已拆分到 `doc/` 下，改动前必须先读对应文档（总览保留架构、全局规范与模块索引，业务细节在模块文档中）：

- 后端服务 → 总览 `doc/api/DESIGN-后端服务-v1.0.md`（架构边界、数据库 / API / Python 规范、开发约定）；模块文档 `doc/api/DESIGN-鉴权与用户-v1.0.md`（登录令牌 / 图形验证码 / 第三方与邮箱登录 / 后台权限 / 移动端用户资料）、`doc/api/DESIGN-AI牧师与模型-v1.0.md`（AI 牧师配置 / 模型渠道 / 对话 / 运行参数）、`doc/api/DESIGN-AI牧师陪谈-v1.0.md`（AI 会话的两个入口 / 开场回复抽签 / 回复生成与「真人感」/ 失败降级）、`doc/api/DESIGN-文件存储-v1.0.md`（图片上传 / S3 / 预签名下载 / 媒体代理）、`doc/api/DESIGN-内容配置-v1.0.md`（头像库 / 随机昵称库 / 每日经文）、`doc/api/DESIGN-真人牧师陪谈-v1.0.md`（新建与设为牧师 / 陪谈会话与消息 / 实时通道 / 同时接待上限后台可配）、`doc/api/DESIGN-部署与运维-v1.0.md`（健康检查 / 容器化部署）。
- 移动端 → 总览 `doc/app/DESIGN-移动端-v1.0.md`（Flutter 工程、平台范围、端侧边界）；模块文档 `doc/app/DESIGN-功能与工程-v1.0.md`（移动端功能范围、工程落地结构）、`doc/app/DESIGN-iOS设计规范-v1.0.md`（iOS 交互与视觉规范、与 Android 的差异、落地映射与检查清单）、`doc/app/DESIGN-真人牧师陪谈-v1.0.md`（真人牧师列表 / 匹配队列 / 真人会话与实时通道）、`doc/app/DESIGN-AI牧师陪谈-v1.0.md`（真人优先与 AI 回落排期 / 开场回复的呈现 / AI 回复节奏）、`doc/app/DESIGN-PWA发布-v1.0.md`（PWA 发布：`sw.js` 缓存策略、manifest 与图标、构建版本号、Nginx 缓存约束、更新机制与验收清单）。
- 管理后台 → 总览 `doc/web/DESIGN-管理后台-v1.0.md`（Ant Design 6、功能范围索引、权限与安全、审计）；模块文档 `doc/web/DESIGN-权限与鉴权-v1.0.md`（权限管理 / 管理员 / 角色 / 菜单 / 审计日志 / 初始化与登录，含接口与表结构）、`doc/web/DESIGN-AI牧师与模型-v1.0.md`（AI 牧师配置 / 模型接入 / 运行参数，含接口与表结构）、`doc/web/DESIGN-运营内容-v1.0.md`（平台用户管理 / 图片上传 / 随机昵称 / 头像库 / 每日经文）、`doc/web/DESIGN-牧师陪谈工作台-v1.0.md`（新建与设为牧师 / 陪谈设置 / 后台陪谈台）。

未在需求中出现的后台功能（财务、报表、运营数据等）不要自行扩展，需要时先补 `PRD-` / `DESIGN-` 文档。

## 通用开发约束

以下约束跨模块生效，各模块详细规范见对应 DESIGN 文档与工作区共享规范：

- 分层清晰：接入层只做入出参，业务规则集中到 service，持久化访问集中到 repository / dao，接口模型与数据库模型分离。
- 环境变量不加统一前缀：变量名即后端配置字段名（`DATABASE_URL`、`S3_BUCKET`、`CORS_ORIGINS`…），服务器参数用 `UVICORN_*`；新增配置项须同步 `docker/.env.prod` 与 `docker/.env.test`（应用配置随镜像分发，`docker-compose.yml` 只保留容器运行时参数），生效需重新构建镜像。
- 配置载体分工：基础设施与启动期必需项（数据库 / 端口 / 密钥 / 存储凭据）只能走环境变量；**运行期需要调、且不希望重发容器的业务参数走后台配置**（`system_setting` 表，按分组维护，环境变量仅作兜底，如模型运行参数），不得要求运营改 `docker-compose.yml` 才能调参。
- 数据库变更必须走 Alembic 迁移脚本，并同步更新相关 `DB-` 文档。
- 对外部系统调用（模型服务、支付平台、邮件服务、OAuth）保留超时、重试、降级与明确失败状态，不得把失败伪装成成功。
- 捐助、预约、支付回调、邮件提醒等外部副作用能力必须幂等或可重试。
- 涉及用户告解内容、会话、捐助、预约的接口必须做身份与权限校验，禁止越权访问他人数据。
- 隐私数据遵循最小权限与合规原则；客户端不硬编码密钥、支付凭据或 Secret，模型调用一律经后端代理。
- 不要提交真实密钥、支付凭据、OAuth Secret 或生产地址（按项目约定直接写入入仓 dotenv 的只有两项：S3 接入点密钥，以及各环境独立、用于登录令牌 JWT 签名、渠道密钥加密与模型密钥回退的 `API_SECRET`，见 `doc/api/DESIGN-后端服务-v1.0.md` 第 9 节）；Demo 的 `config.js` 仅作占位示例。
- 共享规范真源：`backend-shared-assets/docs/` 下 `API-接口规范.md`、`DB-数据库字段设计与使用规范.md`、`PYTHON-项目开发规范.md`。
- **多功能点拆任务、一任务一提交**：一次请求包含多个相互独立的功能点（不同需求 / 不同缺陷 / 后端 `api/` 与 `web/`、`app/` 不同端 / 不同模块）时，**先拆成多个任务**（`todo` 逐项对应），每个任务独立实现、独立验证、**独立提交一次**；禁止多个功能点揉进一个 commit，也禁止把一个功能点拆成多个半成品 commit。同一功能点的实现 + 迁移 + 后台页面 + 端侧改动 + 文档 + 测试属同一次提交；多个不相关缺陷按缺陷逐个提交。

## 待确认项

模块级待确认项已随详细设计拆分到 `doc/` 下，落地前需先确认并回写对应文档：

- **后端服务** → `doc/api/DESIGN-后端服务-v1.0.md`：AI 牧师模型默认接入 DeepSeek，并已支持后台维护多渠道接入（`model_channel` 表 + `API_SECRET` 加密托管渠道密钥，未配置渠道时回退环境变量，见该文档第 8 节；登录令牌统一采用 JWT、签名密钥同为 `API_SECRET`）与模型运行参数后台配置（`system_setting` 表 + `system_setting_log` 变更追溯，保存即生效、环境变量兜底，见该文档第 8 节；**计费口径已确认按 token**（2026-09-21 产品确认，用量采集待建设），用量归集粒度、自动故障转移、降级策略仍待确认；**告解内容留存已部分确认**：AI 陪谈会话的用户消息与 AI 回复均落 `pastor_message`（与真人会话同表同接口，见 `doc/api/DESIGN-真人牧师陪谈-v1.0.md` 第 7 节），**留存期限已确认：6 个月、超期归档**（2026-09-21 产品确认，归档任务待建设，AI 牧师各议题的最终产品口径统一见 `doc/DESIGN-AI牧师-产品说明-v1.0.md` 第 11 节）、支付与邮件服务、登录方式（已确认第三方 OAuth：Google / Facebook 与**邮箱 + 密码**并存、共用同一套令牌，见该文档第 8 节；账号合并、邮箱验证与找回密码等待定；**Facebook 凭证链路已确认**：iOS 用 Limited Login 的 idToken、Android / Web 用经典登录的访问令牌，后端分别走 JWKS 与 Graph `debug_token` 校验；**游客登录已确认**：以端侧设备标识作 `guest` 身份绑定、与第三方和邮箱密码共用同一套令牌，开关 `GUEST_LOGIN_ENABLED`，**游客账号能否升级为正式账号（绑定邮箱 / 第三方）仍待确认**，见 `doc/api/DESIGN-鉴权与用户-v1.0.md` 第 8.2 节）、真人志愿者接入、匹配降级、每日经文的生成质量与用量口径（生成结果不可用时的重试策略、模型调用成本归集）、管理后台接口路径与字段。
- **移动端** → `doc/app/DESIGN-移动端-v1.0.md`：~~是否复用 Demo 的 H5 作为 Web 端形态~~（**已确认为 PWA 发布形态**，用本工程 Flutter Web 产物而非 Demo，见 `doc/app/DESIGN-PWA发布-v1.0.md`；该文档的 5 项待确认项——端内安装引导、宽屏布局、Web 推送、`display` 模式、离线草稿暂存——仍待确认）、国际化、第三方路由 / 状态管理框架、离线缓存、推送方案、资源上传下发、应用标识与签名；`doc/app/DESIGN-iOS设计规范-v1.0.md` 第 15 节的 9 项 iOS 侧待确认项，以及后续确认的 3 项（**iPad 与横屏纳入目标形态**、列表项 / 状态徽标补 `Semantics`、新增绿色 / 琥珀色文字令牌）**均已确认并落地**，iOS 侧已无阻塞项（仅剩性别偏好等选择组的 `selected` 组语义、长页面朗读顺序优化待排期）。
- **管理后台** → `doc/web/DESIGN-管理后台-v1.0.md`：管理员登录方式、后台「体验对话」的用量与审计口径、采样参数是否需要牧师级覆盖（当前在「AI 牧师配置」页的「运行参数」弹窗全局维护、环境变量兜底，见该文档 3.6；接入渠道已支持牧师级绑定）、渠道密钥主密钥的托管与轮换、渠道故障切换、后端接口路径与字段（权限模型已确认采用独立的角色管理，见该文档 3.1）。
