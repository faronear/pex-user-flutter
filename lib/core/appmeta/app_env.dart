/// 构建环境标识，对应源项目 `wo.ss.inProd`（`process.env.NODE_ENV === 'production'`）。
///
/// 本地开发/预览构建默认 `false`（与源项目 `localhost` 预览一致：不做生产环境守卫）；
/// 正式打包用 `--dart-define=IN_PROD=true`。
library;

/// 是否为生产构建。
const bool kInProd = bool.fromEnvironment('IN_PROD', defaultValue: false);
