// Cross-platform credential management tool.
//
// Fetches and decrypts credentials from the shared credentials Git repository.
// Compatible with the match_keystore encryption format (AES-256-CBC, PBKDF2).
//
// Usage:
//   dart run tool/credentials.dart fetch
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

// Encrypted files in the credentials repo → local destination paths.
// Files ending in .enc are decrypted; others are copied as-is.
const _fileMappings = {
  'keystores/keystore.jks': 'android/app/keystore.jks',
  'keystores/key.properties.enc': 'android/key.properties',
  'firebase/google-services.json.enc': 'android/app/google-services.json',
  'firebase/GoogleService-Info.plist.enc':
      'ios/Runner/GoogleService-Info.plist',
  'firebase/service-account.json.enc': 'service-account.json',
};

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

class Config {
  final String gitUrl;
  final String gitBranch;
  final String gitBasicAuthorization;
  final String matchPassword;

  Config({
    required this.gitUrl,
    required this.gitBranch,
    required this.gitBasicAuthorization,
    required this.matchPassword,
  });

  factory Config.load() {
    var env = Platform.environment;

    // Fall back to .env file if env vars are missing
    if (!env.containsKey('MATCH_GIT_URL') ||
        !env.containsKey('MATCH_PASSWORD')) {
      final dotenv = _parseDotEnv();
      env = {...dotenv, ...env}; // env vars take precedence
    }

    final gitUrl = env['MATCH_GIT_URL'];
    final password = env['MATCH_PASSWORD'];
    if (gitUrl == null || password == null) {
      stderr.writeln(
        'Missing required config: MATCH_GIT_URL and MATCH_PASSWORD.\n'
        'Set them as environment variables or in a .env file.',
      );
      exit(1);
    }

    return Config(
      gitUrl: gitUrl,
      gitBranch: env['MATCH_GIT_BRANCH'] ?? 'main',
      gitBasicAuthorization: env['MATCH_GIT_BASIC_AUTHORIZATION'] ?? '',
      matchPassword: password,
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

  for (final entry in _fileMappings.entries) {
    final srcPath = '$_repoDir/${entry.key}';
    final destPath = entry.value;
    final srcFile = File(srcPath);

    if (!srcFile.existsSync()) {
      stdout.writeln('  skip ${entry.key} (not found)');
      continue;
    }

    // Ensure destination directory exists
    File(destPath).parent.createSync(recursive: true);

    if (entry.key.endsWith('.enc')) {
      final encrypted = srcFile.readAsBytesSync();
      final decrypted = decryptBytes(encrypted, config.matchPassword);

      File(destPath).writeAsBytesSync(decrypted);
      stdout.writeln('  decrypt ${entry.key} -> $destPath');
    } else {
      srcFile.copySync(destPath);
      stdout.writeln('  copy ${entry.key} -> $destPath');
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

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage:');
    stderr.writeln('  dart run tool/credentials.dart fetch');
    stderr.writeln(
      '  dart run tool/credentials.dart encrypt <source-file> <dest-path-in-repo>',
    );
    exit(1);
  }

  final config = Config.load();

  switch (args[0]) {
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
      stderr.writeln('Unknown command: ${args[0]}');
      exit(1);
  }
}
