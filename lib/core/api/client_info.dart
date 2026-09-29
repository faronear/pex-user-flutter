/// 客户端信息，对应源项目 `wo.ss._clientInfo`。
library;

import '../responsive/device_info.dart';
import '../../brands/brand_config.dart';

class ClientInfo {
  const ClientInfo({
    required this.appkey,
    required this.appVersionCode,
    required this.uniPlatform,
    required this.deviceType,
    required this.osName,
    required this.webDomain,
  });

  final String appkey;

  /// 源项目版本码格式 `YYMMDDHH`（如 26082301 = 2026-08-23 01 时）。
  final int appVersionCode;

  /// `web` 或 `app`（与源项目 `uniPlatform` 一致）。
  final String uniPlatform;

  /// `pc` / `pad` / `phone`。
  final String deviceType;

  final String osName;

  /// 当前网站域名（返给后端用于拼接链接）。
  final String webDomain;

  factory ClientInfo.forBrand(BrandConfig brand, DeviceInfo device) => ClientInfo(
        appkey: brand.appkey,
        appVersionCode: kAppVersionCode,
        uniPlatform: device.inWeb ? 'web' : 'app',
        deviceType: switch (device.deviceType) {
          DeviceType.pc => 'pc',
          DeviceType.pad => 'pad',
          DeviceType.phone => 'phone',
        },
        osName: device.osName,
        webDomain: brand.webDomain,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'appkey': appkey,
        'appVersionCode': appVersionCode,
        'uniPlatform': uniPlatform,
        'deviceType': deviceType,
        'osName': osName,
        'webDomain': webDomain,
      };
}

/// 应用版本码（源项目 `manifest.json` 的 `versionCode`，由构建脚本按 `YYMMDDHH` 生成）。
/// 迁移期先用固定值，后续由构建流程注入。
const int kAppVersionCode = 26092900;
