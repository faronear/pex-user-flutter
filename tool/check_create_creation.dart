// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证「创作」链路（批次 3，对本地后端）。
///
/// 运行：`dart run tool/check_create_creation.dart [baseUrl]`
/// 流程：注册临时用户 → `create_creation`（新建，AGENT 模式）→ 复查 `get_single_creation`
/// → 带 `csid` 再提交一次（更新）→ 复查标题已变。
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

String hashStable(String data) => sha256.convert(utf8.encode(data)).toString();

Future<Map<String, dynamic>> post(
  HttpClient client,
  String baseUrl,
  String apiWho,
  String apiTodo,
  Map<String, dynamic> what,
  String passtoken,
) async {
  final HttpClientRequest request =
      await client.postUrl(Uri.parse('$baseUrl/api/$apiWho/$apiTodo'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(<String, dynamic>{
    ...what,
    '_clientInfo': <String, dynamic>{
      'appkey': 'AKBABELY',
      'lang': 'enUS',
      'uniPlatform': 'app',
      'deviceType': 'phone',
      'osName': 'macos',
      'webDomain': 'babelyx.com',
    },
    '_passtoken': passtoken,
  }));
  final HttpClientResponse response = await request.close();
  final String body = await response.transform(utf8.decoder).join();
  final dynamic decoded = jsonDecode(body);
  return decoded is Map
      ? decoded.map((dynamic k, dynamic v) => MapEntry(k.toString(), v))
      : <String, dynamic>{'_state': 'BAD_RESPONSE'};
}

/// 一份最小可用的创建草稿（对齐 `App.data.js` 的 `creation_reset_pexNew`）。
Map<String, dynamic> draft({
  required String title,
  required String text,
  num viewAmount = 1,
}) =>
    <String, dynamic>{
      'pexdataRaw': <Map<String, dynamic>>[
        <String, dynamic>{'text': text},
      ],
      'openTitle': title,
      'openCover': '',
      'viewerPact': <String, dynamic>{'type': 'PAYABLE', 'amount': viewAmount, 'coin': 'TUC'},
      'holderPact': <String, dynamic>{
        'type': 'FORBIDDEN',
        'amount': '',
        'quota': '',
        'coin': 'TUC'
      },
      'workerPact': <String, dynamic>{
        'type': 'FORBIDDEN',
        'amount': '',
        'share': '',
        'coin': 'TUC'
      },
      'ownerPact': <String, dynamic>{'type': 'FORBIDDEN', 'amount': '', 'coin': 'TUC'},
      'totalPriceToSeal': 0,
      'totalPriceToMint': 0,
      'mintNow': false,
    };

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String commid =
      '+86-136${DateTime.now().millisecondsSinceEpoch % 100000000}';

  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);
  String passtoken = '';

  try {
    print('--- 1) 注册临时用户 $commid');
    final Map<String, dynamic> ident = await post(
        client, baseUrl, 'User', 'identify_user', <String, dynamic>{'commid': commid}, '');
    passtoken = ident['_passtoken']?.toString() ?? '';
    if (ident['_state'] != 'NEW_USER') {
      print('FAIL  非新用户，终止');
      return;
    }
    final String usid = ident['usid'].toString();
    final Map<String, dynamic> sent = await post(
        client, baseUrl, 'User', 'send_passcode',
        <String, dynamic>{'passcodeType': 'REGISTER', 'commid': commid}, passtoken);
    passtoken = sent['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> verified = await post(
        client, baseUrl, 'User', 'verify_passcode',
        <String, dynamic>{'passcode': sent['passcode'], 'inviterHaid': ''}, passtoken);
    passtoken = verified['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> registered = await post(
        client, baseUrl, 'User', 'register_new_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        },
        passtoken);
    passtoken = registered['_passtoken']?.toString() ?? passtoken;
    print('  register _state=${registered['_state']}');

    print('--- 2) create_creation（新建，AGENT 模式）');
    final String title = 'create check ${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> created = await post(
        client,
        baseUrl,
        'Creation',
        'create_creation',
        draft(title: title, text: '为了验证创建链路而写的内容。'),
        passtoken);
    print('  _state=${created['_state']}  _msg=${created['_msg']}');
    if (created['_state'] != 'SUCCESS') {
      print('FAIL  创建失败');
      return;
    }
    final Map<String, dynamic> creation =
        (created['creation'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String csid = creation['csid']?.toString() ?? '';
    print('  csid=$csid  openTitle=${creation['openTitle']}');
    print('  creationReward=${created['creationReward']}  '
        'userUpdated=${created['userUpdated'] != null}');
    if (csid.isEmpty) {
      print('FAIL  响应里没有 creation.csid');
      return;
    }

    print('--- 3) 复查 get_single_creation');
    final Map<String, dynamic> single = await post(client, baseUrl, 'Creation',
        'get_single_creation', <String, dynamic>{'csid': csid}, passtoken);
    final Map<String, dynamic> fetched =
        (single['creation'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final bool titleOk = fetched['openTitle']?.toString() == title;
    final bool hasContent = fetched['pexdataUser'] != null;
    print('  标题一致? $titleOk   含 pexdataUser? $hasContent');

    print('--- 4) 带 csid 再提交（更新）');
    final String newTitle = '$title updated';
    final Map<String, dynamic> updated = await post(
        client,
        baseUrl,
        'Creation',
        'create_creation',
        <String, dynamic>{
          ...fetched,
          ...draft(title: newTitle, text: '更新后的内容。', viewAmount: 2),
          'csid': csid,
        },
        passtoken);
    print('  _state=${updated['_state']}  _msg=${updated['_msg']}');
    final bool updatedOk = updated['_state'] == 'SUCCESS';

    final Map<String, dynamic> recheck = await post(client, baseUrl, 'Creation',
        'get_single_creation', <String, dynamic>{'csid': csid}, passtoken);
    final Map<String, dynamic> after =
        (recheck['creation'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final bool newTitleOk = after['openTitle']?.toString() == newTitle;
    print('  更新后标题=$newTitle? $newTitleOk');

    print(titleOk && hasContent && updatedOk && newTitleOk
        ? 'PASS  创作链路（新建 + 更新）契约正确'
        : 'FAIL  创作链路有异常');
  } finally {
    client.close(force: true);
  }
}
