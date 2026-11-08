import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'core/theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/library_screen.dart';

class ComprendreApp extends ConsumerWidget {
  const ComprendreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(settingsProvider.select((s) => s.value?.localeCode));
    final themeMode = ref.watch(settingsProvider.select((s) => s.value?.themeMode));
    final ready = ref.watch(settingsProvider.select((s) => s.hasValue));
    return MaterialApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: code == null ? null : Locale(code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Anglais si le téléphone est en anglais, sinon français.
      localeResolutionCallback: (device, supported) => device?.languageCode == 'en' ? const Locale('en') : const Locale('fr'),
      home: ready ? const LibraryScreen() : const Scaffold(),
    );
  }
}
