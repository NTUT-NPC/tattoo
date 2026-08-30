///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsZhTw = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhTw,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-TW>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$general$zh_TW general = Translations$general$zh_TW.internal(_root);
	late final Translations$errors$zh_TW errors = Translations$errors$zh_TW.internal(_root);
	late final Translations$intro$zh_TW intro = Translations$intro$zh_TW.internal(_root);
	late final Translations$login$zh_TW login = Translations$login$zh_TW.internal(_root);
	late final Translations$nav$zh_TW nav = Translations$nav$zh_TW.internal(_root);
	late final Translations$portal$zh_TW portal = Translations$portal$zh_TW.internal(_root);
	late final Translations$home$zh_TW home = Translations$home$zh_TW.internal(_root);
	late final Translations$score$zh_TW score = Translations$score$zh_TW.internal(_root);
	late final Translations$calendar$zh_TW calendar = Translations$calendar$zh_TW.internal(_root);
	late final Translations$courseTable$zh_TW courseTable = Translations$courseTable$zh_TW.internal(_root);
	late final Translations$profile$zh_TW profile = Translations$profile$zh_TW.internal(_root);
	late final Translations$scanner$zh_TW scanner = Translations$scanner$zh_TW.internal(_root);
	late final Translations$ntutWifi$zh_TW ntutWifi = Translations$ntutWifi$zh_TW.internal(_root);
	late final Translations$kioskLogin$zh_TW kioskLogin = Translations$kioskLogin$zh_TW.internal(_root);
	late final Translations$enrollmentStatus$zh_TW enrollmentStatus = Translations$enrollmentStatus$zh_TW.internal(_root);
	late final Translations$about$zh_TW about = Translations$about$zh_TW.internal(_root);
	late final Translations$forceUpdate$zh_TW forceUpdate = Translations$forceUpdate$zh_TW.internal(_root);
	late final Translations$regedit$zh_TW regedit = Translations$regedit$zh_TW.internal(_root);
	late final Translations$changePassword$zh_TW changePassword = Translations$changePassword$zh_TW.internal(_root);
}

// Path: general
class Translations$general$zh_TW {
	Translations$general$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: 'Project Tattoo'
	String get appTitle => 'Project Tattoo';

	/// zh-TW: '尚未實作'
	String get notImplemented => '尚未實作';

	/// zh-TW: '本資料僅供參考'
	String get dataDisclaimer => '本資料僅供參考';

	/// zh-TW: '學生'
	String get student => '學生';

	/// zh-TW: '未知'
	String get unknown => '未知';

	/// zh-TW: '未登入'
	String get notLoggedIn => '未登入';

	/// zh-TW: '複製'
	String get copy => '複製';

	/// zh-TW: '已複製'
	String get copied => '已複製';

	/// zh-TW: '返回'
	String get back => '返回';

	/// zh-TW: '確定'
	String get ok => '確定';

	/// zh-TW: '取消'
	String get cancel => '取消';
}

// Path: errors
class Translations$errors$zh_TW {
	Translations$errors$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '發生錯誤'
	String get occurred => '發生錯誤';

	/// zh-TW: '發生未預期的錯誤'
	String get unexpected => '發生未預期的錯誤';

	/// zh-TW: '網路連線出現錯誤'
	String get networkError => '網路連線出現錯誤';

	/// zh-TW: '發生Flutter錯誤'
	String get flutterError => '發生Flutter錯誤';

	/// zh-TW: '發生非同步錯誤'
	String get asyncError => '發生非同步錯誤';

	/// zh-TW: '登入狀態已過期，請重新登入'
	String get sessionExpired => '登入狀態已過期，請重新登入';

	/// zh-TW: '登入憑證已失效，請重新登入'
	String get credentialsInvalid => '登入憑證已失效，請重新登入';

	/// zh-TW: '無法連線到伺服器，請檢查網路連線'
	String get connectionFailed => '無法連線到伺服器，請檢查網路連線';
}

// Path: intro
class Translations$intro$zh_TW {
	Translations$intro$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$intro$features$zh_TW features = Translations$intro$features$zh_TW.internal(_root);

	/// zh-TW: '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準'
	String get developedBy => '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準';

	/// zh-TW: '繼續'
	String get kContinue => '繼續';
}

// Path: login
class Translations$login$zh_TW {
	Translations$login$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '歡迎加入'
	String get welcomeLine1 => '歡迎加入';

	/// zh-TW: '北科生活'
	String get welcomeLine2 => '北科生活';

	/// zh-TW: '請使用${portalLink(北科校園入口網站)}的帳號密碼登入。'
	TextSpan instruction({required InlineSpanBuilder portalLink}) => TextSpan(children: [
		const TextSpan(text: '請使用'),
		portalLink('北科校園入口網站'),
		const TextSpan(text: '的帳號密碼登入。'),
	]);

	/// zh-TW: '學號'
	String get studentId => '學號';

	/// zh-TW: '密碼'
	String get password => '密碼';

	/// zh-TW: '登入'
	String get loginButton => '登入';

	/// zh-TW: '登入資訊將被安全地儲存在您的裝置中\n登入即表示您同意我們的${privacyPolicy(隱私條款)}'
	TextSpan privacyNotice({required InlineSpanBuilder privacyPolicy}) => TextSpan(children: [
		const TextSpan(text: '登入資訊將被安全地儲存在您的裝置中\n登入即表示您同意我們的'),
		privacyPolicy('隱私條款'),
	]);

	late final Translations$login$errors$zh_TW errors = Translations$login$errors$zh_TW.internal(_root);
}

// Path: nav
class Translations$nav$zh_TW {
	Translations$nav$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '首頁'
	String get home => '首頁';

	/// zh-TW: '課表'
	String get courseTable => '課表';

	/// zh-TW: '成績'
	String get scores => '成績';

	/// zh-TW: '傳送門'
	String get portal => '傳送門';

	/// zh-TW: '行事曆'
	String get calendar => '行事曆';

	/// zh-TW: '我'
	String get profile => '我';

	/// zh-TW: '投票登入'
	String get vote => '投票登入';
}

// Path: portal
class Translations$portal$zh_TW {
	Translations$portal$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '此功能仍在開發中，可能會有較大的改動。'
	String get sourceNotice => '此功能仍在開發中，可能會有較大的改動。';

	/// zh-TW: '開啟校園入口網站'
	String get openPortal => '開啟校園入口網站';

	/// zh-TW: '目前沒有可用的資訊系統'
	String get empty => '目前沒有可用的資訊系統';

	/// zh-TW: '我的最愛'
	String get favorites => '我的最愛';

	/// zh-TW: '加入最愛'
	String get addFavorite => '加入最愛';

	/// zh-TW: '取消最愛'
	String get removeFavorite => '取消最愛';
}

// Path: home
class Translations$home$zh_TW {
	Translations$home$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$home$projectTattoo$zh_TW projectTattoo = Translations$home$projectTattoo$zh_TW.internal(_root);
	late final Translations$home$ideation$zh_TW ideation = Translations$home$ideation$zh_TW.internal(_root);
	late final Translations$home$npcClub$zh_TW npcClub = Translations$home$npcClub$zh_TW.internal(_root);

	/// zh-TW: '連接校園Wi-Fi'
	String get campusWifi => '連接校園Wi-Fi';

	late final Translations$home$vote$zh_TW vote = Translations$home$vote$zh_TW.internal(_root);
}

// Path: score
class Translations$score$zh_TW {
	Translations$score$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '成績載入失敗'
	String get loadFailed => '成績載入失敗';

	/// zh-TW: '成績更新失敗'
	String get refreshFailed => '成績更新失敗';

	/// zh-TW: '目前沒有任何成績紀錄'
	String get noRecords => '目前沒有任何成績紀錄';

	/// zh-TW: '本學期尚無成績'
	String get noScoresThisSemester => '本學期尚無成績';

	/// zh-TW: '課號: ${number} 編碼: ${code}'
	String courseNumber({required Object number, required Object code}) => '課號: ${number}  編碼: ${code}';

	/// zh-TW: '無'
	String get none => '無';

	late final Translations$score$summary$zh_TW summary = Translations$score$summary$zh_TW.internal(_root);
	late final Translations$score$ranking$zh_TW ranking = Translations$score$ranking$zh_TW.internal(_root);
	late final Translations$score$status$zh_TW status = Translations$score$status$zh_TW.internal(_root);
}

// Path: calendar
class Translations$calendar$zh_TW {
	Translations$calendar$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '今天'
	String get today => '今天';
}

// Path: courseTable
class Translations$courseTable$zh_TW {
	Translations$courseTable$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '找不到課表'
	String get notFound => '找不到課表';

	/// zh-TW: '未安排時間的課程'
	String get unscheduled => '未安排時間的課程';

	late final Translations$courseTable$summary$zh_TW summary = Translations$courseTable$summary$zh_TW.internal(_root);
	late final Translations$courseTable$actions$zh_TW actions = Translations$courseTable$actions$zh_TW.internal(_root);
	Map<String, String> get dayOfWeek => {
		'sunday': '日',
		'monday': '一',
		'tuesday': '二',
		'wednesday': '三',
		'thursday': '四',
		'friday': '五',
		'saturday': '六',
	};
	Map<String, String> get dayOfWeekLong => {
		'sunday': '星期日',
		'monday': '星期一',
		'tuesday': '星期二',
		'wednesday': '星期三',
		'thursday': '星期四',
		'friday': '星期五',
		'saturday': '星期六',
	};
}

// Path: profile
class Translations$profile$zh_TW {
	Translations$profile$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '僅供參考，非正式文件'
	String get dataDisclaimer => '僅供參考，非正式文件';

	late final Translations$profile$passwordExpiry$zh_TW passwordExpiry = Translations$profile$passwordExpiry$zh_TW.internal(_root);
	late final Translations$profile$sections$zh_TW sections = Translations$profile$sections$zh_TW.internal(_root);
	late final Translations$profile$options$zh_TW options = Translations$profile$options$zh_TW.internal(_root);
	late final Translations$profile$avatar$zh_TW avatar = Translations$profile$avatar$zh_TW.internal(_root);
	late final Translations$profile$dangerZone$zh_TW dangerZone = Translations$profile$dangerZone$zh_TW.internal(_root);
}

// Path: scanner
class Translations$scanner$zh_TW {
	Translations$scanner$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '掃碼登入'
	String get title => '掃碼登入';

	/// zh-TW: '請將二維碼放入框內'
	String get scanInstruction => '請將二維碼放入框內';

	/// zh-TW: '掃碼登入i學園'
	String get loginIStudy => '掃碼登入i學園';

	/// zh-TW: '登入成功'
	String get success => '登入成功';

	/// zh-TW: '登入失敗'
	String get failed => '登入失敗';

	/// zh-TW: '正在處理…'
	String get processing => '正在處理…';

	/// zh-TW: '正在登入…'
	String get loggingIn => '正在登入…';

	/// zh-TW: '需要相機權限才能掃描QR code'
	String get permissionDenied => '需要相機權限才能掃描QR code';

	/// zh-TW: '請至設定中開啟相機權限，然後再試一次。'
	String get permissionDeniedDescription => '請至設定中開啟相機權限，然後再試一次。';

	/// zh-TW: '無法開啟相機，請檢查硬體或稍後再試。'
	String get cameraError => '無法開啟相機，請檢查硬體或稍後再試。';

	Map<String, String> get errors => {
		'201': '手機未登入',
		'202': '操作錯誤，請先至「首頁」，再點擊「校外人士登入」',
		'203': '已經是登入成功狀態',
		'204': 'QR code已失效，請重新整理頁面',
		'205': '已登入，要切換使用者必須先登出網頁',
		'206': 'QR code已過期，請在電腦上重新整理頁面',
		'unknown': '登入失敗，請確認 QR code 是否正確或從電腦頁面刷新',
	};

	/// zh-TW: '在電腦開啟i.ntut.club並點選QR code登入'
	String get howTo => '在電腦開啟i.ntut.club並點選QR code登入';

	late final Translations$scanner$guide$zh_TW guide = Translations$scanner$guide$zh_TW.internal(_root);

	/// zh-TW: '無效的網址'
	String get invalidUrl => '無效的網址';
}

// Path: ntutWifi
class Translations$ntutWifi$zh_TW {
	Translations$ntutWifi$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: 'NTUT-802.1X'
	String get title => 'NTUT-802.1X';

	/// zh-TW: '使用既有校園入口帳密自動加入NTUT-802.1X校園Wi‑Fi'
	String get entryDescription => '使用既有校園入口帳密自動加入NTUT-802.1X校園Wi‑Fi';

	/// zh-TW: '使用已登入的校園入口帳號密碼，自動加入NTUT-802.1X並讓Android後續自動嘗試連線。'
	String get intro => '使用已登入的校園入口帳號密碼，自動加入NTUT-802.1X並讓Android後續自動嘗試連線。';

	/// zh-TW: '帳號直接使用學號或員編，不要加上@ntut.edu.tw。'
	String get accountHint => '帳號直接使用學號或員編，不要加上@ntut.edu.tw。';

	/// zh-TW: 'Android API ${sdkInt}'
	String androidVersion({required Object sdkInt}) => 'Android API ${sdkInt}';

	/// zh-TW: '這個功能目前僅支援Android裝置。'
	String get unsupportedPlatform => '這個功能目前僅支援Android裝置。';

	/// zh-TW: '請先登入校園入口帳號，才能帶入NTUT-802.1X的帳號與密碼。'
	String get notLoggedIn => '請先登入校園入口帳號，才能帶入NTUT-802.1X的帳號與密碼。';

	/// zh-TW: '找不到已保存的入口網站密碼。若要複製密碼，請先重新登入TAT。'
	String get credentialsMissing => '找不到已保存的入口網站密碼。若要複製密碼，請先重新登入TAT。';

	/// zh-TW: '此助手依Android 12以上介面設計，較舊版本的欄位名稱可能略有不同。'
	String get olderAndroidWarning => '此助手依Android 12以上介面設計，較舊版本的欄位名稱可能略有不同。';

	/// zh-TW: '複製失敗'
	String get copyFailed => '複製失敗';

	/// zh-TW: '無法開啟Wi‑Fi設定'
	String get openSettingsFailed => '無法開啟Wi‑Fi設定';

	/// zh-TW: '無法開啟Wi‑Fi快捷面板'
	String get openPanelFailed => '無法開啟Wi‑Fi快捷面板';

	/// zh-TW: '自動佈署會固定使用「系統憑證 + 網域ntut.edu.tw + PEAP/GTC」。若系統不允許App安全地下發這組Enterprise設定，請改走下方手動fallback。'
	String get systemCertificatesHint => '自動佈署會固定使用「系統憑證 + 網域ntut.edu.tw + PEAP/GTC」。若系統不允許App安全地下發這組Enterprise設定，請改走下方手動fallback。';

	/// zh-TW: '這台裝置目前無法讓TAT自動加入NTUT-802.1X，請改走下方的手動設定路徑。'
	String get automaticProvisionUnavailable => '這台裝置目前無法讓TAT自動加入NTUT-802.1X，請改走下方的手動設定路徑。';

	/// zh-TW: '相容模式已儲存到系統。之後若入口帳密變更，需要再次更新這組 Wi‑Fi 設定。'
	String get compatModeSavedHint => '相容模式已儲存到系統。之後若入口帳密變更，需要再次更新這組 Wi‑Fi 設定。';

	/// zh-TW: '先前使用相容模式寫入的 NTUT-802.1X 帳密已過期，請重新更新系統 Wi‑Fi。'
	String get compatUpdateRequired => '先前使用相容模式寫入的 NTUT-802.1X 帳密已過期，請重新更新系統 Wi‑Fi。';

	/// zh-TW: 'suggestion 自動更新失敗，請改用相容模式將最新 NTUT-802.1X 設定寫入系統。'
	String get suggestionFallbackRequired => 'suggestion 自動更新失敗，請改用相容模式將最新 NTUT-802.1X 設定寫入系統。';

	/// zh-TW: 'Android 10 已拒絕這個 App 的 Wi‑Fi suggestion 權限，請依下方教學手動連線。'
	String get android10PermissionRejected => 'Android 10 已拒絕這個 App 的 Wi‑Fi suggestion 權限，請依下方教學手動連線。';

	/// zh-TW: 'Android 9 以下不支援這個自動加入流程，請依下方教學手動設定。'
	String get legacyManualOnly => 'Android 9 以下不支援這個自動加入流程，請依下方教學手動設定。';

	late final Translations$ntutWifi$sections$zh_TW sections = Translations$ntutWifi$sections$zh_TW.internal(_root);
	late final Translations$ntutWifi$actions$zh_TW actions = Translations$ntutWifi$actions$zh_TW.internal(_root);
	late final Translations$ntutWifi$fields$zh_TW fields = Translations$ntutWifi$fields$zh_TW.internal(_root);
	late final Translations$ntutWifi$fieldValues$zh_TW fieldValues = Translations$ntutWifi$fieldValues$zh_TW.internal(_root);
	late final Translations$ntutWifi$fallbackSteps$zh_TW fallbackSteps = Translations$ntutWifi$fallbackSteps$zh_TW.internal(_root);
	late final Translations$ntutWifi$provisioning$zh_TW provisioning = Translations$ntutWifi$provisioning$zh_TW.internal(_root);
	late final Translations$ntutWifi$compatPrompt$zh_TW compatPrompt = Translations$ntutWifi$compatPrompt$zh_TW.internal(_root);
}

// Path: kioskLogin
class Translations$kioskLogin$zh_TW {
	Translations$kioskLogin$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '登入QR code'
	String get qrCode => '登入QR code';

	/// zh-TW: '重新產生'
	String get refresh => '重新產生';

	/// zh-TW: '請使用投票活動會場的iPad掃描此QR Code。\n為確保您的隱私，請勿將此QR Code分享給他人。'
	String get notice => '請使用投票活動會場的iPad掃描此QR Code。\n為確保您的隱私，請勿將此QR Code分享給他人。';

	/// zh-TW: '無法產生登入QR code，請稍後再試'
	String get loadFailed => '無法產生登入QR code，請稍後再試';

	/// zh-TW: '登入網址格式不正確，無法產生登入QR code'
	String get invalidSsoUrl => '登入網址格式不正確，無法產生登入QR code';
}

// Path: enrollmentStatus
class Translations$enrollmentStatus$zh_TW {
	Translations$enrollmentStatus$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '在學'
	String get learning => '在學';

	/// zh-TW: '休學'
	String get leaveOfAbsence => '休學';

	/// zh-TW: '退學'
	String get droppedOut => '退學';

	/// zh-TW: '畢業'
	String get graduated => '畢業';
}

// Path: about
class Translations$about$zh_TW {
	Translations$about$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: 'Project Tattoo (TAT)是國立臺北科技大學(NTUT)的非官方校園生活小幫手。我們致力於透過現代化且使用者友善的介面，提供更便利的校園生活體驗。'
	String get description => 'Project Tattoo (TAT)是國立臺北科技大學(NTUT)的非官方校園生活小幫手。我們致力於透過現代化且使用者友善的介面，提供更便利的校園生活體驗。';

	/// zh-TW: '開發團隊'
	String get developers => '開發團隊';

	/// zh-TW: '幫助我們翻譯TAT!'
	String get helpTranslate => '幫助我們翻譯TAT!';

	/// zh-TW: '查看原始碼與貢獻'
	String get viewSource => '查看原始碼與貢獻';

	/// zh-TW: '相關連結'
	String get relatedLinks => '相關連結';

	/// zh-TW: '隱私權政策'
	String get privacyPolicy => '隱私權政策';

	/// zh-TW: 'https://github.com/NTUT-NPC/tattoo/blob/main/PRIVACY.zh-TW.md'
	String get privacyPolicyUrl => 'https://github.com/NTUT-NPC/tattoo/blob/main/PRIVACY.zh-TW.md';

	/// zh-TW: '查看隱私權政策'
	String get viewPrivacyPolicy => '查看隱私權政策';

	/// zh-TW: '開放原始碼授權'
	String get openSourceLicenses => '開放原始碼授權';

	/// zh-TW: 'TAT的實作歸功於開放原始碼社群'
	String get viewOpenSourceLicenses => 'TAT的實作歸功於開放原始碼社群';

	/// zh-TW: '© 2025北科程式設計研究社\n以GNU GPL v3.0授權條款釋出'
	String get copyright => '© 2025北科程式設計研究社\n以GNU GPL v3.0授權條款釋出';
}

// Path: forceUpdate
class Translations$forceUpdate$zh_TW {
	Translations$forceUpdate$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '有新版本可用'
	String get title => '有新版本可用';

	/// zh-TW: '請更新至最新版本以繼續使用TAT。'
	String get message => '請更新至最新版本以繼續使用TAT。';

	/// zh-TW: '版本 ${version}'
	String requiredVersion({required Object version}) => '版本 ${version}';

	/// zh-TW: '立即更新'
	String get updateButton => '立即更新';

	/// zh-TW: '稍後'
	String get later => '稍後';

	/// zh-TW: '查看'
	String get view => '查看';

	/// zh-TW: '此為強制更新。'
	String get isForced => '此為強制更新。';
}

// Path: regedit
class Translations$regedit$zh_TW {
	Translations$regedit$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '登錄編輯程式'
	String get title => '登錄編輯程式';

	/// zh-TW: '從遠端獲取'
	String get fetch => '從遠端獲取';

	/// zh-TW: '沒有登錄項目'
	String get noRegistry => '沒有登錄項目';

	/// zh-TW: '登錄檔已更新'
	String get refreshed => '登錄檔已更新';

	/// zh-TW: '重設為預設值'
	String get reset => '重設為預設值';

	late final Translations$regedit$status$zh_TW status = Translations$regedit$status$zh_TW.internal(_root);

	/// zh-TW: '輸入格式錯誤'
	String get invalidInput => '輸入格式錯誤';
}

// Path: changePassword
class Translations$changePassword$zh_TW {
	Translations$changePassword$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '變更密碼'
	String get title => '變更密碼';

	/// zh-TW: '變更過期密碼'
	String get titleExpired => '變更過期密碼';

	/// zh-TW: '您的密碼已過期，請設定新密碼以繼續使用。'
	String get expiredNotice => '您的密碼已過期，請設定新密碼以繼續使用。';

	/// zh-TW: '目前密碼'
	String get currentPassword => '目前密碼';

	/// zh-TW: '新密碼'
	String get newPassword => '新密碼';

	/// zh-TW: '確認新密碼'
	String get confirmPassword => '確認新密碼';

	/// zh-TW: '變更密碼'
	String get submit => '變更密碼';

	/// zh-TW: '密碼變更成功'
	String get success => '密碼變更成功';

	late final Translations$changePassword$errors$zh_TW errors = Translations$changePassword$errors$zh_TW.internal(_root);
}

// Path: intro.features
class Translations$intro$features$zh_TW {
	Translations$intro$features$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$intro$features$courseTable$zh_TW courseTable = Translations$intro$features$courseTable$zh_TW.internal(_root);
	late final Translations$intro$features$scores$zh_TW scores = Translations$intro$features$scores$zh_TW.internal(_root);
	late final Translations$intro$features$campusLife$zh_TW campusLife = Translations$intro$features$campusLife$zh_TW.internal(_root);
}

// Path: login.errors
class Translations$login$errors$zh_TW {
	Translations$login$errors$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '請填寫學號與密碼'
	String get emptyFields => '請填寫學號與密碼';

	/// zh-TW: '請直接使用學號登入，不要使用電子郵件'
	String get useStudentId => '請直接使用學號登入，不要使用電子郵件';

	/// zh-TW: '登入失敗，請確認帳號密碼'
	String get loginFailed => '登入失敗，請確認帳號密碼';

	/// zh-TW: '學號或密碼錯誤'
	String get wrongCredentials => '學號或密碼錯誤';

	/// zh-TW: '登入失敗次數過多，帳號已被鎖定，請稍後再試'
	String get accountLocked => '登入失敗次數過多，帳號已被鎖定，請稍後再試';

	/// zh-TW: '密碼已過期，請至校園入口網站變更密碼'
	String get passwordExpired => '密碼已過期，請至校園入口網站變更密碼';

	/// zh-TW: '需要進行手機驗證，請至校園入口網站完成驗證'
	String get mobileVerificationRequired => '需要進行手機驗證，請至校園入口網站完成驗證';
}

// Path: home.projectTattoo
class Translations$home$projectTattoo$zh_TW {
	Translations$home$projectTattoo$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '關於Project Tattoo'
	String get title => '關於Project Tattoo';

	/// zh-TW: '查看更多資訊或邀請你的朋友加入測試計畫。'
	String get description => '查看更多資訊或邀請你的朋友加入測試計畫。';

	/// zh-TW: 'https://ntut.app'
	String get url => 'https://ntut.app';
}

// Path: home.ideation
class Translations$home$ideation$zh_TW {
	Translations$home$ideation$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '屬於我們的TAT正在打造中'
	String get title => '屬於我們的TAT正在打造中';

	/// zh-TW: '我們正在募集關於「首頁」的想法，歡迎把你的提案分享給我們！'
	String get description => '我們正在募集關於「首頁」的想法，歡迎把你的提案分享給我們！';

	/// zh-TW: 'https://forms.gle/LdQdMfvAfUYyGE4k8'
	String get url => 'https://forms.gle/LdQdMfvAfUYyGE4k8';
}

// Path: home.npcClub
class Translations$home$npcClub$zh_TW {
	Translations$home$npcClub$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '北科程式設計研究社'
	String get title => '北科程式設計研究社';

	/// zh-TW: '有任何想法或是想加入開發，隨時歡迎聯絡我們！'
	String get description => '有任何想法或是想加入開發，隨時歡迎聯絡我們！';

	/// zh-TW: 'https://ntut.club'
	String get url => 'https://ntut.club';
}

// Path: home.vote
class Translations$home$vote$zh_TW {
	Translations$home$vote$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '學生四合一民主選舉活動，5/15下午四點前來一大川堂投票吧！'
	String get description => '學生四合一民主選舉活動，5/15下午四點前來一大川堂投票吧！';
}

// Path: score.summary
class Translations$score$summary$zh_TW {
	Translations$score$summary$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '歷年GPA'
	String get cumulativeGpa => '歷年GPA';

	/// zh-TW: '操行成績'
	String get conduct => '操行成績';

	/// zh-TW: '學期平均'
	String get semesterAverage => '學期平均';

	/// zh-TW: '實得學分'
	String get creditsPassed => '實得學分';

	/// zh-TW: '修課總學分'
	String get totalCredits => '修課總學分';
}

// Path: score.ranking
class Translations$score$ranking$zh_TW {
	Translations$score$ranking$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '排名資訊'
	String get title => '排名資訊';

	late final Translations$score$ranking$type$zh_TW type = Translations$score$ranking$type$zh_TW.internal(_root);

	/// zh-TW: '學期'
	String get semester => '學期';

	/// zh-TW: '歷年'
	String get cumulative => '歷年';

	/// zh-TW: '${rank} / ${total} (${percentage}%)'
	String rankAndTotal({required Object rank, required Object total, required Object percentage}) => '${rank} / ${total} (${percentage}%)';

	/// zh-TW: '尚無排名'
	String get empty => '尚無排名';
}

// Path: score.status
class Translations$score$status$zh_TW {
	Translations$score$status$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '未輸入'
	String get notEntered => '未輸入';

	/// zh-TW: '撤選'
	String get withdraw => '撤選';

	/// zh-TW: '未送成績'
	String get undelivered => '未送成績';

	/// zh-TW: '通過'
	String get pass => '通過';

	/// zh-TW: '不通過'
	String get fail => '不通過';

	/// zh-TW: '抵免'
	String get creditTransfer => '抵免';
}

// Path: courseTable.summary
class Translations$courseTable$summary$zh_TW {
	Translations$courseTable$summary$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '(one) {${count}學分} (other) {${count}學分}'
	String credits({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count,
		one: '${count}學分',
		other: '${count}學分',
	);

	/// zh-TW: '(one) {${count}小時} (other) {${count}小時}'
	String hours({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count,
		one: '${count}小時',
		other: '${count}小時',
	);
}

// Path: courseTable.actions
class Translations$courseTable$actions$zh_TW {
	Translations$courseTable$actions$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '顯示更多選項'
	String get showMoreOptions => '顯示更多選項';

	/// zh-TW: '顯示選項'
	String get displayOptions => '顯示選項';

	/// zh-TW: '切換至週檢視'
	String get showWeeklyView => '切換至週檢視';

	/// zh-TW: '切換至網格檢視'
	String get showGridView => '切換至網格檢視';
}

// Path: profile.passwordExpiry
class Translations$profile$passwordExpiry$zh_TW {
	Translations$profile$passwordExpiry$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '(one) {密碼將在1天後過期} (other) {密碼將在${days}天後過期}'
	String warning({required num days}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(days,
		one: '密碼將在1天後過期',
		other: '密碼將在${days}天後過期',
	);

	/// zh-TW: '更改'
	String get action => '更改';
}

// Path: profile.sections
class Translations$profile$sections$zh_TW {
	Translations$profile$sections$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '帳號設定'
	String get accountSettings => '帳號設定';

	/// zh-TW: '應用程式設定'
	String get appSettings => '應用程式設定';

	/// zh-TW: '危險區域'
	String get dangerZone => '危險區域';
}

// Path: profile.options
class Translations$profile$options$zh_TW {
	Translations$profile$options$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '連接NTUT-802.1X'
	String get ntutWifi => '連接NTUT-802.1X';

	/// zh-TW: '更改密碼'
	String get changePassword => '更改密碼';

	/// zh-TW: '更改個人圖片'
	String get changeAvatar => '更改個人圖片';

	/// zh-TW: '支持我們'
	String get supportUs => '支持我們';

	/// zh-TW: '關於TAT'
	String get about => '關於TAT';

	/// zh-TW: '北科程式設計研究社'
	String get npcClub => '北科程式設計研究社';

	/// zh-TW: '偏好設定'
	String get preferences => '偏好設定';

	/// zh-TW: '登出帳號'
	String get logout => '登出帳號';
}

// Path: profile.avatar
class Translations$profile$avatar$zh_TW {
	Translations$profile$avatar$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '正在更新個人圖片…'
	String get uploading => '正在更新個人圖片…';

	/// zh-TW: '個人圖片已更新'
	String get uploadSuccess => '個人圖片已更新';

	/// zh-TW: '圖片大小超過20 MB限制'
	String get tooLarge => '圖片大小超過20 MB限制';

	/// zh-TW: '無法辨識的圖片格式'
	String get invalidFormat => '無法辨識的圖片格式';

	/// zh-TW: '更改個人圖片失敗，請稍後再試'
	String get uploadFailed => '更改個人圖片失敗，請稍後再試';
}

// Path: profile.dangerZone
class Translations$profile$dangerZone$zh_TW {
	Translations$profile$dangerZone$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '非Flutter框架崩潰'
	String get nonFlutterCrash => '非Flutter框架崩潰';

	/// zh-TW: '模擬非同步錯誤'
	String get nonFlutterCrashException => '模擬非同步錯誤';

	/// zh-TW: '酒吧暫未營業'
	String get closedTitle => '酒吧暫未營業';

	/// zh-TW: '酒吧今天打烊了，改天再來探索吧！'
	String get closedMessage => '酒吧今天打烊了，改天再來探索吧！';

	/// zh-TW: '你被店員勸退，還是早點回家休息吧～'
	String get kickedMessage => '你被店員勸退，還是早點回家休息吧～';

	/// zh-TW: '酒吧陷入火海'
	String get fireMessage => '酒吧陷入火海';

	/// zh-TW: '酒吧開門了'
	String get barOpen => '酒吧開門了';

	/// zh-TW: '酒吧倒閉了'
	String get barClosed => '酒吧倒閉了';

	/// zh-TW: '去酒吧${action}'
	String goAction({required Object action}) => '去酒吧${action}';

	List<String> get actions => [
		'點0杯啤酒',
		'點999999999杯啤酒',
		'點1支蜥蜴',
		'點-1杯啤酒',
		'點1份asdfghjkl',
		'點1碗炒飯',
		'跑進吧檯被店員拖出去',
	];

	/// zh-TW: '清除快取'
	String get clearCache => '清除快取';

	/// zh-TW: '清除Cookies'
	String get clearCookies => '清除Cookies';

	/// zh-TW: '清除偏好設定'
	String get clearPreferences => '清除偏好設定';

	/// zh-TW: '清除登入憑證'
	String get clearCredentials => '清除登入憑證';

	/// zh-TW: '清除使用者資料'
	String get clearUserData => '清除使用者資料';

	/// zh-TW: '已清除${item}'
	String cleared({required Object item}) => '已清除${item}';

	/// zh-TW: '清除${item}失敗'
	String clearFailed({required Object item}) => '清除${item}失敗';

	late final Translations$profile$dangerZone$items$zh_TW items = Translations$profile$dangerZone$items$zh_TW.internal(_root);
}

// Path: scanner.guide
class Translations$scanner$guide$zh_TW {
	Translations$scanner$guide$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '如何掃碼登入？'
	String get title => '如何掃碼登入？';

	/// zh-TW: '1. 電腦前往下列網址：'
	String get step1 => '1. 電腦前往下列網址：';

	/// zh-TW: 'https://i.ntut.club'
	String get url => 'https://i.ntut.club';

	/// zh-TW: '2. 點擊導覽列的「外校人士登入」'
	String get step2 => '2. 點擊導覽列的「外校人士登入」';

	/// zh-TW: '3. 點擊「QR Code 登入」'
	String get step3 => '3. 點擊「QR Code 登入」';

	/// zh-TW: '我知道了'
	String get button => '我知道了';
}

// Path: ntutWifi.sections
class Translations$ntutWifi$sections$zh_TW {
	Translations$ntutWifi$sections$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '快速操作'
	String get quickActions => '快速操作';

	/// zh-TW: '建議設定'
	String get recommendedSettings => '建議設定';

	/// zh-TW: '手動Fallback'
	String get fallback => '手動Fallback';
}

// Path: ntutWifi.actions
class Translations$ntutWifi$actions$zh_TW {
	Translations$ntutWifi$actions$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '自動加入NTUT-802.1X'
	String get autoProvision => '自動加入NTUT-802.1X';

	/// zh-TW: '正在加入NTUT-802.1X…'
	String get autoProvisioning => '正在加入NTUT-802.1X…';

	/// zh-TW: '使用相容模式重試'
	String get retryCompatProvision => '使用相容模式重試';

	/// zh-TW: '使用相容模式更新'
	String get updateCompatProvision => '使用相容模式更新';

	/// zh-TW: '開啟Wi‑Fi設定'
	String get openWifiSettings => '開啟Wi‑Fi設定';

	/// zh-TW: '開啟Wi‑Fi快捷面板'
	String get openWifiPanel => '開啟Wi‑Fi快捷面板';
}

// Path: ntutWifi.fields
class Translations$ntutWifi$fields$zh_TW {
	Translations$ntutWifi$fields$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '網路名稱'
	String get ssid => '網路名稱';

	/// zh-TW: 'EAP方法'
	String get eapMethod => 'EAP方法';

	/// zh-TW: '第二階段驗證'
	String get phase2Auth => '第二階段驗證';

	/// zh-TW: '身分'
	String get identity => '身分';

	/// zh-TW: '密碼'
	String get password => '密碼';

	/// zh-TW: 'CA憑證'
	String get caCertificate => 'CA憑證';

	/// zh-TW: '網域'
	String get domain => '網域';
}

// Path: ntutWifi.fieldValues
class Translations$ntutWifi$fieldValues$zh_TW {
	Translations$ntutWifi$fieldValues$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '已儲存在裝置，可直接複製'
	String get passwordSaved => '已儲存在裝置，可直接複製';

	/// zh-TW: '需要重新登入才能複製密碼'
	String get passwordUnavailable => '需要重新登入才能複製密碼';

	/// zh-TW: '使用系統憑證'
	String get systemCertificates => '使用系統憑證';
}

// Path: ntutWifi.fallbackSteps
class Translations$ntutWifi$fallbackSteps$zh_TW {
	Translations$ntutWifi$fallbackSteps$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '1. 開啟Wi‑Fi設定或快捷面板。'
	String get openSettings => '1. 開啟Wi‑Fi設定或快捷面板。';

	/// zh-TW: '2. 選擇或新增NTUT-802.1X。'
	String get selectNetwork => '2. 選擇或新增NTUT-802.1X。';

	/// zh-TW: '3. 將下方顯示的SSID、PEAP、GTC、帳號、密碼與網域填入。'
	String get useDisplayedValues => '3. 將下方顯示的SSID、PEAP、GTC、帳號、密碼與網域填入。';
}

// Path: ntutWifi.provisioning
class Translations$ntutWifi$provisioning$zh_TW {
	Translations$ntutWifi$provisioning$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '已將NTUT-802.1X加入Android。只要Wi‑Fi開啟且在校園網路範圍內，系統就會自動嘗試連線。'
	String get success => '已將NTUT-802.1X加入Android。只要Wi‑Fi開啟且在校園網路範圍內，系統就會自動嘗試連線。';

	/// zh-TW: '已將NTUT-802.1X加入Android，但目前Wi‑Fi尚未開啟。開啟Wi‑Fi後，系統才會自動嘗試連線。'
	String get successPendingWifi => '已將NTUT-802.1X加入Android，但目前Wi‑Fi尚未開啟。開啟Wi‑Fi後，系統才會自動嘗試連線。';

	/// zh-TW: '系統目前不允許TAT直接送出Wi‑Fi建議，請改用下方設定入口完成系統層操作後再試。'
	String get approvalPending => '系統目前不允許TAT直接送出Wi‑Fi建議，請改用下方設定入口完成系統層操作後再試。';

	/// zh-TW: '系統已拒絕TAT的Wi‑Fi建議，請到系統設定允許後再試，或直接走下方手動設定。'
	String get approvalRejected => '系統已拒絕TAT的Wi‑Fi建議，請到系統設定允許後再試，或直接走下方手動設定。';

	/// zh-TW: '這台裝置無法讓TAT安全地下發「系統憑證 + 網域」Enterprise設定，請改用下方手動設定。'
	String get validationUnavailable => '這台裝置無法讓TAT安全地下發「系統憑證 + 網域」Enterprise設定，請改用下方手動設定。';

	/// zh-TW: '這台裝置目前不支援自動加入NTUT-802.1X。'
	String get unsupportedPlatform => '這台裝置目前不支援自動加入NTUT-802.1X。';

	/// zh-TW: '自動加入NTUT-802.1X失敗，請改用下方手動設定。'
	String get failed => '自動加入NTUT-802.1X失敗，請改用下方手動設定。';

	/// zh-TW: '已透過相容模式將 NTUT-802.1X 寫入系統 Wi‑Fi。'
	String get compatSuccess => '已透過相容模式將 NTUT-802.1X 寫入系統 Wi‑Fi。';

	/// zh-TW: 'suggestion 被拒，已改用相容模式將 NTUT-802.1X 寫入系統 Wi‑Fi。'
	String get compatFallbackSuccess => 'suggestion 被拒，已改用相容模式將 NTUT-802.1X 寫入系統 Wi‑Fi。';

	/// zh-TW: 'Android 回報系統內已存在 NTUT-802.1X 設定，但儲存的密碼可能仍是舊的。請先確認系統 Wi‑Fi 項目，或刪除後再重新使用相容模式。'
	String get compatAlreadyExists => 'Android 回報系統內已存在 NTUT-802.1X 設定，但儲存的密碼可能仍是舊的。請先確認系統 Wi‑Fi 項目，或刪除後再重新使用相容模式。';

	/// zh-TW: '已取消相容模式更新，稍後可在此頁重新嘗試。'
	String get compatCancelled => '已取消相容模式更新，稍後可在此頁重新嘗試。';

	/// zh-TW: '相容模式更新失敗，請改依下方教學手動連線。'
	String get compatFailed => '相容模式更新失敗，請改依下方教學手動連線。';
}

// Path: ntutWifi.compatPrompt
class Translations$ntutWifi$compatPrompt$zh_TW {
	Translations$ntutWifi$compatPrompt$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '更新 NTUT-802.1X'
	String get title => '更新 NTUT-802.1X';

	/// zh-TW: '立即更新'
	String get updateNow => '立即更新';

	/// zh-TW: '稍後'
	String get later => '稍後';

	/// zh-TW: '你先前使用相容模式儲存了 NTUT-802.1X。現在入口帳密已變更，需要重新更新系統 Wi‑Fi。'
	String get credentialChanged => '你先前使用相容模式儲存了 NTUT-802.1X。現在入口帳密已變更，需要重新更新系統 Wi‑Fi。';

	/// zh-TW: '系統無法自動更新 NTUT-802.1X，是否現在改用相容模式完成更新？'
	String get suggestionFallbackRequired => '系統無法自動更新 NTUT-802.1X，是否現在改用相容模式完成更新？';
}

// Path: regedit.status
class Translations$regedit$status$zh_TW {
	Translations$regedit$status$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '預設值'
	String get local => '預設值';

	/// zh-TW: '雲端設定'
	String get remote => '雲端設定';

	/// zh-TW: '使用者覆寫'
	String get localOverride => '使用者覆寫';

	/// zh-TW: '強制覆寫（遠端）'
	String get remoteOverride => '強制覆寫（遠端）';
}

// Path: changePassword.errors
class Translations$changePassword$errors$zh_TW {
	Translations$changePassword$errors$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '請填寫所有欄位'
	String get emptyFields => '請填寫所有欄位';

	/// zh-TW: '兩次輸入的密碼不一致'
	String get mismatch => '兩次輸入的密碼不一致';

	/// zh-TW: '變更密碼失敗：${error}'
	String failed({required Object error}) => '變更密碼失敗：${error}';

	/// zh-TW: '密碼長度須介於8至14個字元之間'
	String get invalidLength => '密碼長度須介於8至14個字元之間';

	/// zh-TW: '密碼須包含英文大小寫字母、數字及符號'
	String get invalidComplexity => '密碼須包含英文大小寫字母、數字及符號';

	/// zh-TW: '密碼不可與學號相同'
	String get sameAsUsername => '密碼不可與學號相同';

	late final Translations$changePassword$errors$server$zh_TW server = Translations$changePassword$errors$server$zh_TW.internal(_root);
}

// Path: intro.features.courseTable
class Translations$intro$features$courseTable$zh_TW {
	Translations$intro$features$courseTable$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '查課表'
	String get title => '查課表';

	/// zh-TW: '快速查看課表和課程資訊，並可快速切換學期。'
	String get description => '快速查看課表和課程資訊，並可快速切換學期。';
}

// Path: intro.features.scores
class Translations$intro$features$scores$zh_TW {
	Translations$intro$features$scores$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '看成績'
	String get title => '看成績';

	/// zh-TW: '即時查詢各科成績與學分，整合歷年成績紀錄。'
	String get description => '即時查詢各科成績與學分，整合歷年成績紀錄。';
}

// Path: intro.features.campusLife
class Translations$intro$features$campusLife$zh_TW {
	Translations$intro$features$campusLife$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '北科生活'
	String get title => '北科生活';

	/// zh-TW: '彙整其他校園生活資訊，更多功能敬請期待。'
	String get description => '彙整其他校園生活資訊，更多功能敬請期待。';
}

// Path: score.ranking.type
class Translations$score$ranking$type$zh_TW {
	Translations$score$ranking$type$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '班級'
	String get classLevel => '班級';

	/// zh-TW: '分組'
	String get groupLevel => '分組';

	/// zh-TW: '系所'
	String get departmentLevel => '系所';
}

// Path: profile.dangerZone.items
class Translations$profile$dangerZone$items$zh_TW {
	Translations$profile$dangerZone$items$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '快取'
	String get cache => '快取';

	/// zh-TW: 'Cookies'
	String get cookies => 'Cookies';

	/// zh-TW: '偏好設定'
	String get preferences => '偏好設定';

	/// zh-TW: '登入憑證'
	String get credentials => '登入憑證';

	/// zh-TW: '使用者資料'
	String get userData => '使用者資料';
}

// Path: changePassword.errors.server
class Translations$changePassword$errors$server$zh_TW {
	Translations$changePassword$errors$server$zh_TW.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '目前密碼錯誤'
	String get authFailed => '目前密碼錯誤';

	/// zh-TW: '密碼於1天內不得再修改'
	String get minAge => '密碼於1天內不得再修改';

	/// zh-TW: '密碼不可與前3組重複'
	String get historyRepeat => '密碼不可與前3組重複';

	/// zh-TW: '密碼不可與學號相同'
	String get sameAsUsername => '密碼不可與學號相同';

	/// zh-TW: '密碼長度須介於8至14個字元之間'
	String get length => '密碼長度須介於8至14個字元之間';

	/// zh-TW: '密碼須包含英文大小寫字母、數字及符號'
	String get complexity => '密碼須包含英文大小寫字母、數字及符號';
}

/// The flat map containing all translations for locale <zh-TW>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'general.appTitle' => 'Project Tattoo',
			'general.notImplemented' => '尚未實作',
			'general.dataDisclaimer' => '本資料僅供參考',
			'general.student' => '學生',
			'general.unknown' => '未知',
			'general.notLoggedIn' => '未登入',
			'general.copy' => '複製',
			'general.copied' => '已複製',
			'general.back' => '返回',
			'general.ok' => '確定',
			'general.cancel' => '取消',
			'errors.occurred' => '發生錯誤',
			'errors.unexpected' => '發生未預期的錯誤',
			'errors.networkError' => '網路連線出現錯誤',
			'errors.flutterError' => '發生Flutter錯誤',
			'errors.asyncError' => '發生非同步錯誤',
			'errors.sessionExpired' => '登入狀態已過期，請重新登入',
			'errors.credentialsInvalid' => '登入憑證已失效，請重新登入',
			'errors.connectionFailed' => '無法連線到伺服器，請檢查網路連線',
			'intro.features.courseTable.title' => '查課表',
			'intro.features.courseTable.description' => '快速查看課表和課程資訊，並可快速切換學期。',
			'intro.features.scores.title' => '看成績',
			'intro.features.scores.description' => '即時查詢各科成績與學分，整合歷年成績紀錄。',
			'intro.features.campusLife.title' => '北科生活',
			'intro.features.campusLife.description' => '彙整其他校園生活資訊，更多功能敬請期待。',
			'intro.developedBy' => '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準',
			'intro.kContinue' => '繼續',
			'login.welcomeLine1' => '歡迎加入',
			'login.welcomeLine2' => '北科生活',
			'login.instruction' => ({required InlineSpanBuilder portalLink}) => TextSpan(children: [ const TextSpan(text: '請使用'), portalLink('北科校園入口網站'), const TextSpan(text: '的帳號密碼登入。'), ]), 
			'login.studentId' => '學號',
			'login.password' => '密碼',
			'login.loginButton' => '登入',
			'login.privacyNotice' => ({required InlineSpanBuilder privacyPolicy}) => TextSpan(children: [ const TextSpan(text: '登入資訊將被安全地儲存在您的裝置中\n登入即表示您同意我們的'), privacyPolicy('隱私條款'), ]), 
			'login.errors.emptyFields' => '請填寫學號與密碼',
			'login.errors.useStudentId' => '請直接使用學號登入，不要使用電子郵件',
			'login.errors.loginFailed' => '登入失敗，請確認帳號密碼',
			'login.errors.wrongCredentials' => '學號或密碼錯誤',
			'login.errors.accountLocked' => '登入失敗次數過多，帳號已被鎖定，請稍後再試',
			'login.errors.passwordExpired' => '密碼已過期，請至校園入口網站變更密碼',
			'login.errors.mobileVerificationRequired' => '需要進行手機驗證，請至校園入口網站完成驗證',
			'nav.home' => '首頁',
			'nav.courseTable' => '課表',
			'nav.scores' => '成績',
			'nav.portal' => '傳送門',
			'nav.calendar' => '行事曆',
			'nav.profile' => '我',
			'nav.vote' => '投票登入',
			'portal.sourceNotice' => '此功能仍在開發中，可能會有較大的改動。',
			'portal.openPortal' => '開啟校園入口網站',
			'portal.empty' => '目前沒有可用的資訊系統',
			'portal.favorites' => '我的最愛',
			'portal.addFavorite' => '加入最愛',
			'portal.removeFavorite' => '取消最愛',
			'home.projectTattoo.title' => '關於Project Tattoo',
			'home.projectTattoo.description' => '查看更多資訊或邀請你的朋友加入測試計畫。',
			'home.projectTattoo.url' => 'https://ntut.app',
			'home.ideation.title' => '屬於我們的TAT正在打造中',
			'home.ideation.description' => '我們正在募集關於「首頁」的想法，歡迎把你的提案分享給我們！',
			'home.ideation.url' => 'https://forms.gle/LdQdMfvAfUYyGE4k8',
			'home.npcClub.title' => '北科程式設計研究社',
			'home.npcClub.description' => '有任何想法或是想加入開發，隨時歡迎聯絡我們！',
			'home.npcClub.url' => 'https://ntut.club',
			'home.campusWifi' => '連接校園Wi-Fi',
			'home.vote.description' => '學生四合一民主選舉活動，5/15下午四點前來一大川堂投票吧！',
			'score.loadFailed' => '成績載入失敗',
			'score.refreshFailed' => '成績更新失敗',
			'score.noRecords' => '目前沒有任何成績紀錄',
			'score.noScoresThisSemester' => '本學期尚無成績',
			'score.courseNumber' => ({required Object number, required Object code}) => '課號: ${number}  編碼: ${code}',
			'score.none' => '無',
			'score.summary.cumulativeGpa' => '歷年GPA',
			'score.summary.conduct' => '操行成績',
			'score.summary.semesterAverage' => '學期平均',
			'score.summary.creditsPassed' => '實得學分',
			'score.summary.totalCredits' => '修課總學分',
			'score.ranking.title' => '排名資訊',
			'score.ranking.type.classLevel' => '班級',
			'score.ranking.type.groupLevel' => '分組',
			'score.ranking.type.departmentLevel' => '系所',
			'score.ranking.semester' => '學期',
			'score.ranking.cumulative' => '歷年',
			'score.ranking.rankAndTotal' => ({required Object rank, required Object total, required Object percentage}) => '${rank} / ${total} (${percentage}%)',
			'score.ranking.empty' => '尚無排名',
			'score.status.notEntered' => '未輸入',
			'score.status.withdraw' => '撤選',
			'score.status.undelivered' => '未送成績',
			'score.status.pass' => '通過',
			'score.status.fail' => '不通過',
			'score.status.creditTransfer' => '抵免',
			'calendar.today' => '今天',
			'courseTable.notFound' => '找不到課表',
			'courseTable.unscheduled' => '未安排時間的課程',
			'courseTable.summary.credits' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count, one: '${count}學分', other: '${count}學分', ), 
			'courseTable.summary.hours' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(count, one: '${count}小時', other: '${count}小時', ), 
			'courseTable.actions.showMoreOptions' => '顯示更多選項',
			'courseTable.actions.displayOptions' => '顯示選項',
			'courseTable.actions.showWeeklyView' => '切換至週檢視',
			'courseTable.actions.showGridView' => '切換至網格檢視',
			'courseTable.dayOfWeek.sunday' => '日',
			'courseTable.dayOfWeek.monday' => '一',
			'courseTable.dayOfWeek.tuesday' => '二',
			'courseTable.dayOfWeek.wednesday' => '三',
			'courseTable.dayOfWeek.thursday' => '四',
			'courseTable.dayOfWeek.friday' => '五',
			'courseTable.dayOfWeek.saturday' => '六',
			'courseTable.dayOfWeekLong.sunday' => '星期日',
			'courseTable.dayOfWeekLong.monday' => '星期一',
			'courseTable.dayOfWeekLong.tuesday' => '星期二',
			'courseTable.dayOfWeekLong.wednesday' => '星期三',
			'courseTable.dayOfWeekLong.thursday' => '星期四',
			'courseTable.dayOfWeekLong.friday' => '星期五',
			'courseTable.dayOfWeekLong.saturday' => '星期六',
			'profile.dataDisclaimer' => '僅供參考，非正式文件',
			'profile.passwordExpiry.warning' => ({required num days}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(days, one: '密碼將在1天後過期', other: '密碼將在${days}天後過期', ), 
			'profile.passwordExpiry.action' => '更改',
			'profile.sections.accountSettings' => '帳號設定',
			'profile.sections.appSettings' => '應用程式設定',
			'profile.sections.dangerZone' => '危險區域',
			'profile.options.ntutWifi' => '連接NTUT-802.1X',
			'profile.options.changePassword' => '更改密碼',
			'profile.options.changeAvatar' => '更改個人圖片',
			'profile.options.supportUs' => '支持我們',
			'profile.options.about' => '關於TAT',
			'profile.options.npcClub' => '北科程式設計研究社',
			'profile.options.preferences' => '偏好設定',
			'profile.options.logout' => '登出帳號',
			'profile.avatar.uploading' => '正在更新個人圖片…',
			'profile.avatar.uploadSuccess' => '個人圖片已更新',
			'profile.avatar.tooLarge' => '圖片大小超過20 MB限制',
			'profile.avatar.invalidFormat' => '無法辨識的圖片格式',
			'profile.avatar.uploadFailed' => '更改個人圖片失敗，請稍後再試',
			'profile.dangerZone.nonFlutterCrash' => '非Flutter框架崩潰',
			'profile.dangerZone.nonFlutterCrashException' => '模擬非同步錯誤',
			'profile.dangerZone.closedTitle' => '酒吧暫未營業',
			'profile.dangerZone.closedMessage' => '酒吧今天打烊了，改天再來探索吧！',
			'profile.dangerZone.kickedMessage' => '你被店員勸退，還是早點回家休息吧～',
			'profile.dangerZone.fireMessage' => '酒吧陷入火海',
			'profile.dangerZone.barOpen' => '酒吧開門了',
			'profile.dangerZone.barClosed' => '酒吧倒閉了',
			'profile.dangerZone.goAction' => ({required Object action}) => '去酒吧${action}',
			'profile.dangerZone.actions.0' => '點0杯啤酒',
			'profile.dangerZone.actions.1' => '點999999999杯啤酒',
			'profile.dangerZone.actions.2' => '點1支蜥蜴',
			'profile.dangerZone.actions.3' => '點-1杯啤酒',
			'profile.dangerZone.actions.4' => '點1份asdfghjkl',
			'profile.dangerZone.actions.5' => '點1碗炒飯',
			'profile.dangerZone.actions.6' => '跑進吧檯被店員拖出去',
			'profile.dangerZone.clearCache' => '清除快取',
			'profile.dangerZone.clearCookies' => '清除Cookies',
			'profile.dangerZone.clearPreferences' => '清除偏好設定',
			'profile.dangerZone.clearCredentials' => '清除登入憑證',
			'profile.dangerZone.clearUserData' => '清除使用者資料',
			'profile.dangerZone.cleared' => ({required Object item}) => '已清除${item}',
			'profile.dangerZone.clearFailed' => ({required Object item}) => '清除${item}失敗',
			'profile.dangerZone.items.cache' => '快取',
			'profile.dangerZone.items.cookies' => 'Cookies',
			'profile.dangerZone.items.preferences' => '偏好設定',
			'profile.dangerZone.items.credentials' => '登入憑證',
			'profile.dangerZone.items.userData' => '使用者資料',
			'scanner.title' => '掃碼登入',
			'scanner.scanInstruction' => '請將二維碼放入框內',
			'scanner.loginIStudy' => '掃碼登入i學園',
			'scanner.success' => '登入成功',
			'scanner.failed' => '登入失敗',
			'scanner.processing' => '正在處理…',
			'scanner.loggingIn' => '正在登入…',
			'scanner.permissionDenied' => '需要相機權限才能掃描QR code',
			'scanner.permissionDeniedDescription' => '請至設定中開啟相機權限，然後再試一次。',
			'scanner.cameraError' => '無法開啟相機，請檢查硬體或稍後再試。',
			'scanner.errors."201"' => '手機未登入',
			'scanner.errors."202"' => '操作錯誤，請先至「首頁」，再點擊「校外人士登入」',
			'scanner.errors."203"' => '已經是登入成功狀態',
			'scanner.errors."204"' => 'QR code已失效，請重新整理頁面',
			'scanner.errors."205"' => '已登入，要切換使用者必須先登出網頁',
			'scanner.errors."206"' => 'QR code已過期，請在電腦上重新整理頁面',
			'scanner.errors.unknown' => '登入失敗，請確認 QR code 是否正確或從電腦頁面刷新',
			'scanner.howTo' => '在電腦開啟i.ntut.club並點選QR code登入',
			'scanner.guide.title' => '如何掃碼登入？',
			'scanner.guide.step1' => '1. 電腦前往下列網址：',
			'scanner.guide.url' => 'https://i.ntut.club',
			'scanner.guide.step2' => '2. 點擊導覽列的「外校人士登入」',
			'scanner.guide.step3' => '3. 點擊「QR Code 登入」',
			'scanner.guide.button' => '我知道了',
			'scanner.invalidUrl' => '無效的網址',
			'ntutWifi.title' => 'NTUT-802.1X',
			'ntutWifi.entryDescription' => '使用既有校園入口帳密自動加入NTUT-802.1X校園Wi‑Fi',
			'ntutWifi.intro' => '使用已登入的校園入口帳號密碼，自動加入NTUT-802.1X並讓Android後續自動嘗試連線。',
			'ntutWifi.accountHint' => '帳號直接使用學號或員編，不要加上@ntut.edu.tw。',
			'ntutWifi.androidVersion' => ({required Object sdkInt}) => 'Android API ${sdkInt}',
			'ntutWifi.unsupportedPlatform' => '這個功能目前僅支援Android裝置。',
			'ntutWifi.notLoggedIn' => '請先登入校園入口帳號，才能帶入NTUT-802.1X的帳號與密碼。',
			'ntutWifi.credentialsMissing' => '找不到已保存的入口網站密碼。若要複製密碼，請先重新登入TAT。',
			'ntutWifi.olderAndroidWarning' => '此助手依Android 12以上介面設計，較舊版本的欄位名稱可能略有不同。',
			'ntutWifi.copyFailed' => '複製失敗',
			'ntutWifi.openSettingsFailed' => '無法開啟Wi‑Fi設定',
			'ntutWifi.openPanelFailed' => '無法開啟Wi‑Fi快捷面板',
			'ntutWifi.systemCertificatesHint' => '自動佈署會固定使用「系統憑證 + 網域ntut.edu.tw + PEAP/GTC」。若系統不允許App安全地下發這組Enterprise設定，請改走下方手動fallback。',
			'ntutWifi.automaticProvisionUnavailable' => '這台裝置目前無法讓TAT自動加入NTUT-802.1X，請改走下方的手動設定路徑。',
			'ntutWifi.compatModeSavedHint' => '相容模式已儲存到系統。之後若入口帳密變更，需要再次更新這組 Wi‑Fi 設定。',
			'ntutWifi.compatUpdateRequired' => '先前使用相容模式寫入的 NTUT-802.1X 帳密已過期，請重新更新系統 Wi‑Fi。',
			'ntutWifi.suggestionFallbackRequired' => 'suggestion 自動更新失敗，請改用相容模式將最新 NTUT-802.1X 設定寫入系統。',
			'ntutWifi.android10PermissionRejected' => 'Android 10 已拒絕這個 App 的 Wi‑Fi suggestion 權限，請依下方教學手動連線。',
			'ntutWifi.legacyManualOnly' => 'Android 9 以下不支援這個自動加入流程，請依下方教學手動設定。',
			'ntutWifi.sections.quickActions' => '快速操作',
			'ntutWifi.sections.recommendedSettings' => '建議設定',
			'ntutWifi.sections.fallback' => '手動Fallback',
			'ntutWifi.actions.autoProvision' => '自動加入NTUT-802.1X',
			'ntutWifi.actions.autoProvisioning' => '正在加入NTUT-802.1X…',
			'ntutWifi.actions.retryCompatProvision' => '使用相容模式重試',
			'ntutWifi.actions.updateCompatProvision' => '使用相容模式更新',
			'ntutWifi.actions.openWifiSettings' => '開啟Wi‑Fi設定',
			'ntutWifi.actions.openWifiPanel' => '開啟Wi‑Fi快捷面板',
			'ntutWifi.fields.ssid' => '網路名稱',
			'ntutWifi.fields.eapMethod' => 'EAP方法',
			'ntutWifi.fields.phase2Auth' => '第二階段驗證',
			'ntutWifi.fields.identity' => '身分',
			'ntutWifi.fields.password' => '密碼',
			'ntutWifi.fields.caCertificate' => 'CA憑證',
			'ntutWifi.fields.domain' => '網域',
			'ntutWifi.fieldValues.passwordSaved' => '已儲存在裝置，可直接複製',
			'ntutWifi.fieldValues.passwordUnavailable' => '需要重新登入才能複製密碼',
			'ntutWifi.fieldValues.systemCertificates' => '使用系統憑證',
			'ntutWifi.fallbackSteps.openSettings' => '1. 開啟Wi‑Fi設定或快捷面板。',
			'ntutWifi.fallbackSteps.selectNetwork' => '2. 選擇或新增NTUT-802.1X。',
			'ntutWifi.fallbackSteps.useDisplayedValues' => '3. 將下方顯示的SSID、PEAP、GTC、帳號、密碼與網域填入。',
			'ntutWifi.provisioning.success' => '已將NTUT-802.1X加入Android。只要Wi‑Fi開啟且在校園網路範圍內，系統就會自動嘗試連線。',
			'ntutWifi.provisioning.successPendingWifi' => '已將NTUT-802.1X加入Android，但目前Wi‑Fi尚未開啟。開啟Wi‑Fi後，系統才會自動嘗試連線。',
			'ntutWifi.provisioning.approvalPending' => '系統目前不允許TAT直接送出Wi‑Fi建議，請改用下方設定入口完成系統層操作後再試。',
			'ntutWifi.provisioning.approvalRejected' => '系統已拒絕TAT的Wi‑Fi建議，請到系統設定允許後再試，或直接走下方手動設定。',
			'ntutWifi.provisioning.validationUnavailable' => '這台裝置無法讓TAT安全地下發「系統憑證 + 網域」Enterprise設定，請改用下方手動設定。',
			'ntutWifi.provisioning.unsupportedPlatform' => '這台裝置目前不支援自動加入NTUT-802.1X。',
			'ntutWifi.provisioning.failed' => '自動加入NTUT-802.1X失敗，請改用下方手動設定。',
			'ntutWifi.provisioning.compatSuccess' => '已透過相容模式將 NTUT-802.1X 寫入系統 Wi‑Fi。',
			'ntutWifi.provisioning.compatFallbackSuccess' => 'suggestion 被拒，已改用相容模式將 NTUT-802.1X 寫入系統 Wi‑Fi。',
			'ntutWifi.provisioning.compatAlreadyExists' => 'Android 回報系統內已存在 NTUT-802.1X 設定，但儲存的密碼可能仍是舊的。請先確認系統 Wi‑Fi 項目，或刪除後再重新使用相容模式。',
			'ntutWifi.provisioning.compatCancelled' => '已取消相容模式更新，稍後可在此頁重新嘗試。',
			'ntutWifi.provisioning.compatFailed' => '相容模式更新失敗，請改依下方教學手動連線。',
			'ntutWifi.compatPrompt.title' => '更新 NTUT-802.1X',
			'ntutWifi.compatPrompt.updateNow' => '立即更新',
			'ntutWifi.compatPrompt.later' => '稍後',
			'ntutWifi.compatPrompt.credentialChanged' => '你先前使用相容模式儲存了 NTUT-802.1X。現在入口帳密已變更，需要重新更新系統 Wi‑Fi。',
			'ntutWifi.compatPrompt.suggestionFallbackRequired' => '系統無法自動更新 NTUT-802.1X，是否現在改用相容模式完成更新？',
			'kioskLogin.qrCode' => '登入QR code',
			'kioskLogin.refresh' => '重新產生',
			'kioskLogin.notice' => '請使用投票活動會場的iPad掃描此QR Code。\n為確保您的隱私，請勿將此QR Code分享給他人。',
			'kioskLogin.loadFailed' => '無法產生登入QR code，請稍後再試',
			'kioskLogin.invalidSsoUrl' => '登入網址格式不正確，無法產生登入QR code',
			'enrollmentStatus.learning' => '在學',
			'enrollmentStatus.leaveOfAbsence' => '休學',
			'enrollmentStatus.droppedOut' => '退學',
			'enrollmentStatus.graduated' => '畢業',
			'about.description' => 'Project Tattoo (TAT)是國立臺北科技大學(NTUT)的非官方校園生活小幫手。我們致力於透過現代化且使用者友善的介面，提供更便利的校園生活體驗。',
			'about.developers' => '開發團隊',
			'about.helpTranslate' => '幫助我們翻譯TAT!',
			'about.viewSource' => '查看原始碼與貢獻',
			'about.relatedLinks' => '相關連結',
			'about.privacyPolicy' => '隱私權政策',
			'about.privacyPolicyUrl' => 'https://github.com/NTUT-NPC/tattoo/blob/main/PRIVACY.zh-TW.md',
			'about.viewPrivacyPolicy' => '查看隱私權政策',
			'about.openSourceLicenses' => '開放原始碼授權',
			'about.viewOpenSourceLicenses' => 'TAT的實作歸功於開放原始碼社群',
			'about.copyright' => '© 2025北科程式設計研究社\n以GNU GPL v3.0授權條款釋出',
			'forceUpdate.title' => '有新版本可用',
			'forceUpdate.message' => '請更新至最新版本以繼續使用TAT。',
			'forceUpdate.requiredVersion' => ({required Object version}) => '版本 ${version}',
			'forceUpdate.updateButton' => '立即更新',
			'forceUpdate.later' => '稍後',
			'forceUpdate.view' => '查看',
			'forceUpdate.isForced' => '此為強制更新。',
			'regedit.title' => '登錄編輯程式',
			'regedit.fetch' => '從遠端獲取',
			'regedit.noRegistry' => '沒有登錄項目',
			'regedit.refreshed' => '登錄檔已更新',
			'regedit.reset' => '重設為預設值',
			'regedit.status.local' => '預設值',
			'regedit.status.remote' => '雲端設定',
			'regedit.status.localOverride' => '使用者覆寫',
			'regedit.status.remoteOverride' => '強制覆寫（遠端）',
			'regedit.invalidInput' => '輸入格式錯誤',
			'changePassword.title' => '變更密碼',
			'changePassword.titleExpired' => '變更過期密碼',
			'changePassword.expiredNotice' => '您的密碼已過期，請設定新密碼以繼續使用。',
			'changePassword.currentPassword' => '目前密碼',
			'changePassword.newPassword' => '新密碼',
			'changePassword.confirmPassword' => '確認新密碼',
			'changePassword.submit' => '變更密碼',
			'changePassword.success' => '密碼變更成功',
			'changePassword.errors.emptyFields' => '請填寫所有欄位',
			'changePassword.errors.mismatch' => '兩次輸入的密碼不一致',
			'changePassword.errors.failed' => ({required Object error}) => '變更密碼失敗：${error}',
			'changePassword.errors.invalidLength' => '密碼長度須介於8至14個字元之間',
			'changePassword.errors.invalidComplexity' => '密碼須包含英文大小寫字母、數字及符號',
			'changePassword.errors.sameAsUsername' => '密碼不可與學號相同',
			'changePassword.errors.server.authFailed' => '目前密碼錯誤',
			'changePassword.errors.server.minAge' => '密碼於1天內不得再修改',
			'changePassword.errors.server.historyRepeat' => '密碼不可與前3組重複',
			'changePassword.errors.server.sameAsUsername' => '密碼不可與學號相同',
			'changePassword.errors.server.length' => '密碼長度須介於8至14個字元之間',
			'changePassword.errors.server.complexity' => '密碼須包含英文大小寫字母、數字及符號',
			_ => null,
		};
	}
}
