import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/http.dart';

typedef _PortalApplicationPageDto = ({
  String code,
  String name,
  String? iconUrl,
});

typedef _PortalApplicationCategoryPageDto = ({
  String distinguishedName,
  String name,
  List<_PortalApplicationPageDto> applications,
});

class NtutPortalService implements PortalService {
  static const _chineseLocale = 'zh_TW';
  static const _englishLocale = 'en';
  // The mobile home endpoint is a JSON feed and exposes no locale marker.
  // This category has a stable DN and is translated in both portal locales.
  static const _academicCategoryDnPrefix = 'OU=aa,';
  static const _chineseAcademicCategoryName = '教務系統';
  static const _englishAcademicCategoryName = 'System of Academic Affairs';
  static final _folderCallPattern = RegExp(
    r"apPopupSubEip5\('([^']+)','apMap','([^']*)'\)",
  );

  late final Dio _portalDio;
  Future<void> _portalLocaleOperation = Future.value();
  bool _portalLocaleStateUncertain = false;

  NtutPortalService() {
    // Emulate the NTUT iOS app's HTTP client
    _portalDio = createDio()
      ..options.baseUrl = 'https://app.ntut.edu.tw/'
      ..options.headers = {
        'User-Agent': 'Direk ios App',
        // Prevent keep-alive connection reuse — NTUT servers close their end
        // after multipart uploads, causing stale connection errors.
        'Connection': 'close',
      };
  }

  @override
  Future<UserDto> login(String username, String password) async {
    final response = await _portalDio.post(
      'login.do',
      queryParameters: {
        'muid': username,
        'mpassword': password,
        'thetime': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    final body = jsonDecode(response.data);
    if (!body['success']) {
      final String? errorMsg = body['errorMsg'];
      final bool resetPwd = body['resetPwd'] ?? false;
      throw LoginException(
        switch (errorMsg) {
          final msg? when msg.contains('密碼錯誤') => .wrongCredentials,
          final msg? when msg.contains('已被鎖住') => .accountLocked,
          final msg? when msg.contains('密碼已過期') && resetPwd => .passwordExpired,
          final msg? when msg.contains('驗證手機') => .mobileVerificationRequired,
          _ => .unknown,
        },
        message: errorMsg?.isNotEmpty == true ? errorMsg : null,
      );
    }

    final String? passwordExpiredRemind = body['passwordExpiredRemind'];
    _portalLocaleStateUncertain = false;

    // Normalize empty strings to null for consistency
    String? normalizeEmpty(String? value) =>
        value?.isNotEmpty == true ? value : null;

    return (
      name: normalizeEmpty(body['givenName']),
      avatarFilename: normalizeEmpty(body['userPhoto']),
      email: normalizeEmpty(body['userMail']),
      passwordExpiresInDays: passwordExpiredRemind != null
          ? int.tryParse(passwordExpiredRemind)
          : null,
    );
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _portalDio.post(
      'passwordMdy.do',
      queryParameters: {
        "oldPassword": currentPassword,
        "userPassword": newPassword,
        "pwdForceMdy": "profile",
      },
    );

    final body = jsonDecode(response.data);

    // API returns "success": "false" on failure (note the string "false")
    if (body['success'] != true) {
      throw Exception(
        body['returnMsg'] ?? 'Password change failed. Please try again.',
      );
    }
  }

  @override
  Future<void> changeExpiredPassword(String newPassword) async {
    final response = await _portalDio.post(
      'passwordFirstMdy.do',
      data: {
        'pwdForceMdy': 'expired',
        'userPassword': newPassword,
        'confirmPassword': newPassword,
        'localeId': _chineseLocale,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: const {'X-Requested-With': 'XMLHttpRequest'},
      ),
    );

    final dynamic body;
    if (response.data is String) {
      body = jsonDecode(response.data as String);
    } else {
      body = response.data;
    }

    if (body['success'] != true && body['success'] != 'true') {
      throw Exception(
        body['returnMsg'] ?? 'Password change failed. Please try again.',
      );
    }
  }

  @override
  Future<Uint8List> getAvatar([String? filename]) async {
    final response = await _portalDio.get(
      'photoView.do',
      queryParameters: {'realname': filename ?? ''},
      options: Options(responseType: .bytes),
    );

    final contentType = response.headers.value('content-type') ?? '';
    final mediaType = MediaType.parse(contentType);
    if (mediaType.type != 'image') {
      throw FormatException(
        'Expected image response, got Content-Type: $contentType',
      );
    }

    return response.data;
  }

  @override
  Future<String> uploadAvatar(Uint8List imageBytes, String? oldFilename) async {
    final response = await _portalDio.post(
      'photoUpload.do',
      queryParameters: {
        'uploadQuota': '20', // max file size in MB
        // current avatar filename for server-side cleanup
        'ldapPhoto': oldFilename ?? '',
      },
      data: FormData.fromMap({
        'file[]': MultipartFile.fromBytes(
          imageBytes,
          filename: 'avatar.jpg', // required by server
          contentType: DioMediaType('application', 'octet-stream'),
        ),
      }),
    );

    final body = jsonDecode(response.data);
    return body['ldapPhoto'];
  }

  @override
  Future<void> sso(String serviceCode) {
    return _withPortalLocaleLock(() async {
      final (actionUrl, formData) = await _fetchSsoForm(serviceCode);

      // Prepend the invalid cookie filter interceptor for i-School Plus SSO
      if (serviceCode == PortalServiceCode.iSchoolPlusService.code) {
        _portalDio.interceptors.insert(0, InvalidCookieFilter());
        _portalDio.transformer = PlainTextTransformer();
      }

      // Submit the SSO form and follow redirects
      // Sets the necessary cookies for the target service
      await _portalDio.post(
        actionUrl,
        data: formData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    });
  }

  @override
  Future<Uri> getSsoUrl(String serviceCode) {
    return _withPortalLocaleLock(() async {
      final (actionUrl, formData) = await _fetchSsoForm(serviceCode);

      // Clone and strip RedirectInterceptor so we can capture the 302 Location
      // instead of following it.
      final dioWithoutRedirects = _portalDio.clone()
        ..interceptors.removeWhere(
          (interceptor) => interceptor is RedirectInterceptor,
        );

      final response = await dioWithoutRedirects.post(
        actionUrl,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final location = response.headers.value('location');
      if (location == null) {
        throw Exception('SSO redirect not received. Are you logged in?');
      }

      // The portal may return http:// URLs; upgrade to https://
      var uri = Uri.parse(location);
      if (uri.scheme == 'http') {
        uri = uri.replace(scheme: 'https');
      }
      return uri;
    });
  }

  /// Fetches and parses the SSO form for a given apOu code.
  ///
  /// Returns (actionUrl, formData) for submitting the form.
  Future<(String, Map<String, dynamic>)> _fetchSsoForm(String apOu) async {
    final response = await _portalDio.get(
      'ssoIndex.do',
      queryParameters: {'apOu': apOu},
    );

    final document = parse(response.data);
    final form = document.querySelector('form[name="ssoForm"]');
    if (form == null) {
      throw Exception('SSO form not found. Are you logged in?');
    }

    final actionUrl = form.attributes['action']!;
    final inputs = form.querySelectorAll('input');
    final formData = <String, dynamic>{
      for (final input in inputs)
        if (input.attributes['name'] != null)
          input.attributes['name']!: input.attributes['value'] ?? '',
    };

    return (actionUrl, formData);
  }

  @override
  Future<List<CalendarEventDto>> getCalendar(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final formatter = DateFormat('yyyy/MM/dd');
    final response = await _portalDio.get(
      'calModeApp.do',
      queryParameters: {
        'startDate': formatter.format(startDate),
        'endDate': formatter.format(endDate),
      },
    );

    final List<dynamic> events = jsonDecode(response.data);

    String? normalizeEmpty(String? value) =>
        value?.isNotEmpty == true ? value : null;

    // The portal returns proper Unix epoch ms (e.g. 1753977600000 ↔
    // 2025-08-01 00:00 +08:00). Naively decoding via the device's local
    // timezone would shift the displayed date when the user is outside
    // Taipei — Aug 1 would render as Jul 31 in London. We instead build
    // a UTC DateTime, add 8h, and copy its wall-clock fields into a local
    // DateTime so the result reads as Taipei time regardless of the
    // device's offset (and DST).
    DateTime taipeiWallClock(int ms) {
      final taipei = DateTime.fromMillisecondsSinceEpoch(
        ms,
        isUtc: true,
      ).add(const Duration(hours: 8));
      return DateTime(
        taipei.year,
        taipei.month,
        taipei.day,
        taipei.hour,
        taipei.minute,
        taipei.second,
        taipei.millisecond,
      );
    }

    return events
        .where(
          // Filter out weekend markers
          (e) => e['isHoliday'] != '1',
        )
        .map<CalendarEventDto>(
          (e) => (
            id: e['id'],
            start: taipeiWallClock(e['calStart']),
            end: taipeiWallClock(e['calEnd']),
            allDay: e['allDay'] == '1',
            title: normalizeEmpty(e['calTitle']),
            place: normalizeEmpty(e['calPlace']),
            content: normalizeEmpty(e['calContent']),
            ownerName: normalizeEmpty(e['ownerName']),
            creatorName: normalizeEmpty(e['creatorName']),
          ),
        )
        .toList();
  }

  @override
  Future<List<PortalApplicationCategoryDto>> getApplicationCatalog() {
    return _withPortalLocaleLock(() async {
      final initialResponse = await _getApplicationPage(
        queryParameters: {'init': ''},
      );
      final initialDocument = _parseApplicationPage(initialResponse.data!);
      final originalLocale = _parsePortalLocale(initialDocument);
      var localeMutationAttempted = false;
      Object? operationError;
      try {
        List<_PortalApplicationCategoryPageDto> english = const [];
        late final List<_PortalApplicationCategoryPageDto> chinese;
        if (originalLocale == _englishLocale) {
          try {
            english = await _getApplicationCatalogForCurrentLocale(
              categoryDocument: initialDocument,
            );
          } on SessionExpiredException {
            rethrow;
          } catch (_) {
            // English is optional; continue with the canonical Chinese crawl.
          }
          localeMutationAttempted = true;
          await _setPortalLocale(_chineseLocale);
          chinese = await _getApplicationCatalogForCurrentLocale();
        } else {
          chinese = await _getApplicationCatalogForCurrentLocale(
            categoryDocument: initialDocument,
          );
          localeMutationAttempted = true;
          await _setPortalLocale(_englishLocale);
          try {
            english = await _getApplicationCatalogForCurrentLocale();
          } on SessionExpiredException {
            rethrow;
          } catch (_) {
            // Match CourseService's bilingual behavior: English enriches the
            // canonical Chinese response, but its instability must not make
            // the complete catalog unavailable.
          }
        }

        return _mergeApplicationCatalog(chinese, english);
      } catch (error) {
        operationError = error;
        rethrow;
      } finally {
        if (localeMutationAttempted) {
          try {
            await _setPortalLocale(originalLocale);
          } catch (restoreError, restoreStackTrace) {
            _portalLocaleStateUncertain = true;
            // Preserve the root failure when both the crawl and cleanup fail.
            // If the crawl succeeded, fail the refresh so the repository does
            // not mark an uncertain portal session state as freshly cached.
            if (operationError == null) {
              Error.throwWithStackTrace(restoreError, restoreStackTrace);
            }
          }
        }
      }
    });
  }

  String _parsePortalLocale(Document document) {
    for (final category in _parseApplicationCategories(document)) {
      if (!category.distinguishedName.startsWith(_academicCategoryDnPrefix)) {
        continue;
      }
      return switch (category.name) {
        _chineseAcademicCategoryName => _chineseLocale,
        _englishAcademicCategoryName => _englishLocale,
        _ => throw FormatException(
          'Unknown NTUT Portal academic category name: ${category.name}',
        ),
      };
    }
    throw const FormatException(
      'NTUT Portal academic category was not found.',
    );
  }

  Future<List<_PortalApplicationCategoryPageDto>>
  _getApplicationCatalogForCurrentLocale({Document? categoryDocument}) async {
    final Document document;
    if (categoryDocument case final cached?) {
      document = cached;
    } else {
      final response = await _getApplicationPage(
        queryParameters: {'init': ''},
      );
      document = _parseApplicationPage(response.data!);
    }
    final categories = _parseApplicationCategories(document);
    if (categories.isEmpty) {
      throw const FormatException(
        'No application categories found in NTUT Portal response.',
      );
    }

    final result = <_PortalApplicationCategoryPageDto>[];
    for (final category in categories) {
      final applications = await _getCategoryApplications(
        category.distinguishedName,
        visitedFolders: <String>{},
      );
      result.add((
        distinguishedName: category.distinguishedName,
        name: category.name,
        applications: applications,
      ));
    }
    return result;
  }

  Future<void> _setPortalLocale(String locale) async {
    final response = await _portalDio.post<String>(
      'localeModify.do',
      data: {'localeId': locale},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: .plain,
        headers: const {'X-Requested-With': 'XMLHttpRequest'},
      ),
    );
    final body = response.data?.trim() ?? '';
    _throwIfPortalSessionExpired(body);
    if (body != locale) {
      throw FormatException(
        'NTUT Portal did not confirm locale $locale.',
      );
    }

    final reload = await _portalDio.get<String>(
      'localeReload.do',
      queryParameters: {'locale': body},
      options: Options(responseType: .plain),
    );
    _throwIfPortalSessionExpired(reload.data ?? '');
  }

  Future<T> _withPortalLocaleLock<T>(Future<T> Function() operation) async {
    final previous = _portalLocaleOperation;
    final release = Completer<void>();
    _portalLocaleOperation = release.future;
    await previous;
    try {
      if (_portalLocaleStateUncertain) {
        throw const SessionExpiredException(
          'NTUT Portal locale state could not be restored',
        );
      }
      return await operation();
    } finally {
      release.complete();
    }
  }

  Future<Response<String>> _getApplicationPage({
    required Map<String, dynamic> queryParameters,
  }) {
    return _portalDio.get<String>(
      'apPopupFull.do',
      queryParameters: queryParameters,
      options: Options(
        responseType: .plain,
        headers: const {'X-Requested-With': 'XMLHttpRequest'},
      ),
    );
  }

  Document _parseApplicationPage(String html) {
    _throwIfPortalSessionExpired(html);
    final document = parse(html);
    return document;
  }

  void _throwIfPortalSessionExpired(String body) {
    if (body.contains('請重新登入') ||
        body.contains('您目前已和伺服器中斷連線') ||
        body.contains('You have been disconnected from the server')) {
      throw const SessionExpiredException('NTUT Portal session expired');
    }
  }

  List<({String distinguishedName, String name})> _parseApplicationCategories(
    Document document,
  ) {
    final categories = <({String distinguishedName, String name})>[];
    final seen = <String>{};
    for (final anchor in document.querySelectorAll('a.dropdown-item[href]')) {
      final folder = _parseFolderCall(anchor.attributes['href']);
      if (folder == null ||
          folder.name.trim().isEmpty ||
          !seen.add(folder.distinguishedName)) {
        continue;
      }
      categories.add((
        distinguishedName: folder.distinguishedName,
        name: folder.name.trim(),
      ));
    }
    return categories;
  }

  Future<List<_PortalApplicationPageDto>> _getCategoryApplications(
    String distinguishedName, {
    required Set<String> visitedFolders,
  }) async {
    if (!visitedFolders.add(distinguishedName)) return const [];

    final response = await _getApplicationPage(
      queryParameters: {
        'apView': 'apMap',
        'apDn': distinguishedName,
      },
    );
    final document = _parseApplicationPage(response.data!);
    final applications = <_PortalApplicationPageDto>[];
    final seenCodes = <String>{};

    for (final item in document.querySelectorAll('.apt-icon')) {
      final application = _parseApplication(
        item,
        response.requestOptions.uri,
      );
      if (application != null) {
        if (seenCodes.add(application.code)) applications.add(application);
        continue;
      }

      final folder = _parseFolderCall(item.attributes['onclick']);
      if (folder == null) continue;
      final nested = await _getCategoryApplications(
        folder.distinguishedName,
        visitedFolders: visitedFolders,
      );
      for (final application in nested) {
        if (seenCodes.add(application.code)) applications.add(application);
      }
    }

    return applications;
  }

  _PortalApplicationPageDto? _parseApplication(
    Element item,
    Uri responseUri,
  ) {
    Element? link;
    for (final candidate in item.querySelectorAll('a[href]')) {
      final href = candidate.attributes['href'];
      if (href == null) continue;
      final uri = Uri.tryParse(href);
      final endpoint = uri?.path.split('/').last;
      if (uri == null ||
          (endpoint != 'ssoIndex.do' && endpoint != 'ssoFromOu.do') ||
          !uri.queryParameters.containsKey('apOu')) {
        continue;
      }
      link = candidate;
      break;
    }
    if (link == null) return null;

    final href = Uri.parse(link.attributes['href']!);
    final code = href.queryParameters['apOu'];
    if (code == null || code.isEmpty) return null;

    final name =
        item
            .querySelector('[data-bs-original-title]')
            ?.attributes['data-bs-original-title']
            ?.trim() ??
        item.querySelector('[title]')?.attributes['title']?.trim() ??
        link.text.trim();
    if (name.isEmpty) return null;

    final iconPath = item.querySelector('img[src]')?.attributes['src'];
    return (
      code: code,
      name: name,
      iconUrl: iconPath == null || iconPath.isEmpty
          ? null
          : responseUri.resolve(iconPath).toString(),
    );
  }

  List<PortalApplicationCategoryDto> _mergeApplicationCatalog(
    List<_PortalApplicationCategoryPageDto> chinese,
    List<_PortalApplicationCategoryPageDto> english,
  ) {
    final englishByDn = {
      for (final category in english) category.distinguishedName: category,
    };
    final englishApplicationsByCode = {
      for (final category in english)
        for (final application in category.applications)
          application.code: application,
    };
    return [
      for (final category in chinese)
        _mergeApplicationCategory(
          chinese: category,
          english: englishByDn[category.distinguishedName],
          englishApplicationsByCode: englishApplicationsByCode,
        ),
    ];
  }

  PortalApplicationCategoryDto _mergeApplicationCategory({
    required _PortalApplicationCategoryPageDto chinese,
    _PortalApplicationCategoryPageDto? english,
    required Map<String, _PortalApplicationPageDto> englishApplicationsByCode,
  }) {
    return (
      distinguishedName: chinese.distinguishedName,
      nameZh: chinese.name,
      nameEn: english?.name,
      applications: [
        for (final application in chinese.applications)
          (
            code: application.code,
            nameZh: application.name,
            nameEn: englishApplicationsByCode[application.code]?.name,
            iconUrl: application.iconUrl,
          ),
      ],
    );
  }

  ({String distinguishedName, String name})? _parseFolderCall(
    String? script,
  ) {
    if (script == null) return null;
    final match = _folderCallPattern.firstMatch(script);
    if (match == null) return null;
    return (
      distinguishedName: match.group(1)!,
      name: match.group(2)!,
    );
  }
}
