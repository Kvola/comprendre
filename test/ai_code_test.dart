import 'dart:convert';

import 'package:comprendre/app.dart';
import 'package:comprendre/app/providers.dart';
import 'package:comprendre/data/database.dart';
import 'package:comprendre/remote/ai_client.dart';
import 'package:comprendre/ui/ai_code.dart';
import 'package:comprendre/ui/codes_screen.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Serveur simulé : un code valable, « BON7-CODE », 12 quiz jusqu'au 31/12/2026 ;
/// « AUTRE-TEL1 » est sur un autre téléphone (transférable une fois).
class _FakeServer {
  bool redeemed = false;
  bool transferredHere = false;
  bool offline = false;
  final calls = <String>[];
  /// Paramètres des activations demandées.
  final sent = <Map<String, dynamic>>[];

  Map<String, dynamic> _code(String code) => {
    'code': code, 'remaining': 12, 'credits': 12, 'expires': '2026-12-31', 'daily_left': false, 'usable_today': true,
    'state': 'active', 'used': 0, 'used_by_me': 0, 'daily_limit': 0, 'max_devices': 1, 'devices': 1,
    'activated': '2026-11-12 10:00:00', 'last_used': false, 'source': 'gift', 'transfers_left': 1,
  };

  List<Map<String, dynamic>> get _codes => [if (redeemed) _code('BON7-CODE'), if (transferredHere) _code('AUTRE-TEL1')];

  Map<String, dynamic> get _quota => {
    'success': true, 'remaining': 3 + 12 * _codes.length, 'free_remaining': 3, 'code_remaining': 12 * _codes.length,
    'codes': _codes, 'all_codes': _codes, 'daily': 3, 'max_chars': 30000, 'enabled': true, 'limited': '',
    'languages': ['fr', 'en'],
  };

  Map<String, dynamic> _refused(String reason, [Map<String, dynamic> more = const {}]) => {
    'success': false,
    'error': {'code': 'REFUSED', 'message': 'x', 'details': {'reason': reason, ...more}},
  };

  late final client = MockClient((req) async {
    if (offline) throw http.ClientException('hors ligne');
    final path = req.url.path.replaceFirst('/comprendre/api/v1/', '');
    final params = jsonDecode(req.body)['params'] as Map<String, dynamic>;
    calls.add(path);
    if (path == 'redeem') sent.add(params);
    final key = '${params['code']}'.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    Map<String, dynamic> result;
    if (path == 'redeem') {
      if (key == 'BON7CODE') {
        final already = redeemed;
        redeemed = true;
        result = {..._quota, 'redeemed': _code('BON7-CODE'), 'already': already};
      } else if (key == 'AUTRETEL1') {
        if (params['transfer'] == true) {
          transferredHere = true;
          result = {..._quota, 'redeemed': _code('AUTRE-TEL1')};
        } else {
          result = _refused('code_transferable', {'transfers_left': 1});
        }
      } else {
        result = _refused('code_unknown');
      }
    } else if (path == 'code/release') {
      if (key == 'BON7CODE' && redeemed) {
        redeemed = false;
        result = _quota;
      } else {
        result = _refused('code_unknown');
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

  test('code repéré dans un texte collé', () {
    expect(findAiCode('Votre code IA : ab12-cd34 !'), 'AB12-CD34');
    expect(findAiCode('Bonjour, voici le code LYC-7KQ3-M9PX pour la classe.'), 'LYC-7KQ3-M9PX');
    expect(findAiCode('  demo 2026 '), 'DEMO-2026');
    expect(findAiCode('KQMX-PAHT'), 'KQMX-PAHT', reason: 'sans chiffre mais en majuscules');
    expect(findAiCode('Votre code-barre est prêt'), isNull);
    expect(findAiCode('Bonjour, comment allez-vous aujourd’hui ?'), isNull);
    expect(findAiCode(null), isNull);
  });

  test('codes : jours restants, état, expire bientôt', () {
    final now = DateTime(2026, 12, 29, 15);
    final soon = AiCode.fromJson({'code': 'A', 'remaining': 4, 'credits': 10, 'expires': '2026-12-31'});
    final later = AiCode.fromJson({'code': 'B', 'remaining': 4, 'credits': 10, 'expires': '2027-03-01'});
    final off = AiCode.fromJson({'code': 'C', 'remaining': 4, 'credits': 10, 'state': 'disabled'});
    expect(soon.daysLeft(now), 2);
    expect(later.daysLeft(now), 62);
    expect(off.daysLeft(now), isNull);
    expect((soon.stateAt(now), off.stateAt(now)), ('active', 'disabled'));
    expect(off.isLive(now), isFalse);
    expect(expiringSoon([later, soon, off], now)?.code, 'A');
    expect(expiringSoon([later], now), isNull);
    expect(soon.daysLeft(DateTime(2026, 12, 31, 23, 59)), 0, reason: 'dernier jour');
  });

  Future<AppDatabase> pumpApp(WidgetTester tester, _FakeServer server) async {
    // Un téléphone (393 × 873) plutôt que l'écran 800 × 600 par défaut des tests.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
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
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    });
    return db;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openSettings(WidgetTester tester) async {
    await settle(tester);
    await tester.tap(find.byTooltip('Réglages'));
    await settle(tester);
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    final enter = find.byKey(const ValueKey('ai-code-enter'));
    await tester.scrollUntilVisible(enter, 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('ai-code-field')), code);
    await tester.tap(find.text('Activer'));
    await settle(tester);
  }

  testWidgets('réglages : code refusé avec son motif, puis code activé (et l’IA allumée)', (tester) async {
    final server = _FakeServer();
    final db = await pumpApp(tester, server);
    await openSettings(tester);

    await enterCode(tester, 'faux-code');
    expect(find.text('Ce code IA n’existe pas. Vérifiez-le.'), findsOneWidget, reason: 'erreur dans la fenêtre, à corriger');
    final field = tester.widget<TextField>(find.byKey(const ValueKey('ai-code-field')));
    expect(field.focusNode!.hasFocus, isTrue, reason: 'le curseur revient dans le champ');
    expect(field.controller!.selection.textInside(field.controller!.text), 'faux-code', reason: 'texte sélectionné');

    await tester.enterText(find.byKey(const ValueKey('ai-code-field')), 'bon7 code');
    await tester.tap(find.text('Activer'));
    await settle(tester);
    expect(find.textContaining('Code activé : 12 quiz IA disponibles.'), findsOneWidget);
    expect(find.textContaining('L’IA est activée'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('ai')), 'on');
    expect(server.calls.where((c) => c == 'redeem').length, 2);
    expect(server.sent.last['can_transfer'], isTrue, reason: 'l’application sait proposer un transfert');

    // Les réglages résument ; « Mes codes IA » détaille.
    await settle(tester);
    expect(find.text('Encore 15 quiz IA aujourd’hui'), findsOneWidget);
    expect(find.text('3 du quota gratuit + 12 avec vos codes IA'), findsOneWidget);
    expect(find.text('1 code · 12 quiz IA restants'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('my-codes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('my-codes')));
    await settle(tester);
    expect(find.text('BON7-CODE'), findsOneWidget);
    expect(find.text('12 quiz IA restants'), findsOneWidget);
    expect(find.text('0 utilisés sur 12'), findsOneWidget);
    expect(find.text('Reçu'), findsOneWidget);
  });

  testWidgets('changement de téléphone : transfert proposé puis confirmé', (tester) async {
    final server = _FakeServer();
    await pumpApp(tester, server);
    await openSettings(tester);
    await enterCode(tester, 'autre-tel1');
    expect(find.text('Transférer ce code ici ?'), findsOneWidget);
    expect(find.textContaining('C’est le dernier transfert permis.'), findsOneWidget);
    expect(server.transferredHere, isFalse, reason: 'rien ne bouge avant la confirmation');
    await tester.tap(find.text('Transférer'));
    await settle(tester);
    expect(server.transferredHere, isTrue);
    expect(server.sent.last['transfer'], isTrue);
    expect(find.textContaining('Code transféré sur ce téléphone.'), findsOneWidget);
  });

  testWidgets('mes codes : retirer un code ; hors connexion, dernier état daté', (tester) async {
    final server = _FakeServer()..redeemed = true;
    final db = await pumpApp(tester, server);
    await tester.runAsync(() => db.setSetting('ai', 'on'));
    await openSettings(tester);
    final tile = find.byKey(const ValueKey('my-codes'));
    await tester.scrollUntilVisible(tile, 120, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await settle(tester);
    expect(find.text('BON7-CODE'), findsOneWidget);

    // Hors connexion : l'état enregistré reste lisible, sans « retirer ».
    server.offline = true;
    await tester.tap(find.byTooltip('Réessayer').first);
    await settle(tester);
    expect(find.textContaining('Hors connexion : état au'), findsOneWidget);
    expect(find.text('BON7-CODE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('code-menu-BON7-CODE')));
    await settle(tester);
    expect(find.text('Retirer de ce téléphone'), findsNothing);
    expect(find.text('Copier le code'), findsOneWidget);
    await tester.tap(find.text('Copier le code'));
    await settle(tester);

    // En ligne : retirer (pour le donner).
    server.offline = false;
    await tester.tap(find.byTooltip('Réessayer').first);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('code-menu-BON7-CODE')));
    await settle(tester);
    await tester.tap(find.text('Retirer de ce téléphone'));
    await settle(tester);
    expect(find.textContaining('les 12 quiz IA restants restent sur le code'), findsOneWidget);
    await tester.tap(find.text('Retirer de ce téléphone').last);
    await settle(tester);
    expect(server.calls.last, 'quota', reason: 'liste rafraîchie après le retrait');
    expect(server.calls, contains('code/release'));
    expect(find.text('BON7-CODE'), findsNothing);
    expect(find.text('Aucun code IA sur ce téléphone'), findsOneWidget);
  });
}
