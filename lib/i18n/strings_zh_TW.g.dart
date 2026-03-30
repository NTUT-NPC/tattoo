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
	late final TranslationsGeneralZhTw general = TranslationsGeneralZhTw.internal(_root);
	late final TranslationsErrorsZhTw errors = TranslationsErrorsZhTw.internal(_root);
	late final TranslationsIntroZhTw intro = TranslationsIntroZhTw.internal(_root);
	late final TranslationsLoginZhTw login = TranslationsLoginZhTw.internal(_root);
	late final TranslationsNavZhTw nav = TranslationsNavZhTw.internal(_root);
	late final TranslationsCourseTableZhTw courseTable = TranslationsCourseTableZhTw.internal(_root);
	late final TranslationsProfileZhTw profile = TranslationsProfileZhTw.internal(_root);
	late final TranslationsScannerZhTw scanner = TranslationsScannerZhTw.internal(_root);
	late final TranslationsNtutWifiZhTw ntutWifi = TranslationsNtutWifiZhTw.internal(_root);
	late final TranslationsEnrollmentStatusZhTw enrollmentStatus = TranslationsEnrollmentStatusZhTw.internal(_root);
	late final TranslationsAboutZhTw about = TranslationsAboutZhTw.internal(_root);
}

// Path: general
class TranslationsGeneralZhTw {
	TranslationsGeneralZhTw.internal(this._root);

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

	/// zh-TW: '確定'
	String get ok => '確定';
}

// Path: errors
class TranslationsErrorsZhTw {
	TranslationsErrorsZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '發生錯誤'
	String get occurred => '發生錯誤';

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
class TranslationsIntroZhTw {
	TranslationsIntroZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsIntroFeaturesZhTw features = TranslationsIntroFeaturesZhTw.internal(_root);

	/// zh-TW: '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準'
	String get developedBy => '由北科程式設計研究社開發\n所有資訊僅供參考，請以學校官方系統為準';

	/// zh-TW: '繼續'
	String get kContinue => '繼續';
}

// Path: login
class TranslationsLoginZhTw {
	TranslationsLoginZhTw.internal(this._root);

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

	/// zh-TW: '登入資訊將被安全地儲存在您的裝置中 登入即表示您同意我們的${privacyPolicy(隱私條款)}'
	TextSpan privacyNotice({required InlineSpanBuilder privacyPolicy}) => TextSpan(children: [
		const TextSpan(text: '登入資訊將被安全地儲存在您的裝置中\n登入即表示您同意我們的'),
		privacyPolicy('隱私條款'),
	]);

	late final TranslationsLoginErrorsZhTw errors = TranslationsLoginErrorsZhTw.internal(_root);
}

// Path: nav
class TranslationsNavZhTw {
	TranslationsNavZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '課表'
	String get courseTable => '課表';

	/// zh-TW: '成績'
	String get scores => '成績';

	/// zh-TW: '傳送門'
	String get portal => '傳送門';

	/// zh-TW: '我'
	String get profile => '我';
}

// Path: courseTable
class TranslationsCourseTableZhTw {
	TranslationsCourseTableZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '找不到課表'
	String get notFound => '找不到課表';

	Map<String, String> get dayOfWeek => {
		'sunday': '日',
		'monday': '一',
		'tuesday': '二',
		'wednesday': '三',
		'thursday': '四',
		'friday': '五',
		'saturday': '六',
	};
}

// Path: profile
class TranslationsProfileZhTw {
	TranslationsProfileZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '僅供參考，非正式文件'
	String get dataDisclaimer => '僅供參考，非正式文件';

	late final TranslationsProfileSectionsZhTw sections = TranslationsProfileSectionsZhTw.internal(_root);
	late final TranslationsProfileOptionsZhTw options = TranslationsProfileOptionsZhTw.internal(_root);
	late final TranslationsProfileAvatarZhTw avatar = TranslationsProfileAvatarZhTw.internal(_root);
	late final TranslationsProfileDangerZoneZhTw dangerZone = TranslationsProfileDangerZoneZhTw.internal(_root);
}

// Path: scanner
class TranslationsScannerZhTw {
	TranslationsScannerZhTw.internal(this._root);

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

	late final TranslationsScannerGuideZhTw guide = TranslationsScannerGuideZhTw.internal(_root);

	/// zh-TW: '無效的網址'
	String get invalidUrl => '無效的網址';
}

// Path: ntutWifi
class TranslationsNtutWifiZhTw {
	TranslationsNtutWifiZhTw.internal(this._root);

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

	late final TranslationsNtutWifiSectionsZhTw sections = TranslationsNtutWifiSectionsZhTw.internal(_root);
	late final TranslationsNtutWifiActionsZhTw actions = TranslationsNtutWifiActionsZhTw.internal(_root);
	late final TranslationsNtutWifiFieldsZhTw fields = TranslationsNtutWifiFieldsZhTw.internal(_root);
	late final TranslationsNtutWifiFieldValuesZhTw fieldValues = TranslationsNtutWifiFieldValuesZhTw.internal(_root);
	late final TranslationsNtutWifiFallbackStepsZhTw fallbackSteps = TranslationsNtutWifiFallbackStepsZhTw.internal(_root);
	late final TranslationsNtutWifiProvisioningZhTw provisioning = TranslationsNtutWifiProvisioningZhTw.internal(_root);
}

// Path: enrollmentStatus
class TranslationsEnrollmentStatusZhTw {
	TranslationsEnrollmentStatusZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '在學'
	String get learning => '在學';

	/// zh-TW: '休學'
	String get leaveOfAbsence => '休學';

	/// zh-TW: '退學'
	String get droppedOut => '退學';
}

// Path: about
class TranslationsAboutZhTw {
	TranslationsAboutZhTw.internal(this._root);

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

	/// zh-TW: '© 2025北科程式設計研究社\n以GNU GPL v3.0授權條款釋出'
	String get copyright => '© 2025北科程式設計研究社\n以GNU GPL v3.0授權條款釋出';
}

// Path: intro.features
class TranslationsIntroFeaturesZhTw {
	TranslationsIntroFeaturesZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsIntroFeaturesCourseTableZhTw courseTable = TranslationsIntroFeaturesCourseTableZhTw.internal(_root);
	late final TranslationsIntroFeaturesScoresZhTw scores = TranslationsIntroFeaturesScoresZhTw.internal(_root);
	late final TranslationsIntroFeaturesCampusLifeZhTw campusLife = TranslationsIntroFeaturesCampusLifeZhTw.internal(_root);
}

// Path: login.errors
class TranslationsLoginErrorsZhTw {
	TranslationsLoginErrorsZhTw.internal(this._root);

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

// Path: profile.sections
class TranslationsProfileSectionsZhTw {
	TranslationsProfileSectionsZhTw.internal(this._root);

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
class TranslationsProfileOptionsZhTw {
	TranslationsProfileOptionsZhTw.internal(this._root);

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
class TranslationsProfileAvatarZhTw {
	TranslationsProfileAvatarZhTw.internal(this._root);

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
class TranslationsProfileDangerZoneZhTw {
	TranslationsProfileDangerZoneZhTw.internal(this._root);

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

	late final TranslationsProfileDangerZoneItemsZhTw items = TranslationsProfileDangerZoneItemsZhTw.internal(_root);
}

// Path: scanner.guide
class TranslationsScannerGuideZhTw {
	TranslationsScannerGuideZhTw.internal(this._root);

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
class TranslationsNtutWifiSectionsZhTw {
	TranslationsNtutWifiSectionsZhTw.internal(this._root);

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
class TranslationsNtutWifiActionsZhTw {
	TranslationsNtutWifiActionsZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '自動加入NTUT-802.1X'
	String get autoProvision => '自動加入NTUT-802.1X';

	/// zh-TW: '正在加入NTUT-802.1X…'
	String get autoProvisioning => '正在加入NTUT-802.1X…';

	/// zh-TW: '開啟Wi‑Fi設定'
	String get openWifiSettings => '開啟Wi‑Fi設定';

	/// zh-TW: '開啟Wi‑Fi快捷面板'
	String get openWifiPanel => '開啟Wi‑Fi快捷面板';
}

// Path: ntutWifi.fields
class TranslationsNtutWifiFieldsZhTw {
	TranslationsNtutWifiFieldsZhTw.internal(this._root);

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
class TranslationsNtutWifiFieldValuesZhTw {
	TranslationsNtutWifiFieldValuesZhTw.internal(this._root);

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
class TranslationsNtutWifiFallbackStepsZhTw {
	TranslationsNtutWifiFallbackStepsZhTw.internal(this._root);

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
class TranslationsNtutWifiProvisioningZhTw {
	TranslationsNtutWifiProvisioningZhTw.internal(this._root);

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
}

// Path: intro.features.courseTable
class TranslationsIntroFeaturesCourseTableZhTw {
	TranslationsIntroFeaturesCourseTableZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '查課表'
	String get title => '查課表';

	/// zh-TW: '快速查看課表和課程資訊，並可快速切換學期。'
	String get description => '快速查看課表和課程資訊，並可快速切換學期。';
}

// Path: intro.features.scores
class TranslationsIntroFeaturesScoresZhTw {
	TranslationsIntroFeaturesScoresZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '看成績'
	String get title => '看成績';

	/// zh-TW: '即時查詢各科成績與學分，整合歷年成績紀錄。'
	String get description => '即時查詢各科成績與學分，整合歷年成績紀錄。';
}

// Path: intro.features.campusLife
class TranslationsIntroFeaturesCampusLifeZhTw {
	TranslationsIntroFeaturesCampusLifeZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '北科生活'
	String get title => '北科生活';

	/// zh-TW: '彙整其他校園生活資訊，更多功能敬請期待。'
	String get description => '彙整其他校園生活資訊，更多功能敬請期待。';
}

// Path: profile.dangerZone.items
class TranslationsProfileDangerZoneItemsZhTw {
	TranslationsProfileDangerZoneItemsZhTw.internal(this._root);

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
			'general.ok' => '確定',
			'errors.occurred' => '發生錯誤',
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
			'nav.courseTable' => '課表',
			'nav.scores' => '成績',
			'nav.portal' => '傳送門',
			'nav.profile' => '我',
			'courseTable.notFound' => '找不到課表',
			'courseTable.dayOfWeek.sunday' => '日',
			'courseTable.dayOfWeek.monday' => '一',
			'courseTable.dayOfWeek.tuesday' => '二',
			'courseTable.dayOfWeek.wednesday' => '三',
			'courseTable.dayOfWeek.thursday' => '四',
			'courseTable.dayOfWeek.friday' => '五',
			'courseTable.dayOfWeek.saturday' => '六',
			'profile.dataDisclaimer' => '僅供參考，非正式文件',
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
			'ntutWifi.sections.quickActions' => '快速操作',
			'ntutWifi.sections.recommendedSettings' => '建議設定',
			'ntutWifi.sections.fallback' => '手動Fallback',
			'ntutWifi.actions.autoProvision' => '自動加入NTUT-802.1X',
			'ntutWifi.actions.autoProvisioning' => '正在加入NTUT-802.1X…',
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
			'enrollmentStatus.learning' => '在學',
			'enrollmentStatus.leaveOfAbsence' => '休學',
			'enrollmentStatus.droppedOut' => '退學',
			'about.description' => 'Project Tattoo (TAT)是國立臺北科技大學(NTUT)的非官方校園生活小幫手。我們致力於透過現代化且使用者友善的介面，提供更便利的校園生活體驗。',
			'about.developers' => '開發團隊',
			'about.helpTranslate' => '幫助我們翻譯TAT!',
			'about.viewSource' => '查看原始碼與貢獻',
			'about.relatedLinks' => '相關連結',
			'about.privacyPolicy' => '隱私權政策',
			'about.privacyPolicyUrl' => 'https://github.com/NTUT-NPC/tattoo/blob/main/PRIVACY.zh-TW.md',
			'about.viewPrivacyPolicy' => '查看隱私權政策',
			'about.copyright' => '© 2025北科程式設計研究社\n以GNU GPL v3.0授權條款釋出',
			_ => null,
		};
	}
}
