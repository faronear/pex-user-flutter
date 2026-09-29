/// 默认入口 = Agidin（爱奇点）。
///
/// 这样 `flutter build web`（不指定 `-t`）可直接构建 Agidin；
/// 其它品牌请显式指定入口：`flutter build web -t lib/main_babelyx.dart`。
library;

import 'main_agidin.dart' as agidin;

void main() => agidin.main();
