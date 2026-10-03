/// 品牌功能开关。
///
/// 与 [BrandConfig]（外观/身份）分离：本类只回答「这个品牌有哪些业务域」。
/// 路由表按开关注册，配合各品牌的独立入口（`main_<brand>.dart`），
/// 让 Dart 编译器按 import 图做**入口级裁剪**：某品牌未启用的域，其页面代码不会进入该品牌产物。
library;

class BrandFeatures {
  const BrandFeatures({
    this.enableAiChat = false,
    this.enableAibotMarket = false,
    this.enableCreation = false,
    this.enableCreator = false,
    this.enableMarket = false,
    this.enableNft = false,
    this.enableResource = false,
  });

  /// AI 对话（midAgidin / menuAippAichat）。
  final bool enableAiChat;

  /// Aibot 市场（menuAipp）。注意：Aibot 创建/编辑已决定不再投入。
  final bool enableAibotMarket;

  /// 创作（menuCreation / showCreation / showCreationUpdate）。
  final bool enableCreation;

  /// 创作者主页（menuCreator / showCreator）。
  final bool enableCreator;

  /// 作品市场（menuMarket）。
  final bool enableMarket;

  /// NFT / IPFS 相关能力。
  final bool enableNft;

  /// 资源与链接页（userResource / userResourceDetail）。
  final bool enableResource;

  /// Agidin：AI 为主。
  static const BrandFeatures agidin = BrandFeatures(
    enableAiChat: true,
    enableAibotMarket: true,
    enableResource: true,
  );

  /// Babelyx：UGC / NFT 为主（story 的主战场）。
  static const BrandFeatures babelyx = BrandFeatures(
    enableCreation: true,
    enableCreator: true,
    enableMarket: true,
    enableNft: true,
    enableResource: true,
  );
}
