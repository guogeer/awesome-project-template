# awesome-project-template

项目规范与 skills 的沉淀仓库。新项目从这里复制起点配置，AI 编码代理与团队成员从这里查口径。

## 定位

- **项目规范**：代码风格、目录结构、命名、错误处理、Git/提交规范等，可整包或按文件复制到具体项目。
- **项目档案**：`projects/` 收录各真实项目的 AGENTS.md 快照与规范提炼（SUMMARY.md），供跨项目借鉴；真源仍在各项目仓库。
- **skills**：可复用的 AI 代理技能（SKILL.md + 脚本），通用组织、不绑定特定工具；需要时复制或链接到项目的 `.codebuddy/skills/` 等目录即可生效。

## 目录

```
├── AGENTS.md                     # AI 编码代理工作约束模板
├── docs/
│   ├── conventions/              # 项目规范
│   │   ├── code-style.md         # 代码风格
│   │   ├── project-structure.md  # 目录结构
│   │   ├── naming.md             # 命名规范
│   │   ├── error-handling.md     # 错误处理
│   │   ├── data-masking.md       # 数据脱敏规范（落库/日志/测试/凭据全链路）
│   │   ├── testing.md            # 测试规范（增量口径、基线失败、真环境验证）
│   │   └── stack-*.md            # 技术栈细则（FastAPI / Flutter / React）
│   └── git/
│       └── commit-convention.md  # 提交信息规范
├── .github/                      # PR / Issue 模板
├── CHANGELOG.md
├── projects/                     # 各真实项目的规范档案（快照 + 提炼）
│   ├── yellow-dog/               # FaceFlip AI：Flutter + FastAPI + React
│   ├── tangchao/                 # OXPay：ThinkPHP 8 + Vue 2
│   └── gracetalk-pastoral/       # GraceTalk：FastAPI + Flutter + React
└── skills/                       # 可复用技能（只收通用技能）
    ├── README.md                 # skills 使用与安装说明
    ├── _template/                # 新技能骨架模板
    ├── auto-commit-push/         # 示例：自动提交推送
    └── dev-service-refresh/      # 示例：收尾刷新本地 dev 服务（配置化）
```

## 如何在新项目中使用

1. **规范**：把 `docs/` 下需要的文件复制进项目的 `doc/` 或 `docs/`，并按项目实情裁剪；`AGENTS.md` 复制到仓库根后填入项目专属约束。
2. **模板**：`.github/` 与 `CHANGELOG.md` 直接复制到项目仓库根。
3. **skills**：复制 `skills/<name>/` 到项目的 `.codebuddy/skills/<name>/`（CodeBuddy 只扫描该路径）；其他代理工具按其约定放置。
