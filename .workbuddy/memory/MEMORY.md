# flutter_variety_chart — 项目长期约定

## 项目性质
原创 Flutter 图表包（pub.dev 目标），MIT 许可。
**明确约束：不得复制 `syncfusion_flutter_charts` 等商业授权库的源码后改名发布。**
参考其功能范围与架构组织可以，代码必须原创、命名独立（统一 `Variety` 前缀）。

## 命名约定
- 所有公开类型/枚举/函数统一 `Variety` 前缀，系列类型统一 `VarietyXxxSeries`。
- 私有实现放 `lib/src/` 下，按 `models / render / painters / widgets / behaviors / analysis / utils` 分层。
- 公开 API 全部要写 dartdoc（`analysis_options.yaml` 开启了 `public_member_api_docs`）。

## 架构约定
- **渲染**：`VarietyGeometry` 产出 `List<VarietyElement>`，`VarietyElementRenderer`
  负责实际绘制。新增系列只需要在 geometry 里加分支，不要改 painter 的绘制原语。
- **命中测试**：必须复用同一份 geometry（painter 与 hitTest 共用一个实例）。
- **转置**：`transposed == true` 时（全部系列都是 bar），取值用 `valueAt()`，
  纵坐标用类别索引；命中测试走 `hitsBySlot` 的 transposed 分支。
- **可选值覆盖**：不要用 `copyWith(y: null)`，用 `withValue(null)`。

## 交互约定
- 只有缩放在启用时才注册 scale / doubleTap 手势识别器，否则单击会被延迟 300ms。
- 所有图表组件都要求父级提供有界尺寸；无界时内部回退到 320 高度。

## 命令
- 迭代期校验：`dart analyze lib test`（快）
- 运行测试：`env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy flutter test`
- 修改库代码后必须同时保证 `lib`、`test`、`example/lib` 三处 `dart analyze` 零问题。
