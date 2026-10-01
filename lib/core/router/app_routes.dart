/// 路由名常量（与源项目页面文件名一致，便于逐页对照迁移）。
library;

class AppRoutes {
  const AppRoutes._();

  // 公共
  static const String homePortal = 'homePortal';
  static const String identBegin = 'identBegin';
  static const String identNewPasscode = 'identNewPasscode';
  static const String identNewRegcode = 'identNewRegcode';
  static const String identNewRegister = 'identNewRegister';
  static const String identOldLogin = 'identOldLogin';
  static const String identOldPasscode = 'identOldPasscode';
  static const String identOldReset = 'identOldReset';

  // AI 域
  static const String midAgidin = 'midAgidin';
  static const String menuAipp = 'menuAipp';
  static const String menuAippAichat = 'menuAippAichat';

  // 资金域（页面尚未迁移，仅用于跳转占位）
  static const String umyFund = 'umyFund';
  static const String umyFundTranx = 'umyFundTranx';

  // 账户 / 社交域（页面尚未迁移，仅用于跳转占位）
  static const String umyAccount = 'umyAccount';
  static const String umyAccountPassword = 'umyAccountPassword';
  static const String umyAccountCommid = 'umyAccountCommid';
  static const String umyAccountCommidNew = 'umyAccountCommidNew';
  static const String umyAccountTerminate = 'umyAccountTerminate';
  static const String umyKyc = 'umyKyc';
  static const String umyMia = 'umyMia';
  static const String umyConfig = 'umyConfig';
  static const String umyInvite = 'umyInvite';
  static const String umyInviteList = 'umyInviteList';

  // 标签栏页
  static const String menuUzone = 'menuUzone';

  // 社交页（尚未迁移，仅用于跳转占位）
  static const String umyCircle = 'umyCircle';

  // 创作 / NFT 域（待迁移）
  static const String midBabely = 'midBabely';
  static const String umyContact = 'umyContact';
  static const String menuCreation = 'menuCreation';
  static const String umyCollection = 'umyCollection';
  static const String menuCreator = 'menuCreator';
  static const String menuMarket = 'menuMarket';
  static const String showCreation = 'showCreation';
  static const String showCreationUpdate = 'showCreationUpdate';
  static const String showCreator = 'showCreator';
  static const String userResource = 'userResource';
  static const String userResourceDetail = 'userResourceDetail';

  static String path(String name) => '/$name';
}
