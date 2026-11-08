import 'package:flutter/material.dart';

/// Couleurs de marque : bleu-vert profond (réflexion, calme) et ambre (l'idée
/// qui s'allume). Les écrans n'emploient pas ces constantes pour du texte :
/// ils passent par le ColorScheme (Material 3, contrasté par construction) et
/// par [AppPalette], vérifiés par test/theme_contrast_test.dart.
abstract final class BrandColors {
  static const teal = Color(0xFF0E5E6F);
  static const amber = Color(0xFFF2A541);
  static const darkBackground = Color(0xFF0F1416);
}

/// Couleurs sémantiques (bonne / mauvaise réponse, citation), pour chaque luminosité.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.wrong,
    required this.wrongContainer,
    required this.onWrongContainer,
    required this.quoteBackground,
    required this.quoteBar,
    required this.highlight,
    required this.onHighlight,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color wrong;
  final Color wrongContainer;
  final Color onWrongContainer;

  /// Encadré « Dans le texte » (citation).
  final Color quoteBackground;
  final Color quoteBar;

  /// Passage surligné dans le texte.
  final Color highlight;
  final Color onHighlight;

  static const light = AppPalette(
    success: Color(0xFF1E6B34),
    successContainer: Color(0xFFDDF1E1),
    onSuccessContainer: Color(0xFF0B3A19),
    wrong: Color(0xFFB3261E),
    wrongContainer: Color(0xFFFBE2DF),
    onWrongContainer: Color(0xFF5C0F0A),
    quoteBackground: Color(0xFFF1F6F7),
    quoteBar: BrandColors.teal,
    highlight: Color(0xFFFFE3A8),
    onHighlight: Color(0xFF1B1B1B),
  );

  static const dark = AppPalette(
    success: Color(0xFF8ED69C),
    successContainer: Color(0xFF173D22),
    onSuccessContainer: Color(0xFFCDEFD3),
    wrong: Color(0xFFFFA59E),
    wrongContainer: Color(0xFF4D1915),
    onWrongContainer: Color(0xFFFFDAD6),
    quoteBackground: Color(0xFF1A2326),
    quoteBar: Color(0xFF7FC8D6),
    highlight: Color(0xFF6B4E12),
    onHighlight: Color(0xFFFFF3DC),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => t < 0.5 || other == null ? this : other;
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.teal,
    brightness: brightness,
    // Un fond franchement sombre en mode sombre (meilleur contraste, moins de fatigue).
    surface: dark ? BrandColors.darkBackground : null,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [dark ? AppPalette.dark : AppPalette.light],
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface, scrolledUnderElevation: 2, centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52))),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
