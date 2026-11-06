# Changelog

本仓库自身的变更记录。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循语义化版本。

## [Unreleased]

### Added

- 初始骨架：README 定位说明、`docs/conventions/`（代码风格 / 目录结构 / 命名 / 错误处理）、`docs/git/commit-convention.md`、`.github/` PR 与 Issue 模板、`AGENTS.md` 模板。
- `skills/` 通用骨架：`_template/` 技能模板、`auto-commit-push` 示例技能（通用化版）。

### Added（第二批）

- `docs/conventions/testing.md`：测试规范（增量口径、基线失败判定、MySQL 语义真环境验证、幂等用例）。
- `docs/conventions/stack-*.md`：FastAPI / Flutter / React 三个技术栈细则。
- `skills/dev-service-refresh/`：收尾刷新本地 dev 服务（端口/触发文件配置化，含陈旧 .env 检查与信号安全护栏）。
