# projects：各项目规范收录

每个子目录 = 一个真实项目的规范档案：

- `AGENTS.md`：该项目的 AI 代理工作约束**快照**（原样复制）。
- `SUMMARY.md`：一页提炼——技术栈、关键口径、踩坑教训，供跨项目借鉴。

**真源在各自项目仓库**（`AGENTS.md` / `doc/`），本目录是快照与提炼；规范冲突时以项目真源为准。项目 `AGENTS.md` 有实质变更后，回本仓库同步一次快照并更新 `SUMMARY.md`。

## 收录情况

| 项目 | 位置 | 技术栈 | 规范成熟度 |
| --- | --- | --- | --- |
| yellow-dog | `~/gitcode.com/yellow-dog` | Flutter + FastAPI + React(antd) | 详尽（AGENTS.md + doc/ 分层文档 + 2 个 skill） |
| tangchao (oxpay) | `~/gitcode.com/tangchao` | ThinkPHP 8 + Vue 2 | 精要（AGENTS.md 一页 + doc/ 部署与文档站） |
| gracetalk-pastoral | `~/gitcode.com/gracetalk-pastoral` | FastAPI + Flutter + React(antd 6) | 中等（AGENTS.md + doc/ 按模块 DESIGN 文档） |
| quasar / gofishing-game | `~/github.com/` | Go | 待沉淀（无规范文件，仅有 README/结构） |
