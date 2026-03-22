import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  void showErrorDialog(
    Object error, {
    ErrorType type = ErrorType.unknown,
    StackTrace? stackTrace,
  }) {
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null) return;
    final errorMessage = error.toString();
    final copyText = [
      errorMessage,
      if (stackTrace != null) stackTrace.toString(),
    ].join('\n');
    final errorTitle = switch (type) {
      ErrorType.flutter => t.errors.flutterError,
      ErrorType.async => t.errors.asyncError,
      ErrorType.unknown => t.errors.occurred,
    };

    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(errorTitle),
        // TODO: Remove technical details from user-facing error messages
        content: SelectableText(errorMessage),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!rootContext.mounted) return;
              ScaffoldMessenger.maybeOf(rootContext)?.showSnackBar(
                SnackBar(content: Text(t.general.copied)),
              );
            },
            child: Text(t.general.copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.general.ok),
          ),
        ],
      ),
    );
  }

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (details) {
    firebaseService.crashlytics?.recordFlutterFatalError(details);
    FlutterError.dumpErrorToConsole(details);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showErrorDialog(
        details.exception,
        type: ErrorType.flutter,
        stackTrace: details.stack,
      );
    });
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    firebaseService.crashlytics?.recordError(error, stack, fatal: true);
    showErrorDialog(error, type: ErrorType.async, stackTrace: stack);
    log('Uncaught asynchronous error: $error', stackTrace: stack);
    return true;
  };

  firebaseService.analytics?.logAppOpen();

  await LocaleSettings.useDeviceLocale();

  final authRepository = container.read(authRepositoryProvider);
  final user = await authRepository.getUser();
  final initialLocation = user != null ? AppRoutes.home : AppRoutes.intro;
  final router = createAppRouter(initialLocation: initialLocation);

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

  static const themeColor = Color(0xFF4B709B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: t.general.appTitle,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
      ),
      routerConfig: router,
    );
  }
}
