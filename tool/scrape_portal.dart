import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as hp;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('username', abbr: 'u', help: 'NTUT portal username (muid)')
    ..addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'test/test_config.json',
      help: 'Path to test config JSON containing credentials',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path (prints to stdout if omitted)',
    )
    ..addOption(
      'format',
      abbr: 'f',
      allowed: ['text', 'json'],
      defaultsTo: 'text',
      help: 'Output format',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help usage',
    );

  final ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (argResults['help'] as bool) {
    stdout.writeln('NTUT Portal Scraper Tool');
    stdout.writeln(
      'Scrapes all available portal endpoints from https://nportal.ntut.edu.tw/',
    );
    stdout.writeln('\nUsage:');
    stdout.writeln(parser.usage);
    return;
  }

  // Resolve credentials
  String? username = argResults['username'];
  username ??=
      Platform.environment['NTUT_PORTAL_USERNAME'] ??
      Platform.environment['NTUT_TEST_USERNAME'];

  String? password =
      Platform.environment['NTUT_PORTAL_PASSWORD'] ??
      Platform.environment['NTUT_TEST_PASSWORD'];

  if (username == null || password == null) {
    final configPath = argResults['config'] as String;
    final configFile = File(configPath);
    if (configFile.existsSync()) {
      try {
        final config =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        username ??= config['NTUT_TEST_USERNAME'];
        password ??= config['NTUT_TEST_PASSWORD'];
      } catch (e) {
        stderr.writeln(
          'Warning: Failed to parse config file at $configPath: $e',
        );
      }
    }
  }

  if (username == null ||
      username.isEmpty ||
      password == null ||
      password.isEmpty) {
    stderr.writeln(
      'Error: Credentials are required. Specify them via --username argument, environment variables (NTUT_PORTAL_USERNAME/NTUT_PORTAL_PASSWORD), or in a config file.',
    );
    exit(1);
  }

  final cookieJar = CookieJar();
  final dio = Dio()
    ..options = BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );

  dio.interceptors.addAll([
    CookieManager(cookieJar),
    RedirectInterceptor(() => dio),
  ]);

  // Step 1: Login using mobile User-Agent to bypass captcha
  dio.options.headers = {
    'User-Agent': 'Direk ios App',
    'Connection': 'close',
  };

  stderr.writeln('Logging in to NTUT Portal as $username...');
  try {
    final loginResponse = await dio.post(
      'https://nportal.ntut.edu.tw/login.do',
      queryParameters: {
        'muid': username,
        'mpassword': password,
        'thetime': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    final loginBody = jsonDecode(loginResponse.data);
    if (loginBody['success'] != true) {
      final errorMsg = loginBody['errorMsg'] ?? 'Unknown error';
      stderr.writeln('Error: Login failed: $errorMsg');
      exit(1);
    }
    stderr.writeln('Login successful. Session established.');
  } on DioException catch (e) {
    stderr.writeln('Error: Login network request failed: ${e.message}');
    exit(1);
  } catch (e) {
    stderr.writeln('Error: Unexpected login failure: $e');
    exit(1);
  }

  // Step 2: Switch User-Agent to desktop browser and fetch aptreeMain.do
  dio.options.headers = {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Connection': 'close',
  };

  stderr.writeln('Fetching aptreeMain.do...');
  final String htmlContent;
  try {
    final response = await dio.get(
      'https://nportal.ntut.edu.tw/aptreeMain.do',
      queryParameters: {
        'thetime': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    htmlContent = response.data.toString();
  } on DioException catch (e) {
    stderr.writeln('Error: Failed to fetch aptreeMain.do: ${e.message}');
    exit(1);
  } catch (e) {
    stderr.writeln('Error: Unexpected failure fetching aptreeMain.do: $e');
    exit(1);
  }

  // Step 3: Parse the HTML tree
  stderr.writeln('Parsing portal tree structure...');
  final doc = hp.parse(htmlContent);
  final table = doc.querySelector('table.eipTable2');
  if (table == null) {
    stderr.writeln(
      'Error: Could not locate table.eipTable2 in response. Ensure session is valid.',
    );
    exit(1);
  }

  final rows = table.querySelectorAll('tr');
  final scrapedItems = <Map<String, String>>[];
  final seen = <String>{};

  final ssoLogAddRegexp = RegExp(
    r"ssoLogAdd\s*\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)",
  );
  final nextPopRegexp = RegExp(
    r"aptreeNextPop\s*\(\s*'([^']*)'\s*,\s*'([^']*)'",
  );
  final subListRegexp = RegExp(
    r"aptreeSubList\s*\(\s*'([^']*)'\s*,\s*'([^']*)'",
  );

  Future<void> scrapeSubtree(
    String rootFolderDn,
    String apDn,
    String category,
  ) async {
    final subUrl =
        'https://nportal.ntut.edu.tw/aptree6List.do?rootFolderDn=${Uri.encodeComponent(rootFolderDn)}&apDn=${Uri.encodeComponent(apDn)}';
    stderr.writeln('Fetching subfolder items: $category...');
    try {
      final response = await dio.get(
        subUrl,
        queryParameters: {
          'thetime': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final subDoc = hp.parse(response.data.toString());
      final aTags = subDoc.querySelectorAll('ul.aptreeSystemA a');

      for (final a in aTags) {
        final name = a.text.trim();
        if (name.isEmpty) continue;

        final href = a.attributes['href'] ?? '';
        final onclick = a.attributes['onclick'] ?? '';

        // Check if this child itself is a subfolder
        String? childRootFolderDn;
        String? childApDn;

        final nextPopMatch =
            nextPopRegexp.firstMatch(href) ?? nextPopRegexp.firstMatch(onclick);
        if (nextPopMatch != null) {
          childRootFolderDn = nextPopMatch.group(1);
          childApDn = nextPopMatch.group(2);
        } else {
          final subListMatch =
              subListRegexp.firstMatch(href) ??
              subListRegexp.firstMatch(onclick);
          if (subListMatch != null) {
            childRootFolderDn = subListMatch.group(1);
            childApDn = subListMatch.group(2);
          }
        }

        if (childRootFolderDn != null && childApDn != null) {
          await scrapeSubtree(
            childRootFolderDn,
            childApDn,
            '$category - $name',
          );
        } else {
          String? code;

          // Try to find the apOu code in ssoLogAdd call in parents or the element itself
          dom.Element? current = a;
          while (current != null) {
            final currentOnclick = current.attributes['onclick'] ?? '';
            final match = ssoLogAddRegexp.firstMatch(currentOnclick);
            if (match != null) {
              code = match.group(1);
              break;
            }
            current = current.parent;
          }

          // Fallback: extract apOu from query parameters of the href URL
          if (code == null && href.isNotEmpty) {
            try {
              final uri = Uri.parse(href);
              code = uri.queryParameters['apOu'];
            } catch (_) {}
          }

          // Build full URL
          String fullUrl = href;
          if (href.isNotEmpty &&
              !href.startsWith('http') &&
              !href.startsWith('javascript:')) {
            fullUrl = Uri.parse(
              'https://nportal.ntut.edu.tw/',
            ).resolve(href).toString();
          }

          final signature = '$category|$name|$code|$fullUrl';
          if (seen.contains(signature)) continue;
          seen.add(signature);

          scrapedItems.add({
            'category': category,
            'name': name,
            'code': code ?? '',
            'url': fullUrl,
          });
        }
      }
    } catch (e) {
      stderr.writeln('Warning: Failed to fetch subfolder $subUrl: $e');
    }
  }

  String currentFolder = 'Root';

  for (final row in rows) {
    if (row.classes.contains('eipItem')) {
      // It's a category/folder header row
      currentFolder = row.text.trim();
      continue;
    }

    // It's a content row containing a table with actual portal links
    final aTags = row.querySelectorAll('a');
    for (final a in aTags) {
      final name = a.text.trim();
      if (name.isEmpty) continue;

      final href = a.attributes['href'] ?? '';
      final onclick = a.attributes['onclick'] ?? '';

      // Check if this item is a subfolder tree
      String? subFolderDn;
      String? apDn;

      final nextPopMatch =
          nextPopRegexp.firstMatch(href) ?? nextPopRegexp.firstMatch(onclick);
      if (nextPopMatch != null) {
        subFolderDn = nextPopMatch.group(1);
        apDn = nextPopMatch.group(2);
      } else {
        final subListMatch =
            subListRegexp.firstMatch(href) ?? subListRegexp.firstMatch(onclick);
        if (subListMatch != null) {
          subFolderDn = subListMatch.group(1);
          apDn = subListMatch.group(2);
        }
      }

      if (subFolderDn != null && apDn != null) {
        await scrapeSubtree(subFolderDn, apDn, '$currentFolder - $name');
      } else {
        String? code;

        // Try to find the apOu code in ssoLogAdd call in parents or the element itself
        dom.Element? current = a;
        while (current != null && current != row) {
          final currentOnclick = current.attributes['onclick'] ?? '';
          final match = ssoLogAddRegexp.firstMatch(currentOnclick);
          if (match != null) {
            code = match.group(1);
            break;
          }
          current = current.parent;
        }

        // Fallback: extract apOu from query parameters of the href URL
        if (code == null && href.isNotEmpty) {
          try {
            final uri = Uri.parse(href);
            code = uri.queryParameters['apOu'];
          } catch (_) {}
        }

        // Build full URL
        String fullUrl = href;
        if (href.isNotEmpty &&
            !href.startsWith('http') &&
            !href.startsWith('javascript:')) {
          fullUrl = Uri.parse(
            'https://nportal.ntut.edu.tw/',
          ).resolve(href).toString();
        }

        final signature = '$currentFolder|$name|$code|$fullUrl';
        if (seen.contains(signature)) continue;
        seen.add(signature);

        scrapedItems.add({
          'category': currentFolder,
          'name': name,
          'code': code ?? '',
          'url': fullUrl,
        });
      }
    }
  }

  // Step 4: Output the results
  final format = argResults['format'] as String;
  final String outputString;

  if (format == 'json') {
    outputString = const JsonEncoder.withIndent('  ').convert(scrapedItems);
  } else {
    // Plain text table format
    final buffer = StringBuffer();
    buffer.writeln('NTUT Portal Endpoints Scraped:');
    buffer.writeln('=' * 80);
    String? lastCategory;
    for (final item in scrapedItems) {
      if (item['category'] != lastCategory) {
        lastCategory = item['category'];
        buffer.writeln('\n[Category] $lastCategory');
        buffer.writeln('-' * 80);
      }
      buffer.writeln('  * Name: ${item['name']}');
      buffer.writeln('    Code: ${item['code']}');
      buffer.writeln('    URL:  ${item['url']}');
    }
    outputString = buffer.toString();
  }

  final outputPath = argResults['output'] as String?;
  if (outputPath != null) {
    try {
      final outputFile = File(outputPath);
      outputFile.writeAsStringSync(outputString);
      stderr.writeln('Success: Wrote scraped endpoints to $outputPath');
    } catch (e) {
      stderr.writeln('Error: Failed to write output file at $outputPath: $e');
      exit(1);
    }
  } else {
    stdout.write(outputString);
  }
}
