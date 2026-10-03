/// 实名认证，对应源项目 `pages/umyKyc.vue`。
///
/// 表单：姓名 / 国籍 / 证件类型 / 证件号码 + 证件正反面照片。
/// 已提交或通过（`kycStateL1` ∈ SUBMITTED / PASSED）时整表只读（源项目 `isFixed`）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/fileloader_api.dart';
import '../core/api/user_api.dart';
import '../core/i18n/i18n.dart';
import '../core/i18n/lands.dart';
import '../core/i18n/lang_text.dart';
import '../core/router/app_routes.dart';
import '../core/state/app_startup_notifier.dart';
import '../core/state/envar_provider.dart';
import '../core/state/region_provider.dart';
import '../core/util/pex_file_picker.dart';
import '../core/util/file_utils.dart';
import '../core/util/server_url.dart';
import '../theme/app_theme.dart';
import '../widgets/part_button_submit.dart';
import '../widgets/part_land_table.dart';
import '../widgets/part_navibar_pc_fixed.dart';
import '../widgets/part_texts.dart';
import '../widgets/part_window_layout.dart';

const LangText _kRealName = LangText(
  zhCN: '姓名',
  enUS: 'Real Name',
  jaJP: '氏名',
  deDE: 'Vollständiger Name',
);

const LangText _kRealNameHint = LangText(
  zhCN: '请输入您的姓名',
  enUS: 'Enter your real name',
  jaJP: 'あなたの氏名を入力してください',
  deDE: 'Geben Sie Ihren vollständigen Namen ein',
);

const LangText _kRealNameRequired = LangText(
  zhCN: '请输入姓名。',
  enUS: 'Enter your realname.',
  jaJP: '氏名を入力してください。',
  deDE: 'Geben Sie Ihren echten Namen ein.',
);

const LangText _kCitizen = LangText(
  zhCN: '国籍',
  enUS: 'Citizenship',
  jaJP: '国籍',
  deDE: 'Staatsangehörigkeit',
);

const LangText _kIdType = LangText(
  zhCN: '证件类型',
  enUS: 'ID Type',
  jaJP: '証明書の種類',
  deDE: 'Ausweistyp',
);

const LangText _kIdNumber = LangText(
  zhCN: '证件号码',
  enUS: 'ID Number',
  jaJP: '証明書番号',
  deDE: 'Ausweisnummer',
);

const LangText _kIdNumberHint = LangText(
  zhCN: '输入您的证件号码',
  enUS: 'Enter your ID number',
  jaJP: 'あなたの証明書番号を入力してください',
  deDE: 'Geben Sie Ihre Ausweisnummer ein',
);

const LangText _kIdNumberRequired = LangText(
  zhCN: '请输入证件号码。',
  enUS: 'Enter your ID number.',
  jaJP: '証明書番号を入力してください。',
  deDE: 'Geben Sie Ihre Ausweisnummer ein.',
);

const LangText _kIdCover = LangText(
  zhCN: '证件正面',
  enUS: 'ID Cover',
  jaJP: '証明書の表面',
  deDE: 'Vorderseite des Ausweises',
);

const LangText _kIdBack = LangText(
  zhCN: '证件背面',
  enUS: 'ID Back',
  jaJP: '証明書の裏面',
  deDE: 'Rückseite des Ausweises',
);

const LangText _kUploadPrompt = LangText(
  zhCN: '点击上传图片',
  enUS: 'Click to upload',
  jaJP: '写真をアップロードするにはクリックしてください',
  deDE: 'Klicken Sie hier, um ein Foto hochzuladen',
);

const LangText _kSubmit = LangText(
  zhCN: '提交',
  enUS: 'Submit',
  jaJP: '送信',
  deDE: 'Absenden',
);

/// 证件类型（源项目 `idTypeDict`）。
const Map<String, LangText> _kIdTypeDict = <String, LangText>{
  'IDCARD': LangText(
    zhCN: '身份证',
    enUS: 'ID Card',
    jaJP: '身分証明書',
    deDE: 'Personalausweis',
  ),
  'PASSPORT': LangText(
    zhCN: '护照',
    enUS: 'Passport',
    jaJP: 'パスポート',
    deDE: 'Reisepass',
  ),
  'DRIVERID': LangText(
    zhCN: '驾照',
    enUS: 'Driver License',
    jaJP: '運転免許証',
    deDE: 'Führerschein',
  ),
  'OTHER': LangText(
    zhCN: '其他',
    enUS: 'Others',
    jaJP: 'その他',
    deDE: 'Sonstiges',
  ),
};

class UmyKycPage extends ConsumerStatefulWidget {
  const UmyKycPage({super.key});

  @override
  ConsumerState<UmyKycPage> createState() => _UmyKycPageState();
}

class _UmyKycPageState extends ConsumerState<UmyKycPage> {
  late final TextEditingController _realname = TextEditingController();
  late final TextEditingController _idNumber = TextEditingController();

  // 注意：这几个字段必须在**首次 build 之前**就有值。
  // 早前写成 `late` 再在「自动登录完成后」的异步回调里赋值，
  // 一旦首次 build 早于回调就会抛 `LateInitializationError`（冒烟测出来的）。
  String _idType = 'IDCARD';
  LandItem? _land;
  String _idCardCover = '';
  String _idCardBack = '';

  bool _loading = false;
  LangText? _feedback;
  LangText? _feedbackCover;
  LangText? _feedbackBack;

  @override
  void initState() {
    super.initState();
    // 必须等自动登录（first_touch）完成后再读用户资料，否则读到的是空用户。
    Future<void>.delayed(const Duration(milliseconds: 100), () async {
      await ref.read(appStartupProvider.notifier).waitAutologin();
      if (!mounted) return;
      final Map<String, dynamic> user = ref.read(onlineUserProvider);
      setState(() {
        _realname.text = user['realname']?.toString() ?? '';
        _idNumber.text = user['idNumber']?.toString() ?? '';
        _idType = user['idType']?.toString() ?? 'IDCARD';
        _idCardCover = user['idCardCover']?.toString() ?? '';
        _idCardBack = user['idCardBack']?.toString() ?? '';
        _land = _landOf(user['citizen']?.toString() ?? '');
      });
    });
  }

  /// 源项目：`landSet[onlineUser.citizen || userlandCode] || phonelandNow`。
  LandItem _landOf(String citizen) {
    final LandItem fallback = ref.read(phoneLandProvider);
    final String code = citizen.isEmpty ? ref.read(userlandCodeProvider) : citizen;
    for (final LandItem land in kLands) {
      if (land.iso2 == code) return land;
    }
    return fallback;
  }

  /// 当前国籍（首帧还没拿到用户资料时用「电话区号国家」兜底）。
  LandItem get _landNow => _land ?? ref.read(phoneLandProvider);

  @override
  void dispose() {
    _realname.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  bool _isFixed(String state) =>
      state == 'SUBMITTED' || state == 'PASSED';

  bool get _canSubmit =>
      _realname.text.trim().isNotEmpty &&
      _idNumber.text.trim().isNotEmpty &&
      _idCardCover.isNotEmpty &&
      (_idType != 'IDCARD' || _idCardBack.isNotEmpty);

  Future<void> _pickLand() async {
    final LandItem? picked = await showModalBottomSheet<LandItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          minWidth: 320,
        ),
        child: PartLandTable(
          landCodeNow: _landNow.iso2,
          onPick: (LandItem land) => Navigator.of(context).pop(land),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _land = picked);
  }

  /// 选图 → 上传 → 记下地址（源项目 `upload_id_photo`）。
  Future<void> _uploadIdPhoto(bool isCover) async {
    final PickedMedia? picked = await pickMedia(mediaType: 'image');
    if (picked == null || !mounted) return; // 用户取消，静默

    final FileloaderApi api = ref.read(fileloaderApiProvider);
    final LangText? invalid = api.validate(
      filename: picked.filename,
      size: picked.size,
      mediaType: 'image',
    );
    if (invalid != null) {
      setState(() => isCover ? _feedbackCover = invalid : _feedbackBack = invalid);
      return;
    }
    setState(() => isCover ? _feedbackCover = null : _feedbackBack = null);
    final FileUploadResult upload =
        await api.uploadFile(filename: picked.filename, bytes: picked.bytes);
    if (!mounted) return;
    if (!upload.ok) {
      if (!upload.cancelled) {
        setState(() => isCover
            ? _feedbackCover = upload.message
            : _feedbackBack = upload.message);
      }
      return;
    }
    setState(() {
      if (isCover) {
        _idCardCover = chooseUrl(upload.fileInfo);
      } else {
        _idCardBack = chooseUrl(upload.fileInfo);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _feedback = null);
    if (_realname.text.trim().isEmpty) {
      setState(() => _feedback = _kRealNameRequired);
      return;
    }
    if (_idNumber.text.trim().isEmpty) {
      setState(() => _feedback = _kIdNumberRequired);
      return;
    }

    setState(() => _loading = true);
    final Map<String, dynamic> data = await ref.read(userApiProvider).updateKyc(
      <String, dynamic>{
        'realname': _realname.text.trim(),
        'citizen': _landNow.iso2,
        'idType': _idType,
        'idNumber': _idNumber.text.trim(),
        'idCardBack': _idCardBack,
        'idCardCover': _idCardCover,
      },
    );
    if (!mounted) return;
    setState(() => _loading = false);

    // 源项目：只有 `_state === 'SUBMITTED'` 才算成功（后端也只在这个分支发信给值班邮箱）。
    if (data['_state']?.toString() == 'SUBMITTED') {
      ref.read(appStartupProvider.notifier).mergeOnlineUser(
        <String, dynamic>{
          'kycStateL1': 'SUBMITTED',
          'realname': _realname.text.trim(),
          'citizen': _landNow.iso2,
          'idType': _idType,
          'idNumber': _idNumber.text.trim(),
          'idCardCover': _idCardCover,
          'idCardBack': _idCardBack,
        },
      );
      return;
    }
    final LangText message = LangText.fromMap(data['_msg']);
    setState(
        () => _feedback = message.isEmpty ? PartTexts.systemDown : message);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(languageProvider);
    final Map<String, dynamic> user = ref.watch(onlineUserProvider);
    final String kycState = user['kycStateL1']?.toString() ?? '';
    final bool fixed = _isFixed(kycState);

    final Map<String, dynamic> kycDict =
        ref.watch(envarProvider).raw['kycDict'] is Map
            ? (ref.watch(envarProvider).raw['kycDict'] as Map)
                .cast<String, dynamic>()
            : <String, dynamic>{};
    final LangText stateLong = LangText.fromMap(
        (kycDict[kycState.isEmpty ? 'NONE' : kycState] as Map?)?['long']);

    return PartWindowLayout(
      pageName: AppRoutes.umyKyc,
      child: Column(
        children: <Widget>[
          const PartNavibarPcFixed(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _field(
                          lang: lang,
                          label: _kRealName,
                          frozen: fixed,
                          frozenText: _realname.text,
                          child: TextField(
                            controller: _realname,
                            maxLength: 50,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: _kRealNameHint.resolve(lang),
                              counterText: '',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        _field(
                          lang: lang,
                          label: _kCitizen,
                          frozen: fixed,
                          frozenText: _landNow.nameZh,
                          child: OutlinedButton(
                            onPressed: _pickLand,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    lang == 'zhCN'
                                        ? _landNow.nameZh
                                        : _landNow.nameEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, size: 20),
                              ],
                            ),
                          ),
                        ),
                        _field(
                          lang: lang,
                          label: _kIdType,
                          frozen: fixed,
                          frozenText: (_kIdTypeDict[_idType] ?? _kIdTypeDict['IDCARD']!)
                              .resolve(lang),
                          child: DropdownButtonFormField<String>(
                            initialValue: _idType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            items: <DropdownMenuItem<String>>[
                              for (final MapEntry<String, LangText> entry
                                  in _kIdTypeDict.entries)
                                DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value.resolve(lang)),
                                ),
                            ],
                            onChanged: (String? value) =>
                                setState(() => _idType = value ?? _idType),
                          ),
                        ),
                        _field(
                          lang: lang,
                          label: _kIdNumber,
                          frozen: fixed,
                          frozenText: _idNumber.text,
                          child: TextField(
                            controller: _idNumber,
                            maxLength: 18,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(letterSpacing: 2),
                            decoration: InputDecoration(
                              hintText: _kIdNumberHint.resolve(lang),
                              counterText: '',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _PhotoBox(
                                  title: _kIdCover.resolve(lang),
                                  prompt: _kUploadPrompt.resolve(lang),
                                  url: _idCardCover,
                                  readonly: fixed,
                                  feedback: _feedbackCover,
                                  lang: lang,
                                  onTap: () => _uploadIdPhoto(true),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _PhotoBox(
                                  title: _kIdBack.resolve(lang),
                                  prompt: _kUploadPrompt.resolve(lang),
                                  url: _idCardBack,
                                  readonly: fixed,
                                  feedback: _feedbackBack,
                                  lang: lang,
                                  onTap: () => _uploadIdPhoto(false),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Text(
                            stateLong.resolve(lang),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: _stateColor(kycState),
                            ),
                          ),
                        ),
                        if (!fixed)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: PartButtonSubmit(
                              disabled: !_canSubmit,
                              loading: _loading,
                              onPressed: _submit,
                              children: <Widget>[
                                Text(_kSubmit.resolve(lang)),
                              ],
                            ),
                          ),
                        if (_feedback != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Text(
                              _feedback!.resolve(lang),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: PexColors.redMy),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 源项目按 `kycStateL1` 给状态文案上色：SUBMITTED 黄 / REJECTED 红 / PASSED 绿。
  static Color _stateColor(String state) => switch (state) {
        'SUBMITTED' => const Color(0xFFF29100),
        'REJECTED' => PexColors.redMy,
        'PASSED' => PexColors.greenMy,
        _ => PexColors.grey3,
      };

  Widget _field({
    required String lang,
    required LangText label,
    required bool frozen,
    required String frozenText,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label.resolve(lang),
              style: const TextStyle(fontSize: 14, color: PexColors.grey6),
            ),
          ),
          frozen
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    frozenText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : child,
        ],
      ),
    );
  }
}

/// 证件照片上传框（1:1），对应源项目 `dragFileUploader` 的用法（拖拽仅 PC，此处只做点击）。
class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.title,
    required this.prompt,
    required this.url,
    required this.readonly,
    required this.feedback,
    required this.lang,
    required this.onTap,
  });

  final String title;
  final String prompt;
  final String url;
  final bool readonly;
  final LangText? feedback;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: PexColors.grey6),
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: readonly ? null : onTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: readonly || url.isNotEmpty
                      ? Colors.transparent
                      : PexColors.border,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  if (url.isNotEmpty)
                    Positioned.fill(child: ServerImage(url, fit: BoxFit.contain)),
                  if (!readonly && url.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.add,
                              size: 48, color: PexColors.greyA),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(5),
                            color: PexColors.grey9,
                            child: Text(
                              prompt,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (feedback != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              feedback!.resolve(lang),
              style: const TextStyle(fontSize: 13, color: Color(0xFFDD6161)),
            ),
          ),
      ],
    );
  }
}
