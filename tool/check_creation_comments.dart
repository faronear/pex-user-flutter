// ignore_for_file: avoid_print
/// 开发辅助脚本：端到端验证 showCreation 2B 评论链路（对本地后端）。
///
/// 运行：`dart run tool/check_creation_comments.dart [baseUrl]`
/// 流程：注册临时用户 → 取样例作品 → comment_creation → get_comment_list
/// → delete_comment → 复查列表。
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

Future<void> main(List<String> args) async {
  final String baseUrl = args.isNotEmpty ? args.first : 'http://localhost:7739';
  final String commid =
      '+86-137${DateTime.now().millisecondsSinceEpoch % 100000000}';

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
        client,
        baseUrl,
        'User',
        'send_passcode',
        <String, dynamic>{'passcodeType': 'REGISTER', 'commid': commid},
        passtoken);
    passtoken = sent['_passtoken']?.toString() ?? passtoken;
    final String passcode = sent['passcode'].toString();
    final Map<String, dynamic> verified = await post(
        client,
        baseUrl,
        'User',
        'verify_passcode',
        <String, dynamic>{'passcode': passcode, 'inviterHaid': ''},
        passtoken);
    passtoken = verified['_passtoken']?.toString() ?? passtoken;
    final Map<String, dynamic> registered = await post(
        client,
        baseUrl,
        'User',
        'register_new_user',
        <String, dynamic>{
          'commid': commid,
          'passwordClient': hashStable('test1234$usid'),
        },
        passtoken);
    passtoken = registered['_passtoken']?.toString() ?? passtoken;
    print('  register _state=${registered['_state']}');

    print('--- 2) 取样例作品');
    final Map<String, dynamic> list = await post(client, baseUrl, 'Creation',
        'get_creation_list', <String, dynamic>{'takeLimit': 1}, passtoken);
    final List<dynamic> items = (list['creationList'] as List?) ?? <dynamic>[];
    if (items.isEmpty) {
      print('FAIL  没有样例作品');
      return;
    }
    final Map<String, dynamic> sample =
        (items.first as Map).cast<String, dynamic>();
    final String csid = sample['csid'].toString();
    final String target = sample['pexdataCidHashRoot'].toString();
    print('  csid=$csid');

    print('--- 3) comment_creation');
    final String text = 'comment check ${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> published = await post(
        client,
        baseUrl,
        'Creation',
        'comment_creation',
        <String, dynamic>{
          'commentStory': <Map<String, dynamic>>[<String, dynamic>{'text': text}],
          'commentTarget': target,
          'commentCsid': csid,
        },
        passtoken);
    print('  _state=${published['_state']}  _msg=${published['_msg']}');
    if (published['_state'] != 'SUCCESS') {
      print('FAIL  评论未发表');
      return;
    }
    final Map<String, dynamic> comment =
        (published['comment'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String uuid = comment['commentUuid']?.toString() ?? '';
    print('  commentUuid=$uuid  story=${jsonEncode(comment['commentStory'])}');
    if (uuid.isEmpty) {
      print('FAIL  响应里没有 comment.commentUuid');
      return;
    }

    print('--- 4) get_comment_list 应包含该评论');
    final Map<String, dynamic> listed = await post(
        client,
        baseUrl,
        'Creation',
        'get_comment_list',
        <String, dynamic>{'commentTarget': target, 'commentCsid': csid, 'takeLimit': 10},
        passtoken);
    final List<dynamic> comments = (listed['commentList'] as List?) ?? <dynamic>[];
    final bool found =
        comments.any((dynamic e) => e['commentUuid']?.toString() == uuid);
    print('  列表 ${comments.length} 条，包含新评论? $found');
    if (!found) {
      print('FAIL  新评论不在列表里');
      return;
    }

    print('--- 5) delete_comment');
    final Map<String, dynamic> deleted = await post(client, baseUrl, 'Creation',
        'delete_comment', <String, dynamic>{'commentUuid': uuid}, passtoken);
    print('  _state=${deleted['_state']}  _msg=${deleted['_msg']}');

    print('--- 6) 复查列表');
    final Map<String, dynamic> relisted = await post(
        client,
        baseUrl,
        'Creation',
        'get_comment_list',
        <String, dynamic>{'commentTarget': target, 'commentCsid': csid, 'takeLimit': 10},
        passtoken);
    final List<dynamic> after = (relisted['commentList'] as List?) ?? <dynamic>[];
    final bool still = after.any((dynamic e) => e['commentUuid']?.toString() == uuid);
    print('  列表 ${after.length} 条，仍包含? $still');

    print(!still && deleted['_state'] == 'SUCCESS'
        ? 'PASS  评论链路（发表/列表/删除）契约正确'
        : 'FAIL  评论链路有异常');
  } finally {
    client.close(force: true);
  }
}
