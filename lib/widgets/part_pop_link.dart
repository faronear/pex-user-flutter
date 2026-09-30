/// 分享弹窗，对应源项目 `parts/partPopLink.vue`：
/// 品牌 logo + 称谓 + 分享标题 + 二维码 + 可点链接 + 复制/系统分享。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/pex_icon.dart';
import '../core/state/app_providers.dart';
import '../core/state/envar_provider.dart';
import '../theme/app_theme.dart';
import 'part_close_button.dart';
import 'part_icontext_copy.dart';

/// [shareTitle] / [shareUrl] 均为可为多语言的原始值（对应源项目 `wo.ll(...)` 的入参）。
Future<void> showPopLinkSheet(
  BuildContext context,
  WidgetRef ref, {
  required Object? shareTitle,
  required Object? shareUrl,
  bool linkEllipsis = false,
}) {
  final LangText url = LangText.fromMap(shareUrl);
  final LangText title = LangText.fromMap(shareTitle);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (BuildContext context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        minWidth: 320,
        maxWidth: 600,
      ),
      child: _PopLink(
        shareTitle: title,
        shareUrl: url,
        linkEllipsis: linkEllipsis,
        lang: ref.read(languageProvider),
      ),
    ),
  );
}

class _PopLink extends ConsumerWidget {
  const _PopLink({
    required this.shareTitle,
    required this.shareUrl,
    required this.linkEllipsis,
    required this.lang,
  });

  final LangText shareTitle;
  final LangText shareUrl;
  final bool linkEllipsis;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Envar envar = ref.watch(envarProvider);
    final String url = ll(lang, shareUrl);
    final String brandName = ll(lang, envar.callnames);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PartCloseButton(onClose: () => Navigator.of(context).pop()),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              ref.watch(brandProvider).logoAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.apps, color: PexColors.grey9),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              brandName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              ll(lang, shareTitle),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (url.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: QrImageView(data: url, size: 200, backgroundColor: Colors.white),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openUrl(url);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: <Widget>[
                          PexIcon.icont(
                            'icont-hyperlink',
                            size: 16,
                            color: PexColors.blueMy,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              url,
                              maxLines: linkEllipsis ? 1 : 3,
                              overflow: linkEllipsis
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.clip,
                              style: const TextStyle(
                                fontSize: 14,
                                color: PexColors.blueMy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 系统分享（源项目 `uni.shareWithSystem`，仅 App 端；此处先提供复制）。
                PartIcontextCopy(
                  onCopy: () => Clipboard.setData(
                    ClipboardData(text: _urlAndTitle(ref, url, brandName)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 源项目 `urlAndTitle`：链接后追加 `_ut=\n标题`，便于粘贴到浏览器地址栏。
  String _urlAndTitle(WidgetRef ref, String url, String brandName) {
    final String title = ll(lang, shareTitle);
    final String composed = title.isNotEmpty
        ? '$brandName-$title'
        : ll(lang, LangText.fromMap(ref.read(envarProvider).raw['slogans']));
    if (composed.isNotEmpty && url.contains('://')) {
      return '$url${url.contains('?') ? '&' : '?'}_ut=\n$composed';
    }
    return url;
  }

  Future<void> _openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
