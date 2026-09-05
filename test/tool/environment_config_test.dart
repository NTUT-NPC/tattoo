import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/firebase_options.dart';

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
      expect(ios['bundle_identifier'], equals('com.ntut.tatflutter'));
      expect(ios['bundle_display_name'], equals('TAT'));
      expect(ios['app_icon_name'], equals('AppIcon'));
      expect(
        ios['google_service_info_path'],
        equals('ios/Runner/GoogleService-Info.plist'),
      );

      final firebase = json['firebase'] as Map<String, dynamic>;
      expect(firebase['project_id'], equals('npc-tattoo-prod'));
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
      expect(
        DefaultFirebaseOptions.iosProd.iosBundleId,
        equals('com.ntut.tatflutter'),
      );
    });
  });
}
