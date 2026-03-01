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
	late final TranslationsProfileZhTw profile = TranslationsProfileZhTw.internal(_root);
	late final TranslationsEnrollmentStatusZhTw enrollmentStatus = TranslationsEnrollmentStatusZhTw.internal(_root);
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

	/// zh-TW: '僅供參考'
	String get dataDisclaimer => '僅供參考';

	/// zh-TW: '學生'
	String get student => '學生';

	/// zh-TW: '未知'
	String get unknown => '未知';

	/// zh-TW: '未登入'
	String get notLoggedIn => '未登入';

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

	/// zh-TW: '我'
	String get profile => '我';
}

// Path: profile
class TranslationsProfileZhTw {
	TranslationsProfileZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsProfileSectionsZhTw sections = TranslationsProfileSectionsZhTw.internal(_root);
	late final TranslationsProfileOptionsZhTw options = TranslationsProfileOptionsZhTw.internal(_root);
	late final TranslationsProfileNoticesZhTw notices = TranslationsProfileNoticesZhTw.internal(_root);
	late final TranslationsProfileAvatarZhTw avatar = TranslationsProfileAvatarZhTw.internal(_root);

	/// zh-TW: '本資料僅供參考，不做其他證明用途'
	String get dataDisclaimer => '本資料僅供參考，不做其他證明用途';
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

	/// zh-TW: '訊息範例'
	String get notices => '訊息範例';
}

// Path: profile.options
class TranslationsProfileOptionsZhTw {
	TranslationsProfileOptionsZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '更改密碼'
	String get changePassword => '更改密碼';

	/// zh-TW: '更改個人圖片'
	String get changeAvatar => '更改個人圖片';

	/// zh-TW: '支持我們'
	String get supportUs => '支持我們';

	/// zh-TW: '關於 TAT'
	String get about => '關於 TAT';

	/// zh-TW: '北科程式設計研究社'
	String get npcClub => '北科程式設計研究社';

	/// zh-TW: '偏好設定'
	String get preferences => '偏好設定';

	/// zh-TW: '登出帳號'
	String get logout => '登出帳號';
}

// Path: profile.notices
class TranslationsProfileNoticesZhTw {
	TranslationsProfileNoticesZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '目前新版的 TAT 仍在測試階段，若有問題歡迎和我們反映。'
	String get betaTesting => '目前新版的 TAT 仍在測試階段，若有問題歡迎和我們反映。';

	/// zh-TW: '您的密碼將於 7 天後到期，請盡快更新以免無法登入。'
	String get passwordExpiring => '您的密碼將於 7 天後到期，請盡快更新以免無法登入。';

	/// zh-TW: '無法連接到伺服器，資料可能不正確。'
	String get connectionError => '無法連接到伺服器，資料可能不正確。';
}

// Path: profile.avatar
class TranslationsProfileAvatarZhTw {
	TranslationsProfileAvatarZhTw.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-TW: '正在更新個人圖片...'
	String get uploading => '正在更新個人圖片...';

	/// zh-TW: '個人圖片已更新'
	String get uploadSuccess => '個人圖片已更新';

	/// zh-TW: '圖片大小超過 20 MB 限制'
	String get tooLarge => '圖片大小超過 20 MB 限制';

	/// zh-TW: '無法辨識的圖片格式'
	String get invalidFormat => '無法辨識的圖片格式';

	/// zh-TW: '更改個人圖片失敗，請稍後再試'
	String get uploadFailed => '更改個人圖片失敗，請稍後再試';
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
			'general.dataDisclaimer' => '僅供參考',
			'general.student' => '學生',
			'general.unknown' => '未知',
			'general.notLoggedIn' => '未登入',
			'general.ok' => '確定',
			'errors.occurred' => '發生錯誤',
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
			'nav.courseTable' => '課表',
			'nav.scores' => '成績',
			'nav.profile' => '我',
			'profile.sections.accountSettings' => '帳號設定',
			'profile.sections.appSettings' => '應用程式設定',
			'profile.sections.notices' => '訊息範例',
			'profile.options.changePassword' => '更改密碼',
			'profile.options.changeAvatar' => '更改個人圖片',
			'profile.options.supportUs' => '支持我們',
			'profile.options.about' => '關於 TAT',
			'profile.options.npcClub' => '北科程式設計研究社',
			'profile.options.preferences' => '偏好設定',
			'profile.options.logout' => '登出帳號',
			'profile.notices.betaTesting' => '目前新版的 TAT 仍在測試階段，若有問題歡迎和我們反映。',
			'profile.notices.passwordExpiring' => '您的密碼將於 7 天後到期，請盡快更新以免無法登入。',
			'profile.notices.connectionError' => '無法連接到伺服器，資料可能不正確。',
			'profile.avatar.uploading' => '正在更新個人圖片...',
			'profile.avatar.uploadSuccess' => '個人圖片已更新',
			'profile.avatar.tooLarge' => '圖片大小超過 20 MB 限制',
			'profile.avatar.invalidFormat' => '無法辨識的圖片格式',
			'profile.avatar.uploadFailed' => '更改個人圖片失敗，請稍後再試',
			'profile.dataDisclaimer' => '本資料僅供參考，不做其他證明用途',
			'enrollmentStatus.learning' => '在學',
			'enrollmentStatus.leaveOfAbsence' => '休學',
			'enrollmentStatus.droppedOut' => '退學',
			_ => null,
		};
	}
}
