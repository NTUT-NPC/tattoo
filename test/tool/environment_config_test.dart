import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/firebase_options.dart';

import '../../tool/credentials.dart';

void main() {
  group('Environment Configuration Files', () {
    test('development.json has valid dev settings', () {
      final file = File('build_config/development.json');
      expect(file.existsSync(), isTrue);

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['flavor'], equals('dev'));
      expect(json['name'], equals('development'));
      expect(json['app_name'], equals('Tattoo'));

      final android = json['android'] as Map<String, dynamic>;
      expect(android['application_id'], equals('club.ntut.tattoo'));
      expect(android['app_name'], equals('Tattoo'));
      expect(android['icon'], equals('ic_launcher'));
      expect(
        android['google_services_path'],
        equals('android/app/google-services.json'),
      );
      expect(
        android['res_dir'],
        equals('android/app/src/dev/res'),
      );

      final ios = json['ios'] as Map<String, dynamic>;
      expect(ios['bundle_identifier'], equals('club.ntut.tattoo'));
      expect(ios['bundle_display_name'], equals('Tattoo'));
      expect(ios['app_icon_name'], equals('AppIcon-dev'));
      expect(
        ios['google_service_info_path'],
        equals('ios/Runner/GoogleService-Info.plist'),
      );

      final firebase = json['firebase'] as Map<String, dynamic>;
      expect(firebase['project_id'], equals('npc-tattoo'));
    });

    test('production.json has valid prod settings', () {
      final file = File('build_config/production.json');
      expect(file.existsSync(), isTrue);

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['flavor'], equals('prod'));
      expect(json['name'], equals('production'));
      expect(json['app_name'], equals('TAT'));

      final android = json['android'] as Map<String, dynamic>;
      expect(android['application_id'], equals('club.ntut.npc.tat'));
      expect(android['app_name'], equals('TAT'));
      expect(android['icon'], equals('ic_launcher'));
      expect(
        android['google_services_path'],
        equals('android/app/google-services.json'),
      );
      expect(
        android['res_dir'],
        equals('android/app/src/main/res'),
      );

      final ios = json['ios'] as Map<String, dynamic>;
      expect(ios['bundle_identifier'], equals('com.npc.tatFlutter'));
      expect(ios['bundle_display_name'], equals('TAT'));
      expect(ios['app_icon_name'], equals('AppIcon'));
      expect(
        ios['google_service_info_path'],
        equals('ios/Runner/GoogleService-Info.plist'),
      );

      final firebase = json['firebase'] as Map<String, dynamic>;
      expect(firebase['project_id'], equals('npc-tattoo-prod'));
    });

    test('canonical configs and flat Dart defines stay separate', () {
      const environments = [
        ('dev', 'development', 'dev.defines.json'),
        ('prod', 'production', 'prod.defines.json'),
      ];

      for (final (alias, canonicalName, definesName) in environments) {
        final canonical = jsonDecode(
          File('build_config/$alias.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        expect(canonical['name'], equals(canonicalName));
        expect(canonical, isNot(contains('ENV')));
        expect(canonical['android'], isA<Map<String, dynamic>>());
        expect(canonical['ios'], isA<Map<String, dynamic>>());
        expect(canonical['firebase'], isA<Map<String, dynamic>>());

        final defines = jsonDecode(
          File('build_config/$definesName').readAsStringSync(),
        ) as Map<String, dynamic>;
        expect(
          defines.values.every((value) => value is String),
          isTrue,
        );
        expect(defines['FLAVOR'], equals(canonical['flavor']));
        expect(defines['APP_NAME'], equals(canonical['app_name']));
        expect(
          defines['ANDROID_APPLICATION_ID'],
          equals(
            (canonical['android'] as Map<String, dynamic>)['application_id'],
          ),
        );
      }
    });

    test('schema.json exists and defines required properties', () {
      final file = File('build_config/schema.json');
      expect(file.existsSync(), isTrue);

      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
        json['required'],
        containsAll(['flavor', 'android', 'ios', 'firebase']),
      );
    });

    test('dev and prod asset directories exist', () {
      expect(Directory('android/app/src/dev/res').existsSync(), isTrue);
      expect(Directory('android/app/src/main/res').existsSync(), isTrue);
      expect(Directory('ios/Runner/AppIcon-dev.icon').existsSync(), isTrue);
      expect(Directory('ios/Runner/AppIcon.icon').existsSync(), isTrue);
    });
    test('EnvironmentConfig resolves both short environment names', () {
      expect(EnvironmentConfig.load('dev').flavor, equals('dev'));
      expect(EnvironmentConfig.load('prod').flavor, equals('prod'));
    });
  });

  group('Firebase Options', () {
    test('DefaultFirebaseOptions dev and prod configurations are distinct', () {
      expect(DefaultFirebaseOptions.androidDev.projectId, equals('npc-tattoo'));
      expect(
        DefaultFirebaseOptions.androidProd.projectId,
        equals('npc-tattoo-prod'),
      );
      expect(DefaultFirebaseOptions.iosDev.projectId, equals('npc-tattoo'));
      expect(
        DefaultFirebaseOptions.iosProd.projectId,
        equals('npc-tattoo-prod'),
      );

      expect(
        DefaultFirebaseOptions.iosDev.iosBundleId,
        equals('club.ntut.tattoo'),
      );
      final development = jsonDecode(
        File('build_config/development.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final production = jsonDecode(
        File('build_config/production.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final devFirebase = development['firebase'] as Map<String, dynamic>;
      final prodFirebase = production['firebase'] as Map<String, dynamic>;
      expect(
        (devFirebase['android'] as Map<String, dynamic>)['app_id'],
        equals(DefaultFirebaseOptions.androidDev.appId),
      );
      expect(
        (devFirebase['ios'] as Map<String, dynamic>)['app_id'],
        equals(DefaultFirebaseOptions.iosDev.appId),
      );
      expect(
        devFirebase['project_id'],
        equals(DefaultFirebaseOptions.androidDev.projectId),
      );
      expect(
        (prodFirebase['android'] as Map<String, dynamic>)['app_id'],
        equals(DefaultFirebaseOptions.androidProd.appId),
      );
      expect(
        (prodFirebase['ios'] as Map<String, dynamic>)['app_id'],
        equals(DefaultFirebaseOptions.iosProd.appId),
      );
      expect(
        prodFirebase['project_id'],
        equals(DefaultFirebaseOptions.androidProd.projectId),
      );
      expect(
        DefaultFirebaseOptions.iosProd.iosBundleId,
        equals('com.npc.tatFlutter'),
      );
    });
  });
}
