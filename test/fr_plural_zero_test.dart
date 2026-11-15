import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// En français, 0 tombe dans la catégorie « one » comme 1 : un pluriel dont le cas
/// « =1 » écrit « 1 … » doit avoir un cas « =0 », sinon zéro s'affiche « 1 … ».
/// Correction : python3 docs/fr_pluriel_zero.py lib/l10n/app_fr.arb (dépôt sunday_jobs).
void main() {
  test('Pluriels français : un cas « =0 » quand « =1 » écrit « 1 »', () {
    final arb = jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync()) as Map<String, dynamic>;
    final un = RegExp(r'(=1|one)\{[^{}]*(?<![\d])1(?![\d])');
    final missing = [
      for (final e in arb.entries)
        if (!e.key.startsWith('@') && e.value is String && un.hasMatch(e.value as String) && !(e.value as String).contains('=0{'))
          e.key,
    ];
    expect(missing, isEmpty, reason: 'Pluriels sans cas « =0 » : $missing');
  });
}
