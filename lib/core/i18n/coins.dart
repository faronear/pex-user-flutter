// 由 `wo-core-i18n` 自动生成，请勿手工编辑。
// 生成方式：`node tool/genCoins.js`（数据源 = 源项目 pex-user-uniapp 的依赖包 wo-core-i18n）。
// ignore_for_file: constant_identifier_names

import 'lang_text.dart';

/// 一种货币，对应源项目 `wo.ss.i18n.bankcoinSet` / `cryptocoinSet` 的条目。
class Coin {
  const Coin({
    required this.coinCode,
    required this.coinSymbol,
    required this.coinPrecision,
    required this.nameEn,
    required this.nameZh,
    this.coinSupply,
  });

  /// 币种代码，如 `USD` / `BTC`。
  final String coinCode;

  /// 货币符号，如 `$` / `₿`。
  final String coinSymbol;

  /// 小数位数。
  final int coinPrecision;

  final String nameEn;
  final String nameZh;

  /// 发行总量（仅加密货币有）。
  final int? coinSupply;

  /// 多语言名称（源项目 `coinIname`）。
  LangText get name => LangText(zhCN: nameZh, enUS: nameEn);

  /// 列表行的主显示：`$ (USD)` 之类的写法由调用方拼装。
  String get label => nameEn;
}

/// 法定货币（源项目 `bankcoinSet`，联合国登记的全部币种）。
const List<Coin> kBankCoins = <Coin>[
  Coin(coinCode: 'AED', coinSymbol: '', coinPrecision: 2, nameEn: 'United Arab Emirates dirham', nameZh: '阿联酋迪拉姆'),
  Coin(coinCode: 'AFN', coinSymbol: '', coinPrecision: 2, nameEn: 'Afghan afghani', nameZh: '阿富汗尼'),
  Coin(coinCode: 'ALL', coinSymbol: '', coinPrecision: 2, nameEn: 'Albanian lek', nameZh: '阿尔巴尼亚列克'),
  Coin(coinCode: 'AMD', coinSymbol: '', coinPrecision: 2, nameEn: 'Armenian dram', nameZh: '亚美尼亚德拉姆'),
  Coin(coinCode: 'ANG', coinSymbol: '', coinPrecision: 2, nameEn: 'Netherlands Antillean guilder', nameZh: '荷属安的列斯盾'),
  Coin(coinCode: 'AOA', coinSymbol: '', coinPrecision: 2, nameEn: 'Angolan kwanza', nameZh: '安哥拉宽扎'),
  Coin(coinCode: 'ARS', coinSymbol: '', coinPrecision: 2, nameEn: 'Argentine peso', nameZh: '阿根廷比索'),
  Coin(coinCode: 'AUD', coinSymbol: '', coinPrecision: 2, nameEn: 'Australian dollar', nameZh: '澳大利亚元'),
  Coin(coinCode: 'AWG', coinSymbol: '', coinPrecision: 2, nameEn: 'Aruban florin', nameZh: '阿鲁巴弗罗林'),
  Coin(coinCode: 'AZN', coinSymbol: '', coinPrecision: 2, nameEn: 'Azerbaijani manat', nameZh: '阿塞拜疆马纳特'),
  Coin(coinCode: 'BAM', coinSymbol: '', coinPrecision: 2, nameEn: 'Bosnia and Herzegovina convertible mark', nameZh: '波斯尼亚和黑塞哥维那可兑换马克'),
  Coin(coinCode: 'BBD', coinSymbol: '', coinPrecision: 2, nameEn: 'Barbados dollar', nameZh: '巴巴多斯元'),
  Coin(coinCode: 'BDT', coinSymbol: '', coinPrecision: 2, nameEn: 'Bangladeshi taka', nameZh: '孟加拉塔卡'),
  Coin(coinCode: 'BGN', coinSymbol: '', coinPrecision: 2, nameEn: 'Bulgarian lev', nameZh: '保加利亚列弗'),
  Coin(coinCode: 'BHD', coinSymbol: '', coinPrecision: 3, nameEn: 'Bahraini dinar', nameZh: '巴林第纳尔'),
  Coin(coinCode: 'BIF', coinSymbol: '', coinPrecision: 0, nameEn: 'Burundian franc', nameZh: '布隆迪法郎'),
  Coin(coinCode: 'BMD', coinSymbol: '', coinPrecision: 2, nameEn: 'Bermudian dollar', nameZh: '百慕大元'),
  Coin(coinCode: 'BND', coinSymbol: '', coinPrecision: 2, nameEn: 'Brunei dollar', nameZh: '文莱元'),
  Coin(coinCode: 'BOB', coinSymbol: '', coinPrecision: 2, nameEn: 'Boliviano', nameZh: '玻利维亚诺'),
  Coin(coinCode: 'BOV', coinSymbol: '', coinPrecision: 2, nameEn: 'Bolivian Mvdol (funds code)', nameZh: 'Mvdol（资金代码）'),
  Coin(coinCode: 'BRL', coinSymbol: '₢', coinPrecision: 2, nameEn: 'Brazilian real', nameZh: '巴西雷亚尔'),
  Coin(coinCode: 'BSD', coinSymbol: '', coinPrecision: 2, nameEn: 'Bahamian dollar', nameZh: '巴哈马元'),
  Coin(coinCode: 'BTN', coinSymbol: '', coinPrecision: 2, nameEn: 'Bhutanese ngultrum', nameZh: '不丹努尔特鲁姆'),
  Coin(coinCode: 'BWP', coinSymbol: '', coinPrecision: 2, nameEn: 'Botswana pula', nameZh: '博茨瓦纳普拉'),
  Coin(coinCode: 'BYN', coinSymbol: '', coinPrecision: 2, nameEn: 'Belarusian ruble', nameZh: '白俄罗斯卢布'),
  Coin(coinCode: 'BZD', coinSymbol: '', coinPrecision: 2, nameEn: 'Belize dollar', nameZh: '伯利兹元'),
  Coin(coinCode: 'CAD', coinSymbol: '', coinPrecision: 2, nameEn: 'Canadian dollar', nameZh: '加拿大元'),
  Coin(coinCode: 'CDF', coinSymbol: '', coinPrecision: 2, nameEn: 'Congolese franc', nameZh: '刚果法郎'),
  Coin(coinCode: 'CHE', coinSymbol: '', coinPrecision: 2, nameEn: 'WIR euro (complementary currency)', nameZh: 'WIR（英语：WIR Bank）欧元（补充货币）'),
  Coin(coinCode: 'CHF', coinSymbol: '', coinPrecision: 2, nameEn: 'Swiss franc', nameZh: '瑞士法郎'),
  Coin(coinCode: 'CHW', coinSymbol: '', coinPrecision: 2, nameEn: 'WIR franc (complementary currency)', nameZh: 'WIR（英语：WIR Bank）法郎（补充货币）'),
  Coin(coinCode: 'CLF', coinSymbol: '', coinPrecision: 4, nameEn: 'Unidad de Fomento (funds code)', nameZh: '发展单位（资金代码）'),
  Coin(coinCode: 'CLP', coinSymbol: '', coinPrecision: 0, nameEn: 'Chilean peso', nameZh: '智利比索'),
  Coin(coinCode: 'CNY', coinSymbol: '¥', coinPrecision: 2, nameEn: 'Chinese Yuan', nameZh: '人民币'),
  Coin(coinCode: 'COP', coinSymbol: '', coinPrecision: 2, nameEn: 'Colombian peso', nameZh: '哥伦比亚比索'),
  Coin(coinCode: 'COU', coinSymbol: '', coinPrecision: 2, nameEn: 'Unidad de Valor Real (UVR) (funds code)', nameZh: '哥伦比亚实际单位（UVR，资金代码）'),
  Coin(coinCode: 'CRC', coinSymbol: '', coinPrecision: 2, nameEn: 'Costa Rican colon', nameZh: '哥斯达黎加科朗'),
  Coin(coinCode: 'CUC', coinSymbol: '', coinPrecision: 2, nameEn: 'Cuban convertible peso', nameZh: '古巴可兑换比索'),
  Coin(coinCode: 'CUP', coinSymbol: '', coinPrecision: 2, nameEn: 'Cuban peso', nameZh: '古巴比索'),
  Coin(coinCode: 'CVE', coinSymbol: '', coinPrecision: 2, nameEn: 'Cape Verdean escudo', nameZh: '佛得角埃斯库多'),
  Coin(coinCode: 'CZK', coinSymbol: '', coinPrecision: 2, nameEn: 'Czech koruna', nameZh: '捷克克朗'),
  Coin(coinCode: 'DJF', coinSymbol: '', coinPrecision: 0, nameEn: 'Djiboutian franc', nameZh: '吉布提法郎'),
  Coin(coinCode: 'DKK', coinSymbol: '', coinPrecision: 2, nameEn: 'Danish krone', nameZh: '丹麦克朗'),
  Coin(coinCode: 'DOP', coinSymbol: '', coinPrecision: 2, nameEn: 'Dominican peso', nameZh: '多米尼加比索'),
  Coin(coinCode: 'DZD', coinSymbol: '', coinPrecision: 2, nameEn: 'Algerian dinar', nameZh: '阿尔及利亚第纳尔'),
  Coin(coinCode: 'EGP', coinSymbol: '', coinPrecision: 2, nameEn: 'Egyptian pound', nameZh: '埃及镑'),
  Coin(coinCode: 'ERN', coinSymbol: '', coinPrecision: 2, nameEn: 'Eritrean nakfa', nameZh: '厄立特里亚纳克法'),
  Coin(coinCode: 'ETB', coinSymbol: '', coinPrecision: 2, nameEn: 'Ethiopian birr', nameZh: '埃塞俄比亚比尔'),
  Coin(coinCode: 'EUR', coinSymbol: '€', coinPrecision: 2, nameEn: 'Euro', nameZh: '欧元'),
  Coin(coinCode: 'FJD', coinSymbol: '', coinPrecision: 2, nameEn: 'Fiji dollar', nameZh: '斐济元'),
  Coin(coinCode: 'FKP', coinSymbol: '', coinPrecision: 2, nameEn: 'Falkland Islands pound', nameZh: '福克兰群岛镑'),
  Coin(coinCode: 'GBP', coinSymbol: '£', coinPrecision: 2, nameEn: 'Pound sterling', nameZh: '英镑'),
  Coin(coinCode: 'GEL', coinSymbol: '', coinPrecision: 2, nameEn: 'Georgian lari', nameZh: '格鲁吉亚拉里'),
  Coin(coinCode: 'GHS', coinSymbol: '', coinPrecision: 2, nameEn: 'Ghanaian cedi', nameZh: '加纳塞地'),
  Coin(coinCode: 'GIP', coinSymbol: '', coinPrecision: 2, nameEn: 'Gibraltar pound', nameZh: '直布罗陀镑'),
  Coin(coinCode: 'GMD', coinSymbol: '', coinPrecision: 2, nameEn: 'Gambian dalasi', nameZh: '冈比亚达拉西'),
  Coin(coinCode: 'GNF', coinSymbol: '', coinPrecision: 0, nameEn: 'Guinean franc', nameZh: '几内亚法郎'),
  Coin(coinCode: 'GTQ', coinSymbol: '', coinPrecision: 2, nameEn: 'Guatemalan quetzal', nameZh: '危地马拉格查尔'),
  Coin(coinCode: 'GYD', coinSymbol: '', coinPrecision: 2, nameEn: 'Guyanese dollar', nameZh: '圭亚那元'),
  Coin(coinCode: 'HKD', coinSymbol: '', coinPrecision: 2, nameEn: 'Hong Kong dollar', nameZh: '港元'),
  Coin(coinCode: 'HNL', coinSymbol: '', coinPrecision: 2, nameEn: 'Honduran lempira', nameZh: '洪都拉斯伦皮拉'),
  Coin(coinCode: 'HRK', coinSymbol: '', coinPrecision: 2, nameEn: 'Croatian kuna', nameZh: '克罗地亚库纳'),
  Coin(coinCode: 'HTG', coinSymbol: '', coinPrecision: 2, nameEn: 'Haitian gourde', nameZh: '海地古德'),
  Coin(coinCode: 'HUF', coinSymbol: '', coinPrecision: 2, nameEn: 'Hungarian forint', nameZh: '匈牙利福林'),
  Coin(coinCode: 'IDR', coinSymbol: '', coinPrecision: 2, nameEn: 'Indonesian rupiah', nameZh: '印尼盾'),
  Coin(coinCode: 'ILS', coinSymbol: '', coinPrecision: 2, nameEn: 'Israeli new shekel', nameZh: '以色列新谢克尔'),
  Coin(coinCode: 'INR', coinSymbol: '₹', coinPrecision: 2, nameEn: 'Indian rupee', nameZh: '印度卢比'),
  Coin(coinCode: 'IQD', coinSymbol: '', coinPrecision: 3, nameEn: 'Iraqi dinar', nameZh: '伊拉克第纳尔'),
  Coin(coinCode: 'IRR', coinSymbol: '', coinPrecision: 2, nameEn: 'Iranian rial', nameZh: '伊朗里亚尔'),
  Coin(coinCode: 'ISK', coinSymbol: '', coinPrecision: 0, nameEn: 'Icelandic króna (plural: krónur)', nameZh: '冰岛克朗'),
  Coin(coinCode: 'JMD', coinSymbol: '', coinPrecision: 2, nameEn: 'Jamaican dollar', nameZh: '牙买加元'),
  Coin(coinCode: 'JOD', coinSymbol: '', coinPrecision: 3, nameEn: 'Jordanian dinar', nameZh: '约旦第纳尔'),
  Coin(coinCode: 'JPY', coinSymbol: '¥', coinPrecision: 0, nameEn: 'Japanese yen', nameZh: '日圆'),
  Coin(coinCode: 'KES', coinSymbol: '', coinPrecision: 2, nameEn: 'Kenyan shilling', nameZh: '肯尼亚先令'),
  Coin(coinCode: 'KGS', coinSymbol: '', coinPrecision: 2, nameEn: 'Kyrgyzstani som', nameZh: '吉尔吉斯斯坦索姆'),
  Coin(coinCode: 'KHR', coinSymbol: '', coinPrecision: 2, nameEn: 'Cambodian riel', nameZh: '柬埔寨瑞尔'),
  Coin(coinCode: 'KMF', coinSymbol: '', coinPrecision: 0, nameEn: 'Comoro franc', nameZh: '科摩罗法郎'),
  Coin(coinCode: 'KPW', coinSymbol: '', coinPrecision: 2, nameEn: 'North Korean won', nameZh: '朝鲜圆'),
  Coin(coinCode: 'KRW', coinSymbol: '', coinPrecision: 0, nameEn: 'South Korean won', nameZh: '韩圆'),
  Coin(coinCode: 'KWD', coinSymbol: '', coinPrecision: 3, nameEn: 'Kuwaiti dinar', nameZh: '科威特第纳尔'),
  Coin(coinCode: 'KYD', coinSymbol: '', coinPrecision: 2, nameEn: 'Cayman Islands dollar', nameZh: '开曼群岛元'),
  Coin(coinCode: 'KZT', coinSymbol: '', coinPrecision: 2, nameEn: 'Kazakhstani tenge', nameZh: '哈萨克斯坦坚戈'),
  Coin(coinCode: 'LAK', coinSymbol: '', coinPrecision: 2, nameEn: 'Lao kip', nameZh: '老挝基普'),
  Coin(coinCode: 'LBP', coinSymbol: '', coinPrecision: 2, nameEn: 'Lebanese pound', nameZh: '黎巴嫩镑'),
  Coin(coinCode: 'LKR', coinSymbol: '', coinPrecision: 2, nameEn: 'Sri Lankan rupee', nameZh: '斯里兰卡卢比'),
  Coin(coinCode: 'LRD', coinSymbol: '', coinPrecision: 2, nameEn: 'Liberian dollar', nameZh: '利比里亚元'),
  Coin(coinCode: 'LSL', coinSymbol: '', coinPrecision: 2, nameEn: 'Lesotho loti', nameZh: '莱索托洛蒂'),
  Coin(coinCode: 'LYD', coinSymbol: '', coinPrecision: 3, nameEn: 'Libyan dinar', nameZh: '利比亚第纳尔'),
  Coin(coinCode: 'MAD', coinSymbol: '', coinPrecision: 2, nameEn: 'Moroccan dirham', nameZh: '摩洛哥迪尔汗'),
  Coin(coinCode: 'MDL', coinSymbol: '', coinPrecision: 2, nameEn: 'Moldovan leu', nameZh: '摩尔多瓦列伊'),
  Coin(coinCode: 'MGA', coinSymbol: '', coinPrecision: 2, nameEn: 'Malagasy ariary', nameZh: '马达加斯加阿里亚里'),
  Coin(coinCode: 'MKD', coinSymbol: '', coinPrecision: 2, nameEn: 'North Macedonian denar', nameZh: '马其顿代纳尔'),
  Coin(coinCode: 'MMK', coinSymbol: '', coinPrecision: 2, nameEn: 'Myanmar kyat', nameZh: '缅元'),
  Coin(coinCode: 'MNT', coinSymbol: '', coinPrecision: 2, nameEn: 'Mongolian tögrög', nameZh: '蒙古图格里克'),
  Coin(coinCode: 'MOP', coinSymbol: '', coinPrecision: 2, nameEn: 'Macanese pataca', nameZh: '澳门币'),
  Coin(coinCode: 'MRU', coinSymbol: '', coinPrecision: 2, nameEn: 'Mauritanian ouguiya', nameZh: '毛里塔尼亚乌吉亚'),
  Coin(coinCode: 'MUR', coinSymbol: '', coinPrecision: 2, nameEn: 'Mauritian rupee', nameZh: '毛里求斯卢比'),
  Coin(coinCode: 'MVR', coinSymbol: '', coinPrecision: 2, nameEn: 'Maldivian rufiyaa', nameZh: '马尔代夫拉菲亚'),
  Coin(coinCode: 'MWK', coinSymbol: '', coinPrecision: 2, nameEn: 'Malawian kwacha', nameZh: '马拉维克瓦查'),
  Coin(coinCode: 'MXN', coinSymbol: '', coinPrecision: 2, nameEn: 'Mexican peso', nameZh: '墨西哥比索'),
  Coin(coinCode: 'MXV', coinSymbol: '', coinPrecision: 2, nameEn: 'Mexican Unidad de Inversion (UDI) (funds code)', nameZh: '墨西哥发展单位（UDI，资金代码）'),
  Coin(coinCode: 'MYR', coinSymbol: '', coinPrecision: 2, nameEn: 'Malaysian ringgit', nameZh: '马来西亚令吉'),
  Coin(coinCode: 'MZN', coinSymbol: '', coinPrecision: 2, nameEn: 'Mozambican metical', nameZh: '莫桑比克梅蒂卡尔'),
  Coin(coinCode: 'NAD', coinSymbol: '', coinPrecision: 2, nameEn: 'Namibian dollar', nameZh: '纳米比亚元'),
  Coin(coinCode: 'NGN', coinSymbol: '', coinPrecision: 2, nameEn: 'Nigerian naira', nameZh: '尼日利亚奈拉'),
  Coin(coinCode: 'NIO', coinSymbol: '', coinPrecision: 2, nameEn: 'Nicaraguan córdoba', nameZh: '尼加拉瓜科多巴'),
  Coin(coinCode: 'NOK', coinSymbol: '', coinPrecision: 2, nameEn: 'Norwegian krone', nameZh: '挪威克朗'),
  Coin(coinCode: 'NPR', coinSymbol: 'रू', coinPrecision: 2, nameEn: 'Nepalese rupee', nameZh: '尼泊尔卢比'),
  Coin(coinCode: 'NZD', coinSymbol: '', coinPrecision: 2, nameEn: 'New Zealand dollar', nameZh: '新西兰元'),
  Coin(coinCode: 'OMR', coinSymbol: '', coinPrecision: 3, nameEn: 'Omani rial', nameZh: '阿曼里亚尔'),
  Coin(coinCode: 'PAB', coinSymbol: '', coinPrecision: 2, nameEn: 'Panamanian balboa', nameZh: '巴拿马巴波亚'),
  Coin(coinCode: 'PEN', coinSymbol: '', coinPrecision: 2, nameEn: 'Peruvian sol', nameZh: '秘鲁索尔'),
  Coin(coinCode: 'PGK', coinSymbol: '', coinPrecision: 2, nameEn: 'Papua New Guinean kina', nameZh: '巴布亚新几内亚基那'),
  Coin(coinCode: 'PHP', coinSymbol: '₱', coinPrecision: 2, nameEn: 'Philippine peso', nameZh: '菲律宾比索'),
  Coin(coinCode: 'PKR', coinSymbol: '₨', coinPrecision: 2, nameEn: 'Pakistani rupee', nameZh: '巴基斯坦卢比'),
  Coin(coinCode: 'PLN', coinSymbol: '', coinPrecision: 2, nameEn: 'Polish złoty', nameZh: '波兰兹罗提'),
  Coin(coinCode: 'PYG', coinSymbol: '', coinPrecision: 0, nameEn: 'Paraguayan guaraní', nameZh: '巴拉圭瓜拉尼'),
  Coin(coinCode: 'QAR', coinSymbol: '', coinPrecision: 2, nameEn: 'Qatari riyal', nameZh: '卡塔尔里亚尔'),
  Coin(coinCode: 'RON', coinSymbol: '', coinPrecision: 2, nameEn: 'Romanian leu', nameZh: '罗马尼亚列伊'),
  Coin(coinCode: 'RSD', coinSymbol: '', coinPrecision: 2, nameEn: 'Serbian dinar', nameZh: '塞尔维亚第纳尔'),
  Coin(coinCode: 'RUB', coinSymbol: '₽', coinPrecision: 2, nameEn: 'Russian ruble', nameZh: '俄罗斯卢布'),
  Coin(coinCode: 'RWF', coinSymbol: '', coinPrecision: 0, nameEn: 'Rwandan franc', nameZh: '卢旺达法郎'),
  Coin(coinCode: 'SAR', coinSymbol: '', coinPrecision: 2, nameEn: 'Saudi riyal', nameZh: '沙特里亚尔'),
  Coin(coinCode: 'SBD', coinSymbol: '', coinPrecision: 2, nameEn: 'Solomon Islands dollar', nameZh: '所罗门群岛元'),
  Coin(coinCode: 'SCR', coinSymbol: '', coinPrecision: 2, nameEn: 'Seychelles rupee', nameZh: '塞舌尔卢比'),
  Coin(coinCode: 'SDG', coinSymbol: '', coinPrecision: 2, nameEn: 'Sudanese pound', nameZh: '苏丹镑'),
  Coin(coinCode: 'SEK', coinSymbol: '', coinPrecision: 2, nameEn: 'Swedish krona (plural: kronor)', nameZh: '瑞典克朗'),
  Coin(coinCode: 'SGD', coinSymbol: '', coinPrecision: 2, nameEn: 'Singapore dollar', nameZh: '新加坡元'),
  Coin(coinCode: 'SHP', coinSymbol: '', coinPrecision: 2, nameEn: 'Saint Helena pound', nameZh: '圣赫勒拿镑'),
  Coin(coinCode: 'SLL / SLE', coinSymbol: '', coinPrecision: 2, nameEn: 'Sierra Leonean leone', nameZh: 'Sierra Leonean leone'),
  Coin(coinCode: 'SOS', coinSymbol: '', coinPrecision: 2, nameEn: 'Somali shilling', nameZh: '索马里先令'),
  Coin(coinCode: 'SRD', coinSymbol: '', coinPrecision: 2, nameEn: 'Surinamese dollar', nameZh: '苏里南元'),
  Coin(coinCode: 'SSP', coinSymbol: '', coinPrecision: 2, nameEn: 'South Sudanese pound', nameZh: '南苏丹镑'),
  Coin(coinCode: 'STN', coinSymbol: '', coinPrecision: 2, nameEn: 'São Tomé and Príncipe dobra', nameZh: '圣多美和普林西比多布拉'),
  Coin(coinCode: 'SVC', coinSymbol: '', coinPrecision: 2, nameEn: 'Salvadoran colón', nameZh: 'Salvadoran colón'),
  Coin(coinCode: 'SYP', coinSymbol: '', coinPrecision: 2, nameEn: 'Syrian pound', nameZh: '叙利亚镑'),
  Coin(coinCode: 'SZL', coinSymbol: '', coinPrecision: 2, nameEn: 'Swazi lilangeni', nameZh: '斯威士兰里兰吉尼'),
  Coin(coinCode: 'THB', coinSymbol: '฿', coinPrecision: 2, nameEn: 'Thai baht', nameZh: '泰铢'),
  Coin(coinCode: 'TJS', coinSymbol: '', coinPrecision: 2, nameEn: 'Tajikistani somoni', nameZh: '塔吉克斯坦索莫尼'),
  Coin(coinCode: 'TMT', coinSymbol: '', coinPrecision: 2, nameEn: 'Turkmenistan manat', nameZh: '土库曼斯坦马纳特'),
  Coin(coinCode: 'TND', coinSymbol: '', coinPrecision: 3, nameEn: 'Tunisian dinar', nameZh: '突尼斯第纳尔'),
  Coin(coinCode: 'TOP', coinSymbol: '', coinPrecision: 2, nameEn: 'Tongan paʻanga', nameZh: '汤加潘加'),
  Coin(coinCode: 'TRY', coinSymbol: '', coinPrecision: 2, nameEn: 'Turkish lira', nameZh: '土耳其里拉'),
  Coin(coinCode: 'TTD', coinSymbol: '', coinPrecision: 2, nameEn: 'Trinidad and Tobago dollar', nameZh: '特立尼达和多巴哥元'),
  Coin(coinCode: 'TWD', coinSymbol: '', coinPrecision: 2, nameEn: 'New Taiwan dollar', nameZh: '新台币'),
  Coin(coinCode: 'TZS', coinSymbol: '', coinPrecision: 2, nameEn: 'Tanzanian shilling', nameZh: '坦桑尼亚先令'),
  Coin(coinCode: 'UAH', coinSymbol: '₴', coinPrecision: 2, nameEn: 'Ukrainian hryvnia', nameZh: '乌克兰格里夫纳'),
  Coin(coinCode: 'UGX', coinSymbol: '', coinPrecision: 0, nameEn: 'Ugandan shilling', nameZh: '乌干达先令'),
  Coin(coinCode: 'USD', coinSymbol: '\$', coinPrecision: 2, nameEn: 'US dollar', nameZh: '美元'),
  Coin(coinCode: 'USN', coinSymbol: '', coinPrecision: 2, nameEn: 'United States dollar (next day) (funds code)', nameZh: '美元（次日，资金代码）'),
  Coin(coinCode: 'UYI', coinSymbol: '', coinPrecision: 0, nameEn: 'Uruguay Peso en Unidades Indexadas (URUIURUI) (funds code)', nameZh: '乌拉圭比索资金索引（URUIURUI，资金代码）'),
  Coin(coinCode: 'UYU', coinSymbol: '', coinPrecision: 2, nameEn: 'Uruguayan peso', nameZh: '乌拉圭比索'),
  Coin(coinCode: 'UYW', coinSymbol: '', coinPrecision: 4, nameEn: 'Unidad previsional', nameZh: 'Unidad previsional'),
  Coin(coinCode: 'UZS', coinSymbol: '', coinPrecision: 2, nameEn: 'Uzbekistan sum', nameZh: '乌兹别克斯坦索姆'),
  Coin(coinCode: 'VED', coinSymbol: '', coinPrecision: 2, nameEn: 'Venezuelan digital bolívar', nameZh: 'Venezuelan digital bolívar'),
  Coin(coinCode: 'VES', coinSymbol: '', coinPrecision: 2, nameEn: 'Venezuelan sovereign bolívar', nameZh: '委内瑞拉玻利瓦尔'),
  Coin(coinCode: 'VND', coinSymbol: '', coinPrecision: 0, nameEn: 'Vietnamese đồng', nameZh: '越南盾'),
  Coin(coinCode: 'VUV', coinSymbol: '', coinPrecision: 0, nameEn: 'Vanuatu vatu', nameZh: '瓦努阿图瓦图'),
  Coin(coinCode: 'WST', coinSymbol: '', coinPrecision: 2, nameEn: 'Samoan tala', nameZh: '萨摩亚塔拉'),
  Coin(coinCode: 'XAF', coinSymbol: '', coinPrecision: 0, nameEn: 'CFA franc BEAC', nameZh: '中非法郎'),
  Coin(coinCode: 'XAG', coinSymbol: '', coinPrecision: 2, nameEn: 'Silver (one troy ounce)', nameZh: '银（1金衡盎司）'),
  Coin(coinCode: 'XAU', coinSymbol: '', coinPrecision: 2, nameEn: 'Gold (one troy ounce)', nameZh: '金（1金衡盎司）'),
  Coin(coinCode: 'XBA', coinSymbol: '', coinPrecision: 2, nameEn: 'European Composite Unit (EURCO) (bond market unit)', nameZh: '欧洲货币合成单（EURCO，债券市场单位）'),
  Coin(coinCode: 'XBB', coinSymbol: '', coinPrecision: 2, nameEn: 'European Monetary Unit (E.M.U.-6) (bond market unit)', nameZh: '欧洲货币单位（E.M.U.-6，债券市场单位）'),
  Coin(coinCode: 'XBC', coinSymbol: '', coinPrecision: 2, nameEn: 'European Unit of Account 9 (E.U.A.-9) (bond market unit)', nameZh: '欧洲账户9单位（E.U.A.-9，债券市场单位）'),
  Coin(coinCode: 'XBD', coinSymbol: '', coinPrecision: 2, nameEn: 'European Unit of Account 17 (E.U.A.-17) (bond market unit)', nameZh: '欧洲账户17单位（E.U.A.-17，债券市场单位）'),
  Coin(coinCode: 'XCD', coinSymbol: '', coinPrecision: 2, nameEn: 'East Caribbean dollar', nameZh: '东加勒比元'),
  Coin(coinCode: 'XDR', coinSymbol: '', coinPrecision: 2, nameEn: 'Special drawing rights', nameZh: '特别提款权'),
  Coin(coinCode: 'XOF', coinSymbol: '', coinPrecision: 0, nameEn: 'CFA franc BCEAO', nameZh: '西非法郎'),
  Coin(coinCode: 'XPD', coinSymbol: '', coinPrecision: 2, nameEn: 'Palladium (one troy ounce)', nameZh: '钯（1金衡盎司）'),
  Coin(coinCode: 'XPF', coinSymbol: '', coinPrecision: 0, nameEn: 'CFP franc (franc Pacifique)', nameZh: '太平洋法郎（franc Pacifique）'),
  Coin(coinCode: 'XPT', coinSymbol: '', coinPrecision: 2, nameEn: 'Platinum (one troy ounce)', nameZh: '铂（1金衡盎司）'),
  Coin(coinCode: 'XSU', coinSymbol: '', coinPrecision: 2, nameEn: 'SUCRE', nameZh: '苏克雷（英语：SUCRE）'),
  Coin(coinCode: 'XTS', coinSymbol: '', coinPrecision: 2, nameEn: 'Code reserved for testing', nameZh: '为测试而特别保留的代码'),
  Coin(coinCode: 'XUA', coinSymbol: '', coinPrecision: 2, nameEn: 'ADB Unit of Account', nameZh: '非洲开发银行记帐单位'),
  Coin(coinCode: 'XXX', coinSymbol: '', coinPrecision: 2, nameEn: 'No currency', nameZh: '未包括的交易货币代码'),
  Coin(coinCode: 'YER', coinSymbol: '', coinPrecision: 2, nameEn: 'Yemeni rial', nameZh: '也门里亚尔'),
  Coin(coinCode: 'ZAR', coinSymbol: '', coinPrecision: 2, nameEn: 'South African rand', nameZh: '南非兰特'),
  Coin(coinCode: 'ZMW', coinSymbol: '', coinPrecision: 2, nameEn: 'Zambian kwacha', nameZh: '赞比亚克瓦查'),
  Coin(coinCode: 'ZWL', coinSymbol: '', coinPrecision: 2, nameEn: 'Zimbabwean dollar', nameZh: 'Zimbabwean dollar'),
];

/// 加密货币（源项目 `cryptocoinSet`）。
const List<Coin> kCryptoCoins = <Coin>[
  Coin(coinCode: 'BAB', coinSymbol: '￠', coinPrecision: 18, nameEn: 'Babecoin', nameZh: '巴贝币', coinSupply: 10000000000),
  Coin(coinCode: 'BTC', coinSymbol: '₿', coinPrecision: 8, nameEn: 'Bitcoin', nameZh: '比特币', coinSupply: 21000000),
  Coin(coinCode: 'DOGE', coinSymbol: 'Ð', coinPrecision: 8, nameEn: 'Dogecoin', nameZh: '狗狗币', coinSupply: 130000000000),
  Coin(coinCode: 'ETH', coinSymbol: 'Ξ', coinPrecision: 18, nameEn: 'Ethereum', nameZh: '以太币', coinSupply: 120440000),
  Coin(coinCode: 'EURT', coinSymbol: '₮', coinPrecision: 6, nameEn: 'EURT', nameZh: '欧元稳定币'),
  Coin(coinCode: 'LTC', coinSymbol: 'Ł', coinPrecision: 8, nameEn: 'Litecoin', nameZh: '莱特币', coinSupply: 84000000),
  Coin(coinCode: 'TIC', coinSymbol: 'τ', coinPrecision: 18, nameEn: 'Timecoin', nameZh: '时光币'),
  Coin(coinCode: 'TUC', coinSymbol: '￠', coinPrecision: 18, nameEn: 'Creditcoin', nameZh: '信用币', coinSupply: 10000000000),
  Coin(coinCode: 'USDT', coinSymbol: '₮', coinPrecision: 6, nameEn: 'USDT', nameZh: '美元稳定币', coinSupply: 80200000000),
];

/// 加密货币选择器里可选的几种（源项目 `App.data.js` 的 `cryptocoinSet` 子集）。
const List<String> kCryptocoinPickerCodes = <String>['TUC', 'BTC', 'ETH', 'USDT'];

/// 币种代码 → 货币。
final Map<String, Coin> kBankCoinByCode = <String, Coin>{
  for (final Coin coin in kBankCoins) coin.coinCode: coin,
};

final Map<String, Coin> kCryptoCoinByCode = <String, Coin>{
  for (final Coin coin in kCryptoCoins) coin.coinCode: coin,
};

/// 查法定货币；找不到返回 null。
Coin? bankCoinByCode(String? code) =>
    (code == null || code.isEmpty) ? null : kBankCoinByCode[code];

/// 查加密货币；找不到返回 null。
Coin? cryptoCoinByCode(String? code) =>
    (code == null || code.isEmpty) ? null : kCryptoCoinByCode[code];

/// 用户所在地区 → 默认法定货币（源项目 `App.data.js` 的 `land2bankcoin`：CN→CNY，其余→USD）。
Coin bankCoinForLand(String landCode) =>
    bankCoinByCode(landCode == 'CN' ? 'CNY' : 'USD') ?? kBankCoins.first;

/// 应用内默认加密货币（源项目 `cryptocoinNow = cryptocoinSet.TUC`）。
Coin get kCryptocoinDefault =>
    cryptoCoinByCode('TUC') ?? kCryptoCoins.first;

/// 加密货币选择器的候选列表（按 [kCryptocoinPickerCodes] 顺序）。
List<Coin> get kCryptocoinPicker => <Coin>[
      for (final String code in kCryptocoinPickerCodes)
        if (cryptoCoinByCode(code) != null) cryptoCoinByCode(code)!,
    ];
