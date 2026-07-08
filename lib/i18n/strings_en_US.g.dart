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
	@override late final _Translations$general$en_US general = _Translations$general$en_US._(_root);
	@override late final _Translations$errors$en_US errors = _Translations$errors$en_US._(_root);
	@override late final _Translations$intro$en_US intro = _Translations$intro$en_US._(_root);
	@override late final _Translations$login$en_US login = _Translations$login$en_US._(_root);
	@override late final _Translations$nav$en_US nav = _Translations$nav$en_US._(_root);
	@override late final _Translations$home$en_US home = _Translations$home$en_US._(_root);
	@override late final _Translations$score$en_US score = _Translations$score$en_US._(_root);
	@override late final _Translations$calendar$en_US calendar = _Translations$calendar$en_US._(_root);
	@override late final _Translations$courseTable$en_US courseTable = _Translations$courseTable$en_US._(_root);
	@override late final _Translations$profile$en_US profile = _Translations$profile$en_US._(_root);
	@override late final _Translations$scanner$en_US scanner = _Translations$scanner$en_US._(_root);
	@override late final _Translations$kioskLogin$en_US kioskLogin = _Translations$kioskLogin$en_US._(_root);
	@override late final _Translations$enrollmentStatus$en_US enrollmentStatus = _Translations$enrollmentStatus$en_US._(_root);
	@override late final _Translations$about$en_US about = _Translations$about$en_US._(_root);
	@override late final _Translations$featureFlags$en_US featureFlags = _Translations$featureFlags$en_US._(_root);
}

// Path: general
class _Translations$general$en_US extends Translations$general$zh_TW {
	_Translations$general$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

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
	@override String get back => 'Back';
	@override String get ok => 'OK';
	@override String get cancel => 'Cancel';
}

// Path: errors
class _Translations$errors$en_US extends Translations$errors$zh_TW {
	_Translations$errors$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

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
class _Translations$intro$en_US extends Translations$intro$zh_TW {
	_Translations$intro$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$intro$features$en_US features = _Translations$intro$features$en_US._(_root);
	@override String get developedBy => 'Developed by NTUT NPC Club\nAll information is for reference only. Please refer to the official university system.';
	@override String get kContinue => 'Continue';
}

// Path: login
class _Translations$login$en_US extends Translations$login$zh_TW {
	_Translations$login$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

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
	@override late final _Translations$login$errors$en_US errors = _Translations$login$errors$en_US._(_root);
}

// Path: nav
class _Translations$nav$en_US extends Translations$nav$zh_TW {
	_Translations$nav$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get courseTable => 'Courses';
	@override String get scores => 'Scores';
	@override String get portal => 'Portals';
	@override String get calendar => 'Calendar';
	@override String get profile => 'Me';
	@override String get vote => 'Vote Login';
}

// Path: home
class _Translations$home$en_US extends Translations$home$zh_TW {
	_Translations$home$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$home$projectTattoo$en_US projectTattoo = _Translations$home$projectTattoo$en_US._(_root);
	@override late final _Translations$home$ideation$en_US ideation = _Translations$home$ideation$en_US._(_root);
	@override late final _Translations$home$npcClub$en_US npcClub = _Translations$home$npcClub$en_US._(_root);
	@override late final _Translations$home$vote$en_US vote = _Translations$home$vote$en_US._(_root);
}

// Path: score
class _Translations$score$en_US extends Translations$score$zh_TW {
	_Translations$score$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get loadFailed => 'Failed to load scores';
	@override String get refreshFailed => 'Failed to refresh scores';
	@override String get noRecords => 'No score records found';
	@override String get noScoresThisSemester => 'No scores for this semester';
	@override String courseNumber({required Object number, required Object code}) => 'No: ${number}  Code: ${code}';
	@override String get none => 'N/A';
	@override late final _Translations$score$summary$en_US summary = _Translations$score$summary$en_US._(_root);
	@override late final _Translations$score$status$en_US status = _Translations$score$status$en_US._(_root);
}

// Path: calendar
class _Translations$calendar$en_US extends Translations$calendar$zh_TW {
	_Translations$calendar$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get today => 'Today';
}

// Path: courseTable
class _Translations$courseTable$en_US extends Translations$courseTable$zh_TW {
	_Translations$courseTable$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get notFound => 'Course table not found';
	@override String get unscheduled => 'Unscheduled Courses';
	@override late final _Translations$courseTable$summary$en_US summary = _Translations$courseTable$summary$en_US._(_root);
	@override late final _Translations$courseTable$actions$en_US actions = _Translations$courseTable$actions$en_US._(_root);
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
class _Translations$profile$en_US extends Translations$profile$zh_TW {
	_Translations$profile$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get dataDisclaimer => 'Reference only. Not official.';
	@override late final _Translations$profile$passwordExpiry$en_US passwordExpiry = _Translations$profile$passwordExpiry$en_US._(_root);
	@override late final _Translations$profile$sections$en_US sections = _Translations$profile$sections$en_US._(_root);
	@override late final _Translations$profile$options$en_US options = _Translations$profile$options$en_US._(_root);
	@override late final _Translations$profile$avatar$en_US avatar = _Translations$profile$avatar$en_US._(_root);
	@override late final _Translations$profile$dangerZone$en_US dangerZone = _Translations$profile$dangerZone$en_US._(_root);
}

// Path: scanner
class _Translations$scanner$en_US extends Translations$scanner$zh_TW {
	_Translations$scanner$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'QR Code Login';
	@override String get scanInstruction => 'Place the QR code in the box';
	@override String get loginIStudy => 'Login to iSchool Plus';
	@override String get success => 'Login successful';
	@override String get failed => 'Login failed';
	@override String get processing => 'Processing…';
	@override String get loggingIn => 'Logging in…';
	@override String get permissionDenied => 'Camera permission required to scan QR codes';
	@override String get permissionDeniedDescription => 'Please enable camera access in your device settings and try again.';
	@override String get cameraError => 'Unable to start the camera. Please check your hardware or try again later.';
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
	@override late final _Translations$scanner$guide$en_US guide = _Translations$scanner$guide$en_US._(_root);
	@override String get invalidUrl => 'Invalid URL';
}

// Path: kioskLogin
class _Translations$kioskLogin$en_US extends Translations$kioskLogin$zh_TW {
	_Translations$kioskLogin$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get qrCode => 'login QR code';
	@override String get refresh => 'Regenerate';
	@override String get notice => 'Use the iPad at the voting venue to scan this QR code.\nTo protect your privacy, do not share this QR code with anyone.';
	@override String get loadFailed => 'Unable to generate the login code. Please try again later.';
	@override String get invalidSsoUrl => 'The login URL is invalid. Unable to generate the login code.';
}

// Path: enrollmentStatus
class _Translations$enrollmentStatus$en_US extends Translations$enrollmentStatus$zh_TW {
	_Translations$enrollmentStatus$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get learning => 'Enrolled';
	@override String get leaveOfAbsence => 'Leave of Absence';
	@override String get droppedOut => 'Withdrawn';
}

// Path: about
class _Translations$about$en_US extends Translations$about$zh_TW {
	_Translations$about$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

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
	@override String get openSourceLicenses => 'Open Source Licenses';
	@override String get viewOpenSourceLicenses => 'TAT\'s implementation is made possible by the open source community';
	@override String get copyright => '© 2025 NTUT Programming Club\nLicensed under the GNU GPL v3.0';
}

// Path: featureFlags
class _Translations$featureFlags$en_US extends Translations$featureFlags$zh_TW {
	_Translations$featureFlags$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feature Flags';
	@override String get fetchFlags => 'Fetch from remote';
	@override String get noFlag => 'No Feature Flags';
	@override String get refreshed => 'Feature flags refreshed';
	@override String get reset => 'Reset to default';
	@override late final _Translations$featureFlags$status$en_US status = _Translations$featureFlags$status$en_US._(_root);
	@override String get invalidInput => 'Invalid input';
}

// Path: intro.features
class _Translations$intro$features$en_US extends Translations$intro$features$zh_TW {
	_Translations$intro$features$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$intro$features$courseTable$en_US courseTable = _Translations$intro$features$courseTable$en_US._(_root);
	@override late final _Translations$intro$features$scores$en_US scores = _Translations$intro$features$scores$en_US._(_root);
	@override late final _Translations$intro$features$campusLife$en_US campusLife = _Translations$intro$features$campusLife$en_US._(_root);
}

// Path: login.errors
class _Translations$login$errors$en_US extends Translations$login$errors$zh_TW {
	_Translations$login$errors$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

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

// Path: home.projectTattoo
class _Translations$home$projectTattoo$en_US extends Translations$home$projectTattoo$zh_TW {
	_Translations$home$projectTattoo$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'About Project Tattoo';
	@override String get description => 'Learn more or invite your friends to join the testing program.';
	@override String get url => 'https://ntut.app';
}

// Path: home.ideation
class _Translations$home$ideation$en_US extends Translations$home$ideation$zh_TW {
	_Translations$home$ideation$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Our TAT is under construction';
	@override String get description => 'We\'re collecting ideas for the Home page. Share your proposal with us.';
	@override String get url => 'https://forms.gle/LdQdMfvAfUYyGE4k8';
}

// Path: home.npcClub
class _Translations$home$npcClub$en_US extends Translations$home$npcClub$zh_TW {
	_Translations$home$npcClub$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'NTUT Programming Club';
	@override String get description => 'If you have ideas or want to contribute, feel free to reach out anytime.';
	@override String get url => 'https://ntut.club';
}

// Path: home.vote
class _Translations$home$vote$en_US extends Translations$home$vote$zh_TW {
	_Translations$home$vote$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get description => 'Student four-in-one democratic election voting is open. Come vote at Yida Corridor before 4:00 PM on 5/15.';
}

// Path: score.summary
class _Translations$score$summary$en_US extends Translations$score$summary$zh_TW {
	_Translations$score$summary$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get cumulativeGpa => 'Cumulative GPA';
	@override String get conduct => 'Conduct';
	@override String get semesterAverage => 'Semester Avg';
	@override String get creditsPassed => 'Credits Passed';
	@override String get totalCredits => 'Total Credits';
}

// Path: score.status
class _Translations$score$status$en_US extends Translations$score$status$zh_TW {
	_Translations$score$status$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get notEntered => 'Not entered';
	@override String get withdraw => 'Withdrawn';
	@override String get undelivered => 'Not submitted';
	@override String get pass => 'Pass';
	@override String get fail => 'Fail';
	@override String get creditTransfer => 'Credit transfer';
}

// Path: courseTable.summary
class _Translations$courseTable$summary$en_US extends Translations$courseTable$summary$zh_TW {
	_Translations$courseTable$summary$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String credits({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} credit',
		other: '${count} credits',
	);
	@override String hours({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} hour',
		other: '${count} hours',
	);
}

// Path: courseTable.actions
class _Translations$courseTable$actions$en_US extends Translations$courseTable$actions$zh_TW {
	_Translations$courseTable$actions$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get showMoreOptions => 'Show more options';
	@override String get displayOptions => 'Display options';
}

// Path: profile.passwordExpiry
class _Translations$profile$passwordExpiry$en_US extends Translations$profile$passwordExpiry$zh_TW {
	_Translations$profile$passwordExpiry$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String warning({required num days}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(days,
		one: 'Password expires in 1 day',
		other: 'Password expires in ${days} days',
	);
	@override String get action => 'Change';
}

// Path: profile.sections
class _Translations$profile$sections$en_US extends Translations$profile$sections$zh_TW {
	_Translations$profile$sections$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get accountSettings => 'Account Settings';
	@override String get appSettings => 'App Settings';
	@override String get dangerZone => 'Danger Zone';
}

// Path: profile.options
class _Translations$profile$options$en_US extends Translations$profile$options$zh_TW {
	_Translations$profile$options$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get changePassword => 'Change Password';
	@override String get changeAvatar => 'Change Avatar';
	@override String get supportUs => 'Support Us';
	@override String get about => 'About TAT';
	@override String get npcClub => 'NTUT Programming Club';
	@override String get preferences => 'Preferences';
	@override String get logout => 'Sign Out';
}

// Path: profile.avatar
class _Translations$profile$avatar$en_US extends Translations$profile$avatar$zh_TW {
	_Translations$profile$avatar$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get uploading => 'Updating avatar…';
	@override String get uploadSuccess => 'Avatar updated';
	@override String get tooLarge => 'Image exceeds the 20 MB size limit';
	@override String get invalidFormat => 'Unrecognized image format';
	@override String get uploadFailed => 'Failed to change avatar. Please try again later.';
}

// Path: profile.dangerZone
class _Translations$profile$dangerZone$en_US extends Translations$profile$dangerZone$zh_TW {
	_Translations$profile$dangerZone$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get nonFlutterCrash => 'Non-Flutter Framework Crash';
	@override String get nonFlutterCrashException => 'Simulation of asynchronous error';
	@override String get closedTitle => 'Bar is currently closed';
	@override String get closedMessage => 'The bar is closed today, come back another time to explore!';
	@override String get kickedMessage => 'You were kicked out by the staff. Better head home and rest!';
	@override String get fireMessage => 'Bar is on fire';
	@override String get barOpen => 'The bar is now open';
	@override String get barClosed => 'The bar has closed down';
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
	@override late final _Translations$profile$dangerZone$items$en_US items = _Translations$profile$dangerZone$items$en_US._(_root);
}

// Path: scanner.guide
class _Translations$scanner$guide$en_US extends Translations$scanner$guide$zh_TW {
	_Translations$scanner$guide$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'How to login?';
	@override String get step1 => '1. Go to the following URL on your computer:';
	@override String get url => 'https://i.ntut.club';
	@override String get step2 => '2. Click "Outside school login" in the navigation bar';
	@override String get step3 => '3. Click "Scan QR code"';
	@override String get button => 'Got it';
}

// Path: featureFlags.status
class _Translations$featureFlags$status$en_US extends Translations$featureFlags$status$zh_TW {
	_Translations$featureFlags$status$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get local => 'Local Default';
	@override String get remote => 'Remote Config';
	@override String get localOverride => 'User Override';
	@override String get remoteOverride => 'Forced (Remote)';
}

// Path: intro.features.courseTable
class _Translations$intro$features$courseTable$en_US extends Translations$intro$features$courseTable$zh_TW {
	_Translations$intro$features$courseTable$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Courses';
	@override String get description => 'Quickly view your course schedule and switch between semesters.';
}

// Path: intro.features.scores
class _Translations$intro$features$scores$en_US extends Translations$intro$features$scores$zh_TW {
	_Translations$intro$features$scores$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scores';
	@override String get description => 'Check your grades and credits with integrated historical records.';
}

// Path: intro.features.campusLife
class _Translations$intro$features$campusLife$en_US extends Translations$intro$features$campusLife$zh_TW {
	_Translations$intro$features$campusLife$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Campus Life';
	@override String get description => 'Access campus life information, with more features coming soon.';
}

// Path: profile.dangerZone.items
class _Translations$profile$dangerZone$items$en_US extends Translations$profile$dangerZone$items$zh_TW {
	_Translations$profile$dangerZone$items$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

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
			'general.back' => 'Back',
			'general.ok' => 'OK',
			'general.cancel' => 'Cancel',
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
			'nav.home' => 'Home',
			'nav.courseTable' => 'Courses',
			'nav.scores' => 'Scores',
			'nav.portal' => 'Portals',
			'nav.calendar' => 'Calendar',
			'nav.profile' => 'Me',
			'nav.vote' => 'Vote Login',
			'home.projectTattoo.title' => 'About Project Tattoo',
			'home.projectTattoo.description' => 'Learn more or invite your friends to join the testing program.',
			'home.projectTattoo.url' => 'https://ntut.app',
			'home.ideation.title' => 'Our TAT is under construction',
			'home.ideation.description' => 'We\'re collecting ideas for the Home page. Share your proposal with us.',
			'home.ideation.url' => 'https://forms.gle/LdQdMfvAfUYyGE4k8',
			'home.npcClub.title' => 'NTUT Programming Club',
			'home.npcClub.description' => 'If you have ideas or want to contribute, feel free to reach out anytime.',
			'home.npcClub.url' => 'https://ntut.club',
			'home.vote.description' => 'Student four-in-one democratic election voting is open. Come vote at Yida Corridor before 4:00 PM on 5/15.',
			'score.loadFailed' => 'Failed to load scores',
			'score.refreshFailed' => 'Failed to refresh scores',
			'score.noRecords' => 'No score records found',
			'score.noScoresThisSemester' => 'No scores for this semester',
			'score.courseNumber' => ({required Object number, required Object code}) => 'No: ${number}  Code: ${code}',
			'score.none' => 'N/A',
			'score.summary.cumulativeGpa' => 'Cumulative GPA',
			'score.summary.conduct' => 'Conduct',
			'score.summary.semesterAverage' => 'Semester Avg',
			'score.summary.creditsPassed' => 'Credits Passed',
			'score.summary.totalCredits' => 'Total Credits',
			'score.status.notEntered' => 'Not entered',
			'score.status.withdraw' => 'Withdrawn',
			'score.status.undelivered' => 'Not submitted',
			'score.status.pass' => 'Pass',
			'score.status.fail' => 'Fail',
			'score.status.creditTransfer' => 'Credit transfer',
			'calendar.today' => 'Today',
			'courseTable.notFound' => 'Course table not found',
			'courseTable.unscheduled' => 'Unscheduled Courses',
			'courseTable.summary.credits' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} credit', other: '${count} credits', ), 
			'courseTable.summary.hours' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} hour', other: '${count} hours', ), 
			'courseTable.actions.showMoreOptions' => 'Show more options',
			'courseTable.actions.displayOptions' => 'Display options',
			'courseTable.dayOfWeek.sunday' => 'Sun',
			'courseTable.dayOfWeek.monday' => 'Mon',
			'courseTable.dayOfWeek.tuesday' => 'Tue',
			'courseTable.dayOfWeek.wednesday' => 'Wed',
			'courseTable.dayOfWeek.thursday' => 'Thu',
			'courseTable.dayOfWeek.friday' => 'Fri',
			'courseTable.dayOfWeek.saturday' => 'Sat',
			'profile.dataDisclaimer' => 'Reference only. Not official.',
			'profile.passwordExpiry.warning' => ({required num days}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(days, one: 'Password expires in 1 day', other: 'Password expires in ${days} days', ), 
			'profile.passwordExpiry.action' => 'Change',
			'profile.sections.accountSettings' => 'Account Settings',
			'profile.sections.appSettings' => 'App Settings',
			'profile.sections.dangerZone' => 'Danger Zone',
			'profile.options.changePassword' => 'Change Password',
			'profile.options.changeAvatar' => 'Change Avatar',
			'profile.options.supportUs' => 'Support Us',
			'profile.options.about' => 'About TAT',
			'profile.options.npcClub' => 'NTUT Programming Club',
			'profile.options.preferences' => 'Preferences',
			'profile.options.logout' => 'Sign Out',
			'profile.avatar.uploading' => 'Updating avatar…',
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
			'profile.dangerZone.barOpen' => 'The bar is now open',
			'profile.dangerZone.barClosed' => 'The bar has closed down',
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
			'scanner.processing' => 'Processing…',
			'scanner.loggingIn' => 'Logging in…',
			'scanner.permissionDenied' => 'Camera permission required to scan QR codes',
			'scanner.permissionDeniedDescription' => 'Please enable camera access in your device settings and try again.',
			'scanner.cameraError' => 'Unable to start the camera. Please check your hardware or try again later.',
			'scanner.errors."201"' => 'Mobile login required',
			'scanner.errors."202"' => 'Error occurred. Please go to "Home" and click "Outside school login"',
			'scanner.errors."203"' => 'You are already logged in',
			'scanner.errors."204"' => 'The QR code session has ended. Please refresh the page.',
			'scanner.errors."205"' => 'Already logged in. Log out from the portal first to switch users.',
			'scanner.errors."206"' => 'The QR code has expired. Please refresh the page on your computer.',
			'scanner.errors.unknown' => 'Login failed. Please check the QR code or refresh the page.',
			'scanner.howTo' => 'Open i.ntut.club on your computer and select QR code login',
			'scanner.guide.title' => 'How to login?',
			'scanner.guide.step1' => '1. Go to the following URL on your computer:',
			'scanner.guide.url' => 'https://i.ntut.club',
			'scanner.guide.step2' => '2. Click "Outside school login" in the navigation bar',
			'scanner.guide.step3' => '3. Click "Scan QR code"',
			'scanner.guide.button' => 'Got it',
			'scanner.invalidUrl' => 'Invalid URL',
			'kioskLogin.qrCode' => 'login QR code',
			'kioskLogin.refresh' => 'Regenerate',
			'kioskLogin.notice' => 'Use the iPad at the voting venue to scan this QR code.\nTo protect your privacy, do not share this QR code with anyone.',
			'kioskLogin.loadFailed' => 'Unable to generate the login code. Please try again later.',
			'kioskLogin.invalidSsoUrl' => 'The login URL is invalid. Unable to generate the login code.',
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
			'about.openSourceLicenses' => 'Open Source Licenses',
			'about.viewOpenSourceLicenses' => 'TAT\'s implementation is made possible by the open source community',
			'about.copyright' => '© 2025 NTUT Programming Club\nLicensed under the GNU GPL v3.0',
			'featureFlags.title' => 'Feature Flags',
			'featureFlags.fetchFlags' => 'Fetch from remote',
			'featureFlags.noFlag' => 'No Feature Flags',
			'featureFlags.refreshed' => 'Feature flags refreshed',
			'featureFlags.reset' => 'Reset to default',
			'featureFlags.status.local' => 'Local Default',
			'featureFlags.status.remote' => 'Remote Config',
			'featureFlags.status.localOverride' => 'User Override',
			'featureFlags.status.remoteOverride' => 'Forced (Remote)',
			'featureFlags.invalidInput' => 'Invalid input',
			_ => null,
		};
	}
}
