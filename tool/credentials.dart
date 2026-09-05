// Cross-platform credential management and environment configuration tool.
//
// Fetches and decrypts credentials from the shared credentials Git repository,
// and generates environment-specific build configurations (such as AppConfig.xcconfig).
// Compatible with the match_keystore encryption format (AES-256-CBC, PBKDF2).
//
// Usage:
//   dart run tool/credentials.dart fetch [--env=dev|--env=prod]
//   dart run tool/credentials.dart configure [--env=dev|--env=prod]
//   dart run tool/credentials.dart generate [--env=dev|--env=prod]
//   dart run tool/credentials.dart validate
//   dart run tool/credentials.dart encrypt <source-file> <dest-path-in-repo>

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

const _saltHeader = 'Salted__';
const _pbkdf2Iterations = 10000;
const _keyLength = 32;
const _ivLength = 16;

// Where to clone the credentials repo (already in .gitignore via .dart_tool/)
const _repoDir = '.dart_tool/credentials';

// ---------------------------------------------------------------------------
// Environment Configuration Model
// ---------------------------------------------------------------------------

class EnvironmentConfig {
  final String name;
  final String flavor;
  final String appName;
  final String androidAppId;
  final String androidAppName;
  final String androidIcon;
  final String? androidResDir;
  final String androidGoogleServicesPath;
  final String iosBundleId;
  final String iosDisplayName;
  final String iosAppIconName;
  final String iosGoogleServiceInfoPath;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final String? firebaseAndroidAppId;
  final String? firebaseIosAppId;

  EnvironmentConfig({
    required this.name,
    required this.flavor,
    required this.appName,
    required this.androidAppId,
    required this.androidAppName,
    required this.androidIcon,
    this.androidResDir,
    required this.androidGoogleServicesPath,
    required this.iosBundleId,
    required this.iosDisplayName,
    required this.iosAppIconName,
    required this.iosGoogleServiceInfoPath,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    this.firebaseAndroidAppId,
    this.firebaseIosAppId,
  });

  factory EnvironmentConfig.fromJson(Map<String, dynamic> json) {
    void requireKey(Map<String, dynamic> map, String key, String context) {
      if (!map.containsKey(key) || map[key] == null) {
        throw FormatException('Missing required key "$key" in $context');
      }
    }

    requireKey(json, 'name', 'build_config');
    requireKey(json, 'flavor', 'build_config');
    requireKey(json, 'app_name', 'build_config');
    requireKey(json, 'android', 'build_config');
    requireKey(json, 'ios', 'build_config');
    requireKey(json, 'firebase', 'build_config');

    final android = json['android'] as Map<String, dynamic>;
    requireKey(android, 'application_id', 'build_config.android');
    requireKey(android, 'app_name', 'build_config.android');
    requireKey(android, 'icon', 'build_config.android');
    requireKey(android, 'google_services_path', 'build_config.android');

    final ios = json['ios'] as Map<String, dynamic>;
    requireKey(ios, 'bundle_identifier', 'build_config.ios');
    requireKey(ios, 'bundle_display_name', 'build_config.ios');
    requireKey(ios, 'app_icon_name', 'build_config.ios');
    requireKey(ios, 'google_service_info_path', 'build_config.ios');

    final firebase = json['firebase'] as Map<String, dynamic>;
    requireKey(firebase, 'project_id', 'build_config.firebase');
    requireKey(firebase, 'storage_bucket', 'build_config.firebase');

    final fbAndroid = firebase['android'] as Map<String, dynamic>?;
    final fbIos = firebase['ios'] as Map<String, dynamic>?;

    return EnvironmentConfig(
      name: json['name'] as String,
      flavor: json['flavor'] as String,
      appName: json['app_name'] as String,
      androidAppId: android['application_id'] as String,
      androidAppName: android['app_name'] as String,
      androidIcon: android['icon'] as String,
      androidResDir: (android['res_dir'] ?? json['ANDROID_RES_DIR']) as String?,
      androidGoogleServicesPath: android['google_services_path'] as String,
      iosBundleId: ios['bundle_identifier'] as String,
      iosDisplayName: ios['bundle_display_name'] as String,
      iosAppIconName: ios['app_icon_name'] as String,
      iosGoogleServiceInfoPath: ios['google_service_info_path'] as String,
      firebaseProjectId: firebase['project_id'] as String,
      firebaseStorageBucket: firebase['storage_bucket'] as String,
      firebaseAndroidAppId: fbAndroid?['app_id'] as String?,
      firebaseIosAppId: fbIos?['app_id'] as String?,
    );
  }

  static EnvironmentConfig load(String env) {
    final normalized = env.toLowerCase();
    final candidates = [
      if (normalized == 'dev' || normalized == 'staging')
        'build_config/development.json',
      if (normalized == 'prod' || normalized == 'production')
        'build_config/production.json',
      'build_config/$normalized.json',
    ];

    File? foundFile;
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        foundFile = file;
        break;
      }
    }

    if (foundFile == null) {
      stderr.writeln(
        'Error: Could not find build configuration for environment "$env".\n'
        'Looked in: ${candidates.join(', ')}',
      );
      exit(1);
    }

    try {
      final content = foundFile.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return EnvironmentConfig.fromJson(data);
    } catch (e) {
      stderr.writeln(
        'Error parsing build configuration at ${foundFile.path}: $e',
      );
      exit(1);
    }
  }

  static void validateAll() {
    final configs = ['development', 'production'];
    for (final env in configs) {
      try {
        final config = EnvironmentConfig.load(env);
        stdout.writeln(
          '✓ Validated build_config/$env.json (flavor: ${config.flavor}, name: ${config.name}, app: ${config.appName})',
        );
      } catch (e) {
        stderr.writeln('✗ Failed validating build_config/$env.json: $e');
        exit(1);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

class Config {
  final String gitUrl;
  final String gitBranch;
  final String gitBasicAuthorization;
  final String matchPassword;
  final String env;
  final EnvironmentConfig environmentConfig;

  Config({
    required this.gitUrl,
    required this.gitBranch,
    required this.gitBasicAuthorization,
    required this.matchPassword,
    required this.env,
    required this.environmentConfig,
  });

  factory Config.load({String? overrideEnv}) {
    var envMap = Platform.environment;
    final dotenv = _parseDotEnv();
    envMap = {...dotenv, ...envMap}; // process env vars take precedence

    final gitUrl = envMap['MATCH_GIT_URL'];
    final password = envMap['MATCH_PASSWORD'];
    if (gitUrl == null || password == null) {
      stderr.writeln(
        'Missing required config: MATCH_GIT_URL and MATCH_PASSWORD.\n'
        'Set them as environment variables or in a .env file.',
      );
      exit(1);
    }

    var resolvedEnv =
        (overrideEnv ??
                envMap['MATCH_ENV'] ??
                envMap['APP_ENV'] ??
                envMap['FLAVOR'] ??
                envMap['ENV'] ??
                'prod')
            .toLowerCase();
    if (resolvedEnv == 'staging' || resolvedEnv == 'development') {
      resolvedEnv = 'dev';
    } else if (resolvedEnv == 'production') {
      resolvedEnv = 'prod';
    }

    final envConfig = EnvironmentConfig.load(resolvedEnv);

    return Config(
      gitUrl: gitUrl,
      gitBranch: envMap['MATCH_GIT_BRANCH'] ?? 'main',
      gitBasicAuthorization: envMap['MATCH_GIT_BASIC_AUTHORIZATION'] ?? '',
      matchPassword: password,
      env: resolvedEnv,
      environmentConfig: envConfig,
    );
  }
}

Map<String, String> _parseDotEnv() {
  final file = File('.env');
  if (!file.existsSync()) return {};

  final result = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    result[trimmed.substring(0, idx).trim()] = trimmed
        .substring(idx + 1)
        .trim();
  }
  return result;
}

// ---------------------------------------------------------------------------
// Crypto — compatible with match_keystore's OpenSSL-style encryption
// ---------------------------------------------------------------------------

/// Derives the 128-char hex password from MATCH_PASSWORD (matches Ruby's gen_key).
Uint8List _deriveKeyPassword(String matchPassword) {
  final digest = SHA512Digest();
  final hash = digest.process(utf8.encode(matchPassword));
  final hex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return utf8.encode(hex);
}

Uint8List _pbkdf2(Uint8List password, Uint8List salt, int outputLength) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, outputLength));
  return derivator.process(password);
}

Uint8List decryptBytes(Uint8List encrypted, String matchPassword) {
  if (encrypted.length < 16) {
    throw FormatException(
      'File too short (${encrypted.length} bytes) — is it encrypted?',
    );
  }
  final header = utf8.decode(encrypted.sublist(0, 8));
  if (header != _saltHeader) {
    throw FormatException('Missing salt header — is the file encrypted?');
  }
  final salt = encrypted.sublist(8, 16);
  final ciphertext = encrypted.sublist(16);
  if (ciphertext.isEmpty || ciphertext.length % 16 != 0) {
    throw FormatException(
      'Invalid ciphertext length (${ciphertext.length}) — corrupted file',
    );
  }

  final password = _deriveKeyPassword(matchPassword);
  final keyIv = _pbkdf2(password, salt, _keyLength + _ivLength);
  final key = keyIv.sublist(0, _keyLength);
  final iv = keyIv.sublist(_keyLength);

  final cipher = CBCBlockCipher(AESEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv));

  final plaintext = Uint8List(ciphertext.length);
  for (var offset = 0; offset < ciphertext.length; offset += 16) {
    cipher.processBlock(ciphertext, offset, plaintext, offset);
  }

  // Strip and validate PKCS7 padding
  final padLen = plaintext.last;
  if (padLen < 1 || padLen > 16) {
    throw FormatException(
      'Invalid PKCS7 padding ($padLen) — wrong password or corrupted file',
    );
  }
  for (var i = plaintext.length - padLen; i < plaintext.length; i++) {
    if (plaintext[i] != padLen) {
      throw FormatException(
        'Inconsistent PKCS7 padding — wrong password or corrupted file',
      );
    }
  }
  return plaintext.sublist(0, plaintext.length - padLen);
}

Uint8List encryptBytes(Uint8List plaintext, String matchPassword) {
  final password = _deriveKeyPassword(matchPassword);
  final random = Random.secure();
  final salt = Uint8List.fromList(
    List.generate(8, (_) => random.nextInt(256)),
  );

  final keyIv = _pbkdf2(password, salt, _keyLength + _ivLength);
  final key = keyIv.sublist(0, _keyLength);
  final iv = keyIv.sublist(_keyLength);

  // PKCS7 padding
  final padLen = 16 - (plaintext.length % 16);
  final padded = Uint8List(plaintext.length + padLen)
    ..setAll(0, plaintext)
    ..fillRange(plaintext.length, plaintext.length + padLen, padLen);

  final cipher = CBCBlockCipher(AESEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv));

  final ciphertext = Uint8List(padded.length);
  for (var offset = 0; offset < padded.length; offset += 16) {
    cipher.processBlock(padded, offset, ciphertext, offset);
  }

  return Uint8List.fromList([
    ...utf8.encode(_saltHeader),
    ...salt,
    ...ciphertext,
  ]);
}

// ---------------------------------------------------------------------------
// Git operations
// ---------------------------------------------------------------------------

Future<void> _git(List<String> args, String auth) async {
  final fullArgs = <String>[];
  if (auth.isNotEmpty) {
    fullArgs.addAll(['-c', 'http.extraHeader=Authorization: Basic $auth']);
  }
  fullArgs.addAll(args);

  final result = await Process.run('git', fullArgs);
  if (result.exitCode != 0) {
    stderr.writeln('git ${args.join(' ')} failed (exit ${result.exitCode}):');
    stderr.writeln(result.stderr);
    exit(1);
  }
}

Future<void> cloneOrPull(Config config) async {
  final gitDir = Directory('$_repoDir/.git');
  if (gitDir.existsSync()) {
    stdout.writeln('Pulling credentials repository...');
    await _git([
      '-C',
      _repoDir,
      'pull',
      '--ff-only',
    ], config.gitBasicAuthorization);
  } else {
    stdout.writeln('Cloning credentials repository...');
    await _git(
      [
        'clone',
        '--depth',
        '1',
        '--branch',
        config.gitBranch,
        config.gitUrl,
        _repoDir,
      ],
      config.gitBasicAuthorization,
    );
  }
}

// ---------------------------------------------------------------------------
// Generation and Configuration
// ---------------------------------------------------------------------------

bool _containsOtherEnvironmentCredential(
  File file,
  EnvironmentConfig envConfig,
) {
  if (envConfig.flavor != 'dev' || !file.existsSync()) {
    return false;
  }

  final content = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  final production = EnvironmentConfig.load('prod');
  final productionValues = [
    production.androidAppId,
    production.iosBundleId,
    production.firebaseProjectId,
    production.firebaseAndroidAppId,
    production.firebaseIosAppId,
  ];
  return productionValues.any(
    (value) => value != null && content.contains(value),
  );
}

void _refuseOverwritingOtherEnvironmentCredential(
  String destinationPath,
  EnvironmentConfig envConfig,
) {
  final destination = File(destinationPath);
  if (!_containsOtherEnvironmentCredential(destination, envConfig)) {
    return;
  }

  stderr.writeln(
    'Error: ${destination.path} contains production Firebase credentials; '
    'refusing to overwrite it while configuring development.',
  );
  exit(1);
}

void _writeCredentialBytes(
  String destinationPath,
  List<int> bytes,
  EnvironmentConfig envConfig,
) {
  _refuseOverwritingOtherEnvironmentCredential(destinationPath, envConfig);
  File(destinationPath).parent.createSync(recursive: true);
  File(destinationPath).writeAsBytesSync(bytes);
}

void generateAppConfig(EnvironmentConfig envConfig) {
  // 1. Generate AppConfig.xcconfig for iOS
  final xcconfigFile = File('ios/Flutter/AppConfig.xcconfig');
  xcconfigFile.parent.createSync(recursive: true);
  final xcconfigContent =
      '''
// Auto-generated by tool/credentials.dart. Do NOT edit manually.
// Target environment: ${envConfig.name} (${envConfig.flavor})

PRODUCT_BUNDLE_IDENTIFIER = ${envConfig.iosBundleId}
APP_BUNDLE_IDENTIFIER = ${envConfig.iosBundleId}
APP_CONFIG_NAME = ${envConfig.iosDisplayName}
BUNDLE_DISPLAY_NAME = ${envConfig.iosDisplayName}
APP_CONFIG_ICON_NAME = ${envConfig.iosAppIconName}
APP_ICON_NAME = ${envConfig.iosAppIconName}
''';
  xcconfigFile.writeAsStringSync('${xcconfigContent.trim()}\n');
  stdout.writeln('  generated ${xcconfigFile.path} for ${envConfig.flavor}');

  // 2. Generate app.properties for Android
  final appPropsFile = File('android/app/app.properties');
  appPropsFile.parent.createSync(recursive: true);
  final resDir =
      envConfig.androidResDir ??
      (envConfig.flavor == 'dev'
          ? 'android/app/src/dev/res'
          : 'android/app/src/main/res');
  final appPropsContent =
      '''
# Auto-generated by tool/credentials.dart. Do NOT edit manually.
# Target environment: ${envConfig.name} (${envConfig.flavor})
applicationId=${envConfig.androidAppId}
appLabel=${envConfig.androidAppName}
resDir=$resDir
''';
  appPropsFile.writeAsStringSync('${appPropsContent.trim()}\n');
  stdout.writeln('  generated ${appPropsFile.path} for ${envConfig.flavor}');

  // 3. Ensure valid google-services.json exists.
  final gsFile = File(envConfig.androidGoogleServicesPath);
  final androidConfigValid =
      gsFile.existsSync() &&
      gsFile.readAsStringSync().contains(envConfig.androidAppId);
  if (!androidConfigValid) {
    _refuseOverwritingOtherEnvironmentCredential(gsFile.path, envConfig);
    if (envConfig.flavor != 'dev') {
      stderr.writeln(
        'Error: ${gsFile.path} is missing or does not contain '
        'Android application ID ${envConfig.androidAppId}.',
      );
      exit(1);
    }
    gsFile.parent.createSync(recursive: true);
    final stubJson = {
      'project_info': {
        'project_number': '000000000000',
        'project_id': envConfig.firebaseProjectId,
        'storage_bucket': envConfig.firebaseStorageBucket,
      },
      'client': [
        {
          'client_info': {
            'mobilesdk_app_id':
                envConfig.firebaseAndroidAppId ??
                '1:000000000000:android:0000000000000000000000',
            'android_client_info': {'package_name': envConfig.androidAppId},
          },
          'oauth_client': [],
          'api_key': [
            {'current_key': 'AIzaSyDummyKeyForDevEnvironmentTesting1'},
          ],
          'services': {
            'appinvite_service': {'other_platform_oauth_client': []},
          },
        },
      ],
      'configuration_version': '1',
    };
    _writeCredentialBytes(
      gsFile.path,
      utf8.encode(const JsonEncoder.withIndent('  ').convert(stubJson)),
      envConfig,
    );
    stdout.writeln('  generated ${gsFile.path} for ${envConfig.flavor}');
  }

  // 4. Ensure valid GoogleService-Info.plist exists.
  final gspFile = File(envConfig.iosGoogleServiceInfoPath);
  final iosConfigValid =
      gspFile.existsSync() &&
      gspFile.readAsStringSync().contains(envConfig.iosBundleId);
  if (!iosConfigValid) {
    _refuseOverwritingOtherEnvironmentCredential(gspFile.path, envConfig);
    if (envConfig.flavor != 'dev') {
      stderr.writeln(
        'Error: ${gspFile.path} is missing or does not contain '
        'iOS bundle ID ${envConfig.iosBundleId}.',
      );
      exit(1);
    }
    gspFile.parent.createSync(recursive: true);
    final stubPlist =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CLIENT_ID</key>
\t<string>000000000000-dummy.apps.googleusercontent.com</string>
\t<key>REVERSED_CLIENT_ID</key>
\t<string>com.googleusercontent.apps.dummy</string>
\t<key>API_KEY</key>
\t<string>AIzaSyDummyKeyForDevEnvironmentTesting1</string>
\t<key>GCM_SENDER_ID</key>
\t<string>000000000000</string>
\t<key>PLIST_VERSION</key>
\t<string>1</string>
\t<key>BUNDLE_ID</key>
\t<string>${envConfig.iosBundleId}</string>
\t<key>PROJECT_ID</key>
\t<string>${envConfig.firebaseProjectId}</string>
\t<key>STORAGE_BUCKET</key>
\t<string>${envConfig.firebaseStorageBucket}</string>
\t<key>IS_ADS_ENABLED</key>
\t<false/>
\t<key>IS_ANALYTICS_ENABLED</key>
\t<false/>
\t<key>IS_APPINVITE_ENABLED</key>
\t<true/>
\t<key>IS_GCM_ENABLED</key>
\t<true/>
\t<key>IS_SIGNIN_ENABLED</key>
\t<true/>
\t<key>GOOGLE_APP_ID</key>
\t<string>${envConfig.firebaseIosAppId ?? '1:000000000000:ios:0000000000000000000000'}</string>
</dict>
</plist>
''';
    _writeCredentialBytes(
      gspFile.path,
      utf8.encode(stubPlist.trim()),
      envConfig,
    );
    stdout.writeln('  generated ${gspFile.path} for ${envConfig.flavor}');
  }
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

Future<void> fetch(Config config) async {
  await cloneOrPull(config);

  final envConfig = config.environmentConfig;
  stdout.writeln('Target environment: ${config.env} (${envConfig.name})');

  Uint8List? readOrDecrypt(String srcRelPath) {
    final srcPath = '$_repoDir/$srcRelPath';
    final srcFile = File(srcPath);

    if (!srcFile.existsSync()) {
      return null;
    }

    if (srcRelPath.endsWith('.enc')) {
      final encrypted = srcFile.readAsBytesSync();
      return decryptBytes(encrypted, config.matchPassword);
    } else {
      return srcFile.readAsBytesSync();
    }
  }

  bool processFile(
    String srcRelPath,
    String destPath, {
    bool Function(Uint8List bytes)? validate,
  }) {
    final bytes = readOrDecrypt(srcRelPath);
    if (bytes == null) {
      return false;
    }

    if (validate != null && !validate(bytes)) {
      return false;
    }

    if (validate != null) {
      _refuseOverwritingOtherEnvironmentCredential(destPath, envConfig);
    }
    File(destPath).parent.createSync(recursive: true);
    File(destPath).writeAsBytesSync(bytes);

    if (srcRelPath.endsWith('.enc')) {
      stdout.writeln('  decrypt $srcRelPath -> $destPath');
    } else {
      stdout.writeln('  copy $srcRelPath -> $destPath');
    }
    return true;
  }

  // 1. Common keystores and service account (encrypted files take precedence, stop on first match)
  final baseMappings = <String, List<String>>{
    'android/app/keystore.jks': [
      'keystores/keystore.jks.enc',
      'keystores/keystore.jks',
    ],
    'android/key.properties': [
      'keystores/key.properties.enc',
      'keystores/key.properties',
    ],
    'service-account.json': [
      'firebase/service-account.json.enc',
      'firebase/service-account.json',
    ],
  };

  for (final entry in baseMappings.entries) {
    var mapped = false;
    for (final src in entry.value) {
      if (processFile(src, entry.key)) {
        mapped = true;
        break;
      }
    }
    if (!mapped) {
      stdout.writeln(
        '  note: optional base file ${entry.key} not in credentials repo',
      );
    }
  }

  // 2. Google services (Android) - strictly isolated per environment
  final env = config.env;
  final androidSourceCandidates = [
    'firebase/$env/google-services.json.enc',
    'firebase/$env/google-services.json',
    'firebase/google-services-$env.json.enc',
    'firebase/google-services-$env.json',
    'firebase/google-services.$env.json.enc',
    'firebase/google-services.$env.json',
    if (env == 'dev') ...[
      'firebase/staging/google-services.json.enc',
      'firebase/staging/google-services.json',
      'firebase/google-services-staging.json.enc',
      'firebase/google-services-staging.json',
      'firebase/google-services.staging.json.enc',
      'firebase/google-services.staging.json',
      'firebase/dev/google-services.json.enc',
      'firebase/dev/google-services.json',
    ],
    if (env == 'prod') ...[
      'firebase/google-services.json.enc',
      'firebase/google-services.json',
    ],
  ];

  var androidResolved = false;
  for (final src in androidSourceCandidates) {
    if (processFile(
      src,
      envConfig.androidGoogleServicesPath,
      validate: (bytes) => utf8
          .decode(bytes, allowMalformed: true)
          .contains(envConfig.androidAppId),
    )) {
      androidResolved = true;
      if (envConfig.androidGoogleServicesPath !=
          'android/app/google-services.json') {
        processFile(src, 'android/app/google-services.json');
      }
      break;
    }
  }

  if (!androidResolved) {
    if (env == 'dev') {
      stdout.writeln(
        '  note: dev google-services.json not in credentials repo; using generated stub for ${envConfig.androidAppId}',
      );
    } else {
      stderr.writeln(
        'Error: No valid google-services.json found in credentials repository for env "$env".\n'
        'Expected package: ${envConfig.androidAppId}',
      );
      exit(1);
    }
  }

  // 3. GoogleService-Info (iOS) - strictly isolated per environment
  final iosSourceCandidates = [
    'firebase/$env/GoogleService-Info.plist.enc',
    'firebase/$env/GoogleService-Info.plist',
    'firebase/GoogleService-Info-$env.plist.enc',
    'firebase/GoogleService-Info-$env.plist',
    'firebase/GoogleService-Info.$env.plist.enc',
    'firebase/GoogleService-Info.$env.plist',
    if (env == 'dev') ...[
      'firebase/staging/GoogleService-Info.plist.enc',
      'firebase/staging/GoogleService-Info.plist',
      'firebase/GoogleService-Info-staging.plist.enc',
      'firebase/GoogleService-Info-staging.plist',
      'firebase/GoogleService-Info.staging.plist.enc',
      'firebase/GoogleService-Info.staging.plist',
      'firebase/dev/GoogleService-Info.plist.enc',
      'firebase/dev/GoogleService-Info.plist',
    ],
    if (env == 'prod') ...[
      'firebase/GoogleService-Info.plist.enc',
      'firebase/GoogleService-Info.plist',
    ],
  ];

  var iosResolved = false;
  for (final src in iosSourceCandidates) {
    if (processFile(
      src,
      envConfig.iosGoogleServiceInfoPath,
      validate: (bytes) => utf8
          .decode(bytes, allowMalformed: true)
          .contains(envConfig.iosBundleId),
    )) {
      iosResolved = true;
      if (envConfig.iosGoogleServiceInfoPath !=
          'ios/Runner/GoogleService-Info.plist') {
        processFile(src, 'ios/Runner/GoogleService-Info.plist');
      }
      break;
    }
  }

  if (!iosResolved) {
    if (env == 'dev') {
      stdout.writeln(
        '  note: dev GoogleService-Info.plist not in credentials repo; using generated stub for ${envConfig.iosBundleId}',
      );
    } else {
      stderr.writeln(
        'Error: No valid GoogleService-Info.plist found in credentials repository for env "$env".\n'
        'Expected bundle id: ${envConfig.iosBundleId}',
      );
      exit(1);
    }
  }
  generateAppConfig(envConfig);

  stdout.writeln('Done.');
}

Future<void> encrypt(
  Config config,
  String sourcePath,
  String destInRepo,
) async {
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Source file not found: $sourcePath');
    exit(1);
  }

  await cloneOrPull(config);

  final plaintext = sourceFile.readAsBytesSync();
  final encrypted = encryptBytes(plaintext, config.matchPassword);

  final destPath = '$_repoDir/$destInRepo';
  File(destPath).parent.createSync(recursive: true);
  File(destPath).writeAsBytesSync(encrypted);

  stdout.writeln('Encrypted $sourcePath -> $destPath');
  stdout.writeln('Now commit and push the credentials repository:');
  stdout.writeln(
    '  cd $_repoDir && git add . && git commit -m "Add $destInRepo" && git push',
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

String? _extractEnv(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--env=')) {
      return arg.substring(6);
    }
    if (arg == '--env' || arg == '-e') {
      if (i + 1 < args.length) {
        return args[i + 1];
      }
    }
  }
  return null;
}

List<String> _cleanArgs(List<String> args) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--env=')) {
      continue;
    }
    if (arg == '--env' || arg == '-e') {
      i++; // Skip value
      continue;
    }
    result.add(arg);
  }
  return result;
}

Future<void> main(List<String> rawArgs) async {
  final envOverride = _extractEnv(rawArgs);
  final args = _cleanArgs(rawArgs);

  if (args.isEmpty) {
    stderr.writeln('Usage:');
    stderr.writeln(
      '  dart run tool/credentials.dart configure [--env=dev|--env=prod]',
    );
    stderr.writeln(
      '  dart run tool/credentials.dart generate [--env=dev|--env=prod]',
    );
    stderr.writeln(
      '  dart run tool/credentials.dart fetch [--env=dev|--env=prod]',
    );
    stderr.writeln('  dart run tool/credentials.dart validate');
    stderr.writeln(
      '  dart run tool/credentials.dart encrypt <source-file> <dest-path-in-repo>',
    );
    exit(1);
  }

  final command = args[0];
  String? positionalEnv;
  if ((command == 'fetch' || command == 'configure' || command == 'generate') &&
      args.length > 1 &&
      !args[1].startsWith('-')) {
    positionalEnv = args[1];
  }

  final resolvedEnv = envOverride ?? positionalEnv ?? 'dev';

  switch (command) {
    case 'validate':
      EnvironmentConfig.validateAll();
    case 'configure':
    case 'generate':
      {
        final envConfig = EnvironmentConfig.load(resolvedEnv);
        generateAppConfig(envConfig);
        stdout.writeln('Configuration generated for ${envConfig.flavor}.');
      }
    case 'fetch':
      {
        final config = Config.load(overrideEnv: resolvedEnv);
        await fetch(config);
      }
    case 'encrypt':
      {
        if (args.length < 3) {
          stderr.writeln(
            'Usage: dart run tool/credentials.dart encrypt <source-file> <dest-path-in-repo>',
          );
          exit(1);
        }
        final config = Config.load(overrideEnv: resolvedEnv);
        await encrypt(config, args[1], args[2]);
      }
    default:
      stderr.writeln('Unknown command: $command');
      exit(1);
  }
}
