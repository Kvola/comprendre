import 'dart:math' as math;

import 'package:comprendre/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    group('Contraste — ${brightness.name}', () {
      final theme = buildTheme(brightness);
      final s = theme.colorScheme;
      final p = theme.extension<AppPalette>()!;
      final card = theme.cardTheme.color!;
      final text = <(String, Color, Color)>[
        ('texte / fond', s.onSurface, s.surface),
        ('texte / carte', s.onSurface, card),
        ('texte secondaire / carte', s.onSurfaceVariant, card),
        ('liens / fond', s.primary, s.surface),
        ('liens / carte', s.primary, card),
        ('bouton principal', s.onPrimary, s.primary),
        ('bonne réponse (texte)', p.success, s.surface),
        ('mauvaise réponse (texte)', p.wrong, s.surface),
        ('proposition juste', p.onSuccessContainer, p.successContainer),
        ('proposition fausse', p.onWrongContainer, p.wrongContainer),
        ('citation', s.onSurface, p.quoteBackground),
        ('lien dans la citation', s.primary, p.quoteBackground),
        ('passage surligné', p.onHighlight, p.highlight),
        ('encart d’information', s.onSecondaryContainer, s.secondaryContainer),
        ('proposition atténuée', s.onSurfaceVariant, s.surfaceContainerLow),
      ];
      for (final (name, fg, bg) in text) {
        test('$name ≥ 4,5:1', () => expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: contrast(fg, bg).toStringAsFixed(2)));
      }
      final graphics = <(String, Color, Color)>[
        ('bordure juste', p.success, p.successContainer),
        ('bordure fausse', p.wrong, p.wrongContainer),
        ('barre de citation', p.quoteBar, p.quoteBackground),
      ];
      for (final (name, fg, bg) in graphics) {
        test('$name ≥ 3:1', () => expect(contrast(fg, bg), greaterThanOrEqualTo(3), reason: contrast(fg, bg).toStringAsFixed(2)));
      }
    });
  }
}
