import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/firebase_options.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      log(e.toString(), name: 'Firebase Initialization');
    }
  }

  final container = ProviderContainer();
  final firebase = container.read(firebaseServiceProvider);

  FlutterError.onError = (details) {
    firebase.crashlytics?.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    firebase.crashlytics?.recordError(error, stack, fatal: true);
    return true;
  };

  firebase.analytics?.logAppOpen();

  await LocaleSettings.useDeviceLocale();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: t.general.appTitle,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: appRouter,
    );
  }
}
