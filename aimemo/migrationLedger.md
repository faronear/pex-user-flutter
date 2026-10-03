# 迁移台账（migrationLedger）

> 源 `pex-user-uniapp` → 目标 `pex-user-flutter` 的逐项对照与进度。
> 状态：`[ ]` 待迁移 / `[>]` 迁移中 / `[x]` 已迁移 / `[-]` 不迁移（有理由）
> 最后更新：2026-09-29

## 一、页面（pages/，48 个 .vue，11,236 行）

### 入口 / 落地
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `homePortal.vue` | 255 | `pages/home_portal_page.dart` | `[x]` 已实现（待视觉校验） |
| `midAgidin.vue` | 82 | `pages/mid_agidin_page.dart` | `[x] 已迁移` |
| `midAizoic.vue` | 12 | — | `[-]` Agidin 旧名遗留（评估后决定） |
| `midBabely.vue` | 63 | `pages/mid_babely_page.dart` | `[x]` |
| `midTryapp.vue` | 187 | `pages/mid_tryapp_page.dart` | `[x]` 空白框架页（老板决定不做业务） |

### 身份认证（ident）
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `identBegin.vue` | 217 | `pages/ident_begin_page.dart` | `[x]` |
| `identNewRegister.vue` | 164 | `pages/ident_new_register_page.dart` | `[x]` |
| `identNewRegcode.vue` | 159 | `pages/ident_new_regcode_page.dart` | `[x]` |
| `identNewPasscode.vue` | 185 | `pages/ident_new_passcode_page.dart` | `[x]` |
| `identOldLogin.vue` | 138 | `pages/ident_old_login_page.dart` | `[x]` |
| `identOldPasscode.vue` | 170 | `pages/ident_old_passcode_page.dart` | `[x]` |
| `identOldReset.vue` | 161 | `pages/ident_old_reset_page.dart` | `[x]` |

### 账户 / 个人
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `umyAccount.vue` | 108 | `pages/umy_account_page.dart` | `[x]` |
| `umyAccountCommid.vue` | 180 | `pages/umy_account_commid_page.dart` | `[x]` 复用 `part_passcode_verify` |
| `umyAccountCommidNew.vue` | 334 | `pages/umy_account_commid_new_page.dart` | `[x]` 复用 `part_passcode_verify` + `part_land_table` |
| `umyAccountPassword.vue` | 158 | `pages/umy_account_password_page.dart` | `[x]` |
| `umyAccountTerminate.vue` | 124 | `pages/umy_account_terminate_page.dart` | `[x]`（`tTerminate` 源项目从未定义，故不显示） |
| `umyKyc.vue` | 435 | `pages/umy_kyc_page.dart` | `[x]` |
| `umyConfig.vue` | 83 | `pages/umy_config_page.dart` | `[x]` 换币**存本地**（源项目是内存态 todo） |
| `umyContact.vue` | 158 | `pages/umy_contact_page.dart` | `[x]` |

### 资金
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `umyFund.vue` | 271 | `pages/umy_fund_page.dart` | `[ ]` |
| `umyFundChannel.vue` | 58 | `pages/umy_fund_channel_page.dart` | `[ ]` |
| `umyFundChannelCreate.vue` | 592 | `pages/umy_fund_channel_create_page.dart` | `[ ]` |
| `umyFundChannelWithdraw.vue` | 236 | `pages/umy_fund_channel_withdraw_page.dart` | `[ ]` |
| `umyFundTranx.vue` | 70 | `pages/umy_fund_tranx_page.dart` | `[ ]` |

### 社交
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `umyInvite.vue` | 114 | `pages/umy_invite_page.dart` | `[x]` |
| `umyInviteList.vue` | 43 | `pages/umy_invite_list_page.dart` | `[x]` |
| `umyCircle.vue` | 73 | `pages/umy_circle_page.dart` | `[x]` |
| `umyCollection.vue` | 89 | `pages/umy_collection_page.dart` | `[x]` |
| `umyMia.vue` | 130 | `pages/umy_mia_page.dart` | `[x]` |
| `umyMiaDetail.vue` | 185 | `pages/umy_mia_detail_page.dart` | `[x]` |

### AI
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `menuAipp.vue` | 91 | `pages/menu_aipp_page.dart` | `[x] 已迁移` |
| `menuAippAichat.vue` | 42 | `pages/menu_aipp_aichat_page.dart` | `[x] 已迁移` |
| `menuAippCreate.vue` | 611 | — | `[-]` Aibot 创建不再投入（已被 agent 概念超越，Agidin 待重新构思） |
| `menuAippCreate.wrapper.vue` | 101 | — | `[-]` 同上 |
| `menuAippModify.vue` | 691 | — | `[-]` 同上 |
| `menuAippModify.wrapper.vue` | 86 | — | `[-]` 同上 |

### 创作 / NFT
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `menuCreation.vue` | 79 | `pages/menu_creation_page.dart` | `[x]`（2026-10-03 复核：补 `?tagnow=`、前往文案对齐「我的选集」、登录判断改 usid 非空） |
| `menuCreator.vue` | 79 | `pages/menu_creator_page.dart` | `[x]` |
| `menuMarket.vue` | 77 | `pages/menu_market_page.dart` | `[ ]` |
| `showCreation.vue` | 2227 | `pages/show_creation_page.dart` | `[>]` 2A 只读骨架已迁（评论/互动/付费/名单/分享举报待 2B–2F） |
| `showCreationUpdate.vue` | 76 | `pages/show_creation_update_page.dart` | `[x]` |
| `showCreator.vue` | 712 | `pages/show_creator_page.dart` | `[ ]` |
| `userResource.vue` | 133 | `pages/user_resource_page.dart` | `[x]` |
| `userResourceDetail.vue` | 208 | `pages/user_resource_detail_page.dart` | `[x]` 含二维码（新增依赖 qr_flutter） |

### 其它
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `menuUzone.vue` | 675 | `pages/menu_uzone_page.dart` | `[x]`（清单内未迁移页跳占位页） |
| `showWebview.vue` | 24 | `pages/show_webview_page.dart` | `[ ]` |
| `test/testIndex.vue` | 90 | — | `[-]` 开发测试页，迁移时评估 |

---

## 二、组件（parts/，65 个，10,750 行）

### 框架 / 布局（阶段一~二）
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partWindow.vue` | 108 | `widgets/part_window.dart` | `[x]` |
| `partWindowHeader.vue` | 268 | `widgets/part_window_header.dart` | `[x]` |
| `partWindowFooter.vue` | 132 | `widgets/part_window_footer.dart` | `[x]` |
| `partWindowLayout.vue` | 22 | `widgets/part_window_layout.dart` | `[x]` |
| `partWindowLayoutIdent.vue` | 51 | `widgets/part_window_layout_ident.dart` | `[x]` |
| `partWindowLayoutUser.vue` | 101 | — | `[x]` 拆解：布局用 `part_window_layout.dart`，未登录分支落在 `menu_uzone_page.dart` |
| `partNavibarPc.vue` | 115 | `widgets/part_navibar_pc.dart` | `[x]` |
| `partNavibarPcFixed.vue` | 77 | `widgets/part_navibar_pc_fixed.dart` | `[x]` |
| `partNavilink.vue` | 55 | `widgets/part_navilink.dart` | `[ ]` |
| `partLinkview.vue` | 41 | `widgets/part_linkview.dart` | `[ ]` |
| `partLinkhelp.vue` | 47 | `widgets/part_linkhelp.dart` | `[x]` |

### 通用 / UI
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partButtonSubmit.vue` | 76 | `widgets/part_button_submit.dart` | `[x]` |
| `partButtonPasscode.vue` | 40 | `widgets/part_button_passcode.dart` | `[x]` |
| `partCloseButton.vue` | 27 | `widgets/part_close_button.dart` | `[x]` |
| `partCountdown.vue` | 78 | `widgets/part_countdown.dart` | `[x]` |
| `partLoadMore.vue` | 171 | `widgets/part_load_more.dart` | `[x]` |
| `partEmptyList.vue` | 90 | `widgets/part_empty_list.dart` | `[x]` |
| `partShowLoading.vue` | 20 | `widgets/part_show_loading.dart` | `[x]` |
| `partTooltip.vue` | 34 | `widgets/part_tooltip.dart` | `[ ]` |
| `partPopLink.vue` | 69 | `widgets/part_pop_link.dart` | `[x]`（系统分享待阶段四） |
| `partShortcuts.vue` | 75 | `widgets/part_shortcuts.dart` | `[x]` |
| `partBreathingDot.vue` | 59 | `widgets/part_breathing_dot.dart` | `[ ]` |
| `partBreathingOpacity.vue` | 30 | `widgets/part_breathing_opacity.dart` | `[x]` |
| `partDev.vue` | 17 | `widgets/part_dev.dart` | `[ ]` |
| `partIcontextCopy.vue` | 25 | `widgets/part_icontext_copy.dart` | `[x]`（含 `PartIcontextPop`） |
| `partIcontextCopyshare.vue` | 57 | — | `[x]` 合并进 `part_icontext_copy.dart` + `part_pop_link.dart`（复制）；系统分享待阶段四 |
| `partIcontextPop.vue` | 25 | `widgets/part_icontext_copy.dart` | `[x]`（`PartIcontextPop`） |
| `partUserList.vue` | 96 | `widgets/part_user_list.dart` | `[x]`（另见 `part_user_list_sheet.dart`） |
| `partMenuCircle.vue` | 178 | `widgets/part_menu_circle.dart` | `[ ]` |
| `partMenuRing.vue` | 152 | `widgets/part_menu_ring.dart` | `[ ]` |

### 语言 / 地区 / 币种
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partLangPicker.vue` | 44 | `widgets/part_lang_picker.dart` | `[ ]` |
| `partLangSelect.vue` | 39 | `widgets/part_lang_select.dart` | `[ ]` |
| `partLangTable.vue` | 161 | `widgets/part_lang_table.dart` | `[x]` |
| `partLandTable.vue` | 127 | `widgets/part_land_table.dart` | `[x]` |
| `partCoinPicker.vue` | 55 | `widgets/part_coin_picker.dart` | `[ ]` |
| `partCoinTable.vue` | 99 | `widgets/part_coin_table.dart` | `[x]`（可排序表 + 选择弹窗） |

### 身份
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partIdentCommid.vue` | 26 | `widgets/part_ident_commid.dart` | `[x]` |
| `partComplain.vue` | 144 | `widgets/part_complain.dart` | `[x]` |

### 资金
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partDeposit.vue` | 1066 | `widgets/part_deposit.dart` | `[ ]` |
| `partFundChannelCard.vue` | 153 | `widgets/part_fund_channel_card.dart` | `[ ]` |
| `partTxList.vue` | 195 | `widgets/part_tx_list.dart` | `[ ]` |
| `partPexdataSummary.vue` | 44 | `widgets/part_pexdata_summary.dart` | `[x]` |

### AI / 媒体
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partAichat.vue` | 1504 | `widgets/part_aichat.dart` | `[>] 核心已迁移` |
| `partAippEditor.vue` | 510 | — | `[-]` 同上 |
| `partAippModels.vue` | 94 | `widgets/part_aipp_models.dart` | `[x]` |
| `partAippPicked.vue` | 151 | `widgets/part_aipp_picked.dart` | `[x]` |
| `partAippShared.vue` | 131 | `widgets/part_aipp_shared.dart` | `[x]` |
| `partStoryEditor.vue` | 763 | `widgets/part_story_editor.dart` | `[x]` |
| `partStoryReader.vue` | 208 | `widgets/part_story_reader.dart` | `[x]` |
| `partTextReader.vue` | 54 | `widgets/part_text_reader.dart` | `[x]` |
| `partTexturlReader.vue` | 28 | `widgets/part_texturl_reader.dart` | `[ ]` |
| `partSoundRecorder.vue` | 303 | `widgets/part_sound_recorder.dart` | `[ ]` 原生能力 |

### 创作
| 源 | 行数 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `partCreate.vue` | 1012 | `widgets/part_create.dart` | `[x]` AGENT 模式（自封/铸造开关产品未启用） |
| `partCreationAll.vue` | 76 | `widgets/part_creation_all.dart` | `[x]` |
| `partCreationAsCreator.vue` | 108 | `widgets/part_creation_as_list.dart`（5 个合并为参数化组件） | `[x]` |
| `partCreationAsFueler.vue` | 107 | `widgets/part_creation_as_list.dart`（5 个合并为参数化组件） | `[x]` |
| `partCreationAsHolder.vue` | 107 | `widgets/part_creation_as_list.dart`（5 个合并为参数化组件） | `[x]` |
| `partCreationAsOwner.vue` | 107 | `widgets/part_creation_as_list.dart`（5 个合并为参数化组件） | `[x]` |
| `partCreationAsViewer.vue` | 107 | `widgets/part_creation_as_list.dart`（5 个合并为参数化组件） | `[x]` |
| `partCreationCardList.vue` | 363 | `widgets/part_creation_card_list.dart` | `[x]` |
| `partCreatorAll.vue` | 72 | `widgets/part_creator_all.dart` | `[x]` |
| `partCreatorCardList.vue` | 116 | `widgets/part_creator_card_list.dart` | `[x]` |
| `partCreatorMyFollowers.vue` | 98 | `widgets/part_circle_list.dart` | `[x]` 三合一，见下 |
| `partCreatorMyFollowings.vue` | 98 | `widgets/part_circle_list.dart` | `[x]` 三合一：`CircleTag.following` |
| `partCreatorMyInvitees.vue` | 144 | `widgets/part_circle_list.dart` | `[x]` 三合一：`CircleTag.invitee` |

---

## 三、通用组件与外部资产

| 源 | 说明 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `components/dragFileUploader/` | 拖拽/文件上传 | `core/api/fileloader_api.dart` + `core/util/pex_file_picker.dart`（已实现 `Fileloader/receiveFile` 上传与 story 段写入） | `[x]` |
| `components/myp-one/` | 第三方 mypUI 组件（输入框） | 用 Flutter 原生输入替代 | `[ ]` |
| `uni_modules/` | uni-app 模块 | 视依赖逐个替代 | `[ ]` |
| `wo-user-part-uniapp/uc*` | easycom 注册的外部 uc* 组件 | 需盘点后逐个迁移 | `[ ]` |
| `static/` | 图片/图标/字体 | `assets/static/`（已整目录迁移，2.4M） | `[x]` |
| `static/icont/` | icont + uniicons 图标字体（275 图标） | `assets/static/icont/` + `lib/core/icons/`（码点映射已生成） | `[x]` |

## 四、非 UI 资产（需等价重建）

| 源 | 说明 | 目标 | 状态 |
| -- | ---- | ---- | ---- |
| `main.js` 的 `wo` | 全局对象（ss/ll/tt/bok/unisocket/pageSet） | `core/` 各 Provider + 工具类 | `[ ]` |
| `App.data.js` | Vuex store（i18n/Ident/User/Mia/AI/Creation/Creator/Tx/envar） | Riverpod Provider 分层（Ident/region/envar/startup 已迁移） | `[>]` |
| `envar-config.js` | 2417 行共享配置 | 后端 `first_touch` 下发 + `core/state/envar_provider.dart` 类型化访问 | `[x]` |
| `App.vue onLaunch` | 启动流程 | `core/state/app_startup_notifier.dart` | `[x]` |
| `App.theme.scss` / `App.style.scss` | 全局主题与样式 | `theme/`（Material3 ThemeData） | `[ ]` |
| `buildPages/manifest/appPackConfig/androidPrivacy.js` | 生成式配置与打包 | flavors + CI | `[ ]` |
