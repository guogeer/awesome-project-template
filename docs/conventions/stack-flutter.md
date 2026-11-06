# 技术栈细则：Flutter App（一套代码多端）

> 复制到 Flutter 项目后按实情裁剪；通用风格见 `code-style.md`。

## 运行参数不写死

- `api_base_url`、`res_base_url`、`channel`、`privacy_url`、`terms_url`、版本号等**启动时加载**（runtime-config / 环境注入），代码里不硬编码；换环境不改代码。
- 展示文案走多语言表；**全量语言共用同一组 key**，新增 key 所有语言同步补齐。

## 架构

- 状态管理统一一套方案（如 Riverpod），不混用；页面组件不做数据加工，业务在 provider/service 层。
- 路由统一走声明式路由（如 go_router），页面间不直接 push 裸 widget。
- 网络层单例：统一 base URL、超时、重试、错误信封解析；模型与后端契约字段一一对应，契约变更两侧同步（后端 schema + 端侧 model）。

## 价格与展示

- **端侧价格全部后端下发**，不在代码里硬编码金币价；端侧只渲染。
- 展示短名（title/label）不得挪作逻辑输入（如生成提示词）；提示词字段缺失时**报错而不是拿标题兜底**——能下单但结果不对比下单失败更糟。

## 热重载与开发

- dev 服务常驻时，改完代码主动触发一次热重载（SIGUSR1）/热重启（SIGUSR2，`--full`），不依赖用户手动 r；见 `skills/dev-service-refresh`。
- 改了 `pubspec.yaml` / 依赖 / 启动参数，热重启不够，需重跑启动脚本。

## 发布

- Web 构建产物带 runtime 配置一起发（构建时生成 `runtime-config.json`）；入口与不带 hash 的文件更新后要刷 CDN。
- 资源域名与写入桶**配套**：换环境时同时检查写入桶、CDN 域名、前缀三者一致，配错的表现是资源 403/404。
