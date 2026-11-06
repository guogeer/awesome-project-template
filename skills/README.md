# skills

可复用的 AI 编码代理技能集合。每个技能一个子目录，核心是 `SKILL.md`（给代理读的工作说明），可附 `scripts/`（确定性脚本）与 `references/`（参考文档）。

## 目录结构

```
skills/
├── _template/          # 新技能骨架模板（复制改名后开工）
├── auto-commit-push/   # 示例：任务收尾自动提交并推送
└── <name>/
    ├── SKILL.md
    ├── scripts/        # 可选：bash 等确定性脚本
    └── references/     # 可选：规范/参考文档
```

> 本目录**只收通用技能**（不绑定具体项目、可直接复用）。项目专属技能（部署、构建、排障等含项目地址与流程的）留在各自项目的 `.codebuddy/skills/` 维护，不要沉淀到这里。

## SKILL.md 写法

1. 顶部 front matter：`name`、`description`（含**何时触发**的完整描述——代理靠它判断是否加载本技能；需要常驻时加 `alwaysApply: true`）。
2. 正文按 `# Overview` → `## 何时使用` → `## 工作流`（编号步骤、含可直接执行的命令）→ `## 资源` 组织。
3. 写"给代理的指令"而非产品文档：明确硬约束（不要做什么）、失败分支怎么处理、完成后如何回报。
4. 关键经验写成"常见漏触发的情形，别再犯"这类负例清单，比正向描述更防错。

## 安装到具体项目

**一键安装**（推荐，本仓库自带 `skills/install.sh`）：

```bash
bash skills/install.sh                                  # 装到本仓库根的 .codebuddy/skills/
bash skills/install.sh --project ~/some-repo            # 装到其他项目
bash skills/install.sh --tools codebuddy,codex,kilo     # 一次装多个工具目录
bash skills/install.sh --link                           # 软链模式：源仓库改一处，各处即时生效
bash skills/install.sh --only auto-commit-push          # 只装指定技能
```

幂等覆盖，升级技能后重跑一遍即可。各工具的放置路径：

| 工具 | 放置路径 |
| --- | --- |
| CodeBuddy | `<项目>/.codebuddy/skills/<name>/`（**只扫描这个路径**，其他副本不可见） |
| Codex / Kilo 等各自副本 | 按工具约定路径放置（`.codex/skills/`、`.kilo/skills/`），**多副本需各自安装** |

复制或软链后无需其他注册步骤；修改技能时所有副本一起改（复制模式重跑脚本、软链模式自动同步）。
