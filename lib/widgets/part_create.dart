/// 创作编辑器，对应源项目 `parts/partCreate.vue`（1012 行，UGC 核心）。
///
/// 用于两处：`midBabely`（新建）与 `showCreationUpdate`（修改），草稿由
/// [creationDraftProvider] 承载（对应 `wo.ss.Creation.ctnCreate` / `ctnUpdate`）。
///
/// **范围说明（重要）**：源项目支持三种加密封印模式（AGENT 委托 / JOINT 联合 / CREATOR 自主）
/// 与「同时铸造 NFT」开关，但两者都由 `envar.sealChoice` / `mintChoice` 控制，
/// 而这两个开关在**客户端与服务端都为 false**（`envar-config.js` 里 `inUniapp ? false : undefined`
/// 且后端 `create_creation` 同样校验 `sealChoice`）。因此自封模式与铸造开关**在当前产品中不可达**，
/// 本轮只实现 **AGENT** 路径；将来若要启用，需先补 Dart 版 `tic-crypto`（阶段四）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/api/creation_api.dart';
import '../core/api/fileloader_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lang_text.dart';
import '../core/icons/icont_icons.dart';
import '../core/icons/pex_icon.dart';
import '../core/router/app_router.dart';
import '../core/state/app_providers.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/creation_draft_provider.dart';
import '../core/state/creation_provider.dart';
import '../core/state/envar_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/feedback.dart';
import '../core/util/file_utils.dart';
import '../core/util/online_guard.dart';
import '../core/util/pex_file_picker.dart';
import '../core/util/pex_toolkit.dart';
import '../core/util/server_url.dart';
import '../core/util/story_utils.dart';
import '../theme/app_theme.dart';
import 'part_button_submit.dart';
import 'part_close_button.dart';
import 'part_empty_list.dart';
import 'part_linkhelp.dart';
import 'part_pay_sheet.dart';
import 'part_show_loading.dart';
import 'part_story_editor.dart';
import 'part_texts.dart';

const LangText _kTitleLabel = LangText(zhCN: '标题', enUS: 'Title');

const LangText _kPublicOptional = LangText(
  zhCN: '将被公开。可省略。',
  enUS: 'Will be public. Optional.',
  deDE: 'Wird öffentlich sein. Optional.',
  jaJP: '公開されます。任意です。',
);

const LangText _kUntitled = LangText(
  zhCN: '无题',
  enUS: 'Untitled',
  deDE: 'Ohne Titel',
  jaJP: '無題',
);

const LangText _kCoverLabel = LangText(zhCN: '封面', enUS: 'Cover');

const LangText _kCoverHintPc = LangText(
  zhCN: '把图片拖拽到这里，或者点击上传。',
  enUS: 'Drag&drop or click to upload an image.',
);

const LangText _kContentLabel = LangText(zhCN: '内容', enUS: 'Content');

const LangText _kRequired = LangText(zhCN: '必填。', enUS: 'Required. ');

const LangText _kContentNotes = LangText(
  zhCN: '将被加密保存，永远属于您。',
  enUS: 'Will be encrypted. Belongs to you forever.',
  jaJP: '暗号化され、あなたのものになります。',
  deDE: 'Wird verschlüsselt. Gehört Ihnen für immer.',
);

const LangText _kEstimatedCost = LangText(
  zhCN: '\n预估费用 = ',
  enUS: '\nEstimated Cost = ',
);

const LangText _kNext = LangText(zhCN: '下一步', enUS: 'Next');

const LangText _kCreate = LangText(zhCN: '创建', enUS: 'Create');

const LangText _kContentEmpty = LangText(
  zhCN: '内容不能为空！',
  enUS: 'Content cannot be empty!',
);

const LangText _kNeedOwnerPrice = LangText(
  zhCN: '所有权合约的价格必须大于0',
  enUS: 'The price of the ownership pact must be bigger than 0.',
);

const LangText _kDecryptFee = LangText(
  zhCN: '解密费',
  enUS: 'Decryption Fee',
  deDE: 'Entschlüsselungsgebühr',
  jaJP: '復号化料',
);

const LangText _kQuota = LangText(
  zhCN: '名额',
  enUS: 'Quota',
  deDE: 'Quoten',
  jaJP: '定員',
);

const LangText _kUnitPrice = LangText(
  zhCN: '单价',
  enUS: 'Unit Price',
  deDE: 'Stückpreis',
  jaJP: '単価',
);

const LangText _kShareRatio = LangText(
  zhCN: '股权占比',
  enUS: 'Sharing Ratio',
  deDE: 'Einnahmeanteil',
  jaJP: '収益分配比率',
);

const LangText _kAgencyFee = LangText(
  zhCN: '代理费',
  enUS: 'Agency Fee',
  deDE: 'Agenturgebühr',
  jaJP: '代理手数料',
);

const LangText _kSharePlaceholder = LangText(
  zhCN: '收益分成百分比',
  enUS: 'Profit sharing of the worker',
);

const LangText _kTransferPrice = LangText(
  zhCN: '转让总价',
  enUS: 'Total Transfer Price',
  deDE: 'Gesamtpreis',
  jaJP: '譲渡総額',
);

const LangText _kMinOne = LangText(
  zhCN: '最小为1',
  enUS: 'Minimum is 1',
  deDE: 'Minimum ist 1',
  jaJP: '最小は 1 です',
);

const LangText _kFeeTitle = LangText(
  zhCN: '加密铸造费',
  enUS: 'Encryption & Minting Fee',
);

const LangText _kRejected = LangText(
  zhCN: '疑似违反中国审查政策无法发表',
  enUS: 'Rejected by China moderation policy',
);

const LangText _kGotIt = LangText(zhCN: '知道了', enUS: 'Got it');

/// 创作编辑器。草稿由 [creationDraftProvider] 提供；未装载时显示加载态。
class PartCreate extends ConsumerStatefulWidget {
  const PartCreate({super.key});

  @override
  ConsumerState<PartCreate> createState() => _PartCreateState();
}

class _PartCreateState extends ConsumerState<PartCreate> {
  bool _coverLoading = false;
  LangText? _coverFeedback;
  LangText? _storyFeedback;
  bool _showErrorStory = false;

  /// 上传封面（源项目 `upload_creation_cover`）。
  Future<void> _uploadCover() async {
    if (!await checkOnline(context, ref)) return;
    if (!mounted) return;
    setState(() {
      _coverLoading = true;
      _coverFeedback = null;
    });

    final PickedMedia? picked = await pickMedia(mediaType: 'image');
    if (picked == null || !mounted) {
      setState(() => _coverLoading = false);
      return;
    }
    final FileloaderApi api = ref.read(fileloaderApiProvider);
    final LangText? invalid =
        api.validate(filename: picked.filename, size: picked.size, mediaType: 'image');
    if (invalid != null) {
      setState(() {
        _coverLoading = false;
        _coverFeedback = invalid;
      });
      return;
    }
    final FileUploadResult result =
        await api.uploadFile(filename: picked.filename, bytes: picked.bytes);
    if (!mounted) return;
    setState(() => _coverLoading = false);
    if (!result.ok) {
      if (!result.cancelled) setState(() => _coverFeedback = result.message);
      return;
    }
    ref.read(creationDraftProvider.notifier).setField(
          'openCover',
          chooseUrl(result.fileInfo, prefer: 'url'),
        );
  }

  /// 下一步：校验后打开合约弹窗（源项目 `validate_creation`）。
  Future<void> _next(CreationDraftState draft, bool storyEmpty) async {
    final bool contentRequired = ref.read(envarProvider).boolOf('contentRequired');
    final String title = draft.raw['openTitle']?.toString() ?? '';
    final String cover = draft.raw['openCover']?.toString() ?? '';
    final bool invalid = contentRequired
        ? storyEmpty
        : (title.trim().isEmpty && cover.isEmpty && storyEmpty);
    if (invalid) {
      setState(() {
        _showErrorStory = true;
        _storyFeedback = _kContentEmpty;
      });
      return;
    }
    await showPactSheet(
      context,
      ref,
      onCreated: (Map<String, dynamic> creation, num? reward) =>
          afterCreation(context, ref, creation, reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CreationDraftState draft = ref.watch(creationDraftProvider);
    final Envar envar = ref.watch(envarProvider);
    final String lang = ref.watch(languageProvider);
    final bool inPc = MediaQuery.sizeOf(context).width >= 900;

    if (!draft.readyShow) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: PartShowLoading(),
      );
    }
    if (draft.notFound || draft.denied) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: PartEmptyList(
          prompt: draft.denied
              ? const LangText(
                  zhCN: '您没有修改本作品的权限。',
                  enUS: 'You have no right to modify this creation.',
                )
              : const LangText(
                  zhCN: '找不到您指定的创作品',
                  enUS: 'The creation you specified could not be found',
                  deDE: 'Die von Ihnen angegebene Kreation konnte nicht gefunden werden',
                  jaJP: '指定された创作品が見つかりませんでした',
                ),
          belowText: ref.watch(brandProvider).midPageTitle,
          belowAction: () =>
              context.push('/${ref.read(brandProvider).midPage}'),
        ),
      );
    }

    final bool storyEmpty = isEmptyStory(draft.story);
    final String title = draft.raw['openTitle']?.toString() ?? '';
    final String cover = draft.raw['openCover']?.toString() ?? '';
    final bool contentRequired = envar.boolOf('contentRequired');
    final bool invalidInput = contentRequired
        ? storyEmpty
        : (title.trim().isEmpty && cover.isEmpty && storyEmpty);
    final num priceToSeal = _numOf(envar.raw['priceToSeal']);
    final num totalSeal = priceToSeal * draft.story.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PartLinkhelp(helpLink: envar.str('linkHowToCreateArtifact')),
        _section(
          header: <Widget>[
            Text(ll(lang, _kTitleLabel), style: _kSectionTitle),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ll(lang, _kPublicOptional), style: _kSectionDesc),
            ),
          ],
          body: TextField(
            controller: TextEditingController(text: title)
              ..selection = TextSelection.collapsed(offset: title.length),
            onChanged: (String value) =>
                ref.read(creationDraftProvider.notifier).setField('openTitle', value),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: ll(lang, _kUntitled),
              hintStyle: const TextStyle(fontSize: 13, color: PexColors.greyA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: PexColors.border),
              ),
            ),
          ),
        ),
        _section(
          header: <Widget>[
            Text(ll(lang, _kCoverLabel), style: _kSectionTitle),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ll(lang, _kPublicOptional), style: _kSectionDesc),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: _coverLoading ? null : _uploadCover,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: PexColors.border),
                  ),
                  child: cover.isNotEmpty
                      ? Stack(
                          children: <Widget>[
                            ServerImage(cover, fit: BoxFit.fitWidth, width: double.infinity),
                            if (_coverLoading)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: Color(0x66000000),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: <Widget>[
                              PexIcon.uni('plusempty', size: 32, color: PexColors.grey9),
                              if (inPc)
                                Text(
                                  ll(lang, _kCoverHintPc),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: PexColors.greyA,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
              if (_coverFeedback != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    ll(lang, _coverFeedback!),
                    style: const TextStyle(fontSize: 13, color: Color(0xFFDD6161)),
                  ),
                ),
            ],
          ),
        ),
        _section(
          header: <Widget>[
            Text(ll(lang, _kContentLabel), style: _kSectionTitle),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: _kSectionDesc,
                  children: <InlineSpan>[
                    if (contentRequired)
                      TextSpan(
                        text: ll(lang, _kRequired),
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    TextSpan(text: ll(lang, _kContentNotes)),
                    if (priceToSeal > 0)
                      TextSpan(
                        text: '${ll(lang, _kEstimatedCost)}'
                            '${numberPrecision(totalSeal)}'
                            '${envar.tucSymbol}',
                      ),
                  ],
                ),
              ),
            ),
          ],
          body: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: storyEmpty && _showErrorStory
                    ? const Color(0xFFDD6161)
                    : Colors.transparent,
              ),
            ),
            child: PartStoryEditor(
              story: draft.story,
              onStoryChanged: (List<Map<String, dynamic>> next) {
                ref.read(creationDraftProvider.notifier).setStory(next);
                if (_showErrorStory && !isEmptyStory(next)) {
                  setState(() {
                    _showErrorStory = false;
                    _storyFeedback = null;
                  });
                }
              },
              allowText: true,
              allowImage: true,
              allowVideo: envar.boolOf('creationVideo'),
              allowAudio: envar.boolOf('creationAudio'),
              allowFile: envar.boolOf('creationFile'),
              allowLink: envar.boolOf('creationLink'),
              textPlaceholder: null,
            ),
          ),
        ),
        const SizedBox(height: 30),
        PartButtonSubmit(
          disabled: invalidInput || _coverLoading,
          onPressed: () => _next(draft, storyEmpty),
          children: <Widget>[
            Text(ll(lang, _kNext)),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.arrow_forward, size: 20, color: Colors.white),
            ),
          ],
        ),
        if (_storyFeedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 30),
            child: Text(
              ll(lang, _storyFeedback!),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFDD6161)),
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _section({required List<Widget> header, required Widget body}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...header,
            ],
          ),
          const SizedBox(height: 5),
          body,
        ],
      ),
    );
  }
}

const TextStyle _kSectionTitle = TextStyle(fontSize: 15);
const TextStyle _kSectionDesc = TextStyle(fontSize: 13, color: PexColors.grey9);

// ---------------------------------------------------------------------------
// 合约设置弹窗（源项目 `popPact`）
// ---------------------------------------------------------------------------

Future<void> showPactSheet(
  BuildContext context,
  WidgetRef ref, {
  required void Function(Map<String, dynamic> creation, num? reward) onCreated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PexColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (BuildContext context) => _PactSheet(onCreated: onCreated),
  );
}

class _PactSheet extends ConsumerStatefulWidget {
  const _PactSheet({required this.onCreated});

  final void Function(Map<String, dynamic> creation, num? reward) onCreated;

  @override
  ConsumerState<_PactSheet> createState() => _PactSheetState();
}

class _PactSheetState extends ConsumerState<_PactSheet> {
  bool _creating = false;
  LangText? _feedback;

  Map<String, dynamic> get _draft => ref.read(creationDraftProvider).raw;

  /// 合约开关：`FORBIDDEN` ↔ `PAYABLE`。
  Widget _switch({required String pactKey, required bool enabled}) {
    return Switch(
      value: enabled,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: (bool value) => ref
          .read(creationDraftProvider.notifier)
          .setPact(pactKey, 'type', value ? 'PAYABLE' : 'FORBIDDEN'),
    );
  }

  Widget _pactHeader(Map<String, dynamic> item, String noteKey) {
    final String lang = ref.watch(languageProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PexIcon(
          PexIcons.byPrefix(item['iconPrefix']?.toString(), item['iconType']?.toString()),
          size: 20,
          color: PexColors.grey3,
        ),
        const SizedBox(width: 6),
        Text(
          ll(lang, LangText.fromMap(item['pact_tag'])),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ll(lang, LangText.fromMap(item[noteKey])),
            style: _kSectionDesc,
          ),
        ),
      ],
    );
  }

  /// 数字输入 + 右侧单位标签（源项目 `.locInputSymbol`）。
  Widget _numberField({
    required String pactKey,
    required String field,
    required LangText unit,
    required String hint,
    String symbol = '',
    List<String> forbiddenKeys = const <String>['-'],
  }) {
    final String value = _draft[pactKey]?[field]?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.deny(RegExp('[${forbiddenKeys.join()}]')),
        ],
        onChanged: (String text) => ref
            .read(creationDraftProvider.notifier)
            .setPact(pactKey, field, text),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: PexColors.greyA),
          contentPadding: const EdgeInsets.fromLTRB(8, 10, 45, 10),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(symbol, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 2),
                Text(
                  ll(ref.watch(languageProvider), unit),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: PexColors.border),
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_creating) return;
    setState(() {
      _creating = true;
      _feedback = null;
    });
    final CreateOutcome outcome = await submitCreation(context, ref);
    if (!mounted) return;
    setState(() => _creating = false);

    if (outcome.needTopUp) {
      // 先关掉合约弹窗，再开「付费确认」（源项目同样是关掉再开）。
      Navigator.of(context).pop();
      await showCreationFeeSheet(context, ref, onCreated: widget.onCreated);
      return;
    }
    if (outcome.creation != null) {
      Navigator.of(context).pop();
      widget.onCreated(outcome.creation!, outcome.reward);
      return;
    }
    setState(() => _feedback = outcome.error);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Envar envar = ref.watch(envarProvider);
    final Map<String, dynamic> pactDict =
        (envar.raw['pactDict'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final CreationDraftState draft = ref.watch(creationDraftProvider);
    final bool storyEmpty = isEmptyStory(draft.story);
    final String tucSymbol = envar.tucSymbol;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        minWidth: 320,
        maxWidth: 750,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PartCloseButton(onClose: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
              child: Column(
                children: <Widget>[
                  Text(
                    ll(lang, LangText.fromMap(envar.raw['byxCertMakerTitle'])),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  PartLinkhelp(helpLink: envar.str('linkHowToMonetizeCreation')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (pactDict['TVIEW'] != null) ...<Widget>[
                    _pactHeader(
                      (pactDict['TVIEW'] as Map).cast<String, dynamic>(),
                      'VIEW_SETNOTES',
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        _switch(
                          pactKey: 'viewerPact',
                          enabled: draft.viewerPact['type'] != 'FORBIDDEN',
                        ),
                        Expanded(
                          child: draft.viewerPact['type'] == 'FORBIDDEN'
                              ? Text(
                                  ll(lang, LangText.fromMap(
                                    ((pactDict['TVIEW'] as Map)['VIEW_FORBIDDEN']),
                                  )),
                                  style: _kSectionDesc,
                                )
                              : _numberField(
                                  pactKey: 'viewerPact',
                                  field: 'amount',
                                  unit: _kDecryptFee,
                                  symbol: tucSymbol,
                                  hint: '0: ${ll(lang, LangText.fromMap(
                                    ((pactDict['TVIEW'] as Map)['VIEW_FREE']),
                                  ))}',
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                  if (pactDict['THOLD'] != null) ...<Widget>[
                    _pactHeader(
                      (pactDict['THOLD'] as Map).cast<String, dynamic>(),
                      'HOLD_SETNOTES',
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        _switch(
                          pactKey: 'holderPact',
                          enabled: draft.holderPact['type'] != 'FORBIDDEN',
                        ),
                        Expanded(
                          child: draft.holderPact['type'] == 'FORBIDDEN'
                              ? Text(
                                  ll(lang, LangText.fromMap(
                                    ((pactDict['THOLD'] as Map)['HOLD_FORBIDDEN']),
                                  )),
                                  style: _kSectionDesc,
                                )
                              : Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _numberField(
                                        pactKey: 'holderPact',
                                        field: 'quota',
                                        unit: _kQuota,
                                        hint: '0: ${ll(lang, LangText.fromMap(
                                          ((pactDict['THOLD'] as Map)['HOLD_QUOTA_INFINITE']),
                                        ))}',
                                        forbiddenKeys: const <String>['-', '.'],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _numberField(
                                        pactKey: 'holderPact',
                                        field: 'amount',
                                        unit: _kUnitPrice,
                                        symbol: tucSymbol,
                                        hint: '0: ${ll(lang, LangText.fromMap(
                                          ((pactDict['THOLD'] as Map)['HOLD_FREE']),
                                        ))}',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                  if (pactDict['TWORK'] != null) ...<Widget>[
                    _pactHeader(
                      (pactDict['TWORK'] as Map).cast<String, dynamic>(),
                      'WORK_SETNOTES',
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        _switch(
                          pactKey: 'workerPact',
                          enabled:
                              draft.workerPact['type'].toString().isNotEmpty &&
                                  draft.workerPact['type'] != 'FORBIDDEN',
                        ),
                        Expanded(
                          child: draft.workerPact['type'].toString().isEmpty ||
                                  draft.workerPact['type'] == 'FORBIDDEN'
                              ? Text(
                                  ll(lang, LangText.fromMap(
                                    ((pactDict['TWORK'] as Map)['WORK_FORBIDDEN']),
                                  )),
                                  style: _kSectionDesc,
                                )
                              : Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _numberField(
                                        pactKey: 'workerPact',
                                        field: 'share',
                                        unit: _kShareRatio,
                                        symbol: '%',
                                        hint: ll(lang, _kSharePlaceholder),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _numberField(
                                        pactKey: 'workerPact',
                                        field: 'amount',
                                        unit: _kAgencyFee,
                                        symbol: tucSymbol,
                                        hint: '',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                  if (pactDict['TOWN'] != null) ...<Widget>[
                    _pactHeader(
                      (pactDict['TOWN'] as Map).cast<String, dynamic>(),
                      'OWN_SETNOTES',
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        _switch(
                          pactKey: 'ownerPact',
                          enabled: draft.ownerPact['type'].toString().isNotEmpty &&
                              draft.ownerPact['type'] != 'FORBIDDEN',
                        ),
                        Expanded(
                          child: draft.ownerPact['type'].toString().isEmpty ||
                                  draft.ownerPact['type'] == 'FORBIDDEN'
                              ? Text(
                                  ll(lang, LangText.fromMap(
                                    ((pactDict['TOWN'] as Map)['OWN_FORBIDDEN']),
                                  )),
                                  style: _kSectionDesc,
                                )
                              : _numberField(
                                  pactKey: 'ownerPact',
                                  field: 'amount',
                                  unit: _kTransferPrice,
                                  symbol: tucSymbol,
                                  hint: ll(lang, _kMinOne),
                                ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  ll(lang, _feedback!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFDD6161)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: PartButtonSubmit(
                loading: _creating,
                disabled: _creating || storyEmpty,
                onPressed: _create,
                children: <Widget>[
                  PexIcon.uni('fire-filled', size: 20, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(ll(lang, _kCreate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 提交（源项目 to_create_by_agent）与成功后处理
// ---------------------------------------------------------------------------

/// 提交结果：成功时 [creation] 非空，失败时 [error] 为展示在弹窗内的原因。
class CreateOutcome {
  const CreateOutcome({
    this.creation,
    this.reward,
    this.error,
    this.needTopUp = false,
  });

  final Map<String, dynamic>? creation;
  final num? reward;
  final LangText? error;

  /// 余额不足，需要先走「付费确认」流程。
  final bool needTopUp;
}

/// 提交创建/更新（源项目 `to_create_by_agent`）。
///
/// 先做契约校验与余额判定：余额不足返回 [CreateOutcome.needTopUp]，
/// 由调用方（合约弹窗）关闭自己并转「付费确认」流程。
Future<CreateOutcome> submitCreation(
  BuildContext context,
  WidgetRef ref, {
  bool ignoreBalance = false,
}) async {
  if (!await checkOnline(context, ref)) {
    return const CreateOutcome(error: PartTexts.systemDown);
  }
  if (!context.mounted) return const CreateOutcome();

  final Envar envar = ref.read(envarProvider);
  final CreationDraftState draft = ref.read(creationDraftProvider);

  // 所有权合约一旦启用，价格必须大于 0（源项目同款校验）。
  final Object? pactDict = envar.raw['pactDict'];
  final bool hasOwnerPact = pactDict is Map && pactDict['TOWN'] != null;
  if (hasOwnerPact &&
      draft.ownerPact['type'] != 'FORBIDDEN' &&
      _numOf(draft.ownerPact['amount']) <= 0) {
    return const CreateOutcome(error: _kNeedOwnerPrice);
  }

  if (!ignoreBalance) {
    final Map<String, dynamic> user = ref.read(onlineUserProvider);
    final String usid = user['usid']?.toString() ?? '';
    final num priceToSeal = _numOf(envar.raw['priceToSeal']);
    final num totalCreate = priceToSeal * draft.story.length;
    final num balance = _numOf(user['balanceTUC']);
    if (totalCreate > 0 && (usid.isEmpty || balance < totalCreate)) {
      return const CreateOutcome(needTopUp: true);
    }
  }

  return _send(context, ref);
}

/// 余额不足时的「付费确认」弹窗（源项目 `popDeposit`）。
Future<void> showCreationFeeSheet(
  BuildContext context,
  WidgetRef ref, {
  required void Function(Map<String, dynamic> creation, num? reward) onCreated,
}) {
  final Envar envar = ref.read(envarProvider);
  final CreationDraftState draft = ref.read(creationDraftProvider);
  final num totalCreate = _numOf(envar.raw['priceToSeal']) * draft.story.length;

  return showPaySheet(
    context,
    ref,
    title: _kFeeTitle,
    amountInit: totalCreate,
    submitText: _kCreate,
    onSubmit: (num amount) async {
      final CreateOutcome outcome = await submitCreation(
        context,
        ref,
        ignoreBalance: true,
      );
      if (outcome.error != null) return outcome.error;
      final Map<String, dynamic>? creation = outcome.creation;
      if (creation == null) return PartTexts.systemDown;
      onCreated(creation, outcome.reward);
      return null;
    },
  );
}

Future<CreateOutcome> _send(BuildContext context, WidgetRef ref) async {
  final CreationDraftState draft = ref.read(creationDraftProvider);
  final Envar envar = ref.read(envarProvider);
  final num priceToSeal = _numOf(envar.raw['priceToSeal']);
  final num totalSeal = priceToSeal * draft.story.length;

  final Map<String, dynamic> data =
      await ref.read(creationApiProvider).createCreation(<String, dynamic>{
    ...draft.raw,
    'totalPriceToSeal': totalSeal,
    'totalPriceToMint': 0,
    'mintNow': false,
  });
  if (!context.mounted) return const CreateOutcome();

  if (bok(data['_state']?.toString())) {
    final Map<String, dynamic> creation =
        (data['creation'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final Map<String, dynamic> userUpdated =
        (data['userUpdated'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final String usid = ref.read(onlineUserProvider)['usid']?.toString() ?? '';

    if (userUpdated.isNotEmpty && userUpdated['usid'] == usid) {
      ref.read(appStartupProvider.notifier).mergeOnlineUser(userUpdated);
    }
    // 新建的作品放进「我的选集·原创」列表头部（源项目同款）。
    if (!draft.isUpdate && creation.isNotEmpty) {
      ref.read(creationProvider.notifier).setCollection(
            CreationRole.creator,
            <Map<String, dynamic>>[
              creation,
              ...ref.read(creationProvider).collectionOf(CreationRole.creator),
            ],
          );
    }
    return CreateOutcome(
      creation: creation,
      reward: _numOrNull(data['creationReward']),
    );
  }

  // 中国区被审查拒绝：弹模态说明原因（源项目同款）。
  final String state = data['_state']?.toString() ?? '';
  final List<String> banChina = (envar.raw['banChina'] as List?)
          ?.map((dynamic e) => e.toString())
          .toList() ??
      const <String>[];
  if (ref.read(userlandCodeProvider) == 'CN' && banChina.contains(state)) {
    await showPexModal(
      context,
      ref,
      title: _kRejected,
      content: LangText.fromMap(data['rejectReason']),
      confirmText: _kGotIt,
    );
    return const CreateOutcome();
  }

  final LangText message = LangText.fromMap(data['_msg']);
  return CreateOutcome(error: message.isEmpty ? PartTexts.systemDown : message);
}

/// 创建/更新成功后的收尾：刷新草稿 → 奖励弹窗 → 跳转作品详情。
Future<void> afterCreation(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> creation,
  num? reward,
) async {
  ref.read(creationDraftProvider.notifier).reset();
  final String csid = creation['csid']?.toString() ?? '';
  if (csid.isEmpty) return;

  if (reward != null && reward > 0) {
    if (!context.mounted) return;
    final String symbol = ref.read(brandProvider).coinCode;
    await showPexModal(
      context,
      ref,
      title: LangText(
        zhCN: '您获得了 $reward $symbol！',
        enUS: 'You are rewarded $reward $symbol!',
      ),
      content: LangText(
        zhCN: '您已成功发表作品！感谢您的创作，当前空投活动期，您能够领取奖励 $reward $symbol！',
        enUS:
            'You have successfully published your creation! Thank you for your contribution. During the current airdrop event, you can claim a reward of $reward $symbol!',
      ),
      confirmText: const LangText(
        zhCN: '领取奖励',
        enUS: 'Claim Reward',
      ),
    );
  }
  if (!context.mounted) return;
  context.pushReplacement('/${AppRoutes.showCreation}?unid=$csid');
}

num _numOf(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

num? _numOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
