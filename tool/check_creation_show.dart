// ignore_for_file: avoid_print
/// 开发辅助脚本：核对 `showCreation` 详情页（2A 只读骨架）所依赖的后端契约。
///
/// 运行：`dart run tool/check_creation_show.dart [baseUrl] [csid] [appkey]`
/// 流程：`get_creation_list` 取首个 csid（或直接用入参）→ `get_single_creation`
/// → 校验页面读取的关键字段是否齐备，并输出封面判定所需的状态。
library;

import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> post(
  HttpClient client,
  String baseUrl,
  String apiTodo,
  Map<String, dynamic> what,
  String appkey,
) async {
  final HttpClientRequest request =
      await client.postUrl(Uri.parse('$baseUrl/api/Creation/$apiTodo'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(<String, dynamic>{
    ...what,
    '_clientInfo': <String, dynamic>{
      'appkey': appkey,
      'lang': 'enUS',
      'uniPlatform': 'app',
      'deviceType': 'phone',
      'osName': 'macos',
      'webDomain': appkey == 'AKBABELY' ? 'babelyx.com' : 'agidin.com',
    },
    '_passtoken': '',
  }));
  final HttpClientResponse response = await request.close();
  final String body = await response.transform(utf8.decoder).join();
  final dynamic decoded = jsonDecode(body);
  return decoded is Map
      ? decoded.map((dynamic k, dynamic v) => MapEntry(k.toString(), v))
      : <String, dynamic>{'_state': 'BAD_RESPONSE'};
}

void main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String appkey = args.length > 2 ? args[2] : 'AKBABELY';

  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  String csid = args.length > 1 ? args[1] : '';
  try {
    if (csid.isEmpty) {
      final Map<String, dynamic> list = await post(
          client, baseUrl, 'get_creation_list', <String, dynamic>{'takeLimit': 1}, appkey);
      final List<dynamic> items = (list['creationList'] as List?) ?? <dynamic>[];
      if (items.isEmpty) {
        print('FAIL  列表为空，无法取样例作品');
        return;
      }
      csid = (items.first as Map)['csid'].toString();
    }
    print('--- 样例作品 csid=$csid');

    final Map<String, dynamic> single = await post(
        client, baseUrl, 'get_single_creation', <String, dynamic>{'csid': csid}, appkey);
    print('  _state=${single['_state']}');
    if (single['_state'] != 'SUCCESS') {
      print('FAIL  get_single_creation 失败: ${single['_msg']}');
      return;
    }

    final Map<String, dynamic> c =
        (single['creation'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> sum =
        (c['pexdataSum'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> viewer =
        (c['viewerPact'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> holder =
        (c['holderPact'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final List<(String, bool)> checks = <(String, bool)>[
      ('csid', (c['csid']?.toString() ?? '').isNotEmpty),
      ('openTitle', c.containsKey('openTitle')),
      ('createTimeUnix', c['createTimeUnix'] != null),
      ('creatorUsid', c.containsKey('creatorUsid')),
      ('nickname', c.containsKey('nickname')),
      ('pexBaseCidRoot', c.containsKey('pexBaseCidRoot')),
      ('pexBaseCidNow', c.containsKey('pexBaseCidNow')),
      ('pexdataSum', sum.isNotEmpty),
      ('viewerPact.type', viewer.containsKey('type')),
      ('holderPact.type', holder.containsKey('type')),
      ('holderPact.quota', holder.containsKey('quota')),
      ('countViewer', c.containsKey('countViewer')),
      ('countHolder', c.containsKey('countHolder')),
      ('countComment', c.containsKey('countComment')),
      ('lifeState', c.containsKey('lifeState')),
      ('ownerState', c.containsKey('ownerState')),
      ('creatorState', c.containsKey('creatorState')),
      ('censorState', c.containsKey('censorState')),
    ];

    bool ok = true;
    for (final (String name, bool present) in checks) {
      if (!present) ok = false;
      print('  ${present ? 'OK  ' : 'MISS'} $name');
    }

    final bool unlocked = c['pexdataUser'] != null;
    final String viewerType = viewer['type']?.toString() ?? '';
    print('--- 派生（匿名视角）');
    print('  已解锁(pexdataUser) = $unlocked  → 封面分支 = ${unlocked ? 'content/censoring' : 'locked'}');
    print('  viewerPact.type = $viewerType  → 解密遮罩 = ${viewerType != 'FORBIDDEN'}');
    print('  库存 = ${holder['quota'] ?? '(无限)'} - ${c['countHolder']}');
    print('  评论数 = ${(single['commentList'] as List?)?.length}（首屏返回）');

    print(ok ? 'PASS  详情页 2A 所需字段齐备' : 'FAIL  存在缺失字段');
  } finally {
    client.close(force: true);
  }
}
