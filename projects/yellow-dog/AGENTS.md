# AGENTS.md（yellow-dog）

本文件为本仓库（yellow-dog）内 AI 编码代理的工作约束。

**仓库边界**：本仓库是位于 `/data/ubtrobot/gitlab.ubtrobot.com/yellow-dog/` 的独立 git 仓库（`origin: git@github.com:guogeer-png/yellow-dog.git`，**外部 GitHub 托管，不属于 gitlab.ubtrobot.com 组织**）。所有 `git`、格式化、静态检查、测试命令都必须在本仓库目录内执行，不要在工作区根目录或其它仓库目录操作；也不要把本仓文件复制到其它仓库。

**2026-10-23 起 App 端是 git 子模块**：Flutter 客户端在 `app/flutter/`，是独立仓库 `git@github.com:guogeer-png/faceflip-ai-app.git` 的子模块挂载（`.gitmodules` 登记 `branch = main`；历史由 `git subtree split -P app/flutter` 抽出，167 个提交）。**在本仓里 `app/flutter` 只是一个 gitlink（commit 指针），不含文件内容**：端侧改动必须进子模块目录提交并推送到它自己的 origin，然后回到本仓把 gitlink 变动再提交一次；克隆本仓后要 `git submodule update --init --recursive` 才会拉出端侧代码。本仓自有内容：后台服务 `app/api/`、运营后台 `admin/`、App 壳 `app/shell/`、部署编排 `docker/` 与全部 `doc/` 文档。本文件里 `app/flutter/...` 的路径照常有效（子模块就在那个位置）。

## 项目定位与现状

yellow-dog 是一个 **C 端 App（Flutter） + Python 后台服务 + 管理后台** 的项目：

- **App 端（主体）**：`app/flutter/`，**git 子模块**（独立仓库 `git@github.com:guogeer-png/faceflip-ai-app.git`），Flutter 3.47.4 / Dart 3.13.3，**一套代码出 Web + iOS/Android**（Riverpod + go_router）。运行参数不在代码里写死，启动时加载：`api_base_url`、`res_base_url`、`channel`/`channel_id`、`privacy_url`、`terms_url`、`h5_version`。**端侧改动在子模块里做并单独推送**；接口契约变更要两侧同步（本仓 `app/api/` 的 schema/service + 子模块的 `lib/api/` 与 `lib/models/`）。
- **后台服务**：`app/api/`，Python 3.12 + FastAPI + MySQL 8，为 App 端提供业务接口。
- **管理后台**：`admin/`（`admin/api` + `admin/web`），面向运营与客服。
- **H5 端已于 2026-10-10 整体移除**（原 `app/h5/`，含现网 sourcemap 还原的 TS/React 源码）：App 端改由 Flutter 全量重写。历史源码只在 git 记录里可回溯，**参考基线用现网产物副本 `doc/project-handover/现网H5/`**，不要再把 `app/h5` 当真源去找行为依据。

### 官网与投放参数

- **品牌名：`FaceFlip AI`**（2026-10-09 由 Loveme AI 全量改名）。真源原为 H5 的 `APP_BRAND_NAME = "FaceFlip AI"`，H5 移除后 Flutter 侧沿用**同一取值**；页面标题、多语言文案与文档一律用它，**新增文案不得再出现 Loveme**。
- **本产品官网：`https://faceflip-ai.com/`**（2026-10-09 确定，取代 `loveme.ai` / `loveme.com`）。设置页官网入口与社区分享链接一律用它；域名解析已通，但线上响应仍为空，官网内容待上线。
- **改名范围（2026-10-09）**：代码内标识已全量 `loveme` → `faceflip`——密钥文件 `doc/faceflip-ai.pem`、部署脚本变量前缀 `FACEFLIP_*`、localStorage key `faceflip_onboarding_completed_v1`、部署目录 `~/faceflip-ai`、脚本目录 `docker/`；对外域名也已于同日统一为 `faceflip-ai.com`（`SettingsPage.tsx` 官网链接、`CommunityDetailPage.tsx` 分享链接）。**例外**：AWS 资源标识（IAM 用户 `loveme-ai`、access point `loveme-ai-test-ep`、`.env` 的 `S3_BUCKET`）与旧品牌名的历史叙述，不要顺手替换。
- **竞品参考站：`https://bellaai.me/`（Bella AI）**。现网 H5 产物（`doc/project-handover/现网H5/`）与当初的还原源码（原 `app/h5/src/`，已移除）都取自该站，是**产品形态与 UI 的参考基线（复刻对象）**，不是本产品域名。因此不要把 Bella AI 的品牌、域名、Telegram（`t.me/Bella_AI1`）写进我们自己的页面；`doc/project-handover/现网H5/README.md` 里"站点 bellaai.me"指的是**采样来源**。
- 官网有 Cloudflare 拦截，**直连必 403**（`web_fetch` 与 WSL 内 `curl` 都不行）。**WSL 环境下可用的抓取方式**：借 Windows 侧系统代理（注册表 `HKCU:\...\Internet Settings` 的 `ProxyServer=127.0.0.1:7897`），用 Windows 的 curl 取：

  ```bash
  /mnt/c/Windows/System32/curl.exe -sS -x http://127.0.0.1:7897 \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0.0.0 Safari/537.36" \
    "https://bellaai.me/" -o C:/Windows/Temp/bella.html
  ```

  产物在 WSL 里从 `/mnt/c/Windows/Temp/` 读。WSL 自身不出网（google/openai 均超时），**不要试图在 WSL 内直连**。
- **竞品是多域名轮换**：页面 `og:url` / 图标指向 `https://afetai.vip/`，投放域是 `bellaai.me`（两者同一套产物）。所以"官网域名"对竞品不等于品牌名，别把域名写进我们的品牌口径。
- 域名已收敛（2026-10-09）：`SettingsPage.tsx` 的 `OFFICIAL_WEBSITE_URL = "https://faceflip-ai.com"`（含设置项展示的 `detail`）与 `CommunityDetailPage.tsx` 的分享链接 `https://faceflip-ai.com/community/share/{id}` 均已落地。
- **投放链接形如**（取自竞品，参数口径可借鉴；内部资料勿外发）：

  ```
  https://bellaai.me/?channel_id=WBR21005&fbclid=xxx&sub_channel=AI-WM_Adst01&c=WM_Adst01
  ```

  | 参数 | 含义 | 本项目处理 |
  | --- | --- | --- |
  | `channel_id` | 渠道包（如 `WBR21005`） | 透传，最终由 `X-Client-Channel` 头上报后台 |
  | `sub_channel` | 子渠道（如 `AI-WM_Adst01`） | 透传 |
  | `c` | 投放 campaign 标记（如 `WM_Adst01`） | 透传 |
  | `fbclid` | Facebook 点击 ID | 透传，仅归因用 |

  `channel_id` / `sub_channel` / `c` 由投放侧下发，落到运营后台的**子渠道与像素**配置里做归因与上报（见 [`doc/project-handover/aigc-admin管理后台/补充页面/README.md`](doc/project-handover/aigc-admin管理后台/补充页面/README.md)）。**端侧只负责透传，不做归因计算**。
- **归因采集与落库（2026-10-14 落地）**：投放链接与 AppsFlyer 归因链接的参数由端侧**首触点**采集并持久化 —— `app/flutter/lib/core/attribution/`（`AttributionParams` 解析 + `AttributionStore` 落 localStorage 键 `yellowdog_attribution_v1`），随注册 / 登录和每个请求透传：请求头 `X-Client-{Channel,Sub-Channel,Campaign,Media-Source,Click-Id,Fbclid,Appsflyer-Id}`（`enable_client_headers` 开关，与 `X-Client-Channel` 同族）+ 注册 / 登录 body（camelCase，未开头时兜底）。后台在建号时**一次性**落 `users`（`channel` / `sub_channel` / `campaign` / `media_source` / `click_id` / `fbclid` / `appsflyer_id`，迁移 `0012_users_attribution`），**老账号登录不改写** —— 用户换条链接打开就把归属挪走，运营侧 ROI 会对不上。别名表（`channel_id` / `sub_channel` / `c` / `pid` / `af_clickid` / `af_sub1` / `af_id` ...）真源在 `AttributionParams._aliases` 与 `utils/attribution.py`，改一侧必须同步另一侧。单值上限 128 字符，超长截断（URL 参数不可信，别让它撑爆列或打挂登录）。
  - **运营台归因维度（2026-10-14）**：`运营后台 → AppsFlyer 归因` 页支持「渠道包 / 子渠道 / Campaign」三选一拆分（`GET /growth/appsflyer/daily?dimension=channel|sub_channel|campaign`），取值来自 `users.sub_channel` / `users.campaign`；这两个维度只统计**带归因标记的用户**（空值不入组），且广告消耗按渠道手工录入无法摊分，故花费与 ROI 记 0。镜像模型 `admin/api/.../models/app.py` 只声明后台用到的列，App 端加列后要同步加进来（当前：`sub_channel` / `campaign`）。
  - **移动端 AppsFlyer SDK 已接入（2026-10-15）**：依赖 `appsflyer_sdk`（AppsFlyer SDK 7 形态，`pub add` 在 pub 上解到标记为 latest 的 `7.0.2+2-rc1`），封装 `app/flutter/lib/core/attribution/appsflyer/`：`appsflyer_config.dart`（配置）/ `appsflyer_conversion.dart`（GCD → 归因参数）/ `appsflyer_service.dart`（条件导出，**Web 无原生 SDK，走空实现**）。**Dev Key `NKm4hfEj486BUavtMTx4p3` 写在 `AppsFlyerConfig.defaultDevKey`**，只能随包：移动端目前没有 runtime config 拉取通道（`RuntimeConfigHttp` 只有 Web 实现），runtime config 有 `appsflyer_dev_key` / `appsflyer_ios_app_id` 时才覆盖。**iOS 侧还没法归因**：Apple App ID（`AppsFlyerConfig.iosAppId`）未提供，缺它 LAUNCH 会被拒，TODO 上架后补。**启动顺序必须按 SDK 7 的口径**：`enableDebug` → `init(devKey:appId:)` → `getAppsFlyerUID()` → `registerConversionListener` → `registerSessionReadyListener`（回调里才 `start()`），顺序错了丢会话或丢转化数据。数据两批到——AppsFlyer ID 同步可取，媒体源 / campaign 在 `start()` 之后异步回来（晚于首屏请求），所以请求头一律读 `AttributionStore.current`（`ClientMeta.attributionStore`），**不要拿 provider 快照**：注册那一刻转化数据还没到就漏了归属，而后台只在建号时写一次、补不回来。登录 / 注册后调 `setCustomerUserId(userId)` 把账号维度交给 AF（建号时另记 `af_complete_registration`）。Web 端照旧只认链接参数。**未做**：ATT / IDFA 授权（要先确定 `NSUserTrackingUsageDescription` 与要不要 Podfile 的 `$AppsFlyerStrictMode`）；Android 的 `AD_ID` 权限由 SDK manifest 自动合并，主 manifest 只加了 `INTERNET` / `ACCESS_NETWORK_STATE`（模板原先只有 debug/profile manifest 带 INTERNET，release 包会没网）。
  - **H5 也要投 AF，但走的是「网页侧」而不是 SDK（2026-10-15）**：产品形态之一是**塞进别人 App 的 WebView**，那里面没有原生 SDK，`AppsFlyerService` 在 Web 上是空实现，所以：①**App 端用户归属根本不靠 AF**——一直靠落地 URL 上的投放参数（`AttributionParams.fromCurrentUri` → `AttributionStore` → 注册/请求头），只要投放链接是 OneLink 且把归因参数带到了落地 URL，这条链路就成立；②想让 AF 后台看到这批网页会话，要挂 AF 的 **Smart Script** 网页 JS，代码在 `lib/core/attribution/appsflyer/appsflyer_web_sdk.dart`——**脚本地址必须服务端下发**（runtime config 的 `appsflyer_smart_script_url`，两种 key 写法都认），写死在代码里不行：官方 support 站不可抓（403）、`websdk.appsflyer.com` 是私有桶，猜出来的路径一律 403，值只能从 **AF 后台 » Smart Script 配置页**生成。发布链路已通：`docker/deploy.sh` 从服务器 `.env` 的 `APPSFLYER_SMART_SCRIPT_URL` 写进 `runtime-config.json`，本地 `tool/dev.sh --af-smart-script <url>`；字段为空 = 不挂网页脚本（不影响其余功能）。③**H5 拿不到 af_id，壳能**：WebView 里没有设备 ID / IDFA / GAID，也没有 install referrer，所以 App 壳形态的归因**只能靠壳**——壳装原生 AF SDK，经 Bridge 的 `prepareLoginAttribution` 把数据给 H5（这条链路 2026-10-22 打通，见下一条）。
  - **App 壳 AF 接入 + H5 打包（2026-10-22 打通，完整方案 [`doc/DESIGN-App壳-AF接入与H5打包-v1.0.md`](doc/DESIGN-App壳-AF接入与H5打包-v1.0.md)）**：①端侧新增 `app/flutter/lib/core/attribution/shell_attribution.dart`，把壳给的 `afId` / `clickId` / `afAttributionJson`（AF 转化数据，对象或 JSON 串）/ `installReferrer`（按 query 解析）转成同一套 `AttributionParams`，在 `attributionStoreProvider` 里按首触点合并进 `AttributionStore`（优先序：直接字段 > 转化数据 > referrer）。走的是底层 `bridge.call('prepareLoginAttribution', timeout: 3s)` 而**不是强类型封装**（那是 12s，第三方壳没实现时会硬等，拖住启动）；非 `isNative` 直接跳过。②runtime config 新增「壳下发」一级：`RuntimeConfig.load(shellConfig:)`，取值顺序 `?cfg=` → 缓存 → **壳下发（`getInfo.runtimeConfig`）** → 同目录 `runtime-config.json`；打包进 App 的 H5 必须靠它（file 源 fetch 被同源策略挡，同目录那份取不到）。③打包脚本 `app/flutter/tool/build_h5_bundle.sh`（`--api-base` / `--channel` / `--zip` / `--no-build` / `--config`），产出自包含目录 + `h5-bundle.json`。**两个坑**：`--base-href` 默认 **`/assets/h5/`**（必须与壳的虚拟域路径逐字一致，否则 `main.dart.js` 解析到站点根、整站 404；上 CDN 时才改 `/`）；壳里别拿 `file://` + WebView 默认设置硬开——Android 用 `WebViewAssetLoader`、iOS 用 `WKURLSchemeHandler` 把 assets 映射成虚拟域，否则 `canvaskit.wasm` 与 `assets/` 全拉不到，表现是白屏。④**壳工程已在 `app/shell/` 落地并跑通**（详见 `app/shell/README.md`）：Android Kotlin（`MainActivity` / `NativeBridge` / `ShellApp`+AF 7.x / `InstallReferrerProbe`，入口 `https://appassets.androidplatform.net/assets/h5/index.html`）+ iOS Swift/XcodeGen（`ShellViewController` / `NativeBridge*` / `H5SchemeHandler`，入口 `yellowdog://h5/assets/h5/index.html`），`app/shell/tool/build_shell.sh` 一键打 H5 → 灌两端 →（`--assemble`）出 APK。**部署侧必须同步**：后端 `CORS_ORIGINS` 要含 `https://appassets.androidplatform.net` 与 `yellowdog://h5`，`allow_headers` 要含 `X-Client-Appsflyer-Id` 等归因头（`app/api/tests/test_cors.py` 钉住），否则壳里页面能开但接口全被预检拦。**设备要求 WebView ≥ 87**：Android 10 + WebView 83 会报 `flutter_bootstrap.js ... Unexpected token '='`。⑤未做：离线包热更新（比对 `h5-bundle.json` 拉增量）、iOS 真机验证、`appleAppID` / ATT、壳内推送（`registerPush` 恒 false）。
  - **包名（2026-10-15 统一为 `com.faceflip.ai`）**：`applicationId` 与 iOS `PRODUCT_BUNDLE_IDENTIFIER` 都要改，连同 `android/app/src/main/kotlin/com/faceflip/ai/MainActivity.kt` 的 `package`（原分别是 `com.faceflip.yellowdog_app` / `com.faceflip.yellowdogApp`）——错一处就是 Android 装不上、iOS 被判成另一个 App。App **展示名仍是 `yellowdog_app`**（`android:label` / `CFBundleName` / `web/manifest.json`），本次没改，要改另说。
  - **`ios/Podfile` 是 2026-10-15 补的**：此前仓库里没有它，`pod install` 从没跑过，iOS 工程一个原生插件都链接不进来（不止 AppsFlyer）。内容是 Flutter 3.47 模板 + `platform :ios, '15.0'`。**首次 `pod install` 前不要奇怪插件为什么没生效**。要用 AppsFlyer 的 Strict mode（不带 IDFA 的二进制）在 Podfile 里放开 `$AppsFlyerStrictMode` 再重装，不能在 Dart 侧切。

### 已确认的重构方针（2026-10-08）

1. ~~H5 源码目录 `app/h5/`~~（**2026-10-10 废止**）：当时由现网产物 sourcemap 还原的 TS/React 源码直接作为主体代码入库（授权口径：复用）。**该目录已整体移除**；现网产物完整副本仍在 `doc/project-handover/现网H5/`。
2. **Flutter 全量重写（2026-10-10 取代原"复用式重构"）**：以 `app/flutter/` 为唯一主体迭代，**不要另起一套 API 层或页面骨架**；原先「按还原源码补齐 sourcemap 缺口」的口径随 H5 移除作废。
3. **接口全量替换**：现网 `/v1`、`/v2`、`/v3` 接口全部由新 FastAPI 后台重写，不保留旧契约。契约基线见 `doc/API-现网H5接口契约-v1.0.md`。
4. **全量覆盖**：所有页面域（首页信息流、模板、任务、社区浏览、创作者中心、草稿与测试、钱包/充值、邀请返利、我的/设置/法务）全部重构，范围清单见契约文档 §7。
5. **新手引导（Onboarding）**（2026-10-08）：首次进入根路由 `/` 且未完成引导时，自动跳 `/#/onboarding`；引导页展示品牌、核心文案与三步用法，点击「进入 {brand}」后写 `localStorage` 标记；设置页增加「新手引导」入口可重新观看。

  - **已落地（2026-10-11，Flutter）**：页面 `lib/pages/onboarding/onboarding_page.dart`，路由常量 `kOnboardingPath = '/onboarding'`，标记键 `faceflip_onboarding_completed_v1`（`lib/state/onboarding.dart`）。**时序要点**：标记必须在启动阶段（`main.dart` 的 `BootGate`）从 KvStore 同步进 `onboardingCompletedProvider`，路由重定向是同步读它的（`resolveTopRedirect`），晚一步就会先闪一下首页再跳引导页；provider 默认 `true`，避免存储未就绪时误判成首次进入。「进入」与「跳过」都会写标记，否则下次进来还会被重定向。设置页入口带 `?from=settings`，看完 pop 回设置页而不是跳首页。

### 测试服部署（2026-10-08 已上线）

- **机器**：`ubuntu@98.93.129.214`（**2026-10-25 实例重启后公网 IP 变更**；未绑弹性 IP，再变需同步改），密钥 `doc/faceflip-ai.pem`（须 600）。部署目录 `~/faceflip-ai`（即 `/home/ubuntu/faceflip-ai`：`data/mysql/` + `docker-compose.yml` + `nginx.conf` + `.env`；**不含 api 源码**，镜像从 ACR 拉取）。
- **入口（2026-10-11 改为域名，全部经 AWS ALB）**：TLS 在 ALB 上终止，服务器只听 http:8080（机器上无证书、安全组不开放 80/443，只需放行 ALB → 8080）。ALB 健康检查路径 `/alb-health`（nginx 直接返回 200，不打后端）。

  | 环境 | 页面 | 接口（App 端 + 运营后台） |
  | --- | --- | --- |
  | 测试服 | `https://test-platform.faceflip-ai.com` | `https://test-api.faceflip-ai.com` |
  | 正式服 | `https://platform.faceflip-ai.com` | `https://api.faceflip-ai.com` |

  路径不变：App 端 `/app/api/`、运营后台 `/admin/api/`。**platform 域的站根 `/` 就是运营后台**（2026-10-11 改），`/admin/*` 保留 301 跳站根；Flutter Web（App 端页面）暂不挂这个域，产物仍同步到宿主机 `./web` 留作回滚，将来要挂需 `--base-href` 重新构建。
  **当前状态（2026-10-11 实测）**：ALB 链路已通——忽略证书校验时两端点全 200，CORS 预检放行 `https://test-platform.faceflip-ai.com`，admin 登录与 App 端设备登录端到端均返回 token；**唯一阻断项是 ACM 证书的 SAN 只有 `DNS:faceflip-ai.com`，不覆盖子域**，浏览器会报证书名不匹配。需在 ACM 重签（含 `*.faceflip-ai.com`）并换到 ALB 443 监听器，详见 `docker/README.md` 的「ALB / DNS 配置清单」第 1 条。
- **nginx 同时监听 80 与 8080**（2026-10-11）：80 给 ALB 目标组用标准 HTTP 端口，8080 保留历史端口；两个端口内容完全一致，目标组端口填哪个都行。
- **跨域（域名拆分带来的硬约束）**：页面在 platform 域（App 端 H5 在 `test-h5` 域）、接口在 api 域，**App 端与运营后台都是跨域调用**，两个后端的 `CORS_ORIGINS` 必须含页面域名，否则浏览器预检 OPTIONS 就失败（`deploy.sh` 会自动把本次的 `PUBLIC_WEB_BASE_URL` 追加进服务器 `.env` 的 `CORS_ORIGINS`）。`app/api` 的 CORS 由 `src/yellowdog/app.py` 注册（`Settings.cors_origins`，逗号分隔）；运营后台沿用 `admin/api` 原有的 `cors_origins`。`app/api` 的 CORS 由 `src/yellowdog/app.py` 注册（`Settings.cors_origins`）；运营后台沿用 `admin/api` 原有的 `cors_origins`。
- **Flutter Web 整站进对象存储（2026-10-13 起）**：正式服与测试服**共用同一个 S3 桶**（`faceflip-ai-prod`），按前缀区分——测试服 Flutter Web 产物落在 **`test/h5/`**，经 `https://test-h5.faceflip-ai.com` 访问（DNS CNAME 到 CloudFront 分发 `E37GJ2NYXWZ64K`，OAC 回源，**服务器不再提供 H5**，`nginx.conf` 里那个 test-h5 server 块已删）。`deploy.sh` 流程：`flutter build web --release` → 生成 `runtime-config.json`（参数取服务器 `.env`）→ `s3_sync.py` 推整个目录到前缀 → `cdn_invalidate.py` 刷入口与不带 hash 的文件；可用 `H5_BUCKET_PREFIX` / `H5_SITE_URL` / `H5_BUCKET_ENV_FILE`（上传凭据，默认 `app/api/.env.production`）/ `H5_CDN_ENV_FILE`（分发 ID，默认 `app/api/.env.test`）覆盖，见 `docker/README.md`「Flutter Web：整站进对象存储」。同源后不再有资源跨域问题，代价是 `main.dart.js` 这类不带 hash 的文件必须靠失效更新；站根 `/` 需要分发配 `DefaultRootObject` 或用 `--root-object` 写 `test/h5/` 键兜底，SPA 子路由仍依赖 CloudFront 的 403/404 → `/index.html` 自定义错误响应。
- **发布**：仓库根 `docker/deploy.sh`（本机构建并推送镜像到阿里云 ACR → rsync 编排文件 → 远端 `compose pull && up -d` → 健康检查）。**镜像不在服务器上构建，也不同步 api 源码**；`--no-image` 跳过镜像构建、`--tag` 指定 tag、`--status` 只看远端状态。`docker/s3_sync.py` 是通用的静态产物上传工具（`--dist` 指定目录、`--prefix` 指定桶前缀、`--index-as-root` 写站根键），现为 H5 发布链路的一环。tag 口径：测试服 `latest`、正式服 `prod-YYYYMMDD-N`。拉取私有镜像前服务器需 `sudo docker login registry.cn-hangzhou.aliyuncs.com`。细节见 `docker/README.md`。
- **架构**：nginx:8080 提供 `/app/api/` 反代到 api:8000，后端依赖 mysql:3306 与 redis:6379；API 容器启动即 `alembic upgrade head`。**服务器上可能还残留历史 H5 产物目录（`~/faceflip-ai/h5/`），属于远端存量，清理前先确认**。
- **表格操作列统一走 `RowActions`（2026-10-12）**：组件 `admin/web/src/components/RowActions.tsx`，**最多平铺 2 个动作，其余折叠进「更多」下拉**（`maxInline` 可覆盖）。页面只负责把「当前账号能做的动作」排成 `RowAction[]`（没权限的不占位，也就不会把后面的挤进折叠区），平铺 / 折叠 / 二次确认都交给组件。`variant="small"` 给原本用小号按钮的表格，`primary` 标出行主操作。⚠️ **折叠区的二次确认必须用 `modal.confirm`，不能挂 `Popconfirm`**——菜单点完即卸载，气泡跟着消失，表现是点了没反应。
- **运营后台权限走完整 RBAC（2026-10-11）**：权限点（内置常量 `admin/api/src/yellowdog_admin/permissions.py`）+ 可自定义角色（`admin_roles` / `admin_role_permissions`），账号靠 `admin_users.role_id` 挂角色；`super_admin` 恒等于全部权限。接口用 `Depends(require_permissions("xxx"))` 校验，缺权限回 `30004`。**新增菜单/接口必须先登记权限点**，否则菜单不显示、接口 403。前端菜单按 `GET /auth/me` 的 `permissions` 过滤，映射表在 `admin/web/src/rbac.ts`。
- **权限点是「菜单项 => 功能」两级（2026-10-28）**：`PermissionDef` 的 `menu_key` / `menu_name` 是它归属的**左侧菜单项**（库里是 `admin_permissions.menu_key/menu_name`，迁移 `0014` 由 `group_*` 改名而来），`name` 是菜单项下的具体功能。角色权限页（`admin/web/src/pages/RolesPage.tsx`）按它渲染成可勾选的树——父节点 key 是 `menu:<menuKey>`（勾父=整组），保存前由 `rbac.ts` 的 `toPermissionCodes()` 把父节点过滤掉，只存权限点 code；分组逻辑是 `buildPermissionMenus()`。**菜单改名要同时改 `permissions.py` 与 `admin/web/src/components/AppLayout.tsx` 的 `MENU_GROUPS`**，否则树上的名字和侧边栏对不上。
- **admin-api 只允许 GET + POST**（CORS 也只放行这三种）：更新/删除统一写成 `POST /xxx/{id}/update` 与 `POST /xxx/{id}/delete`，不要新增 PUT/DELETE 路由。
- **所有签发令牌的入口都必须带 `permissions`**（`/auth/login` 与 `/auth/setup` 两处）：前端菜单按 `permissions` 过滤，漏给就是空菜单（`initialize_admin` 曾漏过一次，修在 `issue_login_out(admin, await load_permissions(...))`）。
- **MySQL 建表务必给时间列默认值**：`created_at` / `updated_at` 若只写 `NOT NULL` 不给 `server_default`，严格模式下插入会报 `Field 'created_at' doesn't have a default value`（`0004` 迁移就是补这个坑）。
- **SQLite 主键必须写 variant，迁移里也要写**：`models/base.py` 的 `pk()` 已经处理（`BigInteger().with_variant(Integer, "sqlite")`），但**迁移文件里的 `sa.BigInteger()` 不会自动带上**——SQLite 只有 `INTEGER PRIMARY KEY` 才自增，漏了就报 `NOT NULL constraint failed: xxx.id`。新建表一律用 `sa.BigInteger().with_variant(sa.Integer(), "sqlite")`。
  - **2026-10-12 踩过一次**：`0001_init` 漏了 variant，SQLite 兜底库（`--admin-sqlite`）/ 测试库的 `admin_users` / `admin_audit_logs` 插不进数据；又赶巧 `auth_service.initialize_admin` 把所有 `IntegrityError` 都翻成 `30013「管理员已存在」`，表现为**「bootstrap-status=false，却说不能重复初始化」，第一个账号永远建不出来**。两处都已修：①迁移 `0008_sqlite_pk_integer`（SQLite 下把这两张表的 id 改成 INTEGER，MySQL 方言直接返回）+ `0001` 补 variant；②`initialize_admin` 只在「rollback 后确实已建号」时才报 30013，其它完整性错误照实上抛。**推论：不要把业务错误码当成 catch-all 兜底**，否则真正的故障会被自己的文案盖住。
- **数据库环境矩阵（2026-10-12）**：**dev / 测试服 / 正式服一律 MySQL 8，SQLite 只给 pytest 用**。`tool/dev.sh --admin-sqlite`（即 `admin/api/.env` 里 `DB_DIALECT=sqlite`）是本机没 MySQL 时的兜底，**不是标准 dev 配置**，别拿它当本地环境结论。本地 dev 连本机 MySQL 容器 `yellowdog-dev-mysql`（端口与凭据跟 `app/api/.env.development`，当前 `DB_PORT=13316`）：后台库 `yellowdog_admin` + App 端库 `yellowdog` 同实例同账号，镜像模型靠 `APP_DB_NAME` 走 `` `yellowdog`.`users` `` 跨库。换库后表由服务启动自动迁移建（App 端表归 `app/api`），再 `cd admin/api && uv run python tool/seed_app_data.py` 灌联调数据，最后走登录页初始化管理员（换库 = 换库，账号不跟着迁）。
- **admin/api 日志落盘**：`logs/YYYYMM/api.log`，按天滚动（`api.log.YYYY-MM-DD`），跨月自动进新月份目录；开关 `LOG_TO_FILE`、目录 `LOG_DIR`、保留份数 `LOG_FILE_BACKUP_COUNT`。⚠️ `setup_logging()` 会在迁移后**再调一次**（alembic 的 `fileConfig` 会把 root 级别压回 WARNING），所以文件 handler 必须幂等，不能重复挂。
- **admin/api 启动自动迁移**：表结构由 lifespan 里的 `run_pending_migrations()` 带到 head，容器 CMD 只起 uvicorn；`DB_AUTO_MIGRATE=0` 可关。⚠️ 跳过条件只看「`APP_ENV=test` **且** `DB_DIALECT=sqlite`」——测试服容器的 `APP_ENV` 就是 `test`，单独按 `app_env` 判断会把线上迁移跳过。
- **运营后台首次初始化（2026-10-11）**：不再预置管理员，服务启动也不自动建号。库内无账号时登录页显示「初始化管理员账号」引导（账号 / 姓名 / 密码 / 确认密码），提交后创建 `super_admin` 并自动登录。接口：`GET /admin/api/v1/auth/bootstrap-status`（匿名）判断 `initialized`，`POST .../auth/setup` 创建；已初始化时重复调用返回 `30013`。`BOOTSTRAP_ADMIN_*` 只留给本地联调与测试夹具。详见 `admin/README.md`。

### 现状约束（改动前必读）

- **前端主体是 `app/flutter/`**（一套代码出 Web / iOS / Android）。原 `app/h5/` 已于 2026-10-10 移除，不要再照其中的实现找行为依据：历史源码从 git 记录回溯，UI/产品形态的参考基线看 `doc/project-handover/现网H5/` 的产物。
- 从产物文件名逆向出的现有页面域（**推断值，待产品确认**）：落地页 `LandingHomePage`、`Trending`、`FeedViewer`、模板 `NewTemplates` / `TemplateDetail`、社区 `CommunityLibrary` / `CommunityStudio` / `CommunityDetail` / `CommunityDraftEditor` / `CommunityCoverPicker` / `CommunityEarnings` / `CommunityInsights` / `CommunityRules` / `CommunityWithdraw` / `CommunityFeedback`、钱包 `WalletRecord` / `RechargeRecord` / `Withdraw`、推广 `Referral` / `ReferralRules`、`TaskStatus`、`Settings`、`Legal`、`Feedback`、`Dance`、`DebugPanel`。**这是梳理业务范围的第一手依据，但不是最终需求**。

### 已确认的邮箱注册方案（2026-10-08）

参考竞品（Bella AI）的账号形态后敲定：

1. **注册方式：邮箱 + 密码**。不发验证码、不做邮箱真实性校验，注册成功即可用。
2. **与匿名账号打通**：注册时携带 `devId`，把该设备已有的匿名账号（`users.dev_id`）**升级为邮箱账号**，保留金币、任务与历史数据；**不为同一设备再建一个独立账号**。
3. **不接入邮件服务**：本期不发任何邮件（无验证码、无欢迎信、无找回密码邮件）。后续要加邮箱验证/找回密码，单独立项并新增邮件通道配置。
4. **改动范围：后端 + App 端页面**（`app/api` 接口与 Alembic 迁移 + App 端注册 / 登录弹窗；弹窗在 Flutter 侧尚未迁移）。

落地约束（实现时必须遵守）：

- 密码**禁止明文落库**，只存加盐哈希（bcrypt / argon2id）；`password` 只进不出，任何响应与日志都不得出现。
- 邮箱在 `users` 上唯一（大小写归一后唯一），重复注册走冲突语义，错误码必须登记到 `app/api/src/yellowdog/errors.py`。
- 注册接口匿名可调用，返回与 `POST /auth/login` 同构的 `TokenResponse`（`accessToken` / `refreshToken` / `userId`）。
- schema 变更**必须走 Alembic 迁移**，禁止 `create_all`。

已落地：`POST /app/api/v1/auth/register`、`POST /app/api/v1/auth/login/email`（`api/auth.py`，逻辑在 `services/auth_service.py`，密码哈希在 `security.py`，错误码 `30103`~`30105`），迁移 `migrations/versions/0002_users_email_registration.py`；Flutter 侧登录弹窗（`pages/auth/auth_dialog.dart`）与接口层（`api/auth_api.dart`）已打通，**只调 `/auth/login/email`**。

⚠️ **认证接口必须自己判业务码（2026-10-11 修过的坑）**：后端是「HTTP 200 + 业务码」的约定，密码错（`30104`）也是 HTTP 200，而 `ApiClient.request()` 只在 HTTP 非 2xx 时抛 `ApiError`。所以 `AuthApi._session()` 里判 `code != 0 || accessToken.isEmpty` 就抛错——漏掉这一步时，登录失败会被当成成功：空 token 存进本地、邮箱还被标成已绑定，表现就是「随便输密码都能登录」。回归用例在 `app/flutter/test/auth_api_test.dart`。

**登录即注册的单入口（2026-10-11）**：`/v1/auth/login/email` 接受可选 `channel`，邮箱不存在时走 `_create_email_user()` 建号（与 `/auth/register` 共用），响应模型是 `EmailRegisterResponse`（`bonusCoins` > 0 表示本次建号）。建号时**昵称留空**（2026-10-11 起不再随机生成，`utils/nickname.py` 已删），App 端 Me 页显示占位符 `-`，由用户自己在「修改昵称」里填。**密码最短 6 位**（2026-10-11 对齐竞品），只能在服务层校验（`security.PASSWORD_MIN_BYTES`）——登录入口的 schema 不能写死最短长度，否则老账号的短密码登录会被 422 拦掉；`/auth/register` 的 schema 已是 `min_length=6`，Flutter 弹窗同步改为 `length < 6`。

**H5 登录 / 注册（2026-10-09，参考竞品 Sign in 形态，居中弹窗）**：

- **登录弹窗形态（口径保留，Flutter 侧待迁移）**：**居中弹窗**（`AppOverlay` + `.auth-dialog-scrim`），登录 / 注册两种模式在弹窗内互切；错误码 `30103` 已注册 / `30104` 邮箱或密码错误 / `30105` 设备已绑其它账号各自映射到文案；注册奖励 `bonusCoins > 0` 时弹 toast 并刷新金币。
- 入口都是**弹窗、不跳路由**：设置页「邮箱注册」「邮箱登录」、「我的」页未登录提示条（`meLoginRequiredHint`）。
- `#/login`、`#/register` 路由保留为 deep-link 薄壳（渲染同一个 `AuthDialog`，关闭即回上一页）。
- **登录态标记**：注册 / 登录成功后写 `glam_login_mail` + `glam_login_method=mail_password`（复用竞品键，与 `utils/token.ts` 的 `clearAuth` 配套，退出登录即清）。判定函数 `utils/emailAccount.getBoundEmail()`。
- **「未登录」= 未绑定邮箱**。设备匿名登录（有 token）不算已登录：MePage 顶栏金币 `showBalance={emailLoggedIn}`，未登录时顶部显示提示条；MePage 监听 `AUTH_TOKEN_CHANGED_EVENT` 同步登录态（tab 常驻不重挂载也能刷新）。
- **退出登录（2026-10-11 落地，Flutter `pages/me/settings_page.dart` 的 `_signOut`）**：只在已绑邮箱时显示「Log out」入口，二次确认后清 `TokenStore.clear()`（token/userId）+ `EmailAccountStore.clear()`（`glam_login_mail` / `glam_login_method`），再 invalidate `boundEmail` / `currentUserId` / `userProfile` / `goldBalance` / `creationList` / `freeformRecent`。**退出后就是未登录**（没有匿名会话可退，也不再有 deviceId 轮换）。
- 登录接口契约只收 `email` / `password` / `channel`（匿名账号下线后不再有 `devId`）。
- 样式坑：`official.css` 在 `global.css` 之后加载，会覆盖同名规则。`.modal-scrim` 是 `align-items: flex-end` 的底部弹层，居中弹窗必须用独立的 `.auth-dialog-scrim`，不能复用它。

#### 竞品实测口径（2026-10-08 抓 bellaai.me 产物，非猜测）

抓的是首页 `index.html` + 全量 108 个 `assets/*.js` 分包，一手证据：

- **竞品没有独立注册接口**：全站只有 `POST /v1/mail/login`（另有 `/v1/login` 设备登录、`/v1/refresh`）。**注册即"登录时自动建号"**——`LoginView` 文案 `login.autoRegisterHint`：`"New here? Enter your email and password, and we'll create a new account automatically."` 页面本身就是 `login.title "Sign in"` + `/` + `login.registerLabel "Register"` 一个页面两种说法。
- **请求体**：`{devId, channel, version:"1.1.0", mail, password}`——字段名是 **`mail` 不是 `email`**（`auth-BZnWMe9x.js` 的 `mailPasswordLogin`），且是 raw fetch、不走统一 request 层。
- **校验**：邮箱 `trim().toLowerCase()` 后按 `@` 分段校验（与我方归一化一致）；密码**最小 6 位**（`login.passwordRule` / `passwordTooShort`，前端 `length < 6` 拦截）——**我方已于 2026-10-11 对齐为 6 位**（此前 8 位）。
- **并存验证码模式**：i18n 里有 `vcode` / `vcodePlaceholder` / `subtitle"（…僅需電子郵件驗證碼）"`，但**前端无任何发码接口**（无 `/v1/mail/code`），判断是灰度中的另一套流程或已下线文案残留。
- **登录态与埋点**：`localStorage` 键 `glam_login_mail` / `glam_login_method`（值 `mail_password` / `google`）/`glam_login_source`；另有未登录拦截浮层（`loginOverlayState`）、会话恢复（`login.sessionTitle` 等）、Google 登录并存。
- **注册激励**：`login.firstRegisterBonus`「首次注册送 2 金币」+ `inviteRegistrationReward` 邀请注册奖励（我方钱包/返利域未做，待产品定）。

结论：~~2026-10-08 曾决定保留"注册 / 邮箱登录两个接口"的差异~~——**2026-10-11 改为对齐竞品的单入口口径**：`POST /v1/auth/login/email` 在邮箱不存在时**自动注册**（可选带 `devId` 升级该设备的匿名账号并发注册奖励，响应多一个 `bonusCoins`；老账号登录恒为 0）。`/v1/auth/register` 保留（向后兼容、仍要求邮箱未被占用）。Flutter 侧弹窗已合并为单一表单（无注册模式、无确认密码），密码统一最短 8 位。

#### 金币域与首登奖励（2026-10-08 落地）

- **表**：`user_wallets`（`user_id` 唯一 + `gold_balance` 余额快照）、`user_gold_ledgers`（流水台账，`amount` 正入账负扣减 + `balance_after`）。迁移 `migrations/versions/0003_user_wallet_and_gold_ledger.py`。
- **唯一入账入口** `services/wallet_service.grant()`：余额与流水**同一事务**写，行锁（`with_for_update`，SQLite 下自动忽略）；`(user_id, biz_type, biz_id)` 唯一约束保证**同一笔业务只入账一次**（幂等，重复调用返回 0）。
- **首登奖励**：邮箱注册成功（含匿名账号升级）时按 **`REGISTER_BONUS_COINS`** 发一次，`biz_type="register_bonus"`、`biz_id=user_id`。**2026-10-11 起默认关闭（=0，注册不送金币）**，配置项保留，填正数即恢复发放。匿名设备登录**不发**。
- **接口**：`GET /app/api/v1/users/{userid}/gold`（`balance`）、`GET .../gold/trans`（`list[]{id,type,amount,create_ts}` + `nextPageToken`），对齐现网契约 §2；**只允许查自己的钱包**（路径 userid ≠ 令牌 user_id → `30007 FORBIDDEN`）。
- 对外 `type` 仍用现网数字枚举（H5 侧 `Number(item.type)`），库内存可读 `biz_type` 字符串，映射表 `wallet_service.GOLD_BIZ_TYPE_CODES`（新增业务类型时两处一起加）。
- **基础定价全部后台可配置（2026-10-24 起；2026-11-02 简化为 5 项）**：所有基础金币价收拢进 App 端表 **`pricing_configs`**（单行 `config_key='pricing'`，迁移 `0033` 播种、`0038` 删掉并入项），运营在**后台「定价配置」页**（`/pricing-config`，权限 `pricing:view` / `pricing:edit`，接口 `GET/POST /admin/api/v1/pricing-config`）改完立即生效。
  - **App 端现查、不做缓存**：`app/api/src/yellowdog/services/pricing_config.py` 的 `load(session)` 每次都读库（口径同 `freeform_configs` / `payment_channels`），所以**改完不用重启服务**；库里没有配置行时回落到 `models/pricing_config.py` 的 `DEFAULT_*`——**那些常量只是兜底，不是真源**，改线上价格一律走后台。
  - **5 项（每项同时管模板与自由创作，2026-11-02 简化口径）**：`freeform_image_gold_{480p,720p}`＝**创作生图 480P/720P**（所有已入库与未入库的图片模板 + 自由创作生图，默认 2 / 3）、`video_gold_per_second{,_720}`＝**模板视频每秒价 480P/720P**（所有视频模板 + 自由创作视频，展示与扣费都是 `时长 × 每秒价` **下单时现算**，默认 2 / 4）、`register_bonus_coins`（注册奖励，默认 1）。已删除：`template_image_gold`（并入创作生图两档价）与 `freeform_video_gold_{5s,10s}_{480p,720p}`（并入每秒价 × 时长），迁移 `0038` 落库删列。
  - **展示与扣费共用同一处取值**：模板链路是展示侧 `content_service._to_card`/`_to_detail`、`community_service._to_card` 与扣费侧 `task_service._gold_for_user_params`、`community_service.use_template` 都现读配置现算；自由创作是 `freeform_service` 的档位表与 `_gold_for_*`（`Pricing.image_gold` / `video_gold`）。端侧档位价全部由后端下发，Flutter 源码里没有硬编码兜底。
  - ⚠️ **无时长模板的回落**：舞蹈等 `duration_seconds=0` 的视频模板算不出每秒价，回落模板库维护的 `consumed_gold*`（同步不覆盖它）；任务结果转视频（`animate_task`）也是「库价优先、缺了现算」。
  - ⚠️ 模板同步仍会把 `时长 × 每秒价` 写进 `templates.consumed_gold*`，但这只是**快照/对账用**，展示与扣费不读它——改每秒价对所有已入库模板立即生效。
  - 副作用：库价为 0 的免费图片模板也会按创作生图档位价收费；注册奖励默认 1 金币，填 0 即停发。

#### 用户 ID 发号：洗牌随机池（2026-11-01）

对外 `user_id`（注册 / 登录响应的 `userId`、`GET /users/{userid}/profile` 的 `userid`、社区作者的 `authorUserId`）**不能直接暴露自增主键**——从 1 开始连号，注册量一眼看穿、还能挨个枚举遍历，正式服尤其不合适。现在是「**一批连续自增号段 → 洗牌进池 → 每次随机取一个**」：

- **两张表**（迁移 `app/api/migrations/versions/0035_user_id_pool.py`）：`user_id_sequences`（发号游标，单行 `seq_key='user'`，`last_id` 记录号段已申请到哪个数）与 `user_id_pool`（待发候选，一行一个，**发出即删除**）。游标初值由迁移写成当时的 `MAX(users.id)`，历史自增号一次性跳过。
- **发号入口** `services/user_id_service.take_user_id(session)`：池空才申请新号段（补池前 `with_for_update()` 锁游标行，避免两批号段重叠），号段用**系统熵**洗牌后整批入库；每次从池里抽样几十个候选再随机取一个，`DELETE` 的 `rowcount` 为 0（被并发抢走）就换一个重试，最多 8 次。
- **取号不单独提交**：与建号同事务（`auth_service._create_email_user` 里 `User(id=...)`），注册失败回滚，号回到池里——不漏号、不重号。默认 `USER_ID_START=100000`（**至少 6 位数**）、`USER_ID_BATCH_SIZE=10000`（一次取 1W 个）。
- ⚠️ 同一段号相邻两次发放的数值可能差很远：**不要用 `user_id` 排序推断注册顺序**，也别再假设账号 ID 递增（`ORDER BY id` 判新用户这类写法要改）。
- ⚠️ SQLite（pytest）会静默忽略 `FOR UPDATE`，**行锁语义单测覆盖不到**：并发正确性只能在 MySQL（本机 dev / 服务器）上验证，别以为 pytest 绿了并发就没问题。

#### 充值支付：OXPay 代收渠道（2026-10-15 接入测试服）

第三方渠道是**反向**的：订单由服务端去渠道下单、拿支付链接给端侧拉起，结果靠**渠道回调**回来。
协议细节（MD5 签名、下单、查单、回调解析）全部收敛在 `app/api/src/yellowdog/services/oxpay.py`，
业务侧（`services/recharge_service.py`）只认它吐出的结构化结果。

- **配置：运营后台「业务 → 支付配置」优先，`.env` 兜底（2026-10-18）**：参数落 App 端库
  `payment_channels`（迁移 `0025`，一行 `channel_code=oxpay`），后台接口
  `GET/POST /admin/api/v1/payment-channel`（权限 `payment:view` / `payment:edit`）。App 端
  每次下单 / 查单 / 回调验签前读库（`services/payment_channel_service.resolve_oxpay`），
  **保存即生效、不用重启**；`enabled=false` 是显式关闭（即使 `.env` 还配着也不再用），
  **库里没有记录**才回落 `Settings.pay_oxpay_*`。字段：`base_url` / `mch_id` / `secret` /
  `notify_url` / `return_url` / `pay_type` / `currencies` / `subject` / `timeout_seconds` /
  `max_attempts`；**三项凭据（base_url / mch_id / secret）齐全才下单**，否则回落本地
  占位收银台（`GET /recharges/checkout`，仅联调），绝不「免签降级」。后台启用渠道时
  后端会校验三件套齐全，避免「保存成功但通不了」。
- **凭据只在服务端**：商户密钥只用于签名与验签，不进日志、不进响应、不下发端侧；
  后台读取只回 `secretConfigured`，保存时 `secret` 留空 = 保持原值，审计日志也不记明文。
- **回调 `POST /recharges/oxpay-notify`**：免令牌、免信封，**响应恒为纯文本 `success`**
  （渠道按「响应体是否等于 success」决定是否重推，这是统一响应体的唯一例外）。
  身份完全靠 MD5 签名，签名/字段不对或金额与订单不符一律拒绝（`30605` / `30606`）；
  异常不外抛（抛 5xx 会引发重推风暴），一律落日志。回调地址未配置时按当前请求兜底拼，
  协议取 `X-Forwarded-Proto`（TLS 在 ALB 上终止）。
- **下单不重试**：商户订单号就是 `order_id`（全局唯一），重试只会撞「订单已存在」；
  渠道失败就把订单置为已关闭（4）并抛 `30603`，不留「待支付但付不了钱」的脏数据；
  幂等键查询**排除已关闭的单**，否则用户会被废单卡住。
- **支付结果线上只认渠道通知（2026-10-29 改）**：测试服 / 正式服订单终态一律由
  `POST /recharges/oxpay-notify` 写入，`GET /orders/{id}/payment-status` 与
  `POST /recharges/confirm` 都**只读库、不向渠道 query 查单**——端侧 2s 一拍的轮询若顺带
  查单，会把每次刷新放大成一次上游外呼，且「已付款」只有渠道通知才是权威口径。
  **本地局域网联调例外（2026-11-03）**：本地回调打不进 `127.0.0.1` / 局域网 IP，
  `APP_ENV=development` 且显式设 `PAY_OXPAY_POLL_ENABLED=true` 时，`payment-status` 会
  经 `services/oxpay_poll.py` 查单补齐终态（充值单与会员单共用）；带 Redis 节流
  （`PAY_OXPAY_POLL_INTERVAL_SECONDS`，默认 5s），查单失败 / 未支付 / 金额不符一律保持
  原状态。硬门控在 `Settings.is_oxpay_poll_enabled`（`app_env == "development"`），
  **测试服 / 正式服恒不生效**，即使误把开关写进服务器 `.env` 也不会查单。
- **本地占位收银台（2026-11-03，联调主链路）**：本地出口 IP 不在 OXPay 商户白名单，
  渠道下单必回 `110019` → `30603`，订单直接作废、查单也无从谈起。`APP_ENV=development`
  且 `PAY_LOCAL_CHECKOUT_ENABLED=true`（`.env.development` 已默认开）时，充值 / 会员
  下单**不向渠道下单**，`paymentUrl` 直接指向本地收银台页
  `/app/api/v1/recharges/checkout?orderId=…&amount=…&payMethod=…`——页面列出后台
  **全部**配置方式（含停用的 googlepay / paypal，标注 local mock，本地模拟不受商户
  开通限制），用户选定后点支付成功，经 `POST /recharges/callback`（带 `payMethod`）
  入账并把所选方式回写订单 `pay_method`（code 必须后台配置过，否则忽略）。端侧
  轮询 `payment-status` 即拿到终态。硬门控 `Settings.is_local_checkout_enabled`
  （`app_env == "development"`），**测试服 / 正式服恒不生效**；收银台开关打开时
  `oxpay_poll` 查单自动跳过（订单没进渠道）。端侧充值与会员购买弹窗共用
  `app/flutter/lib/ui/widgets/pay_method_picker.dart` 选支付方式，选项仍由后台下发
  （`list_enabled`），停用方式只有收银台页能选。
- **金额不换算**：渠道以最小货币单位（分）计，与库内 `amount_cents` 一致。
- **测试服商户**（`7504351449`，`.env.development` / `.env.test` / `docker/env.example`，
  测试网关 `https://test.globaloxpay.com`）**只开通 `1012`（cashapp）
  + `USD**：换成 1013/1016 会回 `110002 Type not support`，换币种会回 `110008 No Channel
  Matched`，这类渠道错误码只在日志里，对外统一 `30603`。
- **正式服**：在后台「支付配置」填正式商户凭据与 `https://globaloxpay.com` 即可（不用重启）；
  也可以继续用 `.env` 兜底——库里没有记录时才读它。**镜像不含任何 `.env` 文件**，测试服若走
  环境变量仍需在服务器 `~/faceflip-ai/.env` 补 `PAY_OXPAY_*` 再 `docker compose up -d`
  （模板见 `docker/env.example`）。
- **端侧现状**：Flutter 侧还没有充值页与 `payment_url` 的消费，渠道接的是后端链路，
  端侧接充值页时直接打开下单返回的 `paymentUrl` 即可。

#### 会员与月卡（M1 门禁 + M2 购买闭环，2026-11-02）

PRD `doc/20261102/PRD-会员与Premium-v1.0.md`，M1（Premium 模板门禁、`GET /users/{id}/membership`、
`MembershipRequiredDialog`）先落地；M2（月卡购买 + 每日免费生图）后端已落地，要点：

- **M1 门禁**：`services/membership.py`（`resolve` / `resolve_for_user` / `require_tier`），
  `users.membership_tier` / `membership_expires_at`（迁移 `0036`）是唯一会员事实源，不建用户-会员
  关系表。Premium 模板门禁在模板详情 / 任务创建 / 社区使用三条链路上，返回 4012（无会员）
  / 4013（已过期）由端侧弹 `MembershipRequiredDialog`。
- **M2 套餐**：`membership_plans`（迁移 `0037`，播种 Basic `$9.9`/赠 `100`/每日免费生图 `5`、
  Pro `$19.9`/赠 `300`/`10`，`sort` 10/20）——价格、赠币、每日免费生图次数**全部后台可改**，
  下单以库为准、订单存 tier/周期/赠币快照（结算不回查套餐）。
- **M2 下单与回调**：`GET /membership/plans`（免登录）、`POST /users/{id}/membership/orders`
  （`services/membership_purchase.py`）；订单号 **`M` 前缀**（充值单是 `R`），
  `GET /orders/{id}/payment-status` 与本地联调回调 `POST /recharges/callback` 都按前缀分发，
  payment-status 响应带 `orderType: recharge|membership`。OXPay 回调独立路径
  `POST /membership/oxpay-notify`（与充值同款：免令牌、非信封、恒回 `success`、只认 MD5 验签
  + 金额核对）。错误码 `30608`~`30611`（套餐不存在 / 不可售 / 订单不存在 / 降级购买）。
- **开通口径（PRD TBD 9.3 默认）**：**30 天滚动**——有效期内续费（含 basic→pro 升级）从当前
  到期时间顺延，过期后从现在起算；有效期内**降级购买直接拒**（`30611`）；结算时发现订单档位已
  低于用户当前档位（人工升级过）则保住更高档位只顺延；不限期会员（`expires_at` 为空，人工发）
  保持不限期。会员赠币走 `wallet_service.grant`，`biz_type=membership_grant`（对外流水 type=18）、
  `biz_id=order_id` 幂等，重复回调不叠加时长也不重复入账。
- **每日免费生图（M2 验收项）**：`user_daily_image_quota` 计数表（迁移 `0039`，一人一天一行、
  UTC 自然日重置），上限取当前档位**在售套餐**的 `daily_free_image`
  （套餐行缺失回落 Basic 5 / Pro 10；配成 0 = 显式关闭）。占名额是**原子条件 UPDATE**、
  行不存在再 INSERT（SAVEPOINT 兜并发首建）。只覆盖 `taskType=1` 模板任务与自由创作 i2i
  （在 `create_direct_task` 公共收尾与 `freeform_service.create` 两处接入），且**原价 > 0 才占**
  （免费模板不占）；占到名额的本单 `consumed_gold=0`，任务/生成记录带 `free_quota_used` 标记。
  **生成失败要回补名额**（2026-11-03 调整，原口径「不回补」）：`membership.release_free_image`
  按**建单日**把 `used_count` 原子 -1（`> 0` 才减），提交即失败（`create_direct_task`）与轮询
  失败（`_advance_task`，靠任务终态 + 行锁幂等）、自由创作 `_refund`（`refund_status` 条件
  UPDATE 抢占，防多副本重复回补）三处都接。视频（含 HD）、i2v、animate 不占名额。
  `GET /users/{id}/membership` 扩展 `dailyFreeImageQuota/Used/Remaining` 供端侧展示。
- ⚠️ **迁移链小插曲**：定价简化提交（`f5cf5d2`）的 `0038_pricing_config_simplify` 曾把
  `down_revision` 写成当时并不存在的 `0037`（链是断的，离线生成用例过不了）；本功能的
  `0037_membership_plans_orders` 落地后恰好补上了缺口，链恢复为 0036→0037→0038→0039。
- **后台**：运营后台「会员套餐」页（`/membership-plans`，权限 `membership:view` /
  `membership:edit`，接口 `GET/POST /admin_api/v1/membership-plans`、`POST .../{planId}/status`，
  镜像模型 `AppMembershipPlan`）——改价 / 改赠币 / 改每日免费生图 / 排序 / 启停保存即生效；
  `planCode` 与 `tier` 建后不改（库级唯一约束），`billingCycle` 暂只放开 monthly（年付 M3）；
  审计 action `membership.plan.save/enable/disable`。
- **端侧（app/flutter 子模块）**：`MembershipSheetBody`（`ui/membership_sheet.dart`）套餐全部来自
  `GET /v1/membership/plans`（价格 / 赠币 / 免费次数不写死），周期 tab 仅在服务端下发多周期时出现
  （M2 只有 monthly 就不摆假 tab）；购买链路复用充值的「下单 → `bridge.openURL(paymentUrl)` →
  轮询 `payment-status` → invalidate 会员态 + 金币」套路；`membershipStatusProvider`（`state/
  membership_provider.dart`）已从 stub 换成真实 `GET /users/{id}/membership`（未登录回落 free）。
  「今日免费剩余 X 次」在模板详情 `_Footer.freeQuotaLabel`（仅图片模板）与自由创作 i2i
  （`freeform_page._freeQuotaLabel`）两处展示。金币流水 type=18 文案 `goldTypeMembershipGrant`
  （9 个语言表全量同步；新增 i18n key 必须补齐 9 表，`i18n_test` 有漏翻校验——注意 HEAD 基线上
  `membershipGoLabel` 在所有语言都是 'Go'，i18n_test 与 top_bar_actions_test 各有 2 个既有红灯，
  非月卡改动引入）。
- 测试：`tests/test_membership_purchase.py`（购买闭环）、`tests/test_membership_premium.py`（门禁）、
  `tests/test_membership_quota.py`（每日免费额度）；admin 侧 `tests/test_membership_plans.py` +
  `MembershipPlansPage.test.tsx`；端侧 `membership_api_test.dart` + `membership_sheet_test.dart`。

## 技术栈

| 层 | 技术栈 | 说明 |
| --- | --- | --- |
| App 端 | Flutter 3.47.4 / Dart 3.13.3 + Riverpod + go_router（`app/flutter/`） | 一套代码出 Web / iOS / Android；Web 产物由 `flutter build web` 产出，静态资源长缓存、`index.html` 不缓存 |
| 后台服务 | **Python 3.12 / uv / FastAPI / SQLAlchemy 2.0 / MySQL 8 / Alembic / pytest / ruff** | 分层：`api`/`schema` → `service` → `repository` → `model`，见共享 Python 规范第 5 节 |

接口、数据库、Python 工程三类改动一律遵循工作区共享规范（真源在 `backend-shared-assets/docs/`，独立 git 仓库）：

- 接口 → `backend-shared-assets/docs/API-接口规范.md`
- 数据库 → `backend-shared-assets/docs/DB-数据库字段设计与使用规范.md`
- Python → `backend-shared-assets/docs/PYTHON-项目开发规范.md`

本文件只写 yellow-dog 特有的落地约定，不与共享规范重复；冲突时以共享规范为准。

## 目录结构（含规划）

```
yellow-dog/
├── README.md
├── AGENTS.md                 # 本文件：代理工作约束（真源，改动保持同步）
├── doc/                      # 正式文档：PRD-/DESIGN-/DB-/API- 前缀 + -v<版本>.md
│   ├── app/                  # App 端模块需求（PRD-NN-主题.md，一模块一份）
│   └── admin/                # 管理后台模块需求（同上，编号按侧栏菜单顺序）
├── app/                      # 应用代码：H5 前端 + 后台服务
│   ├── flutter/              # App 端唯一前端代码（git 子模块，独立仓库 guogeer-png/faceflip-ai-app），见下方「Flutter 重构」
│   │   ├── lib/core/         # config / native(bridge) / network / storage / i18n / media
│   │   ├── lib/{api,models,state}/  # 接口层 / 数据模型 / 本地状态（Riverpod）
│   │   ├── lib/{pages,router,ui,theme}/
│   │   └── web/ android/ ios/
│   └── api/                  # App 端后台服务（Python 3.12 + FastAPI）
│       ├── pyproject.toml    # 依赖 + ruff/pytest 等全部工具配置（唯一工具配置入口）
│       ├── uv.lock           # 必须入仓
│       ├── .env.example      # 环境变量模板（只留占位），.env 必须 gitignore
│       ├── src/yellowdog/    # 业务包（src 布局，禁止根级业务模块）
│       │   ├── main.py / app.py / config.py / db.py / errors.py / logging.py
│       │   ├── models/       # ORM 模型（snake_case，对齐 DB 规范）
│       │   ├── schemas/      # Pydantic 请求/响应模型（字段 camelCase）
│       │   ├── repositories/ # 数据访问，不含业务规则
│       │   ├── services/     # 业务用例、事务边界
│       │   └── api/          # 路由（只做协议转换），按业务域分文件
│       ├── migrations/       # Alembic 迁移
│       └── tests/            # pytest，命名 test_*.py
├── admin/                    # 管理后台（参照现网 AIGC 管理后台交接资料复刻）
│   ├── api/                  # 管理后台 API（Python 3.12 + FastAPI；与 app/api 同栈同规范；tests/ = pytest）
│   └── web/                  # 管理后台前端（Vite + React 19 + TS + antd 6；用例就近 *.test.ts(x) = vitest）
└── docker/                   # 部署编排与镜像（待落地时再定）
```

App 端源码在 `app/flutter/`（**2026-10-23 起为 git 子模块**，独立仓库 `guogeer-png/faceflip-ai-app`）；后台服务在 `app/api/`；管理后台在 `admin/`（`admin/api` + `admin/web`）。原 H5 目录 `app/h5/` 已于 2026-10-10 移除。

## 时间与时区规范（ISO 8601，2026-10-28 定）

跨端统一口径，App 端 / 运营后台 API / 运营后台前端 / Flutter 端共用同一条规则。改时间字段前先读这一节。

1. **库内一律 naive UTC**：时间列 `DATETIME`、以 `xxx_at` 命名，取值统一走 App 端 `models.base.utc_now()` / 运营后台同义函数。**不存带时区的时间，也不存时间戳整数。**
2. **对外一律 ISO 8601 字符串**，格式 `YYYY-MM-DDTHH:mm:ss+08:00`——**秒级精度 + 显式 UTC 偏移**。禁止再输出秒 / 毫秒时间戳。改之前 `createTs` 在 task / freeform 是**秒级 int**、在 community / recharge 是**毫秒数字串**，运营后台 `updateAt` 也是秒级数字串，四个端各猜各的单位，现已全部统一。
3. **时区偏移只有一处开关**：`APP_TIMEZONE_OFFSET_HOURS`（默认 8，App 端与运营后台各有一份）。对外换算必须走唯一入口——App 端 `utils.timeutils.to_iso / to_iso_or_none`、运营后台 `timeutils.to_iso`。**不要在 service 里再写一份 `_iso()` / `.isoformat()` / `.timestamp()`**：运营后台此前 11 个 service 各写一份，产出全是 `+00:00`（运营台按 +08:00 展示，等于每个模块自己猜时区）。
4. **必须先按 UTC 解释**：库里的 datetime 是 naive UTC，直接 `.timestamp()` 会按服务器本地时区解释、直接 `.isoformat()` 则根本不带时区标记，两种情况都会整体差一个时区。
5. **空值两种形态，同域内不要混用**：契约上「一定有值」的字段给空串 `""`，`str | None` 的可选字段给 `null`（端侧对应 `DateTime?` 为 null）。
6. **信封是例外**：`serverTime` 是毫秒时间戳、`serverTimeStr` 是**毫秒精度** ISO 8601（含偏移）。它是给端侧对钟用的，刻意与业务字段的秒级精度不同，**不要去对齐**，也不要在业务字段里用毫秒。
7. **纯日期不算时间**：`statDate` / `createDate` 这类 `YYYY-MM-DD` 本身就是 ISO 8601 的日期形态、不涉及时区，**不要**套 `to_iso`（跨日切分用 `to_date` 落在展示时区上）。
8. **对内仍是 datetime**：SQL 比较 / 排序 / 报表日期切分 / 内部分页游标都继续用 datetime 或原始时间戳，**不要**把 ISO 字符串解析回去做比较（游标里的毫秒数字串也要按 UTC 编解码）。
9. **端侧解析只有一处入口**：`app/flutter/lib/core/time/iso8601.dart` 的 `parseIso8601`（只认 ISO 8601 形态，历史数字串一律判 null——否则 `tryParse('1730000000')` 会得到 172999 年）与 `compareIso8601Desc`（缺时间的排在列表最后）。展示前 `.toLocal()`；**不要自己按 1000 判秒 / 毫秒**。运营后台前端不解析，直接展示服务端字符串。
   - ⚠️ Dart 的 `DateTime ==` 同时要求 `isUtc` 一致：用例里的期望值要先 `.toLocal()` 才能和解析结果比较。
10. **改动检查清单**：加 / 改对外时间字段 → 同步改 `app/api/src/yellowdog/schemas/` 与 `app/flutter/lib/models/`（两侧字段口径必须一一对应）。

## 通用约定（后台服务）

技术栈（已定）：Python 3.12 / uv / FastAPI / SQLAlchemy 2.0 **async（aiomysql）** / MySQL 8 / **Redis** / Alembic / pytest / ruff。**对象存储 = AWS S3（boto3）**。

- **对象存储（已定）**：AWS S3 `us-east-1`，测试服用 access point ARN（`arn:aws:s3:us-east-1:667291759490:accesspoint/faceflip-ai-test-ep`）、正式服用 access point alias（配置落在 `app/api/.env.production`）（`S3_BUCKET` 直接填 ARN，**不带 `s3://` 前缀**），对外 CDN 域名走 `S3_CDN_BASE_URL`：dev / 测试服写**测试桶**（`S3_BUCKET` 填测试桶 access point alias，**不设 key 前缀、写桶根目录**），对外 `https://test-res.faceflip-ai.com`（2026-10-18 起恢复，模板与资源都走它）；正式服写**正式桶**（`S3_BUCKET` 取 `app/api/.env.production` 的 access point alias，同样写桶根目录），对外 `https://res.faceflip-ai.com`。**写入位置必须和对外域名自洽**：桶与 CDN 不配套时新上传的 URL 会全部 403/404（2026-10-12 就因为「上传落测试桶、URL 指向正式桶 `test/` 前缀」废过一批创作结果图，端侧报 `HTTP request failed, statusCode: 0`）。2026-10-12 ~ 2026-10-18 曾因 test-res 域名失效临时改直写正式桶 `test/` 前缀，现已回退；那批历史对象如需继续访问，用 `docker/s3_mirror.py` 搬运。部署口径：测试服 `RES_BASE_URL=https://test-res.faceflip-ai.com`，正式服 `https://res.faceflip-ai.com`。CDN 分发 ID：测试服 `E37GJ2NYXWZ64K`、正式服 `E3SW0UVFK1MNCY`（同时存在各 env 文件的 `CDN_DISTRIBUTION_ID`）；bucket 为 ARN/alias 时留空会让上传后组装 URL 报 `UPLOAD_STORAGE_NOT_CONFIGURED`。实现在 `src/yellowdog/storage.py`，密钥只走 `Settings`（`.env.development` / `.env.test` 入库且含测试服凭据，**仓库须私有**；`.env` 为本地覆盖文件、忽略；`.env.example` 只放占位）。**dev / 测试服共用同一套 S3 参数**（都写测试桶根目录），已落在 `app/api/.env.development`（`resolve_env_file()` 按 `APP_ENV` 优先取 `.env.development`）。上传接口 `POST /v1/upload`（multipart `type` + `file`）返回 `data.url`，**一律是 CDN 地址，禁止下发 S3 原始域名**；对象 key 形如 `{用途}/{yyyy}/{mm}/{dd}/{uuid}.{ext}`，不设业务前缀（`S3_KEY_PREFIX` 配置已于 2026-10-18 移除）。用途白名单与允许的内容类型见 `storage.UPLOAD_TYPES`（当前 `input` / `feedback` 为现网在用，其余预留）。

常用命令（**在 `app/api/` 目录内执行**）：

```bash
uv sync --dev                    # 安装依赖（含 dev 组）
cp .env.example .env             # 首次复制配置（.env 不入库）
uv run alembic upgrade head      # 迁移到最新
uv run python -m yellowdog.main  # 开发启动 http://127.0.0.1:8000
uv run pytest tests/test_<域>.py  # 测试（SQLite + 假 Redis，不需要真实 MySQL/Redis）——**默认只跑增量**，见「测试只跑增量」
# ⚠️ `uv run pytest` 裸跑 = 全量（20 分钟以上），只在用户明确要求或发布前整体回归时才跑
uv run ruff format . && uv run ruff check . --fix   # 提交前必跑
```

- **接口前缀**：业务接口统一前缀 `/app/api/v1`（配置 `APP_API_PREFIX`，可覆盖为空）；网关按前缀路由 `/app/**` 到本服务，服务内再走 `/api/v1`。各 router 只声明相对子路径，在 `app.py` 的 `include_router(prefix=...)` 统一挂载。`/healthz`（健康检查）与 `/docs`、`/openapi.json` 保持根路径。
- **响应信封**：统一 `code` / `msg` / `data`（**仅对象或 null**，列表用 `{list, total}` 包裹）/ `serverTime`（毫秒）/ `serverTimeStr`（带毫秒与 `+08:00` 时区 ISO 8601）；HTTP 恒 200，成功 `code` 恒 0。禁止把数组直接赋给 `data`。
- **HTTP 与命名**：**仅 GET / POST**（现网残留的 PATCH / DELETE 一律改 POST + 动作子路径，如 `POST /tasks/{id}/mark-read`、`POST /tasks/{id}/delete`）；POST 非文件上传统一 `application/json`；URL 资源与动作 kebab-case，Query / body 字段与枚举值 camelCase；入参做类型、范围与联动校验。
- **跨接口统一化（现网混乱点，新后台必须收敛，详见契约文档 §5）**：
  - 分页统一 `pageNum` + `pageSize` + `total` + `hasMore`（无限滚动场景额外给 `nextCursor`）；列表容器统一 `{list, total, ...}`。
  - **int64 对外一律字符串**（`string/int64`）：所有 `*_id`、`userid` 等。
  - 时间对外统一 ISO 8601 字符串；库内 `DATETIME`、`xxx_at` 命名。**完整口径（精度、时区开关、空值形态、端侧解析）见「时间与时区规范（ISO 8601）」**，那一节是本仓时间的唯一真源。
  - 金额：金币 int64 字符串；法币统一 `minorUnits` + `currency`(ISO 4217)，**废弃 micros**。
  - 字段统一 camelCase（现网 referral / 社区提现为 snake_case）；channel 统一走 `X-Client-Channel` 头，不再散落在 query / body。
  - 幂等键统一 `clientRequestId`（充值 confirm、转金币、提现必须支持）。
- **任务进度推送**：`GET /ws?token=`，JSON 文本帧（现网 protobuf，客户端两种都兼容）+ `ping`/`pong` 心跳；任务状态沿用 `0=Pending / 1=Running / 2=Success / 3=Failed` 并写入字段 `COMMENT`。
- **错误码**：业务码 5 位 = 服务标识 `30` + 后 3 位业务码（即 `30xxx`），全量登记在 `app/api/src/yellowdog/errors.py`；公共错误码沿用 3 位。服务标识 `30` 为本仓暂定分配，**需在 `backend-shared-assets/docs/API-接口规范.md` 的服务标识登记处补充后再上线**。
- **数据库**：MySQL 8，表名/字段 snake_case，主键 `id BIGINT UNSIGNED`，时间 `DATETIME` 且以 `xxx_at` 命名，**金额一律整数（`BIGINT`，单位默认分 / 最小货币单位，禁止 `DECIMAL` / `FLOAT` / `DOUBLE`）**，业务表带审计字段与逻辑删除字段，状态字段统一 `status` 且枚举值写入 `COMMENT`；禁止外键、`SELECT *`、浮点金额。
  - **金额单位口径（2026-10-11 定）**：库内一切金额字段（法币、金币、收益、成本、广告消耗）都用 `int` 存**分**（最小货币单位），不用小数类型。字段名带单位后缀以自证：`amount_cents` / `recharge_amount_cents` / `ad_cost_cents` 等；纯金币字段（`gold_balance`、`amount`）存枚数整数，不带后缀但同样是整数。单位换算只在**接口出参与前端展示**层做（分 → 元），库内、服务层计算全程整数，禁止 `round()` 浮点中间值。迁移既有 `Float`/`DECIMAL` 金额列时，必须同批写数据换算（`旧值 * 100` 取整），并对齐出参 `xxxCents` 命名。
  - **已落地（2026-10-11，admin/api）**：迁移 `admin/api/migrations/versions/0006_money_to_cents.py`，把运营台全部金额列由 `Float` 美元改为 `BIGINT` 分并改名（`amount_usd`→`amount_cents`、`ad_cost`→`ad_cost_cents`、`recharge_amount`→`recharge_amount_cents`、`cost`→`cost_cents`、`revenue`→`revenue_cents` 等），JSON 内的 `totalAmount`/`avgAmount`/`rechargeUsd` 同步改为 `totalAmountCents`/`avgAmountCents`/`rechargeCents`；出参与 `admin/web` 展示层按 `Cents` 命名，展示时 /100（`utils/format.ts` 的 `moneyCents`）。`app/api` 侧原本就是整数分，无需迁移。schema 变更**必须走 Alembic 迁移**（`uv run alembic revision --autogenerate`），启动时可 `upgrade head`，但**禁止用 `create_all` 作为生产建表手段**。
- **配置与密钥**：配置通过 Pydantic Settings 集中加载，禁止散落 `os.environ` 直读；环境差异走 dotenv（模板 `.env.example`，真实 `.env` gitignore）。**严禁提交、回显、打印任何密钥**（DB 口令、JWT secret、三方 API Key 等）；MySQL/Redis 连接一律拆分字段、不用 URL。
- **信封实现**：业务 router 必须声明 `route_class=EnvelopeRoute`（`src/yellowdog/envelope.py`），由路由层统一包装 `{code,msg,data,serverTime,serverTimeStr}`；`/healthz`、`/docs`、`/openapi.json` 在 `ENVELOPE_SKIP_PATHS` 中豁免。异常经 `BusinessError` → 全局处理器转信封，**HTTP 恒 200**（前端按 `code` 判定，令牌失效码为 `30002`/`30003`）。
- **Redis 用途**：刷新令牌 jti（一次性轮换，`cache.pop_refresh_token`）、幂等键（`try_acquire_idempotency`）、限流。连接参数拆分字段，不配置 `REDIS_PASSWORD` 视为无口令。
- **日志与追踪**：统一 `logging.getLogger(__name__)`，禁业务 `print`；异常日志必须带堆栈；敏感字段（手机号、token、支付信息）脱敏。链路追踪用 OpenTelemetry W3C Trace Context（请求头 `traceparent`），不自定义 `ecbg-trace-id` 之类追踪头。
- **代码质量**：Python 3.12 + uv（`uv.lock` 入仓），src 布局，函数必须带类型注解，禁裸 `dict` 传业务结构，业务枚举用枚举/常量，禁魔法值。提交前必须 `uv run ruff format .` + `uv run ruff check . --fix`，CI 只读校验 `ruff format --check .` / `ruff check .`；**禁止 black/yapf 混用、禁止 `--no-verify` 绕过、禁止全局 `# noqa`**。
- **测试**：统一 pytest（配置写 `pyproject.toml`，异步用 `asyncio_mode = "auto"`），不依赖真实外部服务；新增业务规则/修 bug 必须配套回归用例；关键链路（鉴权、金额、状态流转、回调幂等）优先覆盖异常与边界分支。

## 运维学与运营后台约定（`admin/api`）

- **明细数据直读 App 端库（2026-10-11 改，取代「后台自建一套 biz_* 表」）**：两端共用同一个
  MySQL 实例（docker-compose 里 host / user 一致，只有库名不同：App `yellowdog`、后台
  `yellowdog_admin`），所以**不建第二个引擎**，而是给镜像模型加 schema，SQLAlchemy 会拼成
  `` `yellowdog`.`users` ``，跨库 JOIN 与跨库事务都能落在同一连接上。镜像模型集中在
  `models/app.py`（AppBase 元数据），**只声明后台用得上的列、不参与 Alembic 迁移**，
  新增列前必须先确认 App 端已落地。App 端表的 `created_at` / `updated_at` **没有 DEFAULT**，
  镜像模型必须在 Python 侧给值（`AuditMixin._utcnow`），否则 MySQL 严格模式报 1364。
- **后台自有表只留「运营配置类」**（迁移 `0007` 已删掉被 App 库取代的 12 张表）：渠道包 /
  子渠道 / 像素 / 模板置顶 / 模板指导意见 / 手工广告消耗 / 反馈批审（job·cluster·suggestion）/
  邀请与提现 / 推送任务 / 工具执行记录。**反馈审核已改为跨库读 App 端 `feedbacks`**
  （迁移 `0026` 补 `review_status` / `reward_coins` / `support_response` / `reviewed_at`）；
  `biz_feedbacks` 仅剩反馈智能批审的演示数据，不要再往它写真实反馈。
- **比率类指标（CTR / 成功率 / ROI / 留存）一律现算**，不在库里冗余；派生聚合集中在
  `repositories/app_stats.py`，service 只负责再算比率与格式化。
- **App 端没有的数据不要硬凑**：国家维度（数据详情只有 `ALL`）、曝光 / 点击埋点（模板统计恒 0）、
  GPU 采样（改成按 `provider` 的「生成服务健康度」`GET /service-nodes`）、支付漏斗事件
  （用订单终态推导：起量 = 成功 + 失败）。新增字段前先确认 App 端有没有源，宁可空缺不要造数。
- **金币读写必须落到 App 端**：所有会改用户余额的动作（反馈奖励 / 邀请结算 / 提现预扣与退回 /
  工具发放扣减 / 批审奖励）统一走 `services/gold_service.grant_gold()`，写 App 端
  `user_wallets` + `user_gold_ledgers`，`(user_id, biz_type, biz_id)` 唯一约束保证幂等；
  `biz_type` 沿用 App 端字典并在 `BIZ_TYPES` 登记。**不要写后台自己的余额字段**。
- **重置 C 端用户密码（2026-10-12）**：后台只做「重置为默认密码」，不收新密码——路由
  `POST /users/{user_id}/reset-password`，权限点 `user:reset-password`，写 App 端
  `users.password_hash`。两条硬约束：①**必须用 bcrypt**（`security.hash_app_password`，
  与 `app/api` 的 `hash_password` 同算法），管理员自己的口令是 PBKDF2，两套别混，
  混了用户就在 App 端登不上；②默认密码走配置 `APP_USER_DEFAULT_PASSWORD`（默认 `123456`，
  ≥ App 端最短 6 位），响应把它明文回给前端仅供客服转告。只有 `email` 非空的账号能重置
  （C 端登录只认邮箱，匿名历史账号重置没意义），列表与出参不带任何密码字段。
- **分层**：`api` → `service` → `repositories`。`repositories/` 只写 SQL，`service` 负责业务口径与
  格式化，路由不许直接写 SQL。写操作与只读一样依赖 session，由路由层统一 `commit()`。
- **本地数据**用两个脚本，**生产严禁调用**：`tool/seed_business.py`（只灌后台自有表）与
  `tool/seed_app_data.py`（灌 App 端演示数据，写的是真实业务表，`--force` 才覆盖）。
  pytest 在 conftest 里两个都调（`seed_app_data(force=True)` + `seed_business()`）。
- **邀请返利 / 推送任务 / 运营工具**三域已落地：路由 `api/operations.py`，权限点 `referral:view` /
  `push:view` / `push:edit` / `tools:view`；金币变动与状态流转必须**同一事务**；提现「预扣 —
  驳回退回 — 重复处理拦截」是强制口径。`admin/web` 页面：`ReferralsPage` / `PushCampaignsPage` /
  `ToolsPage`（API 层 `src/api/operations.ts`，注意只有邀请记录是分页接口，其余返回数组）。
- **令牌要带 `username`**（`security.create_token`）：审计、工具记录、批审任务都靠它显示操作人，
  丢了就全是空字符串。

## App 端约定（`app/flutter/`，git 子模块）

> 本节及以下「Flutter 重构」章节的行为口径长期有效，代码就在 `app/flutter/`（子模块）。**改动与测试在子模块目录内做**（`cd app/flutter && flutter test ...`），提交后推送到子模块自己的 origin，再回到本仓提交 gitlink。子模块内另有一份 `AGENTS.md`，端侧细节以它为准；本仓保留这几节供后端侧查接口契约与字段口径。

- **唯一前端主体**：`app/flutter/`（Flutter 3.47.4 / Dart 3.13.3 + Riverpod + go_router），一套代码出 Web / iOS / Android。工程内校验用 `flutter analyze` / `flutter test` / `flutter build web --release`（**在 `app/flutter/` 目录内执行**）。
- **Flutter Web 必须带 `--no-web-resources-cdn`（2026-10-14）**：不加这个 flag，`flutter run` 与 `flutter build web` 产物都默认让浏览器去 `www.gstatic.com/flutter-canvaskit/<engineRevision>/chromium/canvaskit.{js,wasm}` 拉 CanvasKit；该域名访问不到（公司网络 / 大陆网络）时引擎压根起不来，`flutter-view` 都不会创建，HTML 启动图又被 `web/index.html` 的 15s 兜底隐藏，页面就是**纯黑屏**（不是接口报错、也不是「加载失败」）。加了之后 dev server 把 `<SDK>/flutter_web_sdk/canvaskit/` 挂到本机 `canvaskit/`，release 产物自带 `canvaskit/` 目录，另外 toolchain 还会**顺带把 `Roboto-Regular.ttf` 打进 `assets/fonts/fallback/`**（`build_system/targets/web.dart` 的 `_bundleLocalRobotoFallback`，只在 `useLocalCanvasKit` 时生效）——即 release 连拉丁字体也不再走 Google。两处都已带上：`app/flutter/tool/dev.sh` 的 `RUN_ARGS`、`docker/deploy.sh` 的 `flutter build web --release`。
- **字体：系统字体排序 + 打包 CJK / 天城文字形（2026-10-14）**：症状是「进首页先是乱码（豆腐块），过一会才正常」——原主题字是 `Manrope` + 回落 `Noto Sans SC`，这两个字形都没打进包，中文字形只能由引擎按需去 `fonts.gstatic.com/s/notosans*/` 拉 Noto 子集：域名不通永远拉不到（本机实测 curl 直接超时），通了也要等下载+注册完才纠正。三处已改：① `lib/theme/app_theme.dart` 的 `AppColors.fontFamily` / `fontFamilyFallback`（唯一真源，`ui/brand_splash.dart` 复用）= `system-ui` → `-apple-system` / `Segoe UI` / `Roboto` → `PingFang SC` / `Microsoft YaHei` → **`DroidSansFallback`** / **`NotoSansDevanagari`** → `sans-serif`；② `web/index.html` 启动闪屏 CSS 同一套；③ `web/flutter_bootstrap.js`（新增）给 loader 传 `config: { preferWebParagraph: true }`，并保留 `{{flutter_js}}` / `{{flutter_build_config}}` 占位符（缺了 loader 拿不到 buildConfig，直接启动失败）。
  - **打包字形（关键，不能省）**：`assets/fonts/DroidSansFallbackFull.ttf`（3.9MB，Apache-2.0，繁中/简中/日文假名；**不含基本拉丁与天城文**，所以拉丁仍由工具链打的 `Roboto` 出）+ `assets/fonts/NotoSansDevanagari-Regular.ttf`（224K，OFL-1.1，印地文），在 pubspec `fonts:` 里登记为 family `DroidSansFallback` / `NotoSansDevanagari`，两档都只带 Regular（粗斜体走 Skia 合成）。这是 **CanvasKit 硬限制下的唯一解**：它只渲染 FontManifest 里注册过的字形，拿不到浏览器系统字体。**代价**：Web/原生包里各多约 4.1MB，且引擎启动时会**无条件**拉这两个文件（`assets/assets/fonts/`，实测请求日志里有），首屏多一次 ~4MB 请求。
  - **`preferWebParagraph` 今天是空转**：它要浏览器有 `window.TextCluster`，实测 Chrome 153 默认 `undefined`、加 `--enable-blink-features=TextCluster` 才有（还在实验阶段），所以现网会静默回退到旧的 Skia 链路（不报错、也没收益）。留着是等 Chrome 默认放开后自动升级到「浏览器原生回落」；**不要把它当成本次修复的依赖**，真正生效的是上面那份打包字体。
  - **仍未覆盖**：emoji（`NotoColorEmoji.ttf` 约 11MB，没打，缺 emoji 时仍会尝试 gstatic 并回落成方框）与韩文等其它未打包脚本。要彻底离线可自托管 Noto 子集 + 配 `fontFallbackBaseUrl`，或按需再打字体。
  - 验证套路：`flutter build web --release --no-web-resources-cdn` 后 `python3 -m http.server` 起 `build/web`，用 `google-chrome --headless=new --user-data-dir=<空目录> --lang=zh-TW --screenshot=...` 截图看中文字形是否成形（**必须给全新 profile**，否则旧 profile 里存的 `yellowdog_locale` 会覆盖系统语言；默认语言跟随系统，`--lang=zh-TW` + 全新 profile 应直接得到繁中界面）。改 bootstrap 后 `docker/deploy.sh` 已有对 `/flutter_bootstrap.js` 的失效，无需额外处理。
- **默认语言跟随系统（2026-10-18 恢复，撤销 2026-10-14 的「默认英文」）**：`LocaleController.build()` 里 `yellowdog_locale` 不存在 / 空串 / 显式 `system` 一律按系统语言解析，判定统一走 `locale_provider.dart` 的 `isFollowSystemLocale(stored)`（设置页勾选态与控制器共用一份，首次进入显示「跟随系统」）。系统语言优先取 Bridge 的 `systemLocale`，Bridge 未接入或失败时退回 `PlatformDispatcher.locale`（再取不到才回落英文），**不能因为 Bridge 异常让语言加载失败拖住启动**。`resolveLocale(null, systemLocale)` 语义不变。实测口径：`--lang=zh-TW` + 全新 profile 打开首页就是繁中引导页。
- **`ViewInsets cannot be negative` 是引擎的 debug 断言，不用追（2026-10-14 实测定性）**：控制台里 `DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/window.dart:350:7 _viewInsets.isNonNegative` 来自 Flutter Web 引擎自己（`_handleBrowserResize` → `_computeOnScreenKeyboardInsets`），**不是业务代码报错，release 产物里 `assert` 被剥离、不会出现**。触发链：移动端 UA（真机或浏览器设备模拟）下，引擎启动时才把 `<meta name="viewport">` 换成 `width=device-width, initial-scale=1.0, maximum-scale=5.0`（`full_page_embedding_strategy._applyViewportMeta`，会先删掉页面里已有的 viewport meta），这之前移动浏览器用的是 980px 宽的默认布局视口，于是视口尺寸**跳变一次**（实测 2121px→844px）；这次 resize 里引擎用「上一份 physicalSize 高度 − 当前视口高度」算键盘 inset，两条取高度的路径（`documentElement.clientHeight` 与 `visualViewport.height`）差 1px 或时序错位就得到负数。实测：桌面 UA 从不复现（连 resize 序列 0 命中），iPhone UA 下启动阶段偶发 1 次；抛出位置在 `invokeOnMetricsChanged()` 之前，所以那次 metrics 更新没派发，但**后续帧与页面内容不受影响**（复现后截图是正常首页）。规避：忽略；或 dev 用 `./tool/dev.sh --release` 跑（无热重载）；或别开浏览器设备模拟。另：`me_page.dart` 改昵称弹窗的 `TextField(autofocus: true)` 会让移动端进入编辑态（`_shouldPreservePhysicalSizeOnResize = isMobile && textEditing.isEditing`），键盘收起时更容易命中这条断言，但那是另一条路径、同样只是 debug 噪音。
- **H5 对齐进度看 `doc/flutter-h5-migration.md`**：H5 蓝本在 `demo/h5/`（`.gitignore` 忽略的留档，dev server 5173），共 39 个页面组件；Flutter 按 P1（纯前端）/ P2（补 recharge+referral+feedback 后端）/ P3（社区全套）三批推进，做完一批勾一批。
- **自由创作（freeform）的计费与生成口径（2026-10-11）**：创建时**先比余额再扣**，生成失败**原额退款**，流水类型 `freeform_consume` / `freeform_refund`。出图统一走 `services/generator.py`，当前是**占位实现**（提交即成功、返回占位图），接真上游只替换这一个实现，service 不动。档位与价格是 `freeform_service.py` 顶部的常量（`I2I_RESOLUTIONS`、`I2V_PRICE_TABLE` 等），接运营后台后换读库/配置，接口形态不变。
- **生成结果不能返回取不到的占位路径（2026-10-12）**：成功结果按「上游真实 `result_url` → 固定素材（`FIXED_RESULT_*_URL`，仅占位联调兜底）→ **输入图**（`ref_urls` 里第一个 http(s) 地址）→ `PLACEHOLDER_RESULT_URL`」回落；出参统一过 `generator.displayable_result_urls()`，库里存的老占位路径也用输入图顶上。原因是 `/placeholder/generated-result.png` 在 CDN 上并不存在，端侧按 `res_base_url` 拼完必然 404，创作页看不到任何结果。要展示"生成的图"而不是输入图，就配 `FIXED_RESULT_IMAGE_URL` / `FIXED_RESULT_VIDEO_URL`（必须是 CDN 上真实存在的对象）。
- **资源 URL 出参不再做域名改写（2026-10-13 移除）**：`generator.rewrite_legacy_cdn_urls()` 与旧域名常量已删除，`ref_urls` 原样出参，`result_urls` 只过 `generator.displayable_result_urls()`（占位路径用输入图顶上）。**库里若仍有已下线资源域名的历史记录才会 404**，需要时用 `docker/s3_mirror.py` 搬对象后改数据。当前 dev / 测试服上传写测试桶根目录（`S3_CDN_BASE_URL=https://test-res.faceflip-ai.com`），正式服写正式桶根目录（`https://res.faceflip-ai.com`），不会再产生旧域名地址。
- **`res.faceflip-ai.com` 不保证回 CORS 头，Web 端图片要开 `webHtmlElementStrategy`（2026-10-13 实测）**：同一个图片 URL 用同一组请求头连打，CloudFront 时而带 `access-control-allow-origin: *` 时而没有（不带 `Origin` 的请求一律没有；带 `Origin` 的请求也会时有时无，同一组请求头连打几次结果不一致），`OPTIONS` 预检直接回 403。Flutter Web 的 `Image.network` 默认用 XHR 取字节，CORS 不过整张图就渲染不出来，页面上只会看到 `HTTP request failed, statusCode: 0, <url>`（且是画在图片位置上的异常原文）。端侧兜底：`Image.network(..., webHtmlElementStrategy: kCdnImageWebStrategy)`，常量定义在 `app/flutter/lib/ui/widgets/remote_image.dart`，值为 `WebHtmlElementStrategy.fallback`——XHR 被拦时改用 `<img>` 元素渲染（元素不受同源策略约束，代价是拿不到像素、不能二次处理），移动端该参数无影响。**根治在 CDN**：给 `res.faceflip-ai.com` 那条分发挂一个启用 CORS 的 Response headers policy（`Access-Control-Allow-Origin: *` + 允许 GET/HEAD/OPTIONS，CloudFront 会自己应答预检），当前 IAM 用户没有 CloudFront 写权限（`ListDistributions`、`ListResponseHeadersPolicies` 都是 AccessDenied），只能在控制台改。**2026-10-13 收口**：该分发默认 behavior 已放开 `GET/HEAD/OPTIONS`，响应头策略从托管 SimpleCORS（`60669652-455b-4ae9-85a4-c4c02393f86c`）换成 **CORS-With-Preflight**（`5cc3b908-e619-4b99-88e5-2cf7f45965bd`），并对 `/test/*` 做了失效。现状：带 `Origin` 的 GET 稳定回 `access-control-allow-origin: *` + `access-control-expose-headers: *`，不带 `Origin` 的副本带 `vary: Origin`（不会串）。**`OPTIONS` 预检仍 403，且没有策略能解决**：托管策略的 CORS 头 `Override origin` 全是 No，CloudFront 只是给源站响应**补头**、不会替源应答，请求照样转发到 S3，而 S3 REST 端点不支持 OPTIONS。**所以前端不要发会触发预检的请求**（自定义头、非简单 `Content-Type`）——图片取字节是简单 GET，不受影响；真要让 OPTIONS 返回 200，只能在 viewer-request 挂 CloudFront Function 拦掉。
- **CloudFront 分发 ID 与权限（2026-10-13 落实）**：`res.faceflip-ai.com` = **`EVO2U0M4PGHU4`**（源 `faceflip-ai-prod.s3.us-east-1.amazonaws.com`，OriginPath 空、无 OAI，CachePolicy 是托管 `CachingOptimized`）；`app/api/.env.production` 里写的 `CDN_DISTRIBUTION_ID=E3SW0UVFK1MNCY` 是**已失效的旧测试资源域名**那条，`E37GJ2NYXWZ64K` 连 `GetDistribution` 都 AccessDenied，都别用。IAM 用户 `arn:aws:iam::667291759490:user/faceflip-ai-test` 已补 CloudFront 权限：只读（`ListDistributions` / `GetDistribution` / `GetDistributionConfig` / `ListResponseHeadersPolicies` / `ListInvalidations`，**这些必须 `Resource: *`**）+ 写（`UpdateDistribution` / `CreateInvalidation` / `CreateResponseHeadersPolicy`）；`GetResponseHeadersPolicy` 未授权，看不了策略详情。改配置后要等 `Status` 从 `InProgress` 回到 `Deployed`（数分钟）才生效，且要顺手对 `/test/*` 建失效。本机没有 `aws` CLI，用项目 venv 的 boto3 操作即可。
- **camelCase 序列化会吃掉 `i2i` 这类缩写（2026-10-11）**：`CamelModel` 的 `to_camel` 把 `source_i2i_generation_id` 转成 `sourceI2IGenerationId`，而端侧 `models/freeform.dart` 只认 `sourceI2iGenerationId`，字段直接"消失"（表现为端侧取不到、后端测试 KeyError）。含数字缩写的字段要用 `Field(alias=..., serialization_alias=...)` 显式指定。列表字段同理：端侧读 `list`，不是 `items`。
- **本地接真实上游先起桥接**（2026-10-18）：测试服上游 `16232` 只对同机 / 安全组内开放，WSL 直连超时、SSH `-L` 被 sshd 禁用；先跑 `app/api/tool/upstream-bridge.sh --redirect --daemon`（socat 监听 `127.0.0.1:16232` → ssh 执行远端 `nc 127.0.0.1 16232`；再加 iptables 把 `98.93.129.214:16232` 透明转发到本机桥）。`.env.development` 的 `DISPATCH_BASE_URL` 保持真实地址 `http://98.93.129.214:16232`，日志也显示真实地址；停止桥接后 `--cleanup` 清规则。桥没起时任务直接失败退款，不会退回模拟。
- **后端本地调试跑 `app/api/tool/dev.sh`**（2026-10-11）：默认开自动重载（WatchFiles 只监视 `src/` 与 `migrations/`；**改 `.env*` 不会重启**——watchfiles 忽略点开头路径，实测改完 S3 配置进程里仍跑旧值，改配置必须手动重启脚本），迁移不用单独跑。常用：`--port 8001` 换端口、`--no-reload`（打断点/性能分析）、`--no-migrate`（手工改表时关掉启动迁移）、`--env test` 切环境；**production 下脚本拒绝开重载**。端口被占会先警告（旧进程没退干净是最常见的启动失败原因）。前端 `tool/dev.sh --with-api` 就是调它。
- **一次起全部用仓库根 `tool/dev.sh`**（2026-10-12）：同时拉起 app/api(8000)、admin/api(8001)、admin/web(5273，vite 反代 `/admin/api` 到 8001)、flutter(7357)，日志落 `.dev-logs/*.log` 并带服务名前缀打到同一终端，Ctrl+C 按进程组全部停掉（不留 uvicorn --reload 孤儿占端口）；`--with-deps` 用 docker 起本地 MySQL/Redis（端口与凭据读 `app/api/.env.development`，不是写死的 3306/6379），`--no-app` / `--no-admin` / `--no-flutter` 按需裁剪，`--admin-sqlite` 让运营后台不依赖 MySQL。它是各子项目 `tool/dev.sh` 的编排壳，单服务调试仍直接跑子项目那份。
- **本地调试跑 `app/flutter/tool/dev.sh`**：它按参数生成 `web/runtime-config.json`（本地产物，已 gitignore；字段与 `docker/deploy.sh` 远端生成的那份一致）再调 `flutter run`，默认设备有浏览器用 chrome、否则退回 `web-server`；`--with-api` 顺带拉起本地 `app/api`、`--api` 指向测试服接口。**不要手写 runtime-config.json，也不要把接口地址写进代码**——运行参数一律服务端下发。
- **不要另建平行源码树**：前端行为一律改这里；确认现网上游行为读 `doc/project-handover/现网H5/` 的产物（含 sourcemap）与 git 历史——`app/h5` 已不复存在。
- **UI 视觉基线**（复刻自竞品 Bella AI；本产品品牌为 FaceFlip AI）：字体 Manrope / Noto Sans SC；底部导航 5 项 **Home / Official / Create / Community / Me**；首页是**两列瀑布卡片**（封面按素材宽高比，兜底 9:16）。竞品官网有 Cloudflare 拦截（403），以其现网产物为准（见「官网与投放参数」一节）。
- **轻提示一律走 `AppToast`（2026-10-13：改到屏幕顶部，弃用 `SnackBar`）**：组件 `app/flutter/lib/ui/widgets/app_toast.dart`，`AppToast.show` / `.error` / `.success` 经 root `Overlay` 插在**屏幕顶部**——自动让出状态栏安全区、下滑淡入、`IgnorePointer` 不拦 AppBar 上的返回键、到期自动消失、同一时刻只留最新一条。原因是 `SnackBar` 只能贴底部，而底部是常驻导航栏（首页 / 社群 / 创作 / 我的），错误提示出来正好被压住，用户看不见。**不要再写 `ScaffoldMessenger.showSnackBar`**；失败 / 不可用类传 `kind: AppToastKind.error`（红 `AppColors.danger` + 错误图标），成功类传 `AppToastKind.success`，中性提示（如「即將上線」）用默认 `info`。
- **Web 端「保存到相册」走浏览器下载兜底（2026-10-13）**：`saveMediaToAlbum` 在原生壳里交给 App 写相册，纯浏览器此前直接 `BRIDGE_UNAVAILABLE`，Creation details / 任务结果页的保存键点了永远提示失败。现在 `bridge_web.dart` 的 `_fallback` 对该方法走 `_downloadViaBrowser`（fetch 字节 → blob URL → `<a download>`，可指定文件名；CDN 已回 CORS 头所以 fetch 拿得到字节），拿不到字节再开新标签让用户手动另存（返回 `code: BROWSER_DOWNLOAD_BLOCKED`，页面照常提示失败）。用例 `app/flutter/test/bridge_web_save_test.dart` **必须用 `flutter test --platform chrome` 跑**（js_interop / package:web 在 VM 测试里不存在，走不了 bridge_web.dart）。
- **创作结果靠轮询，后端可模拟 10-300s 耗时（2026-10-13）**：出图 / 出视频是 10s~300s 量级（PRD-03 的进度跟踪）。后端 `app/api` 的占位生成（`services/generator.py` 的 `PlaceholderGenerator`）原本**提交即成功**，端侧完全验不到等待过程；新增 `GENERATION_SIMULATE_SECONDS`（`60` 固定 / `10-300` 区间内每次随机，留空或 `0` = 关；**pytest 与 production 必须 0**，本地 dev 已切 `new_orders`，该开关只在临时切回 `placeholder` 时生效）后切成异步形态：`submit()` 立刻返回「生成中」+ 模拟作业号 `sim:<modality>:<started_ms>:<seconds>`，`poll()` 按已过时间推进 progress（前 10% 算排队），到点才成功。**绝不能在 `submit()` 里 sleep**——创建是同步 await 提交的，睡 300 秒会把 POST 请求挂死撞网关超时。推进只发生在详情接口（`GET /v1/tasks/{id}`、`GET /v1/freeform/generations/{id}`），列表接口不推进。端侧轮询统一走 `app/flutter/lib/core/polling/poller.dart` 的 `Poller`（2s→3s→5s 退避、累计等待 10 分钟后给提示 + 可手动重试、`stop()` 取消、单条请求出错不打断），任务页 `/task/:id` 与自由创作详情页 `/freeform/generation/:id` 共用，**不要再各写一份 `_poll`**。**测试服不走模拟**：`GENERATION_PROVIDER=new_orders` 请求真实上游（`DISPATCH_BASE_URL` / `DISPATCH_API_KEY` 在服务器 `.env`，compose 只兜底前者的测试服地址）；`new_orders` 未配置或上游报错时**直接判失败并退款**，不再降级成「立即成功 + 固定素材」——否则端侧拿到假结果，看起来就是「创建即出结果」。
- **进度条按预计 3 分钟推进（2026-10-18）**：上游只回 `pending/running/success/failed`，没有百分比；`app/api/src/yellowdog/services/progress.py` 的 `estimated_progress()` 按 180s 线性推进，未终态封顶 95%，成功 / 失败才 100%，任务详情 / 我的创作 / 自由创作共用。不要把 `progress` 写成静态 0，否则端侧进度环一直是不确定态。
- **App 端配色口径（2026-10-11 起，真源 `app/flutter/lib/theme/app_theme.dart`）**：**主色调紫**（`primary #A855F7` / `primaryDeep #7C3AED` / `primaryLight #C9A2FF`）+ **深紫底 `#0A0613`**；粉红 `#E0389D` 降级为副强调并承担**图标底色**；金 `#FFD700` 只用于金币。全局背景是 `AppBackground` 的**舞台灯光层**（四角补光 + 两道斜向灯带，9 秒反相呼吸），各页 `Scaffold` 背景保持透明才能透出灯光。改色只改 `AppColors`，不要在页面里硬编码。
- **品牌图片资源一律脚本派生**：源图 `generated-images/brand-icon/app-brand-icon-source-1024.png`（粉红渐变底 + 紫色舞台灯光 + 白色舞者剪影），跑 `python3 app/flutter/tool/generate_app_icons.py [源图]` 覆盖生成 App 内资源、Web favicon/PWA icons、Android mipmap、iOS AppIcon 与 LaunchImage（含 maskable 安全区收缩与圆角透明角）。**换风格只换源图再跑脚本，不要手改某个尺寸的输出**。
- **首页结构（2026-10-11）**：首页 tab = 下载横幅（落地页来自运行时配置 `download_url`，**未配置就不渲染**）+ 4 宫格快捷入口（最新 / 社群 / 趋势 / 舞蹈）+ 运营双卡（免费生成跳自由创作；邀请返利后端未就绪，点击只提示）+ 分类区块（最新 `/new`、舞蹈 `/dance`、图集 `/images`、影片 `/video`，各取自 `homeFeedProvider`，**区块头恒定显示**：加载中给占位卡、无数据给空态文案，不整块隐藏——否则一个模板都没有时首页只剩一句「暂无模板」）+ 两列瀑布。滚动与触底加载由外层一个 `ListView` 统一承担，瀑布网格 `_FeedGrid` 自身不滚动。底部导航是自绘的（中间创作键是渐变圆 + NEW 徽标），不用 `NavigationBar`。
- **运行参数一律服务端下发**：接口地址、资源地址、渠道等不在代码里写死；App 端沿用 H5 时代同名的本地缓存键 `yellowdog_runtime_config_cache`（H5 移除不代表这些键能改）。
- **后端写操作必须显式 `await session.commit()`（2026-10-11）**：`db.get_session()` 依赖只在异常时 rollback，**不会自动提交**。写库不 commit 会静默丢失——接口返回成功、数据却查不到（充值下单踩过）。与 `task_service` / `auth_service` 口径一致。
- **禁止拿 `alembic revision --autogenerate` 的结果直接用（2026-10-11）**：本地库与 models 有历史差异（列注释、索引），autogenerate 会顺带产出 `drop_table` 等**破坏性操作**，实测已误删过 `user_wallets` / `user_gold_ledgers`。做法：先 autogenerate 看差异，再**手写只含目标 DDL** 的迁移文件。
- **应用启动时自动跑迁移（2026-10-11）**：`app.py` 的 lifespan 里 `await asyncio.to_thread(run_pending_migrations)`（`src/yellowdog/migrations.py`），`python -m yellowdog.main` 与容器里的 uvicorn 两个入口行为一致。**必须在 `db.init_engine()` 之前调用**——`migrations/env.py` 会自己 `db.init_engine()` 建引擎并在跑完 dispose，放在之后会把应用的引擎换掉并释放掉。开关 `db_auto_migrate`（默认开），`APP_ENV=test` 时强制跳过（测试库由 fixture 负责）。迁移失败**直接抛出让启动失败**：宁可起不来，也不要带着旧表结构对外服务。容器 `Dockerfile` 的 CMD 因此不再前缀 `alembic upgrade head`。
- **登录态先判本地再请求（2026-10-11）**`ApiClient.ensureDeviceSession()` 三级策略——① accessToken 存在且未过期（解 JWT `exp`，留 60s 余量，解不出按未过期）→ **一个请求都不发**；② 有 refreshToken → 走 `/v1/auth/refresh` 续期，**保住原账号**，不重新设备匿名登录（以前是过期就直接再建会话，等于换号）；③ 都没有 → 才 POST `/v1/auth/login`。**后端是 HTTP 200 + 业务码约定**，`ApiResponse.ok` 只看状态码，所以 auth 相关请求必须再判 `code == 0`（`ApiClient._isSuccess`），否则 `code:30001` 会被当成成功、把 null token 写进存储，会话看着建好了实际没建。
- **匿名账号已下线（2026-10-11，前后端一起移除）**：后端删掉 `POST /v1/auth/login`（设备登录）与 `devId` 升级逻辑（`auth_service.device_login`、`schemas.DeviceLoginRequest`、`USER_EMAIL_ALREADY_BOUND=30105`、`sys_error` 外的 `USER_DEVICE_ALREADY_BOUND`），`users.dev_id` 列**保留**（历史数据），新账号不再写入；账号一律由邮箱创建，**未登录 = 没有令牌**。Flutter 侧：`ApiClient` 不再自动建会话（只整理/续期本地令牌，401 → refresh → 失败即清令牌），`DeviceIdStore` / `deviceIdProvider` 已删除，登录不再带 `devId`；测试统一用 `conftest` 的 `login` fixture（邮箱登录）。
- **进入即未登录 + 引导生成**：首次进首页弹一次生成引导（`state/start_guide.dart` + `pages/home/widgets/start_guide_dialog.dart`，标记 `faceflip_start_guide_shown_v1`）；未登录用户点「生成 / 使用模板」先走 `core/auth/require_login.dart` 的 `requireLogin()`（拉起 `/login`，`AuthPage` 关闭时带回是否登录成功）。强鉴权接口（下单、生成、钱包、收藏）未登录必然 401，所以**入口处先拦**，不等请求失败。
- **本地存储键统一 `yellowdog_` / `yellowdog:` 前缀**；与 H5 双轨期共享的键（`glam_access_token` / `glam_refresh_token` / `glam_user_id` / `glam_device_id` / 收藏键等）**必须保持原名**——改名等于把老用户的登录态与收藏清空。
- **请求地址拼接**：App 端请求路径自带 `/v1`，拼接时会剥掉 baseURL 结尾的 `/v1`；运行参数里的接口地址填到 `/app/api`（带不带 `/v1` 都行）即可打到 `/app/api/v1/*`。
- **int64 一律按字符串处理**：用户 ID、任务 ID、大额金币值在 Web 端会丢精度（见 PRD-10）。
- **前后端字段契约**以 App 端模型与后端 `schemas/` 为准；ORM snake_case ↔ 接口 camelCase 的转换只在 `schema` 层做，改动需两侧同步。
- 后台新增/修改接口要考虑**已发布接口的兼容**：**只增字段不改语义**，废弃字段走标记而非直接删除。

## 管理后台约定（`admin/api` + `admin/web`）

- 定位：复刻现网 AIGC 管理后台，模块清单 / 路由 / 字段口径以 [`doc/project-handover/aigc-admin管理后台/`](doc/project-handover/aigc-admin管理后台/) 交接资料为准；入口说明见 [`admin/README.md`](admin/README.md)。
- **需求文档在 [`doc/admin/`](doc/admin/)**：与 `doc/app/` 同构，一模块一份 `PRD-NN-主题.md`（不带版本号，编号按侧栏菜单顺序），共 14 份 + 索引 `README.md`（含跨模块通用口径与「本期不做」清单）。**实现或改动后台模块前先读对应 PRD**；统计口径以 PRD 为准，PRD 未覆盖的再回交接资料找依据。
- 技术栈：`admin/api` = Python 3.12 + uv + FastAPI + SQLAlchemy 2.0 async + Alembic（`uv.lock` 入仓）；`admin/web` = **Vite + React 19 + TypeScript + antd 6 + @ant-design/icons + TanStack Query**。
- **接口前缀 `/admin/api/v1`**（`ADMIN_API_PREFIX`）：网关按 `/admin/**` 路由；仅 GET / POST，信封与错误码（服务标识 `30`）与 H5 后台 `app/api/` 完全同构。
- **前端 UI 一律用 antd 6**（禁止另起一套组件/样式）：`ConfigProvider` 暗色 `theme.darkAlgorithm` + 主色 `#e0389d`，布局为 Sider 菜单 + Header + Content；消息提示用 `App.useApp()` 的 `message`/`modal`，不要全局静态调用。
- **前端依赖口径**：`antd` 6.x + `@ant-design/icons` 6.x；`@ant-design/pro-components` 目前只有 **3.1.x beta** 支持 antd 6（2.x 只认 antd 5），所以锁精确版本 `3.1.15-8`，升级前先确认 3.x 是否已转正。antd 6 原生支持 React 19，已移除 `@ant-design/v5-patch-for-react-19`。
- 前端单测跑在 jsdom：`src/test/setup.ts` 里补了 `ResizeObserver` 桩（antd 6 的 Table/Tooltip 依赖它，缺了直接抛错）；jsdom 里 `getByRole` 的可见性过滤会逐节点跑样式级联，一次整页查询能到 6s+，**写用例请用 `src/test/queries.ts` 的 `buttonNamed()` / `queryButtonNamed()` / `findButtonNamed()` / `tabNamed()` / `columnHeaderNamed()` / `menuItemNamed()` 代替 `getByRole`**（语义一致、快两个数量级），只有 `switch` / `spinbutton` 这类没有文案的角色才直接用 `getByRole`。
- 请求层统一在 `admin/web/src/api/request.ts`（base URL、Bearer、`30002/30003` 自动跳登录、信封解包），**页面不得直接 `fetch`**；登录令牌存 `localStorage` 键 `yellowdog_admin_token`。
- 运营台数据当前为**确定性种子数据**：`admin/api/src/yellowdog_admin/services/seed.py` 按 `(模块, 维度键)` 派生伪随机，刷新/翻页不跳变；各 service 均标 `TODO(data-source)`，业务库落地后换 repository，出入参不变。
- 已实现模块：概览、用户管理、反馈审核、数据详情、任务类型占比、反馈智能批审、模板统计（数据列表/置顶/指导意见）、充值监控、支付记录（充值订单明细，2026-10-18）、GPU 监控、自定义创作（freeform + HH 消耗）、渠道包、子渠道与像素、AppsFlyer 归因。
- 交接资料未覆盖的模块（子账号、推送任务、邀请返利、工具）在 `router.tsx` 中保留路由并挂 `PlaceholderPage`；实现新模块时替换占位、不要新增平行路由。
- 后端按业务域分文件：`schemas/{statistics,growth,feedback_ai,content,monitor}.py` ↔ `services/{statistics,channel,feedback_ai,content,monitor,growth}_service.py` ↔ `api/{statistics,growth,feedback_ai,content,monitor}.py`；新增能力按域归入，不要堆到 `console.py` / `console_service.py`。
- 生产约束：`DB_DIALECT=mysql` 且必须 `uv run alembic upgrade head`（禁 `create_all` 建生产表）；必须注入 `AUTH_JWT_SECRET`；敏感操作写 `admin_audit_logs`。
- **审计必须带关键参数（2026-10-28）**：`admin_audit_logs.detail` 是唯一参数载体，关键操作一律通过 `write_audit(..., params={...})` 或 `changes=(before, after)` 传结构化参数，由 `services/audit_service.py` 统一拼成 `key=value` / `key=旧值->新值`：改动类用 `changes`（只落变化的字段，无变化记 `changed=false`），状态流转与资金类用 `params`（金额、汇率、操作后余额等前后不变的量必须显式记，靠 diff 记不到）；口令、密钥、令牌键名命中 `SENSITIVE_KEYWORDS` 自动脱敏成 `***`，**不要自己拼敏感值**。新增 action 时同步 `admin/web/src/pages/AuditLogsPage.tsx` 的 `ACTION_GROUPS`，否则页面上筛不到。
- 提交前：`admin/api` 执行 `uv run ruff format .` + `uv run ruff check . --fix` + 增量 `uv run pytest tests/test_<域>.py`（只跑本次改动相关用例，不必全量）；`admin/web` 执行增量 `npx vitest run <相关用例>` + `npm run build`（含 `tsc --noEmit`）。
- **后台功能改动必须自带测试（2026-10-11）**：`admin/api` 新接口 → `admin/api/tests/test_<域>.py`（正常路径 / 未登录 `30002` / 缺权限点 `30004` / 参数校验 / 空结果）；`admin/web` 新页面或权限映射 → 就近 `*.test.ts(x)`（纯函数、`rbac.ts` 路由↔权限点齐全、请求层路径）。完整清单与写法模板走 skill `.kilo/skills/auto-add-tests/`。

## 工作约束

- 遵循本 AGENTS.md 与工作区根 `AGENTS.md`（`/data/ubtrobot/gitlab.ubtrobot.com/AGENTS.md`）；本仓为外部 GitHub 仓库，**推送、部署、镜像构建等外部副作用动作执行前必须先与用户确认**。
- **多功能点拆任务、一任务一提交**：一次请求包含多个相互独立的功能点（`app/flutter`、`app/api`、`admin/api`、`admin/web` 不同端或不同业务域 / 不同缺陷）时，**先拆成多个任务**（`todo` 逐项对应），每个任务独立实现、独立验证、**独立提交一次**；禁止多个功能点揉进一个 commit，也禁止把一个功能点拆成多个半成品 commit。同一功能点的实现 + 用例 + 迁移 + 文档属同一次提交；多个不相关缺陷按缺陷逐个提交（提交顺序按「后端 → 端侧」依赖排列，后者依赖前者时才串行）。
- 涉及接口 / 建表 / Python 工程代码改动前，先读 `backend-shared-assets/docs/` 对应规范；本仓 `doc/` 若不收录副本则以共享规范为准。
- 需求存在歧义或缺失时：① 以用户最新明确指示为准；② 以现有 H5 产物行为为准；③ 以 `doc/` 下设计文档为准；④ 仍无法判断则在代码中保留清晰适配点并标注待确认项，**不要臆造业务规则**。
- **App 端代码即主体代码**：所有前端行为在 `app/flutter/` 迭代，不要另建平行源码树；了解现网上游行为优先读 `doc/project-handover/现网H5/` 的产物（含 sourcemap），历史 H5 源码仅在 git 记录中。
- 正式文档统一放 `doc/`，命名模板 `<前缀>-<主题>-v<版本>.md`（`PRD-` / `DESIGN-` / `DB-` / `API-`）；新增文档按此约定，既有文档改名需先确认。
- **交接资料放 `doc/project-handover/`**：现网系统的产物、页面快照、接口说明与截图按子目录归集，每个子目录必须有 `README.md`，并被 [`doc/project-handover/README.md`](doc/project-handover/README.md) 索引收录；新增资料同步更新索引。该目录放**现网产物与文档**；App 端源码在 `app/flutter/`，此处不重复存放源码。
- **功能改动必须同步加测试用例（2026-10-11，由 AI 判定，无需用户开口；2026-10-11 扩到 `admin/api` + `admin/web`）**：动到 `app/api/`（接口 / service / repository / model / 迁移）或 `app/flutter/`（页面 / state / model / api 层 / `core/` / 路由）、`admin/api/`（接口 / service / model / RBAC 权限点 / 迁移）或 `admin/web/`（页面 / 组件 / hooks / `api/` 请求层 / `utils/` / `rbac.ts` / 路由）的功能代码时，**同批次把测试补上或同步改掉**——新增接口走完整分支（正常路径、参数校验、权限越权、冲突幂等、分页空结果、错误码常量），修 bug 必须先写能复现的回归用例（先红后绿），改行为时实现与用例一起改；禁止只改实现不改测试、禁止删断言 / `skip` / 放宽容错来凑绿。落点：`app/api` → `tests/test_<域>.py`（`conftest.py` 已提供 SQLite + 假 Redis 与 `client` fixture，用例不许连真实 MySQL/Redis），`app/flutter` → `test/<主题>_test.dart`（`flutter_test`，网络用 dio 假 `HttpClientAdapter`、存储用 `SharedPreferences.setMockInitialValues`，不新增测试依赖），`admin/api` → `tests/test_<域>.py`（`conftest.py` 提供独立 SQLite 文件库与 `client` / `empty_client` fixture，新增接口必须连带覆盖「未登录 `30002`」与「缺权限点 `30004`」两条），`admin/web` → 就近 `src/**/*.{test,spec}.{ts,tsx}`（vitest 3 + jsdom，`vite.config.ts` 的 `test` 段已配好，`src/test/setup.ts` 注册 jest-dom 匹配器；请求层 `vi.mock` 掉，不发真实请求）。写完必须真跑**增量用例**（不要求全量）：`app/api` → `cd app/api && uv run pytest tests/test_<域>.py`（+ `ruff format .` / `ruff check . --fix`），`app/flutter` → `cd app/flutter && flutter test test/<主题>_test.dart`（+ `flutter analyze`），`admin/api` → `cd admin/api && uv run pytest tests/test_<域>.py`（+ `ruff format .` / `ruff check . --fix`），`admin/web` → `cd admin/web && npx vitest run src/<相关用例>`（+ `npm run typecheck`）；跑不通就说清楚原因，不留红。完整清单、双端写法模板与踩坑点走项目 skill `.kilo/skills/auto-add-tests/`（`SKILL.md` + `references/testing-playbook.md`）。
- **测试只跑增量，不跑全量（2026-10-18 新增，2026-10-21 收紧为硬约束）**：功能改动**只跑与本次改动相关的用例**——本轮新增 / 修改的 `test_*.py` / `*_test.dart` / `*.test.ts(x)`，加上被改动代码直接影响的既有用例文件。**禁止 `uv run pytest` 裸跑全量**（`app/api` 全量 25 分钟量级，`admin/api` 亦然），也**不要把全量里与本轮无关的历史失败当阻塞**；只有用户明确说「跑全量」或发布前需要整体回归时才跑全量，并在回复里说明是用户要求。改动落在公共层（`conftest.py`、`models/base.py`、`db.py`、`app.py` 响应信封 / 中间件、共享 service / generator / provider、迁移）时，按影响面把相关模块的用例一并跑，不要只跑一个文件就交差。
  **改动 → 目标用例（先按这张表挑文件，再执行）**：

  | 改动落点 | 增量命令（在对应目录内） |
  | --- | --- |
  | `app/api/src/yellowdog/services/freeform_service.py` | `cd app/api && uv run pytest tests/test_freeform.py tests/test_dispatch.py` |
  | `app/api/src/yellowdog/services/{dispatch,generator}.py` | `cd app/api && uv run pytest tests/test_dispatch.py` |
  | `app/api/src/yellowdog/services/{task,wallet,oxpay}_service.py` 等其它域 | `cd app/api && uv run pytest tests/test_<域>.py`（明细：`test_task.py` / `test_wallet.py` / `test_oxpay.py` / `test_auth.py` / `test_content.py` / `test_community.py` / `test_feedback.py` / `test_upload.py` / `test_progress.py` …，按改动域名取对应文件） |
  | `app/api/src/yellowdog/api/<域>.py` / `schemas/<域>.py` | `cd app/api && uv run pytest tests/test_<域>.py` |
  | `app/api/src/yellowdog/config.py` | 受影响的域用例（列举具体文件，如 `tests/test_freeform.py tests/test_dispatch.py`） |
  | 公共层 / 模型 / 迁移 / 信封 | 按影响面列出的多个域用例 + `tests/test_startup_migrations.py` |
  | `app/api/src/yellowdog/utils/timeutils.py`、`admin/api/src/yellowdog_admin/timeutils.py`（对外时间口径，动到它影响所有时间字段） | `cd app/api && uv run pytest tests/test_timeutils.py` / `cd admin/api && uv run pytest tests/test_timeutils.py` + 受影响域用例 |
  | `app/flutter/lib/**` | `cd app/flutter && flutter test test/<主题>_test.dart` + `flutter analyze` |
  | `app/flutter/lib/core/time/iso8601.dart` | `cd app/flutter && flutter test test/iso8601_test.dart` + 受影响模型用例 |
  | `admin/api/**`、`admin/web/**` | `cd admin/api && uv run pytest tests/test_<域>.py`；`cd admin/web && npx vitest run src/<相关用例>` + `npm run typecheck` |

  新增或改过的用例必须真跑并全绿；测试红了就是没跑完，修到绿再提交。改动区域确实没有用例覆盖时，以静态校验（`flutter analyze` / `ruff format + check` / `npm run typecheck`）通过作等价条件并在回复里点明。**回复里要写清实际跑了哪几个用例文件**（不要只写「测试通过」）。
- **任务收尾自动刷新本地 dev 服务（2026-11-06，由 AI 判定，无需用户开口）**：改完 `app/api` / `admin/api` / `admin/web` / `app/flutter` 里会影响运行时的东西（代码 / 配置 / 迁移 / 资源）后，在输出「已完成 / 改动如下」这类收尾结论之前，先跑 `bash .codebuddy/skills/dev-service-refresh/scripts/dev-refresh.sh`，把本机正在跑的 12100-12103 刷一遍让改动立刻可见：两个后端 `touch` 被 uvicorn 监视的 `src/<pkg>/app.py` 触发 worker 重载（只改 mtime，`git status` 仍干净），App 端页面给 flutter 进程发 `SIGUSR1` 热重载（`--full` 发 `SIGUSR2` 热重启），admin/web 只探测并提示（vite HMR 自己热更）。服务没起 / 端口没人监听 / 监听进程不是预期程序时只打印「跳过」——不替用户起服务、不重启进程、不杀进程、不碰任何远程环境，退出码恒 0 不阻断提交；**改 `.env*` 不在这条链路上**（watchfiles 忽略点开头路径），脚本只在发现 `.env*` 比进程新时提示要手动重启。**启动脚本不动重载节奏**（2026-11-06 明确口径）：`tool/dev.sh` 保持「一保存就重载」的即时行为（uvicorn `--reload` / flutter 轮询发信号），**不加静默窗口、不去抖**——重载频繁的问题由「AI 收尾统一刷这一次」来解决，别再去启动脚本里调 `--reload-delay` 之类的节流参数。收尾顺序：跑增量测试 → 刷新本地服务 → 提交推送。口径走项目 skill `.codebuddy/skills/dev-service-refresh/`（`SKILL.md` + `scripts/dev-refresh.sh`，`alwaysApply: true`）。
- **任务完成即自动提交并推送（2026-10-11 用户授权，由 AI 判定，无需逐次确认）**：**判定权在 AI**——收尾时自己判断本次任务是否已完成，完成就提交推送，不要等用户再说"提交 / 推送"；判定权在 AI。判定的四条硬标准：① 任务目标已达成：功能 / 修复写完，todo 全清、没有"下一步再做"的断点、没留下必须用户补充才能跑通的部分；② **涉及代码改动时，增量测试已跑完且全绿**：`app/flutter/` → `cd app/flutter && flutter test test/<主题>_test.dart`；`app/api/`、`admin/api/` → `uv run pytest tests/test_<域>.py`（在各自目录内跑）；`admin/web/` → `cd admin/web && npx vitest run src/<相关用例>` + `npm run typecheck`；只跑本次改动相关的用例文件（含被改动代码直接影响的既有用例），**不要求全量**；改动区域确实没有测试覆盖时，以静态校验通过（`flutter analyze` / `ruff format .` + `ruff check . --fix`）作等价条件，并在回复里点明；**测试失败就是没跑完，不提交**，先修到通过再提交，绝不推跑不过测试的代码；**例外：改动前就红的基线用例（与本轮改动无关，如 `app/flutter` 的 `test/i18n_test.dart` 缺翻译 key 静默回落）不算阻塞**，判定与处理见 `.kilo/skills/auto-commit-push/SKILL.md` 第 3 节「基线失败」，命中时照常提交并在回报里点明，不要让一条历史红永久卡住所有提交；③ 同一个改动带出来的文档、迁移、配置一并提交（它们是这次代码改动的一部分）；④ 用户没说"先别提交 / 等我确认 / 还要再改"。不满足任一条件（任务目标未达成、测试没跑完或用例红了未修、半成品、探索性试写、用户明确暂缓、改动只在别的仓库）就**不提交**，在回复里说明原因。纯文档 / 配置 / skill 类任务完成后同样提交（第 ② 条测试不适用，改动大时至少确认链接与格式）。这是第 267 条"外部副作用先确认"的**显式例外**，推送本身不再逐次请示；但 force push、改 git config、`--amend` 他人提交仍然禁止。走本仓项目 skill `.kilo/skills/auto-commit-push/`（`SKILL.md` 流程 + `scripts/commit_push.sh` 执行，含本仓 scope 表与仓库边界；另有一份通用版，真源 `backend-shared-assets/skills/auto-commit-push/`、用户级安装于 `~/.kilo/skills/auto-commit-push/`，供其它仓库复用——通用能力先改共享真源，本仓副本只保留 yellow-dog 特有约定）把**本次任务相关的改动**提交到当前分支并推送 `origin`。**提交必须显式列出本次任务的路径**（`commit_push.sh` 默认拒绝无路径调用，只在工作区确认无他人残留改动时才用 `--all`）——多会话会并行改同一个工作区，不带路径会顺手带走别的会话的改动；提交信息规范见该 skill 的 `references/commit-convention.md`（含本仓 scope 表），仓库边界与禁止项（force push、改 git config、`--amend` 他人提交、提交 `.env` / `*.pem` 等敏感文件）见该 skill。暂存区里与本次任务无关的旧改动**不**顺手带走，先与用户确认；脚本会拦截敏感文件，命中时先告知再处理。

## Flutter 重构（2026-10-10 启动）

**决策**：H5（React + Vite）用 Flutter 全量重写，**一套代码同时产出 Web 与 iOS/Android**。当前阶段 Web 优先（仍跑在现有原生壳 WebView 里，原生端后续接入），一次性全量重写而非渐进双轨。技术栈 **Riverpod + go_router**（对应现在的 zustand + react-router）。

**工程**：`app/flutter/`（Flutter 3.47.4 / Dart 3.13.3，`flutter create --platforms=web,android,ios`）。

**Bridge 平台抽象**（最关键的一层，`lib/core/native/`）：

- `bridge.dart`：定义 36 个原生方法的**平台无关契约** + iOS `typeName` 映射（`getInfo → getAppInfo`、`h5Ready → Ready`，与 `h5/src/bridge/nativeBridge.ts` 逐条对齐）。
- `bridge_web.dart`（当前主力）：`dart:js_interop` 直接调现有 JS Bridge，协议与 H5 完全一致——消息名 `syncAppInfo`；iOS `webkit.messageHandlers.syncAppInfo.postMessage({requestId,typeName,params})`；Android `YellowDogAndroid.postMessage(obj)` / `YellowDogAndroidBridge.postMessage(JSON串)`；回调 `window.__syncAppInfoResolve`；事件 `yellowdog:native-event`。
- `bridge_mobile.dart`（待原生接入）：MethodChannel `yellowdog_bridge` + EventChannel `yellowdog_bridge_events`，方法名用逻辑名，typeName 映射复用同一份 `kNativeTypeNames`。
- 条件导出：`export 'bridge_stub.dart' if (dart.library.js_interop) 'bridge_web.dart' if (dart.library.io) 'bridge_mobile.dart';` —— 业务代码不区分平台。

**必须与 H5 保持一致的硬约束**（改任意一侧都要同步另一侧）：

- localStorage key：`glam_access_token` / `glam_refresh_token` / `glam_user_id` / `glam_device_id` / `yellowdog_runtime_config_cache`（双轨期共享登录态）。
- 运行时配置三级加载：`?cfg=<https url>` → 本地缓存 → 同目录 `./runtime-config.json`（`lib/core/config/runtime_config.dart`）。Flutter Web **没有** H5 index.html 那段内联预取脚本，靠第 3 级兜底。
- 请求头：`X-Client-Container/Platform/Version/Channel` 由运行时配置开关 `enable_client_headers` 控制；`/v1/login` 设备匿名登录、`/v1/refresh` 续期、401 → refresh → 重建设备会话的重试链。
- 埋点事件名（181 个）迁移时必须保持原名，否则数据断档。

**已知风险**：

- Dart 编译到 Web 时 `int` 是 JS number（53 位），后端 int64（userid、大金币值）会丢精度；H5 用 `json-bigint`（storeAsString）规避。Flutter 侧需给 dio 挂自定义 Transformer（标记 `TODO(flutter-bigint)`）。
- 体积：`main.dart.js` 2.3MB（未压缩），明显大于 H5 的 404KB gzip，首屏压力更大，需评估 canvaskit/skwasm 渲染后端与分包。

### 进展（2026-10-10：首页信息流落地）

工程内执行 `flutter analyze` / `flutter test` / `flutter build web --release` 均通过（9 个单测）。

| 层 | 文件 | 对齐的 H5 真源 |
| --- | --- | --- |
| 主题 | `lib/theme/app_theme.dart`（`AppColors` + `AppBackground`） | `h5/src/styles/global.css` 的 `:root` token |
| 多语言 | `lib/core/i18n/app_locale.dart`（9 语言白名单 + `normalizeAppLocale`）、`app_strings.dart`、`locale_provider.dart` | `utils/locale.ts`、`i18n.ts`、`state/appState.ts`（存储键 `yellowdog_locale`） |
| 资源 URL | `lib/core/media/resource_url.dart` | `utils/resourceURL.ts`、`utils/mediaURL.ts`、`api/templates.ts` 的 `resolveMediaURL` |
| 模型 | `lib/models/home_feed.dart`（`HomeFeedKind` / `FeedCatalog` / `FeedPage` / `FeedItem`） | `api/templates.ts` 的 `templateSummaryFromHomeFeedItem`（20+ 字段别名同序兜底） |
| 接口 | `lib/api/templates_api.dart` + `api_providers.dart` | 契约文档 §3.2 |
| 收藏 | `lib/state/favorites.dart` | `utils/favorites.ts`（存储键 `glam.favoriteTemplates.v1`，上限 500，**无接口**） |
| 页面 | `lib/pages/home/home_page.dart` + `widgets/{catalog_bar,feed_card}.dart` | `HomePage.tsx` |

落地口径（后续页面沿用）：

- **首页默认是两列网格，不是 Reels 全屏**：`HomePage.tsx:302` 的 `showReelFeed` 是硬编码 `false`，现网永远走 `splitIntoColumns(items, 2)` 的两列瀑布；Reels 全屏上下滑与右侧 43px 操作栏的代码分支保留但未启用。因此本文件里「首页 Reels 全屏上下滑」的描述**与现网产物不符**，以源码为准。
- `HomePage(kind:)` 一个实现覆盖 5 个入口：`/home`（`all`，带分类横滑条）与 `/new`、`/trending`、`/dance`（独立路由、顶部返回栏、无底部导航）；`/template/:taskType/:templateId` 先挂占位页 `pages/detail/template_detail_page.dart`，模板详情域未迁移。
- **image_v2（图集/单图模式切换）未迁移**：需要 `/v2/t1/gallery` 与 `imageMode*` 模式 tab，标 `TODO(flutter-home)`。
- 分类：`all` 取 `home_template_feed/config` 的 `catalogs`；`video` 另合并 `/v1/catalogs?titleId=3`；列表头部插「全部」。
- 分页：页码式走 `pageNum/pageSize`，`/v2/*` 走 `cursor/limit`；触底阈值 `max(360, 1.1×视口高)`（对齐 `handleScroll`）。
- 卡片点击 → `/template/{taskType}/{tid}`；收藏为纯本地操作 + SnackBar 提示；**首页没有点赞与分享**。

#### 2026-10-10（第二轮）：模板详情 + 生成下单 + 任务状态

`flutter analyze` / `flutter test`（19 个）/ `flutter build web --release` 通过。

| 层 | 文件 | 对齐的 H5 真源 |
| --- | --- | --- |
| 模型 | `lib/models/template_detail.dart`（`TemplateDetail` / `TemplateUiOptions`）、`lib/models/task.dart`（`TaskRecord`） | 契约文档 §3.2/§3.3、`utils/templateProtocol.ts` |
| 下单参数 | `lib/state/generation_params.dart`（纯函数，可单测） | `utils/generationTask.ts` `buildGenerationUserParams` |
| 接口 | `lib/api/template_api.dart`、`task_api.dart`、`upload_api.dart` | `api/templates.ts:335`、`api/task.ts`、`api/upload.ts:37` |
| 选图 | `lib/core/media/photo_picker.dart` | `nativeBridge.pickPhoto`（新增 file_picker 兜底） |
| 页面 | `lib/pages/detail/template_detail_page.dart`、`lib/pages/task/task_status_page.dart` | `TemplateDetailPage.tsx`（3049 行）、`TaskStatusPage.tsx` |

落地口径（与 H5 逐条对齐，容易踩错的几条）：

- **详情接口按 taskType 分三个路径**：`1 → /v1/t1/{tid}`、`2 → /v1/t2/{tid}`、`3 → /v1/t3/{tid}`；**t1/t2 带 `locale`，t3 不带**。路由 `/template/:taskType/:templateId` 缺失时默认 `taskType=3`。
- **下单 `userParams` 是字符串化 JSON**（不是对象），body 只有 `taskType`/`tid`/`userParams`；返回 `task_id`，随后 `pushReplacement('/task/{id}')`。
- **上传** `POST /v1/upload`：multipart 字段固定 `type=input` + `file`，返回 `{url}`（`url|path|file_url|fileUrl`）。进度钳在 2%~98%（真实完成看响应）。
- **画质默认 720P**；**多人模板（requiredInputSlots>1）锁 480P**；视频类（taskType 2/3）额外带 `Param_Resolution`（小写）+ `Param_Resolution480`（迁移期旧标志位）；v2 判定是 `version=="v2" || uiOptions != null || 是画廊`。
- **任务状态页轮询** `GET /v1/tasks/{id}`，每 3s 一次直到成功/失败（status 2/3）；失败也继续重试到页面销毁。

**新增依赖**：`file_picker ^13`（Web/桌面选图兜底）。Native 侧仍优先走 Bridge `pickPhoto`，浏览器里 Bridge 抛 `BRIDGE_UNAVAILABLE`，必须靠它兜底，否则上传链路断。
**坑**：file_picker 13 没有 `FilePicker.platform`，也没有 `withData`，正确写法是 `FilePicker.pickFile(type: FileType.image)` + `await file.readAsBytes()`。

**本轮未迁移**（`TODO(flutter-detail)`，单独立项）：
预览视频自动播放（需 video_player，本轮预览降级为静态图）、参数 Sheet（appearance/scene/aspectRatio）、服装库、金币不足的充值弹窗、历史照片选择器。

#### 2026-10-10（第三轮）：任务结果的后处理

`flutter analyze` / `flutter test`（31 个）/ `flutter build web --release` 通过。

| 能力 | 实现位置 | 对齐的 H5 真源 |
| --- | --- | --- |
| 满意度确认（去水印 + 存相册） | `pages/task/task_status_page.dart` | `TaskStatusPage.tsx:410-424,848-925,1836-1938` |
| 免费重生成（同图 / 新图） | 同上 + 详情页 `regenerateFromTaskId` | `TaskStatusPage.tsx:1149-1380`、`TemplateDetailPage.tsx:1027-1109` |
| 模板评分 | 同上 | `components/TemplateRatingCard.tsx`、`api/templates.ts:351-372` |
| 接口 | `api/task_api.dart`（satisfaction / eligibility / animate / list / delete）、`api/template_api.dart`（rating） | 契约文档 §3.3、§3.2 |

落地口径（这几条最容易写错）：

- **满意度不是自动提交的**。展示条件是：任务成功 + `satisfaction_pending=true` + **非社区**（`content_source != community`）+ **非图片任务**（`taskType != 1`）+ 非重生成任务（`source_task_id` 为空）+ 尚未表态。点「确认并保存」才 `POST {satisfied:true}`，成功后**本地**置 `satisfied=true` 去水印并继续存相册，**不重新拉任务**。
- **点「不满意」是两步**：先 `POST {satisfied:false}`，再查 `regeneration-eligibility`；无资格只提示 `regenerateUnavailable`，不展开方案面板。`reason` 只记录、不展示，`regeneration_expires_at` 不展示。
- **`regeneration_mode`（same_photo / new_photo）不下传给接口**：它只是本地选项，下单统一只带 `regenerateFromTaskId`。同图重生成直接复用源任务的 `user_params`；新图则回模板详情重新选图（源任务 ID 经路由 extra 带过去）。
- **模板评分**：`templateType` 取任务的 `task_type`（**不是别的枚举**）；展示不检查 `can_rate_template`，只看「成功 + 有 tid + 有结果」；`task_rating_stars` 是初始星数，`task_rating_submitted` 决定锁定；点星即提交，之后锁定。
- **结果保存走 Bridge `saveMediaToAlbum`**；H5 的任务页**没有分享入口**（别照抄首页/社区的分享）。
- **坑**：任务详情里的 `user_params` 是**字符串化的 JSON**，同图重生成要原样带回，必须先反序列化；解析失败要退化成空参数而不是让整条任务解析崩掉。

**本轮未迁移**（`TODO(flutter-task)`）：批量保存多张结果、`POST /v1/tasks/{id}/animate` 转视频（要先有自由创作表单页）。

#### 2026-10-10（第四轮）：我的创作

`flutter analyze` / `flutter test`（37 个）/ `flutter build web --release` 通过。

| 层 | 文件 | 对齐的 H5 真源 |
| --- | --- | --- |
| 列表控制器 | `lib/pages/me/creation_list_controller.dart` | `MyCreationPage.tsx:34-63,134-143`、`utils/creationTasks.ts` |
| 页面 | `lib/pages/me/my_creation_page.dart` | `MyCreationPage.tsx:645-777`、`components/TaskDeleteConfirmModal.tsx` |
| 接口 | `api/task_api.dart`（list / delete / markTaskRead） | `api/task.ts:43-81` |

落地口径（容易写错的几条）：

- **H5 的独立 `MyCreationPage` 其实没挂路由**：`router.tsx:57` 把 `/me/creations` 重定向到 `/?tab=me`，真正生效的是 Me 页内嵌的 `MyCreationContent`（`embedded hideFilters resultsOnly`）。所以这里做成**可内嵌组件**（保留 `showFilters` / `resultsOnly` 两个开关），当前先挂在 `/me/creations` 独立路由上，将来直接塞进 Me 页。
- **「全部」档要并发打两次**：一次不带 `contentSource`、一次带 `community`，按 `task_id` 去重后按 `create_ts` 倒序合并。只打一次会漏掉社区作品。
- **状态档位的值就是接口 `status`**：all=不传 / pending=0 / running=1 / success=2 / failed=3；`pageSize` 30；翻页终止条件是「本页为空」或「首条 task_id 与已加载的重复」。
- **卡片不显示**模板标题、时间、金币、失败原因（这些字段 model 里有，但 H5 本页没渲染）。
- **徽标优先级**：`pendingConfirmationBadge` > `regenerationBadge`（`plan_type == 3`）> 状态文案。
- **未读红点是本地算的**：`status==2 && !is_expired && read_status != 1`。（独立的未读数接口是 `GET /v1/tasks?readStatus=0`，只被 BottomNav 用，本页不请求。）
- **点卡片标记已读**：`PATCH /v1/tasks/{id}?update_mask=read_status` body `{readStatus:1}`（契约文档 §3.3 标注新后台应改 POST）。本地先置位再请求，失败不影响进详情。
- **失败任务重试**带 `regenerateFromTaskId` 重新下单；源任务没有 `user_params` 时提示 `retryTaskUnavailable`（不是静默失败）。
- **保存前**若该任务还挂着待确认满意度，拦下来提示 `taskPendingConfirmationSaveBlocked`。
- **进度刷新**：H5 走 WebSocket（`utils/taskProgressWs.ts`，`wss://host/ws?token=`，指数退避 1s→30s、75s 无消息重连）。Flutter 侧**暂用 10s 轮询**，且只 `getTask` 列表里仍在跑的项再替换，**不整页重拉**（避免打断滚动）——差异已标 `TODO(flutter-creations)`。

**本轮未迁移**：过期作品的批量清理、社区空态的「探索社群」入口（要等社区域）。

#### 2026-10-10（第五轮）：Me 页

`flutter analyze` / `flutter test`（40 个）/ `flutter build web --release` 通过。

| 层 | 文件 | 对齐的 H5 真源 |
| --- | --- | --- |
| 页面 | `lib/pages/me/me_page.dart` | `MePage.tsx:253-445` |
| 接口 | `lib/api/user_api.dart`（gold / profile / nickname） | `api/user.ts:9,90-92`、`api/userProfile.ts:14,28` |
| 收藏明细 | `lib/models/favorite.dart` + `favoritesProvider` 增补 | `utils/favorites.ts`（localStorage） |
| 内嵌 | `my_creation_page.dart` 新增 `embedded` / `onUnreadCountChange` | `MyCreationPage.tsx:85-95,399-401` |

落地口径（容易踩错的几条）：

- **金币接口是 `GET /v1/users/{userid}/gold`，不是 `/v1/wallet`**（全仓搜 `/v1/wallet` 0 命中）。响应取 `balance`，兼容 `gold_balance/goldBalance/user_gold/userGold/coins/gold`，负数归零。
- **官方收藏没有服务端接口**，就是本地 localStorage（H5 键 `glam.favoriteTemplates.v1`，Flutter 侧 `FavoritesController` 用同一个键，双轨期收藏夹不丢）。只有社区收藏才有 `GET /v1/community/favorites`。
- **Me 页内嵌创作列表的四个 prop**：`embedded`（不渲染自己的 Scaffold/AppBar）、`hideFilters`（**只**隐藏状态筛选行，source tabs 仍显示）、`resultsOnly`（隐藏卡片 footer、保存、重试按钮，成功态不显示状态徽章）、`onUnreadCountChange`。
- **未读红点只回传给 Me 页的 tab**，底部导航不消费它（H5 的 BottomNav 用自己的 `readStatus=0` query + `yellowdog:task-read-status-updated` 事件刷新）。
- **收藏 entry 补了 `taskType` 字段**（详情页路由要用）。双轨期要兼容 H5 只写 `kind` 的老数据：`image→1`、`dance→3`、缺失兜底 3。

**刻意没做的（不造假入口）**：H5 的 Me 页还有 4 个入口——设置 `/me/settings`、金币记录 `/me/wallet`、提现 `/withdraw?source=me`（另依赖 `GET /v1/referral/config` 的 `withdrawEnabled`）、创作者中心 `/community-creator`，以及点顶栏余额弹充值。这些页面都还没迁移，所以**不做成点了没反应的死按钮**，统一标 `TODO(flutter-me)`，等各自页面落地再加。
**未登录横幅同理**：H5 的显示条件是 `emailLoggedIn = !!getBoundEmail()`（是否已绑邮箱），而 Flutter 侧目前只有设备匿名会话的 userId，判定不了，横幅与登录/注册按钮暂不显示。

#### 2026-10-10（第六轮）：自由创作（Freeform）核心闭环

`flutter analyze` / `flutter test`（48 个）/ `flutter build web --release` 通过。

| 层 | 文件 | 对齐的 H5 真源 |
| --- | --- | --- |
| 模型 | `lib/models/freeform.dart`（`FreeformConfig` / `FreeformGeneration`） | `api/freeform.ts`、`FreeformPage.tsx:4338-4342` |
| 接口 | `lib/api/freeform_api.dart`（config / i2i / i2v / animate / list / get / delete） | `api/freeform.ts:122-268`、契约文档 §3.4 |
| 页面 | `lib/pages/freeform/freeform_page.dart`、`freeform_detail_page.dart` | `FreeformPage.tsx`（**3640 行**） |

落地口径（这几条不查真源一定会写错）：

- **只有两种 modality：`i2i`（图生图）与 `i2v`（图生视频）**——**图片在 i2v 必填**（主图校验 `FreeformPage.tsx:1442`）；**i2i 自 2026-10-21 派单协议起允许 0 张**（`type=9` 纯文生图，见下一条）。**没有负向提示词**（全文件搜 `negative` 0 命中）。
- **2026-10-18 起改为「单模板视频」模式；默认模板按 2026-10-20 派单协议是 `free_w_i2v_1`（`tp_id=800001`）**：模板在**运营后台 → 自定义创作 → 模板配置**选择（App 库 `freeform_configs` 单行配置，写入即生效）。App 创作页 2026-10-18 起一度「固定 i2v、隐藏图生图切换」，**2026-10-24 起恢复双模式**（顶部「图片 / 视频」两个 tab，默认视频，详见 `app/flutter/AGENTS.md`）。模板服务 2026-10-20 那份文档是**自由创作视频的最新协议**：`type=8`（Wan3 多图参考生视频）、`model_type` 归一 `wan3`、**动作由用户 `prompt` 驱动**（必填）、参考图 1～4 张、**不传 `action_gray_image`**——与固定动作模板（带灰模、姿势由灰模固定，如 800004 / `new_video_1791998380396`）区分开。后端每次请求读库配置，库内无配置行（或配置的模板还没同步到本地）时回退 `FREEFORM_TEMPLATE_TP_SID` / `FREEFORM_TEMPLATE_TP_ID` / `FREEFORM_TEMPLATE_ORDER_TYPE` / `FREEFORM_TEMPLATE_MODEL_TYPE`（默认 `free_w_i2v_1` / `800001` / `8` / `wan3`）。**只带模板自身的灰模图**：模板同步记录里有 `action_gray_images` 才追加，自由创作模板没有就不发。
- **自由创作生图按 2026-10-21 协议走 Wan3 自由生图（`type=9`）**：虚拟模板 `tp_sid=free_wan_i2i_1` / `tp_id=900001`（`model_type` 归一 `wan3`），`prompt` 必填（≤4000 字符，用户输入），`images` **0～4 张可选**（0 张＝纯文生图，≥1 张首张为底图、其余 `reference_images`，本服务产品上限仍是 3 张），**不传 `action_gray_image`**；成片是**图片**（查单 `result_url` 为 CDN 图地址）。与旧的 Comfy 自由创作生图（`type=3` / `300001` / `flux`）**不是一回事**。取值走 `DISPATCH_TP_SID_I2I` / `DISPATCH_TP_ID_I2I` / `DISPATCH_MODEL_TYPE_I2I`（默认 `free_wan_i2i_1` / `900001` / `wan3`），**不要套 `FREEFORM_TEMPLATE_*`**（那是视频单模板设置）。协议见 `doc/project-handover/20261021/5派单接口_自由创作生图_模版id：900001.md`。
- **官方模板「图生图」下单走 `type=9`（2026-10-23 修正，与视频模板对称）**：派单服务的部署档位（conf2）**只收 type 5–9**，按旧表给图生图模板发 `type=1` 会被 400 拒（`deploy profile conf2 allows order types 5–9 only (got 1)`），表现是「点生成 → 扣币 → 轮询 → 失败退款」。视频模板先切到 8 才跑通，生图同样必须切到 9。映射两处：`upstream_template._ORDER_TYPE_BY_SYNC_TYPE`（同步 type 1 / 9 → 下单 9）、`task_service._order_type_for`（**图片任务也认 Wan3 类型**，不再只认视频）；`tp_id` 缺失时按 `DISPATCH_TP_ID_I2I`（900001）兜底。**Wan3 单必须有正向 prompt**：模板自带那份走同步字段 `prompt_image`（视频是 `prompt_video`），缺了上游下单会先回 200、**执行阶段**才报 `wan3: prompt required`（2026-10-23 实测），所以 `dispatch.build_order_payload()` 提前判失败（省掉一次往返），同步侧 `_warn_if_wan3_without_prompt()` 也会 warning——**图生图模板上架前必须让运营配上 `prompt_image`**。
- **上游报 400 `template not found` 时自动补登记再重试（2026-10-21）**：派单服务按 `tp_sid` 匹配**已登记**的模板（登记动作是 `POST /api/templates`，运营侧一次即可，见 `doc/project-handover/20261020/4派单接口_自由创作视频_模版id：800001.md`），而自由创作的虚拟模板 `free_w_i2v_1` 只有本服务知道 —— 漏登记时 `POST /api/new_orders` 会全量 400 `template not found: register POST /api/templates with tp_sid first`，每单都判失败退款（2026-10-21 测试服真实故障）。现在 `services/dispatch.py` 新增 `is_template_missing()` / `build_register_payload()` / `ensure_template_registered()`：`NewOrdersGenerator.submit()` 识别该错误后按同一单的 `tp_sid / tp_id / type` 补登记一次再重试下单；**登记也失败仍按原口径判失败退款**，绝不伪造结果。**登记体有两条实测硬约束（2026-10-21 逐字段探出来的，上游失败只回 `{"ok":0}`，不打 message）**：①`workflow` **必填且必须是非空 JSON 字符串**——传对象、`{}`、普通字符串一律 400，内容只按 ComfyUI API Format 校验（有个带 `class_type` 的节点就行，节点名随意），Wan3 走 Elune 不跑它，用 `dispatch.PLACEHOLDER_WORKFLOW` 占位；②**绝不能带 `model_type`**——登记接口不认 `wan3` / `flux` / `"1"`，带上必 400（`model_type` 只在**下单**时需要，由 `build_order_payload()` 归一）。登记结果按 `tp_sid` 缓存在进程内（`dispatch._registered_tp_sids`），不会每单都发 `POST /api/templates`。开关 `DISPATCH_AUTO_REGISTER_TEMPLATES`（默认 **true**，compose 已透传），关掉即退回「运营侧预登记」口径。它与 `DISPATCH_REGISTER_TEMPLATES`（模板同步那条链路，需要 ComfyUI 工作流、默认关）**是两件事，别混**。
- **查单走轻量接口 + 5s 节流（2026-10-21 上游升级）**：轮询上游一律用 `GET /api/order_status/{id}?view=status`（单条**轻量**查单，只回状态字段，`{id}` 是下单返回的 `id`），**不要拿 `GET /api/new_orders/{id}` 轮询**——那条回完整记录（含工作流），上游压力大。拿到终态（success / failed）后再**补一次** `GET /api/new_orders/{id}` 取 `result_url` / `error`（`NewOrdersGenerator._fetch_detail()`）。服务端按 `DISPATCH_POLL_INTERVAL_SECONDS`（默认 **5**，compose 已透传）**按作业节流**：端侧 `Poller` 最快 2s 一次，间隔内的请求直接返回「保持原状态」、不打上游；设 0 关闭（仅本地 dev / pytest 用，`test_dispatch.py` 的 autouse fixture 就是这么做的）。失败不改变状态，端侧下一拍再来。
- **进度查询是 `/v1/freeform/generations/{id}`，不是 `/v1/generations/{id}`。** 状态 0/1/2/3 与 TaskRecord 同一套。
- **所有档位（分辨率、时长、关键帧模式、`maxRefUrls`、价格）都由服务端 config 下发**（`GET /v1/freeform/i2i|i2v/config?locale`），源码里**没有任何硬编码兜底值**，所以 Flutter 侧也不造。选择顺序是「当前值 → `default*` → `options[0]`」（H5 的 `selectConfiguredValue`）。
- **分辨率是 480p(standard)/720p(high) 语义**，具体字符串由后端下发（H5 靠包含 `720|high|hd|hq|高清` 来判断档位）。
- **参考图数量**：i2i 最多 2 张且不超过 `maxRefUrls-1`；i2v 用 `reference_direct` 关键帧时参考图为 **0**。
- **价格**：i2i = 选中分辨率的 `consumedGold`；i2v = `priceTable` 命中 `(durationSeconds, resolution)` 的行，没命中回落到分辨率单价；总价 = 单价 × 批量数（1-5，默认 1，**并发**创建）。
- **`wanSpeed` 不传**：原 H5 页面也没传（四处创建调用都不带），别自作主张加。

**本轮未迁移**（`TODO(flutter-freeform)`）：历史库（收藏/置顶/搜索/筛选/删除/Reuse settings/衍生视频列表）、快捷提示词模板 `GET /v1/freeform/prompt_templates`、快捷充值弹窗、社区入口、结果预览弹层。
**进度刷新**：H5 走 WebSocket（`connectTaskProgressWebSocket`），Flutter 侧用 3s 轮询替代（与创作列表同一取舍）。
**视频结果**：详情页仍是占位，接 `video_player` 后替换。

#### 2026-10-10（第七/八轮）：视频播放

`flutter analyze` / `flutter test`（49 个）/ `flutter build web --release` 通过。
新增依赖：`video_player ^2.14.1`（web 实现 `video_player_web` 由 federated 自动带入，无需单独声明）、`visibility_detector ^0.4.0+2`。

| 层 | 文件 | 对齐的 H5 真源 |
| --- | --- | --- |
| 通用播放器 | `lib/ui/app_video_player.dart` | H5 **没有**通用组件，各页内联 `<video>` |
| 信息流卡片 | `lib/pages/home/widgets/feed_card.dart` | `HomePage.tsx:3160-3291`（`TemplateCardMedia`）、`:2884-2899` |
| 声音互斥 | `lib/state/feed_sound.dart` | `HomePage.tsx:205,1770,2982-3001` |

接入点：模板详情预览（poster 用预览图）、任务结果视频、自由创作结果、首页信息流卡片。

落地口径：

- **H5 全库没有封装视频组件**，各页面内联 `<video>`，但参数一致：`loop` + `playsInline` + `preload=auto`，**一律不加 controls**，`muted` 由声音开关控制（默认静音）。
- **声音按钮文案描述的是当前状态**：`aria-label={muted ? soundOff : soundOn}`。
- **信息流可见性**：`visible = isIntersecting && ratio >= 0.25`（瀑布流 0.18；Reel 单页 `index === currentIndex`）。**不可见时根本不创建播放器**（`HomePage.tsx:3174` 把 `src` 置空）——这是性能关键，别一进页面就把整屏视频都初始化了。
- **离开视口**：`pause()` + `currentTime = 0`（`parkVideoAtFirstFrame`，`:3190`）。
- **声音互斥**：`cardSoundTemplateKey` 只存一个 key，点第二张时第一张自动静音。
- **`video_player` 没有 muted**，用 `setVolume(0/1)` 代替；iOS 上系统可能拒绝有声播放（H5 同，`TaskStatusPage.tsx:1551-1558`）。
- **任务结果的声音按钮**：H5 只在接口返回 `resultVideoHasAudio` 为真时才渲染，我们没有这个字段，一律给（已注释标注）。

**坑**：riverpod 3 **移除了 `StateProvider`**，写 `feedSoundTemplateIdProvider` 时撞上了，改用 `Notifier` + `NotifierProvider`。

**未迁移**：Reel 全屏播放页（H5 的 `/dance` 等独立路由走的是单卡全屏形态）、H5 首页 Reel 的「页面级全局静音，切 tab / 页面隐藏自动复位」。

#### 2026-10-10（第九轮）：App 端模块需求文档

产出 `doc/app/`，**一个模块一份 markdown**，共 13 份 + 1 份索引（`README.md`）。

| 编号 | 模块 | 编号 | 模块 |
| --- | --- | --- | --- |
| PRD-01 | 首页信息流 | PRD-08 | 视频播放 |
| PRD-02 | 模板详情与下单 | PRD-09 | 路由与导航外壳 |
| PRD-03 | 任务状态与结果 | PRD-10 | 网络层与鉴权 |
| PRD-04 | 我的创作 | PRD-11 | 端能力 Bridge |
| PRD-05 | Me 页 | PRD-12 | 多语言与运行时配置 |
| PRD-06 | 自由创作 | PRD-13 | 媒体选择与上传 |
| PRD-07 | 本地收藏 | | |

「第九轮」最初是按代码反推的功能说明；**2026-10-10 起调整为面向「产品 ↔ 技术」沟通的需求文档口径**：

- 不写文件名、行号、内部组件名等技术实现细节（想查实现直接读 `app/flutter/lib/`）
- **不写 API 设计**：不出现请求方法、路径、字段名、错误码——这些属于 `doc/API-现网H5接口契约-v1.0.md`
- 每份统一 8 节：模块概述 / 用户场景 / 功能需求（FR-xx）/ 页面结构与跳转 / 业务规则与关键判定 / 异常提示与兜底 / 本期不做·待确认 / 验收要点
- 「本期不做 / 待确认」记录的是**刻意保留的缺口**，不要当成遗漏去补
- 索引 `doc/app/README.md` 里有通用口径与跨模块术语，改单篇前先看它

顺带修了 2 处被代码演进甩在后面的注释：`template_detail_page.dart` 与 `freeform_detail_page.dart` 还写着「预览视频需要 video_player」，实际已接通。

**Riverpod 3.4.3 坑**（与常见 2.x 写法不同）：

- 没有 `valueOrNull`，`AsyncValue.value` 本身就是可空的。
- **没有 `FamilyAsyncNotifier`**：family notifier 的构造参数即 family 参数——
  `class X extends AsyncNotifier<S> { X(this.arg); }` + `AsyncNotifierProvider.family<X, S, Arg>(X.new)`。
- `analysis_options.yaml` 关闭了 `use_null_aware_elements`：Bridge 参数是「字面量键 + 可空值」（`if (x != null) 'x': x`），而 `?key: value` 会把**值当成键**，改写会直接改坏原生协议。

## 待确认项（落地前需与用户敲定）

1. 后台范围：是否只服务 H5，还是同时包含运营管理后台页面（后台前端技术栈与目录待定）。
2. 现网资源域名 `res.siren.xin` / `res.glamai01.it.com` 与新 CDN（`damzuukrr4z5d.cloudfront.net`）的切换节奏：存量 URL 是否保留、是否需要双域名兼容。
3. ~~时区口径：库内时间与对外 `serverTimeStr` 时区约定（建议库存 UTC、对外 `+08:00`，面向海外渠道时是否按渠道时区）。~~ **2026-10-28 已定：库存 naive UTC、对外一律 `+08:00` 的 ISO 8601 秒级字符串，见「时间与时区规范（ISO 8601）」。**
4. 支付与归因：是否保留 Apple 内购渠道、AppsFlyer 归因字段、三档收款方式（PIX / IN_BANK / IN_VPA）。
5. 重构推进顺序：骨架 + 请求层 + 路由（已完）→ **首页信息流（已完，2026-10-10）** → 模板详情/任务 → 社区 → 钱包充值 → 返利；期间后端先以 mock 契约并行开发（当前 `app/api` 只有 auth/upload/wallet/health，模板与任务接口尚未实现，Flutter 首页在联调前会停在错误态）。
6. 邮箱注册后续能力：邮箱验证、找回密码、第三方登录（Google / Apple）本期均不做；注册页是否需要先勾选同意 `terms` / `privacy`（现网有 `privacy_url` / `terms_url` 运行时配置）待产品确认。
7. 金币域只做了「钱包 + 流水 + 注册奖励」。消费（任务扣币/失败退币）、充值、兑换码、邀请奖励、社区收益转金币**均未实现**；注册奖励与「邀请注册奖励」（H5 `inviteRegistrationReward` 已有前端逻辑）是否叠加、是否共用一套发放口径待产品确认。
