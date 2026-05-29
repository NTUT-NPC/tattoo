// Captures raw NTUT HTML/XML responses for parser development.
//
// Usage:
//   dart run tool/html_snapshot.dart list
//   dart run tool/html_snapshot.dart capture student_query.profile
//   dart run tool/html_snapshot.dart capture student_query.profile course.semester_list
//   dart run tool/html_snapshot.dart capture -a
//   dart run tool/html_snapshot.dart raw course/tw/Select.jsp --service course

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/src/transformers/util/consolidate_bytes.dart'; // ignore: implementation_imports
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';

part 'html_snapshot_http.dart';
part 'html_snapshot_presets.dart';

const _defaultConfigPath = 'test/test_config.json';
const _defaultOutputDir = 'tmp/html_snapshot';

void main(List<String> args) async {
  final runner =
      SnapshotCommandRunner(
          'html_snapshot',
          'Capture raw NTUT HTML/XML pages for parser development.',
        )
        ..addCommand(ListPresetsCommand())
        ..addCommand(CaptureCommand())
        ..addCommand(RawCommand());

  try {
    exitCode = await runner.run(args) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  } on CliException catch (error) {
    stderr.writeln(error.message);
    exitCode = error.code;
  } on DioException catch (error) {
    stderr.writeln(_formatDioException(error));
    exitCode = 1;
  }
}

class SnapshotCommandRunner extends CommandRunner<int> {
  SnapshotCommandRunner(super.executableName, super.description);

  @override
  String get usageFooter {
    return [
      'Common usage:',
      '  dart run tool/html_snapshot.dart capture <preset> [<preset>...]',
      '  dart run tool/html_snapshot.dart capture -a',
      '  dart run tool/html_snapshot.dart list',
      '  dart run tool/html_snapshot.dart raw <path-or-url> --service <service>',
      '',
      'Run `dart run tool/html_snapshot.dart list` to see available presets.',
    ].join('\n');
  }
}

class ListPresetsCommand extends Command<int> {
  @override
  final name = 'list';

  @override
  final description = 'List available capture presets.';

  @override
  int run() {
    stdout.writeln('Available presets:');
    for (final preset in _presets.values) {
      stdout.writeln(
        '  ${preset.name.padRight(38)} ${preset.description}',
      );
    }
    return 0;
  }
}

class CaptureCommand extends SnapshotCommand {
  CaptureCommand() {
    addCommonOptions(argParser);
    argParser
      ..addFlag(
        'all',
        abbr: 'a',
        negatable: false,
        help: 'Capture all presets that do not require explicit identifiers.',
      )
      ..addOption('year', help: 'Course ROC year, e.g. 114.')
      ..addOption('term', help: 'Course term, e.g. 1 or 2.')
      ..addOption('course-id', help: 'Course catalog ID for course.detail.')
      ..addOption('teacher-id', help: 'Teacher ID for teacher presets.')
      ..addOption('classroom-id', help: 'Classroom ID for course.classroom.')
      ..addOption('course-number', help: 'Course offering number.')
      ..addOption('syllabus-id', help: 'Syllabus ID for course.syllabus.')
      ..addOption('course-internal-id', help: 'Internal iSchool+ course ID.');
  }

  @override
  final name = 'capture';

  @override
  final description = 'Capture a known Service-layer HTML/XML preset.';

  @override
  String get invocation =>
      '${runner!.executableName} $name <preset> [<preset>...] [arguments]';

  @override
  String get usageFooter {
    return [
      'Preset names are positional arguments and can be repeated.',
      '',
      'Examples:',
      '  dart run tool/html_snapshot.dart capture student_query.profile',
      '  dart run tool/html_snapshot.dart capture student_query.profile course.semester_list',
      '  dart run tool/html_snapshot.dart capture -a',
      '',
      'Run `dart run tool/html_snapshot.dart list` to see available presets.',
    ].join('\n');
  }

  @override
  Future<int> run() async {
    if (argResults!.flag('all')) {
      if (argResults!.rest.isNotEmpty) {
        throw UsageException(
          'Do not pass <preset> when using --all/-a.',
          usage,
        );
      }
      return _captureAll();
    }

    final presetNames = argResults!.rest;
    if (presetNames.length == 1 && presetNames.single == 'all') {
      return _captureAll();
    }

    if (presetNames.isEmpty) {
      throw UsageException('Expected at least one <preset>.', usage);
    }

    final presets = <SnapshotPreset>[];
    for (final presetName in presetNames) {
      final preset = _presets[presetName];
      if (preset == null) {
        throw UsageException(
          'Unknown preset: $presetName\nRun `dart run tool/html_snapshot.dart list` to see available presets.',
          usage,
        );
      }
      presets.add(preset);
    }

    return _capturePresets(presets);
  }

  Future<int> _capturePresets(List<SnapshotPreset> presets) async {
    final context = await createContext();
    final failures = <String>[];
    for (final preset in presets) {
      stdout.writeln('');
      stdout.writeln('Capturing ${preset.name}...');
      try {
        await context.ensureSso(preset.service);
        final snapshot = await preset.capture(context, argResults!);
        await writeSnapshot(snapshot);
      } on DioException catch (error) {
        final message = _formatDioException(error);
        failures.add('${preset.name}: $message');
        stderr.writeln('Failed ${preset.name}:\n${_indent(message)}');
      } on Object catch (error) {
        failures.add('${preset.name}: $error');
        stderr.writeln('Failed ${preset.name}: $error');
      }
    }

    if (presets.length > 1 || failures.isNotEmpty) {
      stdout.writeln('');
      final successfulCount = presets.length - failures.length;
      stdout.writeln(
        'Finished capture: $successfulCount succeeded, ${failures.length} failed.',
      );
    }
    return failures.isEmpty ? 0 : 1;
  }

  Future<int> _captureAll() async {
    final allPresets = _presetList
        .where((preset) => preset.includeInAll)
        .toList(growable: false);
    final skippedPresets = _presetList
        .where((preset) => !preset.includeInAll)
        .toList(growable: false);

    stdout.writeln(
      'Capturing ${allPresets.length} preset(s) that can be resolved automatically.',
    );
    if (skippedPresets.isNotEmpty) {
      stdout.writeln('Skipping presets that require explicit identifiers:');
      for (final preset in skippedPresets) {
        stdout.writeln(
          '  ${preset.name.padRight(38)} ${preset.allSkipReason ?? 'requires explicit options'}',
        );
      }
    }

    return _capturePresets(allPresets);
  }
}

class RawCommand extends SnapshotCommand {
  RawCommand() {
    addCommonOptions(argParser);
    argParser
      ..addOption(
        'service',
        allowed: SnapshotService.cliNames,
        mandatory: true,
        help: 'Service client configuration to use.',
      )
      ..addOption(
        'method',
        defaultsTo: 'GET',
        allowed: ['GET', 'POST'],
        help: 'HTTP method.',
      )
      ..addMultiOption(
        'query',
        help: 'Query parameter as key=value. Can be repeated.',
        valueHelp: 'key=value',
      )
      ..addMultiOption(
        'data',
        help: 'POST form field as key=value. Can be repeated.',
        valueHelp: 'key=value',
      )
      ..addOption('body', help: 'Raw request body for POST requests.')
      ..addOption('content-type', help: 'Request Content-Type header.')
      ..addOption(
        'sso',
        allowed: ['none', ...SnapshotService.ssoCliNames],
        help: 'SSO target. Defaults to the selected service when needed.',
      );
  }

  @override
  final name = 'raw';

  @override
  final description =
      'Capture a custom request using known NTUT service clients.';

  @override
  String get invocation =>
      '${runner!.executableName} $name <path-or-url> --service <service> [arguments]';

  @override
  Future<int> run() async {
    final target = _singleRestValue('path-or-url');
    final service = SnapshotService.byCliName(argResults!['service']);
    if (service == null) {
      throw CliException('Unknown service: ${argResults!['service']}');
    }

    final sso = _resolveRawSso(service, argResults!['sso']);
    final context = await createContext();
    if (sso != null) {
      await context.ensureSso(sso);
    }

    final request = RawRequest(
      target: target,
      service: service,
      method: argResults!['method'],
      query: _parseKeyValueOptions(argResults!.multiOption('query')),
      formData: _parseKeyValueOptions(argResults!.multiOption('data')),
      body: argResults!['body'],
      contentType: argResults!['content-type'],
    );
    final snapshot = await _captureRaw(context, request);
    await writeSnapshot(snapshot);
    return 0;
  }
}

abstract class SnapshotCommand extends Command<int> {
  void addCommonOptions(ArgParser parser) {
    parser
      ..addOption(
        'config',
        defaultsTo: _defaultConfigPath,
        help: 'Path to test config JSON.',
      )
      ..addOption(
        'output-dir',
        defaultsTo: _defaultOutputDir,
        help: 'Directory for captured snapshots.',
      )
      ..addOption(
        'name',
        help: 'Extra slug to include in the output file name.',
      );
  }

  Future<SnapshotContext> createContext() async {
    final credentials = TestCredentials.load(argResults!['config']);
    final context = SnapshotContext(credentials);
    await context.login();
    return context;
  }

  Future<void> writeSnapshot(Snapshot snapshot) async {
    final outputDir = argResults!['output-dir'];
    final extraName = argResults!['name'];
    final file = await snapshot.writeTo(
      outputDir: outputDir,
      extraName: extraName,
    );

    stdout.writeln('Captured ${snapshot.label}');
    stdout.writeln('Wrote ${file.absolute.path}');
    stdout.writeln(
      'Do not commit this raw snapshot. De-identify it before promoting it to a fixture.',
    );
  }

  String _singleRestValue(String label) {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException('Expected exactly one <$label>.', usage);
    }
    return rest.single;
  }
}

class TestCredentials {
  final String username;
  final String password;

  const TestCredentials({
    required this.username,
    required this.password,
  });

  factory TestCredentials.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw CliException(_missingConfigMessage(path));
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      throw CliException('Invalid JSON in $path: ${error.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw CliException('Invalid config in $path: expected a JSON object.');
    }

    final username = decoded['NTUT_TEST_USERNAME'];
    final password = decoded['NTUT_TEST_PASSWORD'];
    if (username is! String ||
        username.isEmpty ||
        password is! String ||
        password.isEmpty) {
      throw CliException(_missingConfigMessage(path));
    }

    return TestCredentials(username: username, password: password);
  }
}

class SnapshotContext {
  final TestCredentials credentials;
  final _PortalClient _portal;
  final _clients = <SnapshotService, Dio>{};
  final _ssoTargets = <SnapshotService>{};

  SnapshotContext(this.credentials) : _portal = _PortalClient();

  Future<void> login() async {
    await _portal.login(credentials.username, credentials.password);
  }

  Future<void> ensureSso(SnapshotService service) async {
    if (service == .portal || _ssoTargets.contains(service)) {
      return;
    }
    await _portal.sso(service);
    _ssoTargets.add(service);
  }

  Dio client(SnapshotService service) {
    return _clients.putIfAbsent(service, () => _createDio(service));
  }

  Future<Response> send(
    SnapshotRequest request, {
    bool ensureSession = true,
  }) async {
    if (ensureSession) {
      await ensureSso(request.service);
    }
    return client(request.service).request(
      request.path,
      queryParameters: request.query,
      data: request.data,
      options: Options(
        method: request.method,
        contentType: request.contentType,
      ),
    );
  }
}

class _PortalClient {
  final Dio _dio = _createDio(.portal);

  Future<void> login(String username, String password) async {
    final response = await _dio.post(
      'login.do',
      queryParameters: {'muid': username, 'mpassword': password},
    );

    final body = _decodeJsonObject(response.data);
    if (body['success'] != true) {
      final message = body['errorMsg'];
      throw CliException(
        'Login failed${message is String && message.isNotEmpty ? ': $message' : '.'}',
      );
    }
  }

  Future<void> sso(SnapshotService service) async {
    final serviceCode = service.ssoCode;
    if (serviceCode == null) return;

    final (actionUrl, formData) = await _fetchSsoForm(serviceCode);

    if (service == .ischool) {
      _dio.interceptors.insert(0, _InvalidCookieFilter());
      _dio.transformer = _PlainTextTransformer();
    }

    await _dio.post(
      actionUrl,
      data: formData,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<(String, Map<String, dynamic>)> _fetchSsoForm(
    String serviceCode,
  ) async {
    final response = await _dio.get(
      'ssoIndex.do',
      queryParameters: {'apOu': serviceCode},
    );

    final document = parse(response.data);
    final form = document.querySelector('form[name="ssoForm"]');
    if (form == null) {
      throw CliException('SSO form not found. Are the credentials valid?');
    }

    final actionUrl = form.attributes['action'];
    if (actionUrl == null || actionUrl.isEmpty) {
      throw CliException('SSO form action is missing.');
    }

    final formData = <String, dynamic>{};
    for (final input in form.querySelectorAll('input')) {
      if (input.attributes['name'] case final name?) {
        formData[name] = input.attributes['value'] ?? '';
      }
    }

    return (actionUrl, formData);
  }
}

class SnapshotPreset {
  final String name;
  final SnapshotService service;
  final String description;
  final bool includeInAll;
  final String? allSkipReason;
  final Future<SnapshotRequest> Function(
    SnapshotContext context,
    ArgResults args,
  )
  buildRequest;

  const SnapshotPreset({
    required this.name,
    required this.service,
    required this.description,
    required this.buildRequest,
    this.includeInAll = false,
    this.allSkipReason,
  });

  Future<Snapshot> capture(SnapshotContext context, ArgResults args) async {
    final request = await buildRequest(context, args);
    return _captureRequest(
      context,
      label: name,
      request: request,
    );
  }
}

class Snapshot {
  final SnapshotService service;
  final String label;
  final String body;
  final String extension;
  final List<String> fileParts;

  const Snapshot({
    required this.service,
    required this.label,
    required this.body,
    required this.extension,
    required this.fileParts,
  });

  Future<File> writeTo({
    required String outputDir,
    required String? extraName,
  }) async {
    final normalizedExtraName = extraName?.isNotEmpty == true
        ? extraName
        : null;
    final timestamp = _formatTimestamp(.now());
    final parts = [
      _serviceFilePrefix(service),
      ...fileParts,
      ?normalizedExtraName,
      timestamp,
    ].map(_slug).where((part) => part.isNotEmpty).toList();

    final file = File('$outputDir/${parts.join('_')}.$extension');
    file.parent.createSync(recursive: true);
    await file.writeAsString(body);
    return file;
  }
}

class SnapshotRequest {
  final SnapshotService service;
  final String path;
  final String extension;
  final String method;
  final Map<String, dynamic>? query;
  final Object? data;
  final String? contentType;
  final List<String> fileParts;
  final List<SnapshotRequest> beforeRequests;

  const SnapshotRequest({
    required this.service,
    required this.path,
    this.extension = 'html',
    this.method = 'GET',
    this.query,
    this.data,
    this.contentType,
    this.fileParts = const [],
    this.beforeRequests = const [],
  });
}

class RawRequest {
  final String target;
  final SnapshotService service;
  final String method;
  final Map<String, String> query;
  final Map<String, String> formData;
  final String? body;
  final String? contentType;

  const RawRequest({
    required this.target,
    required this.service,
    required this.method,
    required this.query,
    required this.formData,
    required this.body,
    required this.contentType,
  });
}

Future<Snapshot> _captureRaw(
  SnapshotContext context,
  RawRequest request,
) async {
  final targetUri = Uri.tryParse(request.target);
  if (targetUri != null && targetUri.hasScheme) {
    _validateAbsoluteUri(request.service, targetUri);
  }

  final data = switch ((request.body, request.formData.isNotEmpty)) {
    (final body?, _) => body,
    (null, true) => request.formData,
    (null, false) => null,
  };

  final contentType =
      request.contentType ??
      (request.formData.isNotEmpty ? Headers.formUrlEncodedContentType : null);
  final response = await context.send(
    SnapshotRequest(
      service: request.service,
      path: request.target,
      method: request.method,
      query: request.query,
      data: data,
      contentType: contentType,
    ),
    ensureSession: false,
  );

  final extension = _extensionFromResponse(response);
  return Snapshot(
    service: request.service,
    label: 'raw ${request.target}',
    body: _responseBodyAsString(response.data),
    extension: extension,
    fileParts: ['raw', _rawTargetSlug(request.target)],
  );
}

class CourseSessionCheckInterceptor extends Interceptor {
  static const _markers = ['尚未登錄入口網站', '應用系統連線已逾時'];

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is String && _markers.any(data.contains)) {
      throw CliException('CourseService session expired.');
    }
    handler.next(response);
  }
}

class StudentQuerySessionCheckInterceptor extends Interceptor {
  static const _marker = '應用系統已中斷連線';

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is String && data.contains(_marker)) {
      throw CliException('StudentQuery session expired.');
    }
    handler.next(response);
  }
}

class ISchoolSessionCheckInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 403) {
      throw CliException('ISchoolPlus session expired.');
    }
    handler.next(err);
  }
}

Map<String, dynamic> _decodeJsonObject(Object? data) {
  final decoded = switch (data) {
    final String text => jsonDecode(text),
    final Map<String, dynamic> map => map,
    _ => throw CliException('Expected JSON object, got ${data.runtimeType}.'),
  };
  if (decoded is! Map<String, dynamic>) {
    throw CliException('Expected JSON object, got ${decoded.runtimeType}.');
  }
  return decoded;
}

String _responseBodyAsString(Object? data) {
  return switch (data) {
    final String text => text,
    final Uint8List bytes => utf8.decode(bytes, allowMalformed: true),
    final List<int> bytes => utf8.decode(bytes, allowMalformed: true),
    null => '',
    _ => jsonEncode(data),
  };
}

Map<String, String> _parseKeyValueOptions(List<String> values) {
  final result = <String, String>{};
  for (final value in values) {
    final index = value.indexOf('=');
    if (index <= 0) {
      throw CliException('Expected key=value, got `$value`.');
    }
    final key = value.substring(0, index);
    final mapValue = value.substring(index + 1);
    result[key] = mapValue;
  }
  return result;
}

SnapshotService? _resolveRawSso(SnapshotService service, String? value) {
  if (value == null) {
    return service.ssoCode == null ? null : service;
  }
  if (value == 'none') return null;
  final sso = SnapshotService.byCliName(value);
  if (sso == null || sso.ssoCode == null) {
    throw CliException('Invalid SSO target: $value');
  }
  return sso;
}

void _validateAbsoluteUri(SnapshotService service, Uri uri) {
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw CliException('Only HTTP and HTTPS URLs are supported.');
  }
  if (uri.host != service.host) {
    throw CliException(
      'URL host ${uri.host} does not match --service ${service.cliName} (${service.host}).',
    );
  }
}

String _extensionFromResponse(Response response) {
  final contentType =
      response.headers.value(HttpHeaders.contentTypeHeader) ?? '';
  if (contentType.toLowerCase().contains('xml')) return 'xml';
  final path = response.requestOptions.uri.path.toLowerCase();
  if (path.endsWith('.xml')) return 'xml';
  return 'html';
}

String _formatDioException(DioException error) {
  final response = error.response;
  final status = response?.statusCode;
  final uri = error.requestOptions.uri;
  final statusLine = status == null ? null : 'Status: $status';
  return [
    'HTTP request failed: ${error.requestOptions.method} $uri',
    ?statusLine,
    'Type: ${error.type.name}',
    ?error.message,
  ].join('\n');
}

String _indent(String value) {
  return value
      .split('\n')
      .map((line) => line.isEmpty ? line : '  $line')
      .join('\n');
}

String _requiredOption(ArgResults args, String name) {
  final value = args[name];
  if (value is! String || value.isEmpty) {
    throw CliException('Missing required --$name.');
  }
  return value;
}

int _parseIntOption(String name, String value) {
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw CliException('--$name must be an integer, got `$value`.');
  }
  return parsed;
}

String _shortPresetName(String presetName) {
  return presetName.split('.').last;
}

String _serviceFilePrefix(SnapshotService service) {
  return switch (service) {
    .portal => 'portal',
    .course => 'course',
    .studentQuery => 'sq',
    .ischool => 'ischool',
  };
}

String _rawTargetSlug(String target) {
  final uri = Uri.tryParse(target);
  final path = uri?.pathSegments
      .where((segment) => segment.isNotEmpty)
      .join('_');
  if (path != null && path.isNotEmpty) return path;
  return target;
}

String _slug(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

String _formatTimestamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return [
    time.year.toString().padLeft(4, '0'),
    two(time.month),
    two(time.day),
    '_',
    two(time.hour),
    two(time.minute),
    two(time.second),
  ].join();
}

String _missingConfigMessage(String path) {
  return '''
Missing or incomplete test credentials: $path

Create the config file before running this tool:
  copy test\\test_config.json.example test\\test_config.json

Then fill in:
{
  "NTUT_TEST_USERNAME": "your_student_id",
  "NTUT_TEST_PASSWORD": "your_password"
}
''';
}

class CliException implements Exception {
  final String message;
  final int code;

  const CliException(this.message, [this.code = 1]);
}
