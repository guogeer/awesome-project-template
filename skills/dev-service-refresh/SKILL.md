---
name: dev-service-refresh
alwaysApply: false
description: 任务收尾时自动刷新本机正在跑的 dev 服务，让刚改完的代码立刻生效。当项目声明本技能 `alwaysApply: true` 或已授权自动执行时：只要本轮改了会影响运行时的东西（后端 / 前端 / App 端的代码、配置、迁移、资源），在输出收尾结论之前先跑 `scripts/dev-refresh.sh` 刷新已运行的本地服务，再去做提交推送。服务没起、端口没人监听时只提示不猜；不重启进程、不杀进程、不碰远程环境。
---

# 任务收尾刷新本地 dev 服务

## Overview

本地常驻的 dev 服务都带文件监听，但**收尾时不该依赖"用户回去再动一下文件"才生效**：改完代码、跑完测试后主动刷一次，用户打开浏览器/请求接口看到的就是刚落地的代码。

## 何时执行（授权项目默认自动）

本轮改动命中项目的服务端口映射表（脚本顶部配置段）任一区域，且本机该服务正在跑时执行；纯文档 / 纯 skill 改动不刷新。

| 服务类型 | 刷新方式 |
| --- | --- |
| Python 后端（uvicorn `--reload`） | `touch` 被监视的触发文件，uvicorn 自己重启 worker |
| 前端（vite/webpack HMR） | 自己热更，脚本只探测并提示 |
| Flutter Web/App dev | 给进程发 `SIGUSR1`（热重载）或 `SIGUSR2`（热重启，`--full`） |

## 用法

```bash
bash skills/dev-service-refresh/scripts/dev-refresh.sh            # 刷新所有正在运行的服务
bash skills/dev-service-refresh/scripts/dev-refresh.sh --full     # App 端走热重启（改了依赖/资源/启动参数时）
bash skills/dev-service-refresh/scripts/dev-refresh.sh --api-only # 只刷后端
bash skills/dev-service-refresh/scripts/dev-refresh.sh --web-only # 只刷页面/App
bash skills/dev-service-refresh/scripts/dev-refresh.sh --dry-run  # 只看会做什么
```

退出码恒为 0：刷新是收尾的尽力动作，服务没起、进程不是预期程序都只打印"跳过"，不阻断提交推送。

## 安装到项目（一次性）

复制本技能到项目 `.codebuddy/skills/dev-service-refresh/`，然后**改脚本顶部配置段**：

```bash
BACKENDS=(            # "名称:端口:触发文件路径(相对仓库根):日志名"
  "app-api:12100:app/api/src/<pkg>/app.py:app-api"
)
BACKEND_DIR_FOR_ENV=( # 与 BACKENDS 对应的后端目录，用于 .env 陈旧性检查
  "app/api"
)
FLUTTER_PORT=12103
WEB_PROBE_PORT=12102
DEV_START_CMD="./tool/dev.sh"
```

## 边界（重要）

- **只在 localhost 动手**：只探测配置的端口，不发任何出网请求。
- **不重启、不杀进程**：后端用"改 mtime 触发重载"（`touch` 不改内容，`git status` 仍然干净），前端只发信号。真正重启由用户跑 `DEV_START_CMD`。
- **不确定就跳过**：Flutter 端口的监听进程命令行里没有 `flutter` 时一律跳过——`SIGUSR1` 是 `kill` 的默认终止信号，发错进程会直接弄死它。
- **不替 `.env` 生效**：文件监听忽略点开头路径，改 `.env*` 必须手动重启；脚本探测到后端在跑但 `.env*` 比进程新时会提示。
- 服务没起时输出提示，**不要替用户后台起服务**。
- 不做重载节流：解法就是"任务收尾统一刷一次"，不去改启动脚本的 reload-delay。

## 与提交的关系

收尾顺序：**跑增量测试 → 刷新本地 dev 服务 → 提交推送 → 汇报**。刷新只是让改动立刻可见，不替代测试、不改变提交判定标准（提交仍走 auto-commit-push）。
