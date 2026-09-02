// Cross-platform credential management tool.
//
// Fetches and decrypts credentials from the shared credentials Git repository.
// Compatible with the match_keystore encryption format (AES-256-CBC, PBKDF2).
//
// Usage:
//   dart run tool/credentials.dart fetch [--env=dev|--env=prod]
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

const _devPackageName = 'club.ntut.tattoo';

const _fallbackDevGoogleServicesJson = '''{
  "project_info": {
    "project_number": "838220085712",
    "project_id": "npc-tattoo",
    "storage_bucket": "npc-tattoo.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:838220085712:android:a85cf2541699925c3be1d5",
        "android_client_info": {
          "package_name": "club.ntut.tattoo"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyAwy04VDvRscfjTPu2ShxLbB-_EyuezEhU"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}''';

const _fallbackDevGoogleServiceInfoPlist =
    '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyDp_en-3_f7VONU8KA8zucI-tTgrsV_PJM</string>
	<key>GCM_SENDER_ID</key>
	<string>838220085712</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>club.ntut.tattoo</string>
	<key>PROJECT_ID</key>
	<string>npc-tattoo</string>
	<key>STORAGE_BUCKET</key>
	<string>npc-tattoo.firebasestorage.app</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:838220085712:ios:d5b7636cdc72fd603be1d5</string>
</dict>
</plist>''';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

class Config {
  final String gitUrl;
  final String gitBranch;
  final String gitBasicAuthorization;
  final String matchPassword;
  final String env;

  Config({
    required this.gitUrl,
    required this.gitBranch,
    required this.gitBasicAuthorization,
    required this.matchPassword,
    required this.env,
  });

  factory Config.load({String? overrideEnv}) {
    var envMap = Platform.environment;

    // Fall back to .env file if env vars are missing
    if (!envMap.containsKey('MATCH_GIT_URL') ||
        !envMap.containsKey('MATCH_PASSWORD')) {
      final dotenv = _parseDotEnv();
      envMap = {...dotenv, ...envMap}; // env vars take precedence
    }

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
    if (resolvedEnv == 'staging') {
      resolvedEnv = 'dev';
    }

    return Config(
      gitUrl: gitUrl,
      gitBranch: envMap['MATCH_GIT_BRANCH'] ?? 'main',
      gitBasicAuthorization: envMap['MATCH_GIT_BASIC_AUTHORIZATION'] ?? '',
      matchPassword: password,
      env: resolvedEnv,
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
// Commands
// ---------------------------------------------------------------------------

Future<void> fetch(Config config) async {
  await cloneOrPull(config);

  stdout.writeln('Target environment: ${config.env}');
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

    // Ensure destination directory exists
    File(destPath).parent.createSync(recursive: true);
    File(destPath).writeAsBytesSync(bytes);

    if (srcRelPath.endsWith('.enc')) {
      stdout.writeln('  decrypt $srcRelPath -> $destPath');
    } else {
      stdout.writeln('  copy $srcRelPath -> $destPath');
    }
    return true;
  }

  // 1. Common keystores and service account
  final baseMappings = {
    'keystores/keystore.jks': 'android/app/keystore.jks',
    'keystores/key.properties.enc': 'android/key.properties',
    'keystores/key.properties': 'android/key.properties',
    'firebase/service-account.json.enc': 'service-account.json',
    'firebase/service-account.json': 'service-account.json',
  };

  for (final entry in baseMappings.entries) {
    processFile(entry.key, entry.value);
  }

  // 2. Google services (Android)
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
    ],
    'firebase/google-services.json.enc',
    'firebase/google-services.json',
  ];

  if (env == 'dev') {
    var devAndroidFound = false;
    for (final src in androidSourceCandidates) {
      if (processFile(
        src,
        'android/app/src/dev/google-services.json',
        validate: (bytes) =>
            utf8.decode(bytes, allowMalformed: true).contains(_devPackageName),
      )) {
        devAndroidFound = true;
        processFile(src, 'android/app/google-services.json');
        break;
      }
    }
    if (!devAndroidFound) {
      final destFile = File('android/app/src/dev/google-services.json');
      destFile.parent.createSync(recursive: true);
      destFile.writeAsStringSync(_fallbackDevGoogleServicesJson.trim());
      stdout.writeln(
        '  fallback dev google-services.json -> android/app/src/dev/google-services.json',
      );

      final rootDestFile = File('android/app/google-services.json');
      rootDestFile.parent.createSync(recursive: true);
      rootDestFile.writeAsStringSync(_fallbackDevGoogleServicesJson.trim());
      stdout.writeln(
        '  fallback dev google-services.json -> android/app/google-services.json',
      );
    }
  } else {
    final androidDestPaths = [
      'android/app/src/$env/google-services.json',
      'android/app/google-services.json',
    ];
    for (final dest in androidDestPaths) {
      for (final src in androidSourceCandidates) {
        if (processFile(src, dest)) {
          break;
        }
      }
    }
  }

  // Also place other flavor configs if available in credentials repo
  const allFlavors = ['dev', 'prod'];
  for (final flavor in allFlavors) {
    if (flavor == env) continue;
    final flavorSources = [
      'firebase/$flavor/google-services.json.enc',
      'firebase/$flavor/google-services.json',
      'firebase/google-services-$flavor.json.enc',
      'firebase/google-services-$flavor.json',
      if (flavor == 'dev') ...[
        'firebase/staging/google-services.json.enc',
        'firebase/staging/google-services.json',
        'firebase/google-services-staging.json.enc',
        'firebase/google-services-staging.json',
      ],
    ];
    for (final src in flavorSources) {
      if (processFile(
        src,
        'android/app/src/$flavor/google-services.json',
        validate: flavor == 'dev'
            ? (bytes) => utf8
                  .decode(bytes, allowMalformed: true)
                  .contains(_devPackageName)
            : null,
      )) {
        break;
      }
    }
  }

  // 3. GoogleService-Info (iOS)
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
    ],
    'firebase/GoogleService-Info.plist.enc',
    'firebase/GoogleService-Info.plist',
  ];

  if (env == 'dev') {
    var devIosFound = false;
    for (final src in iosSourceCandidates) {
      if (processFile(
        src,
        'ios/Runner/GoogleService-Info.plist',
        validate: (bytes) =>
            utf8.decode(bytes, allowMalformed: true).contains(_devPackageName),
      )) {
        devIosFound = true;
        break;
      }
    }
    if (!devIosFound) {
      final destFile = File('ios/Runner/GoogleService-Info.plist');
      destFile.parent.createSync(recursive: true);
      destFile.writeAsStringSync(_fallbackDevGoogleServiceInfoPlist.trim());
      stdout.writeln(
        '  fallback dev GoogleService-Info.plist -> ios/Runner/GoogleService-Info.plist',
      );
    }
  } else {
    final iosDestPaths = [
      'ios/Runner/GoogleService-Info.plist',
    ];
    for (final dest in iosDestPaths) {
      for (final src in iosSourceCandidates) {
        if (processFile(src, dest)) {
          break;
        }
      }
    }
  }

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
      '  dart run tool/credentials.dart fetch [--env=dev|--env=prod]',
    );
    stderr.writeln(
      '  dart run tool/credentials.dart encrypt <source-file> <dest-path-in-repo>',
    );
    exit(1);
  }

  final command = args[0];
  String? positionalEnv;
  if (command == 'fetch' && args.length > 1 && !args[1].startsWith('-')) {
    positionalEnv = args[1];
  }

  final config = Config.load(overrideEnv: envOverride ?? positionalEnv);

  switch (command) {
    case 'fetch':
      await fetch(config);
    case 'encrypt':
      if (args.length < 3) {
        stderr.writeln(
          'Usage: dart run tool/credentials.dart encrypt <source-file> <dest-path-in-repo>',
        );
        exit(1);
      }
      await encrypt(config, args[1], args[2]);
    default:
      stderr.writeln('Unknown command: $command');
      exit(1);
  }
}
