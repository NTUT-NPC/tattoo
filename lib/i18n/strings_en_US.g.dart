///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEnUs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEnUs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.enUs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en-US>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEnUs _root = this; // ignore: unused_field

	@override 
	TranslationsEnUs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEnUs(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsGeneralEnUs general = _TranslationsGeneralEnUs._(_root);
	@override late final _TranslationsErrorsEnUs errors = _TranslationsErrorsEnUs._(_root);
	@override late final _TranslationsIntroEnUs intro = _TranslationsIntroEnUs._(_root);
	@override late final _TranslationsLoginEnUs login = _TranslationsLoginEnUs._(_root);
	@override late final _TranslationsNavEnUs nav = _TranslationsNavEnUs._(_root);
	@override late final _TranslationsCourseTableEnUs courseTable = _TranslationsCourseTableEnUs._(_root);
	@override late final _TranslationsProfileEnUs profile = _TranslationsProfileEnUs._(_root);
	@override late final _TranslationsScannerEnUs scanner = _TranslationsScannerEnUs._(_root);
	@override late final _TranslationsEnrollmentStatusEnUs enrollmentStatus = _TranslationsEnrollmentStatusEnUs._(_root);
	@override late final _TranslationsAboutEnUs about = _TranslationsAboutEnUs._(_root);
}

// Path: general
class _TranslationsGeneralEnUs extends TranslationsGeneralZhTw {
	_TranslationsGeneralEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get appTitle => 'Project Tattoo';
	@override String get notImplemented => 'Not implemented';
	@override String get dataDisclaimer => 'For reference only';
	@override String get student => 'Student';
	@override String get unknown => 'Unknown';
	@override String get notLoggedIn => 'Not logged in';
	@override String get copy => 'Copy';
	@override String get copied => 'Copied';
	@override String get ok => 'OK';
}

// Path: errors
class _TranslationsErrorsEnUs extends TranslationsErrorsZhTw {
	_TranslationsErrorsEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get occurred => 'An error occurred';
	@override String get flutterError => 'A Flutter error occurred';
	@override String get asyncError => 'An async error occurred';
	@override String get sessionExpired => 'Session expired. Please sign in again.';
	@override String get credentialsInvalid => 'Credentials are no longer valid. Please sign in again.';
	@override String get connectionFailed => 'Cannot connect to the server. Please check your network connection.';
}

// Path: intro
class _TranslationsIntroEnUs extends TranslationsIntroZhTw {
	_TranslationsIntroEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsIntroFeaturesEnUs features = _TranslationsIntroFeaturesEnUs._(_root);
	@override String get developedBy => 'Developed by NTUT NPC Club\nAll information is for reference only. Please refer to the official university system.';
	@override String get kContinue => 'Continue';
}

// Path: login
class _TranslationsLoginEnUs extends TranslationsLoginZhTw {
	_TranslationsLoginEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get welcomeLine1 => 'Welcome to';
	@override String get welcomeLine2 => 'Campus Life';
	@override TextSpan instruction({required InlineSpanBuilder portalLink}) => TextSpan(children: [
		const TextSpan(text: 'Sign in with your '),
		portalLink('NTUT Portal'),
		const TextSpan(text: ' account credentials.'),
	]);
	@override String get studentId => 'Student ID';
	@override String get password => 'Password';
	@override String get loginButton => 'Sign In';
	@override TextSpan privacyNotice({required InlineSpanBuilder privacyPolicy}) => TextSpan(children: [
		const TextSpan(text: 'Your credentials are stored securely on your device\nBy signing in, you agree to our '),
		privacyPolicy('Privacy Policy'),
		const TextSpan(text: '.'),
	]);
	@override late final _TranslationsLoginErrorsEnUs errors = _TranslationsLoginErrorsEnUs._(_root);
}

// Path: nav
class _TranslationsNavEnUs extends TranslationsNavZhTw {
	_TranslationsNavEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get courseTable => 'Courses';
	@override String get scores => 'Scores';
	@override String get portal => 'Portals';
	@override String get profile => 'Me';
}

// Path: courseTable
class _TranslationsCourseTableEnUs extends TranslationsCourseTableZhTw {
	_TranslationsCourseTableEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get notFound => 'Course table not found';
	@override Map<String, String> get dayOfWeek => {
		'sunday': 'Sun',
		'monday': 'Mon',
		'tuesday': 'Tue',
		'wednesday': 'Wed',
		'thursday': 'Thu',
		'friday': 'Fri',
		'saturday': 'Sat',
	};
}

// Path: profile
class _TranslationsProfileEnUs extends TranslationsProfileZhTw {
	_TranslationsProfileEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get dataDisclaimer => 'For reference only. Not valid as official documentation.';
	@override late final _TranslationsProfileSectionsEnUs sections = _TranslationsProfileSectionsEnUs._(_root);
	@override late final _TranslationsProfileOptionsEnUs options = _TranslationsProfileOptionsEnUs._(_root);
	@override late final _TranslationsProfileAvatarEnUs avatar = _TranslationsProfileAvatarEnUs._(_root);
	@override late final _TranslationsProfileDangerZoneEnUs dangerZone = _TranslationsProfileDangerZoneEnUs._(_root);
}

// Path: scanner
class _TranslationsScannerEnUs extends TranslationsScannerZhTw {
	_TranslationsScannerEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'QR Code Login';
	@override String get scanInstruction => 'Place the QR code in the box';
	@override String get loginIStudy => 'Login to iSchool Plus';
	@override String get success => 'Login successful';
	@override String get failed => 'Login failed';
	@override String get processing => 'Processing...';
	@override Map<String, String> get errors => {
		'201': 'Mobile login required',
		'202': 'Error occurred. Please go to "Home" and click "Outside school login"',
		'203': 'You are already logged in',
		'204': 'The QR code session has ended. Please refresh the page.',
		'205': 'Already logged in. Log out from the portal first to switch users.',
		'206': 'The QR code has expired. Please refresh the page on your computer.',
		'unknown': 'Login failed. Please check the QR code or refresh the page.',
	};
	@override String get howTo => 'Open i.ntut.club on your computer and select QR code login';
	@override late final _TranslationsScannerGuideEnUs guide = _TranslationsScannerGuideEnUs._(_root);
	@override String get invalidUrl => 'Invalid URL';
}

// Path: enrollmentStatus
class _TranslationsEnrollmentStatusEnUs extends TranslationsEnrollmentStatusZhTw {
	_TranslationsEnrollmentStatusEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get learning => 'Enrolled';
	@override String get leaveOfAbsence => 'Leave of Absence';
	@override String get droppedOut => 'Withdrawn';
}

// Path: about
class _TranslationsAboutEnUs extends TranslationsAboutZhTw {
	_TranslationsAboutEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get description => 'Project Tattoo (TAT) is an unofficial campus life assistant for National Taipei University of Technology (NTUT). Our goal is to provide a better student experience through a modern and user-friendly interface.';
	@override String get developers => 'Developers';
	@override String get helpTranslate => 'Help us translate TAT!';
	@override String get viewSource => 'View source code and contributions';
	@override String get relatedLinks => 'Related Links';
	@override String get privacyPolicy => 'Privacy Policy';
	@override String get privacyPolicyUrl => 'https://github.com/NTUT-NPC/tattoo/blob/main/PRIVACY.md';
	@override String get viewPrivacyPolicy => 'View our privacy policy';
	@override String get copyright => '© 2025 NTUT Programming Club\nLicensed under the GNU GPL v3.0';
}

// Path: intro.features
class _TranslationsIntroFeaturesEnUs extends TranslationsIntroFeaturesZhTw {
	_TranslationsIntroFeaturesEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsIntroFeaturesCourseTableEnUs courseTable = _TranslationsIntroFeaturesCourseTableEnUs._(_root);
	@override late final _TranslationsIntroFeaturesScoresEnUs scores = _TranslationsIntroFeaturesScoresEnUs._(_root);
	@override late final _TranslationsIntroFeaturesCampusLifeEnUs campusLife = _TranslationsIntroFeaturesCampusLifeEnUs._(_root);
}

// Path: login.errors
class _TranslationsLoginErrorsEnUs extends TranslationsLoginErrorsZhTw {
	_TranslationsLoginErrorsEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get emptyFields => 'Please enter your student ID and password';
	@override String get useStudentId => 'Please use your student ID to sign in, not an email address';
	@override String get loginFailed => 'Login failed. Please verify your credentials.';
	@override String get wrongCredentials => 'Incorrect student ID or password.';
	@override String get accountLocked => 'Account locked due to too many failed attempts. Please try again later.';
	@override String get passwordExpired => 'Your password has expired. Please change it on the NTUT portal.';
	@override String get mobileVerificationRequired => 'Mobile phone verification is required. Please complete it on the NTUT portal.';
}

// Path: profile.sections
class _TranslationsProfileSectionsEnUs extends TranslationsProfileSectionsZhTw {
	_TranslationsProfileSectionsEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get accountSettings => 'Account Settings';
	@override String get appSettings => 'App Settings';
	@override String get dangerZone => 'Danger Zone';
}

// Path: profile.options
class _TranslationsProfileOptionsEnUs extends TranslationsProfileOptionsZhTw {
	_TranslationsProfileOptionsEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get changePassword => 'Change Password';
	@override String get changeAvatar => 'Change Avatar';
	@override String get supportUs => 'Support Us';
	@override String get about => 'About TAT';
	@override String get npcClub => 'NTUT NPC Club';
	@override String get preferences => 'Preferences';
	@override String get logout => 'Sign Out';
}

// Path: profile.avatar
class _TranslationsProfileAvatarEnUs extends TranslationsProfileAvatarZhTw {
	_TranslationsProfileAvatarEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get uploading => 'Updating avatar...';
	@override String get uploadSuccess => 'Avatar updated';
	@override String get tooLarge => 'Image exceeds the 20 MB size limit';
	@override String get invalidFormat => 'Unrecognized image format';
	@override String get uploadFailed => 'Failed to change avatar. Please try again later.';
}

// Path: profile.dangerZone
class _TranslationsProfileDangerZoneEnUs extends TranslationsProfileDangerZoneZhTw {
	_TranslationsProfileDangerZoneEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get nonFlutterCrash => 'Non-Flutter Framework Crash';
	@override String get nonFlutterCrashException => 'Simulation of asynchronous error';
	@override String get closedTitle => 'Bar is currently closed';
	@override String get closedMessage => 'The bar is closed today, come back another time to explore!';
	@override String get kickedMessage => 'You were kicked out by the staff. Better head home and rest!';
	@override String get fireMessage => 'Bar is on fire';
	@override String get alreadyFull => 'Already full';
	@override String goAction({required Object action}) => 'Go to the bar and ${action}';
	@override List<String> get actions => [
		'order 0 beers',
		'order 999999999 beers',
		'order 1 lizard',
		'order -1 beer',
		'order 1 asdfghjkl',
		'order 1 bowl of fried rice',
		'get kicked out by the staff',
	];
	@override String get clearCache => 'Clear Cache';
	@override String get clearCookies => 'Clear Cookies';
	@override String get clearPreferences => 'Clear Preferences';
	@override String get clearCredentials => 'Clear Credentials';
	@override String get clearUserData => 'Clear User Data';
	@override String cleared({required Object item}) => '${item} cleared';
	@override String clearFailed({required Object item}) => 'Failed to clear ${item}';
	@override late final _TranslationsProfileDangerZoneItemsEnUs items = _TranslationsProfileDangerZoneItemsEnUs._(_root);
}

// Path: scanner.guide
class _TranslationsScannerGuideEnUs extends TranslationsScannerGuideZhTw {
	_TranslationsScannerGuideEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to login?';
	@override String get step1 => '1. Go to the following URL on your computer';
	@override String get url => 'https://i.ntut.club';
	@override String get step2 => '2. Click "Outside school login" in the navigation bar';
	@override String get step3 => '3. Click "Scan QR code"';
	@override String get button => 'Start Scanning';
}

// Path: intro.features.courseTable
class _TranslationsIntroFeaturesCourseTableEnUs extends TranslationsIntroFeaturesCourseTableZhTw {
	_TranslationsIntroFeaturesCourseTableEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Courses';
	@override String get description => 'Quickly view your course schedule and switch between semesters.';
}

// Path: intro.features.scores
class _TranslationsIntroFeaturesScoresEnUs extends TranslationsIntroFeaturesScoresZhTw {
	_TranslationsIntroFeaturesScoresEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scores';
	@override String get description => 'Check your grades and credits with integrated historical records.';
}

// Path: intro.features.campusLife
class _TranslationsIntroFeaturesCampusLifeEnUs extends TranslationsIntroFeaturesCampusLifeZhTw {
	_TranslationsIntroFeaturesCampusLifeEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Campus Life';
	@override String get description => 'Access campus life information, with more features coming soon.';
}

// Path: profile.dangerZone.items
class _TranslationsProfileDangerZoneItemsEnUs extends TranslationsProfileDangerZoneItemsZhTw {
	_TranslationsProfileDangerZoneItemsEnUs._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get cache => 'Cache';
	@override String get cookies => 'Cookies';
	@override String get preferences => 'Preferences';
	@override String get credentials => 'Credentials';
	@override String get userData => 'User data';
}

/// The flat map containing all translations for locale <en-US>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEnUs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'general.appTitle' => 'Project Tattoo',
			'general.notImplemented' => 'Not implemented',
			'general.dataDisclaimer' => 'For reference only',
			'general.student' => 'Student',
			'general.unknown' => 'Unknown',
			'general.notLoggedIn' => 'Not logged in',
			'general.copy' => 'Copy',
			'general.copied' => 'Copied',
			'general.ok' => 'OK',
			'errors.occurred' => 'An error occurred',
			'errors.flutterError' => 'A Flutter error occurred',
			'errors.asyncError' => 'An async error occurred',
			'errors.sessionExpired' => 'Session expired. Please sign in again.',
			'errors.credentialsInvalid' => 'Credentials are no longer valid. Please sign in again.',
			'errors.connectionFailed' => 'Cannot connect to the server. Please check your network connection.',
			'intro.features.courseTable.title' => 'Courses',
			'intro.features.courseTable.description' => 'Quickly view your course schedule and switch between semesters.',
			'intro.features.scores.title' => 'Scores',
			'intro.features.scores.description' => 'Check your grades and credits with integrated historical records.',
			'intro.features.campusLife.title' => 'Campus Life',
			'intro.features.campusLife.description' => 'Access campus life information, with more features coming soon.',
			'intro.developedBy' => 'Developed by NTUT NPC Club\nAll information is for reference only. Please refer to the official university system.',
			'intro.kContinue' => 'Continue',
			'login.welcomeLine1' => 'Welcome to',
			'login.welcomeLine2' => 'Campus Life',
			'login.instruction' => ({required InlineSpanBuilder portalLink}) => TextSpan(children: [ const TextSpan(text: 'Sign in with your '), portalLink('NTUT Portal'), const TextSpan(text: ' account credentials.'), ]), 
			'login.studentId' => 'Student ID',
			'login.password' => 'Password',
			'login.loginButton' => 'Sign In',
			'login.privacyNotice' => ({required InlineSpanBuilder privacyPolicy}) => TextSpan(children: [ const TextSpan(text: 'Your credentials are stored securely on your device\nBy signing in, you agree to our '), privacyPolicy('Privacy Policy'), const TextSpan(text: '.'), ]), 
			'login.errors.emptyFields' => 'Please enter your student ID and password',
			'login.errors.useStudentId' => 'Please use your student ID to sign in, not an email address',
			'login.errors.loginFailed' => 'Login failed. Please verify your credentials.',
			'login.errors.wrongCredentials' => 'Incorrect student ID or password.',
			'login.errors.accountLocked' => 'Account locked due to too many failed attempts. Please try again later.',
			'login.errors.passwordExpired' => 'Your password has expired. Please change it on the NTUT portal.',
			'login.errors.mobileVerificationRequired' => 'Mobile phone verification is required. Please complete it on the NTUT portal.',
			'nav.courseTable' => 'Courses',
			'nav.scores' => 'Scores',
			'nav.portal' => 'Portals',
			'nav.profile' => 'Me',
			'courseTable.notFound' => 'Course table not found',
			'courseTable.dayOfWeek.sunday' => 'Sun',
			'courseTable.dayOfWeek.monday' => 'Mon',
			'courseTable.dayOfWeek.tuesday' => 'Tue',
			'courseTable.dayOfWeek.wednesday' => 'Wed',
			'courseTable.dayOfWeek.thursday' => 'Thu',
			'courseTable.dayOfWeek.friday' => 'Fri',
			'courseTable.dayOfWeek.saturday' => 'Sat',
			'profile.dataDisclaimer' => 'For reference only. Not valid as official documentation.',
			'profile.sections.accountSettings' => 'Account Settings',
			'profile.sections.appSettings' => 'App Settings',
			'profile.sections.dangerZone' => 'Danger Zone',
			'profile.options.changePassword' => 'Change Password',
			'profile.options.changeAvatar' => 'Change Avatar',
			'profile.options.supportUs' => 'Support Us',
			'profile.options.about' => 'About TAT',
			'profile.options.npcClub' => 'NTUT NPC Club',
			'profile.options.preferences' => 'Preferences',
			'profile.options.logout' => 'Sign Out',
			'profile.avatar.uploading' => 'Updating avatar...',
			'profile.avatar.uploadSuccess' => 'Avatar updated',
			'profile.avatar.tooLarge' => 'Image exceeds the 20 MB size limit',
			'profile.avatar.invalidFormat' => 'Unrecognized image format',
			'profile.avatar.uploadFailed' => 'Failed to change avatar. Please try again later.',
			'profile.dangerZone.nonFlutterCrash' => 'Non-Flutter Framework Crash',
			'profile.dangerZone.nonFlutterCrashException' => 'Simulation of asynchronous error',
			'profile.dangerZone.closedTitle' => 'Bar is currently closed',
			'profile.dangerZone.closedMessage' => 'The bar is closed today, come back another time to explore!',
			'profile.dangerZone.kickedMessage' => 'You were kicked out by the staff. Better head home and rest!',
			'profile.dangerZone.fireMessage' => 'Bar is on fire',
			'profile.dangerZone.alreadyFull' => 'Already full',
			'profile.dangerZone.goAction' => ({required Object action}) => 'Go to the bar and ${action}',
			'profile.dangerZone.actions.0' => 'order 0 beers',
			'profile.dangerZone.actions.1' => 'order 999999999 beers',
			'profile.dangerZone.actions.2' => 'order 1 lizard',
			'profile.dangerZone.actions.3' => 'order -1 beer',
			'profile.dangerZone.actions.4' => 'order 1 asdfghjkl',
			'profile.dangerZone.actions.5' => 'order 1 bowl of fried rice',
			'profile.dangerZone.actions.6' => 'get kicked out by the staff',
			'profile.dangerZone.clearCache' => 'Clear Cache',
			'profile.dangerZone.clearCookies' => 'Clear Cookies',
			'profile.dangerZone.clearPreferences' => 'Clear Preferences',
			'profile.dangerZone.clearCredentials' => 'Clear Credentials',
			'profile.dangerZone.clearUserData' => 'Clear User Data',
			'profile.dangerZone.cleared' => ({required Object item}) => '${item} cleared',
			'profile.dangerZone.clearFailed' => ({required Object item}) => 'Failed to clear ${item}',
			'profile.dangerZone.items.cache' => 'Cache',
			'profile.dangerZone.items.cookies' => 'Cookies',
			'profile.dangerZone.items.preferences' => 'Preferences',
			'profile.dangerZone.items.credentials' => 'Credentials',
			'profile.dangerZone.items.userData' => 'User data',
			'scanner.title' => 'QR Code Login',
			'scanner.scanInstruction' => 'Place the QR code in the box',
			'scanner.loginIStudy' => 'Login to iSchool Plus',
			'scanner.success' => 'Login successful',
			'scanner.failed' => 'Login failed',
			'scanner.processing' => 'Processing...',
			'scanner.errors."201"' => 'Mobile login required',
			'scanner.errors."202"' => 'Error occurred. Please go to "Home" and click "Outside school login"',
			'scanner.errors."203"' => 'You are already logged in',
			'scanner.errors."204"' => 'The QR code session has ended. Please refresh the page.',
			'scanner.errors."205"' => 'Already logged in. Log out from the portal first to switch users.',
			'scanner.errors."206"' => 'The QR code has expired. Please refresh the page on your computer.',
			'scanner.errors.unknown' => 'Login failed. Please check the QR code or refresh the page.',
			'scanner.howTo' => 'Open i.ntut.club on your computer and select QR code login',
			'scanner.guide.title' => 'How to login?',
			'scanner.guide.step1' => '1. Go to the following URL on your computer',
			'scanner.guide.url' => 'https://i.ntut.club',
			'scanner.guide.step2' => '2. Click "Outside school login" in the navigation bar',
			'scanner.guide.step3' => '3. Click "Scan QR code"',
			'scanner.guide.button' => 'Start Scanning',
			'scanner.invalidUrl' => 'Invalid URL',
			'enrollmentStatus.learning' => 'Enrolled',
			'enrollmentStatus.leaveOfAbsence' => 'Leave of Absence',
			'enrollmentStatus.droppedOut' => 'Withdrawn',
			'about.description' => 'Project Tattoo (TAT) is an unofficial campus life assistant for National Taipei University of Technology (NTUT). Our goal is to provide a better student experience through a modern and user-friendly interface.',
			'about.developers' => 'Developers',
			'about.helpTranslate' => 'Help us translate TAT!',
			'about.viewSource' => 'View source code and contributions',
			'about.relatedLinks' => 'Related Links',
			'about.privacyPolicy' => 'Privacy Policy',
			'about.privacyPolicyUrl' => 'https://github.com/NTUT-NPC/tattoo/blob/main/PRIVACY.md',
			'about.viewPrivacyPolicy' => 'View our privacy policy',
			'about.copyright' => '© 2025 NTUT Programming Club\nLicensed under the GNU GPL v3.0',
			_ => null,
		};
	}
}
