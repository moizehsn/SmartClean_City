import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/auth_wrapper.dart';
import 'dart:ui';

// ── Global locale notifier — read / write from anywhere in the app ────────────
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('fr'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Restore persisted locale or auto-detect
  final prefs = await SharedPreferences.getInstance();
  String? savedLang = prefs.getString('app_locale');
  
  if (savedLang == null) {
    // Auto-detect system language on first launch
    final systemLang = PlatformDispatcher.instance.locale.languageCode;
    savedLang = (systemLang == 'ar') ? 'ar' : 'fr';
    await prefs.setString('app_locale', savedLang);
  }
  
  localeNotifier.value = Locale(savedLang);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SmartCleanApp());
}

class SmartCleanApp extends StatelessWidget {
  const SmartCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (_, locale, __) {
        return MaterialApp(
          title: 'SmartClean City',
          debugShowCheckedModeBanner: false,
          // Rebuild theme so locale-aware fonts (Tajawal/Cairo) activate.
          theme: AppTheme.light,

          // ── Localization setup ──────────────────────────────────────
          locale: locale,
          supportedLocales: const [Locale('fr'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Convenience helper — toggle locale and persist the choice.
Future<void> toggleLocale() async {
  final current = localeNotifier.value.languageCode;
  final next = current == 'fr' ? 'ar' : 'fr';
  localeNotifier.value = Locale(next);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_locale', next);
}
