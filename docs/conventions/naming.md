# 命名规范（模板）

## 通用

- 用完整英文单词，避免无约定缩写；一个概念在仓库内**只用一个词**（例如统一 `task` 就不要混用 `job`/`order`）。
- 布尔值用 `is_/has_/can_` 或正向形容词；禁止双重否定命名。
- 环境变量全大写 + 下划线：`DISPATCH_BASE_URL`。

## 语言默认风格

| 对象 | 风格 | 示例 |
| --- | --- | --- |
| Python 模块/函数/变量 | snake_case | `wallet_service.grant()` |
| Python 类 | PascalCase | `TaskService` |
| Python 常量 | UPPER_SNAKE | `MAX_RETRY = 3` |
| Dart/TS 类、类型 | PascalCase | `PaymentChannel` |
| Dart/TS 变量、函数 | camelCase | `loadSession()` |
| TS/JS 文件（组件） | PascalCase 或按项目既有约定 | `PricingConfig.tsx` |
| 数据库表/列 | snake_case 复数表名 | `pricing_configs` |
| 文档文件 | 中文主题或英文 kebab/snake，含日期前缀归档 | `20261102-派单接口对接说明.md` |

## 业务命名红线

- **同形不同义的字段要先查清再用**：同一张表存在 `status`（审计列）与 `task_status`（业务列）这类名字时，业务判断必须用业务列——写错不报错、只会静默恒假，是高频事故源。
- 展示用的短名（title/label）**不得**挪作逻辑输入（如提示词、排序键），展示字段与语义字段分开。
- 配置键命名带域前缀并成组：`freeform_image_gold_480p`、`freeform_video_gold_10s_720p`。
