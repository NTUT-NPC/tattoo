import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/firebase_options.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/services/firebase_service.dart';

enum ErrorType {
  flutter,
  async,
  unknown,
}

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

  void showErrorDialog(Object error, {ErrorType type = ErrorType.unknown}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final errorTitle = switch (type) {
      ErrorType.flutter => t.errors.flutterError,
      ErrorType.async => t.errors.asyncError,
      ErrorType.unknown => t.errors.occurred,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(errorTitle),
        // TODO: Remove technical details from user-facing error messages
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.general.ok),
          ),
        ],
      ),
    );
  }

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (details) {
    firebase.crashlytics?.recordFlutterFatalError(details);
    showErrorDialog(details.exception, type: ErrorType.flutter);
    FlutterError.dumpErrorToConsole(details);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    firebase.crashlytics?.recordError(error, stack, fatal: true);
    showErrorDialog(error, type: ErrorType.async);
    log('Uncaught asynchronous error: $error', stackTrace: stack);
    return true;
  };

  firebase.analytics?.logAppOpen();

  await LocaleSettings.useDeviceLocale();

  final authRepository = container.read(authRepositoryProvider);
  final user = await authRepository.getUser();
  final initialLocation = user != null ? AppRoutes.home : AppRoutes.intro;
  final router = buildAppRouter(initialLocation: initialLocation);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: MyApp(router: router),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

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
      routerConfig: router,
    );
  }
}
