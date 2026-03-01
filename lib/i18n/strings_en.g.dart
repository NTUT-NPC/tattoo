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
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsGeneralEn general = _TranslationsGeneralEn._(_root);
	@override late final _TranslationsErrorsEn errors = _TranslationsErrorsEn._(_root);
	@override late final _TranslationsIntroEn intro = _TranslationsIntroEn._(_root);
	@override late final _TranslationsLoginEn login = _TranslationsLoginEn._(_root);
	@override late final _TranslationsNavEn nav = _TranslationsNavEn._(_root);
	@override late final _TranslationsProfileEn profile = _TranslationsProfileEn._(_root);
	@override late final _TranslationsEnrollmentStatusEn enrollmentStatus = _TranslationsEnrollmentStatusEn._(_root);
}

// Path: general
class _TranslationsGeneralEn extends TranslationsGeneralZhTw {
	_TranslationsGeneralEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get appTitle => 'Project Tattoo';
	@override String get notImplemented => 'Not implemented';
	@override String get dataDisclaimer => 'For reference only';
	@override String get student => 'Student';
	@override String get unknown => 'Unknown';
	@override String get notLoggedIn => 'Not logged in';
	@override String get ok => 'OK';
}

// Path: errors
class _TranslationsErrorsEn extends TranslationsErrorsZhTw {
	_TranslationsErrorsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get occurred => 'An error occurred';
	@override String get sessionExpired => 'Session expired. Please sign in again.';
	@override String get credentialsInvalid => 'Credentials are no longer valid. Please sign in again.';
	@override String get connectionFailed => 'Cannot connect to the server. Please check your network connection.';
}

// Path: intro
class _TranslationsIntroEn extends TranslationsIntroZhTw {
	_TranslationsIntroEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsIntroFeaturesEn features = _TranslationsIntroFeaturesEn._(_root);
	@override String get developedBy => 'Developed by NTUT NPC Club\nAll information is for reference only. Please refer to the official university system.';
	@override String get kContinue => 'Continue';
}

// Path: login
class _TranslationsLoginEn extends TranslationsLoginZhTw {
	_TranslationsLoginEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
	@override late final _TranslationsLoginErrorsEn errors = _TranslationsLoginErrorsEn._(_root);
}

// Path: nav
class _TranslationsNavEn extends TranslationsNavZhTw {
	_TranslationsNavEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get courseTable => 'Courses';
	@override String get scores => 'Scores';
	@override String get profile => 'Me';
}

// Path: profile
class _TranslationsProfileEn extends TranslationsProfileZhTw {
	_TranslationsProfileEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsProfileSectionsEn sections = _TranslationsProfileSectionsEn._(_root);
	@override late final _TranslationsProfileOptionsEn options = _TranslationsProfileOptionsEn._(_root);
	@override late final _TranslationsProfileNoticesEn notices = _TranslationsProfileNoticesEn._(_root);
	@override late final _TranslationsProfileAvatarEn avatar = _TranslationsProfileAvatarEn._(_root);
	@override String get dataDisclaimer => 'For reference only. Not valid as official documentation.';
}

// Path: enrollmentStatus
class _TranslationsEnrollmentStatusEn extends TranslationsEnrollmentStatusZhTw {
	_TranslationsEnrollmentStatusEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get learning => 'Enrolled';
	@override String get leaveOfAbsence => 'Leave of Absence';
	@override String get droppedOut => 'Withdrawn';
}

// Path: intro.features
class _TranslationsIntroFeaturesEn extends TranslationsIntroFeaturesZhTw {
	_TranslationsIntroFeaturesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsIntroFeaturesCourseTableEn courseTable = _TranslationsIntroFeaturesCourseTableEn._(_root);
	@override late final _TranslationsIntroFeaturesScoresEn scores = _TranslationsIntroFeaturesScoresEn._(_root);
	@override late final _TranslationsIntroFeaturesCampusLifeEn campusLife = _TranslationsIntroFeaturesCampusLifeEn._(_root);
}

// Path: login.errors
class _TranslationsLoginErrorsEn extends TranslationsLoginErrorsZhTw {
	_TranslationsLoginErrorsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get emptyFields => 'Please enter your student ID and password';
	@override String get useStudentId => 'Please use your student ID to sign in, not an email address';
	@override String get loginFailed => 'Login failed. Please verify your credentials.';
}

// Path: profile.sections
class _TranslationsProfileSectionsEn extends TranslationsProfileSectionsZhTw {
	_TranslationsProfileSectionsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get accountSettings => 'Account Settings';
	@override String get appSettings => 'App Settings';
	@override String get notices => 'Notices';
}

// Path: profile.options
class _TranslationsProfileOptionsEn extends TranslationsProfileOptionsZhTw {
	_TranslationsProfileOptionsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get changePassword => 'Change Password';
	@override String get changeAvatar => 'Change Avatar';
	@override String get supportUs => 'Support Us';
	@override String get about => 'About TAT';
	@override String get npcClub => 'NTUT NPC Club';
	@override String get preferences => 'Preferences';
	@override String get logout => 'Sign Out';
}

// Path: profile.notices
class _TranslationsProfileNoticesEn extends TranslationsProfileNoticesZhTw {
	_TranslationsProfileNoticesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get betaTesting => 'The new version of TAT is still in beta. Please report any issues you encounter.';
	@override String get passwordExpiring => 'Your password will expire in 7 days. Please update it to avoid being locked out.';
	@override String get connectionError => 'Cannot connect to the server. Data may be inaccurate.';
}

// Path: profile.avatar
class _TranslationsProfileAvatarEn extends TranslationsProfileAvatarZhTw {
	_TranslationsProfileAvatarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get uploading => 'Updating avatar...';
	@override String get uploadSuccess => 'Avatar updated';
	@override String get tooLarge => 'Image exceeds the 20 MB size limit';
	@override String get invalidFormat => 'Unrecognized image format';
	@override String get uploadFailed => 'Failed to change avatar. Please try again later.';
}

// Path: intro.features.courseTable
class _TranslationsIntroFeaturesCourseTableEn extends TranslationsIntroFeaturesCourseTableZhTw {
	_TranslationsIntroFeaturesCourseTableEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Courses';
	@override String get description => 'Quickly view your course schedule and switch between semesters.';
}

// Path: intro.features.scores
class _TranslationsIntroFeaturesScoresEn extends TranslationsIntroFeaturesScoresZhTw {
	_TranslationsIntroFeaturesScoresEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scores';
	@override String get description => 'Check your grades and credits with integrated historical records.';
}

// Path: intro.features.campusLife
class _TranslationsIntroFeaturesCampusLifeEn extends TranslationsIntroFeaturesCampusLifeZhTw {
	_TranslationsIntroFeaturesCampusLifeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Campus Life';
	@override String get description => 'Access campus life information, with more features coming soon.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'general.appTitle' => 'Project Tattoo',
			'general.notImplemented' => 'Not implemented',
			'general.dataDisclaimer' => 'For reference only',
			'general.student' => 'Student',
			'general.unknown' => 'Unknown',
			'general.notLoggedIn' => 'Not logged in',
			'general.ok' => 'OK',
			'errors.occurred' => 'An error occurred',
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
			'nav.courseTable' => 'Courses',
			'nav.scores' => 'Scores',
			'nav.profile' => 'Me',
			'profile.sections.accountSettings' => 'Account Settings',
			'profile.sections.appSettings' => 'App Settings',
			'profile.sections.notices' => 'Notices',
			'profile.options.changePassword' => 'Change Password',
			'profile.options.changeAvatar' => 'Change Avatar',
			'profile.options.supportUs' => 'Support Us',
			'profile.options.about' => 'About TAT',
			'profile.options.npcClub' => 'NTUT NPC Club',
			'profile.options.preferences' => 'Preferences',
			'profile.options.logout' => 'Sign Out',
			'profile.notices.betaTesting' => 'The new version of TAT is still in beta. Please report any issues you encounter.',
			'profile.notices.passwordExpiring' => 'Your password will expire in 7 days. Please update it to avoid being locked out.',
			'profile.notices.connectionError' => 'Cannot connect to the server. Data may be inaccurate.',
			'profile.avatar.uploading' => 'Updating avatar...',
			'profile.avatar.uploadSuccess' => 'Avatar updated',
			'profile.avatar.tooLarge' => 'Image exceeds the 20 MB size limit',
			'profile.avatar.invalidFormat' => 'Unrecognized image format',
			'profile.avatar.uploadFailed' => 'Failed to change avatar. Please try again later.',
			'profile.dataDisclaimer' => 'For reference only. Not valid as official documentation.',
			'enrollmentStatus.learning' => 'Enrolled',
			'enrollmentStatus.leaveOfAbsence' => 'Leave of Absence',
			'enrollmentStatus.droppedOut' => 'Withdrawn',
			_ => null,
		};
	}
}
