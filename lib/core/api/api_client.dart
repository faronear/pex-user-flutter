/// API 客户端：封装源项目的 `wo.tt.callBase({ apiWho, apiTodo, apiWhat })`。
///
/// 契约：`POST {baseUrl}/api/{apiWho}/{apiTodo}`，请求体为 `apiWhat` +
/// `_clientInfo`（含 `lang`）+ `_passtoken`；响应体含 `_state`（用 [bok] 判定成功）。
library;

import 'package:dio/dio.dart';

import '../i18n/lang_text.dart';
import 'client_info.dart';

/// 后端成功状态集合（对应源项目 `wo.bok()`）。
const Set<String> kOkStates = <String>{
  'BOK',
  'SUCCESS',
  'REGISTER_SUCCESS',
  'RESET_SUCCESS',
  'LOGIN_SUCCESS',
  'AUTOLOGIN_SUCCESS',
  'VERIFY_SUCCESS',
};

/// 判定后端返回是否为成功状态。
bool bok(String? state) => state != null && kOkStates.contains(state);

/// API 端点。
class ApiEndpoint {
  const ApiEndpoint._();

  /// 编译期覆盖：`--dart-define=API_BASE=http://localhost:7739`。
  static const String _override = String.fromEnvironment('API_BASE');

  /// 生产后端。
  static const String production = 'https://pexserver.tic.cc';

  /// 本地开发后端：由 `keyname_to_apiport(idname) = BASEPORT_API_SERVER + alphaToDigit('pex')` 推导，
  /// 经实测为 `7739`（对应父级 AGENTS.md 的记录；`6173` 未监听）。
  static const String localDev = 'http://localhost:7739';

  static String get baseUrl => _override.isNotEmpty ? _override : production;

  /// 是否指向本地后端（用于开发期行为分支）。
  static bool get isLocal => baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');
}

class ApiClient {
  ApiClient({
    required this.clientInfo,
    String? baseUrl,
    String Function()? passtokenGetter,
    this.lang = LangCode.enUS,
    Dio? dio,
  })  : _baseUrl = baseUrl ?? ApiEndpoint.baseUrl,
        _passtokenGetter = passtokenGetter ?? (() => ''),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? ApiEndpoint.baseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 20),
              // 后端统一返回 JSON；不因非 2xx 抛异常，交由 _state 判定。
              validateStatus: (_) => true,
            ));

  final ClientInfo clientInfo;
  final Dio _dio;
  final String _baseUrl;
  final String Function() _passtokenGetter;

  /// 当前界面语言（随语言切换更新，用于 `_clientInfo.lang`）。
  String lang;

  String get baseUrl => _baseUrl;

  /// 源项目 `callBase` 的等价实现。
  ///
  /// 返回后端响应体（Map）。网络异常时返回 `_state: CLIENT_WOBASE_BROKEN`。
  Future<Map<String, dynamic>> callBase({
    required String apiWho,
    required String apiTodo,
    Map<String, dynamic> apiWhat = const <String, dynamic>{},
    String httpMethod = 'POST',
    Duration? timeout,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{...apiWhat};
    payload['_clientInfo'] = <String, dynamic>{
      ...clientInfo.toJson(),
      'lang': lang,
    };
    payload['_passtoken'] = _passtokenGetter();

    try {
      final Response<dynamic> response = await _dio.request<dynamic>(
        '/api/$apiWho/$apiTodo',
        data: httpMethod == 'GET' ? null : payload,
        queryParameters: httpMethod == 'GET' ? payload : null,
        options: Options(
          method: httpMethod,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      final dynamic body = response.data;
      if (body is Map) {
        return body.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{
        '_state': 'CLIENT_WOBASE_BADRESPONSE',
        '_status': response.statusCode,
      };
    } on DioException catch (error) {
      return <String, dynamic>{
        '_state': 'CLIENT_WOBASE_BROKEN',
        '_error': error.message ?? error.type.name,
      };
    }
  }

  /// 首次接触后端：拉取 envar 配置与自动登录结果。
  Future<Map<String, dynamic>> firstTouch({Duration? timeout}) => callBase(
        apiWho: 'User',
        apiTodo: 'first_touch',
        timeout: timeout,
      );
}
