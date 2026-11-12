import 'dart:convert';

import 'package:comprendre/app.dart';
import 'package:comprendre/app/providers.dart';
import 'package:comprendre/data/database.dart';
import 'package:comprendre/remote/ai_client.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Serveur simulé : un seul code valable, « BON7-CODE », 12 quiz jusqu'au 31/12/2026.
class _FakeServer {
  bool redeemed = false;
  final calls = <String>[];

  Map<String, dynamic> get _code => {
    'code': 'BON7-CODE', 'remaining': 12, 'credits': 12, 'expires': '2026-12-31', 'daily_left': false, 'usable_today': true,
  };

  Map<String, dynamic> get _quota => {
    'success': true, 'remaining': redeemed ? 15 : 3, 'free_remaining': 3, 'code_remaining': redeemed ? 12 : 0,
    'codes': redeemed ? [_code] : [], 'daily': 3, 'max_chars': 30000, 'enabled': true, 'limited': '',
    'languages': ['fr', 'en'],
  };

  late final client = MockClient((req) async {
    final path = req.url.path.split('/').last;
    final params = jsonDecode(req.body)['params'] as Map<String, dynamic>;
    calls.add(path);
    Map<String, dynamic> result;
    if (path == 'redeem') {
      if ('${params['code']}'.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '') == 'BON7CODE') {
        redeemed = true;
        result = {..._quota, 'redeemed': _code};
      } else {
        result = {
          'success': false,
          'error': {'code': 'REFUSED', 'message': 'x', 'details': {'reason': 'code_unknown'}},
        };
      }
    } else {
      result = _quota;
    }
    return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': result}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('quota : codes IA lus ; serveur ancien sans codes', () {
    final q = AiQuota.fromJson({
      'remaining': 15, 'free_remaining': 3, 'code_remaining': 12, 'daily': 3, 'max_chars': 30000,
      'codes': [
        {'code': 'AAAA-BBBB', 'remaining': 12, 'credits': 20, 'expires': '2026-12-31', 'daily_left': 2, 'usable_today': true},
        'abîmé',
      ],
    });
    expect((q.remaining, q.freeRemaining, q.codeRemaining), (15, 3, 12));
    expect(q.codes.single.code, 'AAAA-BBBB');
    expect(q.codes.single.dailyLeft, 2);
    expect(q.codes.single.isExpired(DateTime(2026, 12, 31, 23)), isFalse, reason: 'valable tout le dernier jour');
    expect(q.codes.single.isExpired(DateTime(2027, 1, 1)), isTrue);
    final old = AiQuota.fromJson({'remaining': 4, 'daily': 5, 'max_chars': 30000});
    expect((old.freeRemaining, old.codeRemaining), (4, 0));
    expect(old.codes, isEmpty);
  });

  testWidgets('réglages : code refusé avec son motif, puis code activé (et l’IA allumée)', (tester) async {
    final server = _FakeServer();
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await tester.runAsync(() async {
      await db.setSetting('locale', 'fr');
      await db.setSetting('ai', 'off');
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          aiClientProvider.overrideWith((ref) async => AiClient(deviceId: 'device-0123456789abcdef', httpClient: server.client)),
        ],
        child: const ComprendreApp(),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));
    }

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    });
    await settle();
    await tester.tap(find.byTooltip('Réglages'));
    await settle();
    final enter = find.byKey(const ValueKey('ai-code-enter'));
    await tester.ensureVisible(enter);
    await tester.tap(enter);
    await settle();

    await tester.enterText(find.byKey(const ValueKey('ai-code-field')), 'faux-code');
    await tester.tap(find.text('Activer'));
    await settle();
    expect(find.text('Ce code IA n’existe pas. Vérifiez-le.'), findsOneWidget, reason: 'erreur dans la fenêtre, à corriger');
    final field = tester.widget<TextField>(find.byKey(const ValueKey('ai-code-field')));
    expect(field.focusNode!.hasFocus, isTrue, reason: 'le curseur revient dans le champ');
    expect(field.controller!.selection.textInside(field.controller!.text), 'faux-code', reason: 'texte sélectionné');

    await tester.enterText(find.byKey(const ValueKey('ai-code-field')), 'bon7 code');
    await tester.tap(find.text('Activer'));
    await settle();
    expect(find.textContaining('Code activé : 12 quiz IA disponibles.'), findsOneWidget);
    expect(find.textContaining('L’IA est activée'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('ai')), 'on');
    expect(server.calls.where((c) => c == 'redeem').length, 2);

    // Le quota affiche le détail et le code.
    await settle();
    expect(find.text('Encore 15 quiz IA aujourd’hui'), findsOneWidget);
    expect(find.text('3 du quota gratuit + 12 avec vos codes IA'), findsOneWidget);
    expect(find.text('Code BON7-CODE'), findsOneWidget);
    expect(find.textContaining('12 quiz IA restants'), findsOneWidget);
  });
}
