# AGENTS.md（<项目名>）

本文件为 AI 编码代理在本仓库内的工作约束。复制到具体项目后按实情填写；**没有写明的事项遵循 `docs/conventions/` 与 `docs/git/` 下的通用规范**。

## 仓库边界

- 本仓库位于 `<本地绝对路径>`，origin：`<git@github.com:owner/repo.git>`，默认分支 `<main>`。
- 所有 git、格式化、静态检查、测试命令都必须在本仓库目录内执行，不要在工作区根目录或其它仓库目录操作，也不要把本仓文件复制到其它仓库。
- 不得修改 git config；不得 `--no-verify` 跳过钩子（除非用户明确要求）；不得 force push（尤其主分支）。

## 项目定位

<!-- 两三句话说清：这是什么产品、有哪些端、技术栈。例：
C 端 App（Flutter）+ Python 后台服务 + 管理后台。
- App 端：app/，Flutter 3.x，一套代码出 Web + iOS/Android
- 后台服务：api/，Python 3.12 + FastAPI + MySQL 8
- 管理后台：admin/（api + web）
-->

## 环境与真源

<!-- 例：
- 环境参数真源是服务器 .env，仓库里只有 .env.example / .env.development 等模板；排查配置问题先对比服务器 .env 与 example 的非敏感键差异。
- 域名、上游地址、桶等写进文档时注明来源与生效点（compose 默认值 vs 服务器 .env 覆盖），改配置后必须 up -d --force-recreate 才刷新环境变量。
-->

## 完成定义

- 涉及代码改动：增量用例跑完且全绿 + 静态检查通过；无测试覆盖时由静态校验兜底并点明。
- 已知基线失败（不阻塞提交）：
  <!-- 例：test/i18n_test.dart 的全量语言覆盖断言，与本轮改动无关 -->
- 提交信息遵循 `docs/git/commit-convention.md`，一任务一提交。

## 排障入口

<!-- 例：
- 后端日志：logs/YYYYMM/api.log（outbound 行含完整下单 body 与上游响应）
- 对外文案与根因分离：接口返回的是通用业务文案，根因以 `xxx failed:` 原文落日志，排查别只看接口返回。
-->
