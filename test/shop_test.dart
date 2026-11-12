import 'dart:convert';

import 'package:comprendre/app/providers.dart';
import 'package:comprendre/core/theme.dart';
import 'package:comprendre/data/database.dart';
import 'package:comprendre/l10n/gen/app_localizations.dart';
import 'package:comprendre/remote/ai_client.dart';
import 'package:comprendre/ui/shop_screen.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Serveur simulé : une offre, un achat par clé, paiement confirmé à la demande.
class _FakeShop {
  final buyRefs = <String>[];
  final waveRefs = <String>[];
  bool loseNextBuyResponse = false;
  bool paid = false;
  bool autoConfirm = false;
  String? orderRef;
  Map<String, dynamic>? extraPack;
  Map<String, dynamic>? advice;

  Map<String, dynamic> get _order => {
    'ref': 'ACH-2026-00001', 'pack_id': 7, 'pack': 'Étude', 'credits': 30, 'amount': 2500, 'currency': 'XOF',
    'state': paid ? 'done' : 'draft', 'mode': autoConfirm ? 'checkout' : 'merchant',
    'awaiting_validation': !paid && !autoConfirm, 'wave_ref': waveRefs.isEmpty ? false : waveRefs.last,
    'created': '2026-11-12 10:00:00', 'code': paid ? 'PAYE-CODE' : false,
  };

  late final client = MockClient((req) async {
    final path = req.url.path.replaceFirst('/comprendre/api/v1', '');
    final params = jsonDecode(req.body)['params'] as Map<String, dynamic>;
    Map<String, dynamic> result;
    switch (path) {
      case '/shop':
        result = {
          'success': true, 'payment_available': true, 'auto_confirm': autoConfirm,
          'packs': [
            {'id': 7, 'name': 'Étude', 'description': 'Un trimestre', 'credits': 30, 'price': 2500, 'currency': 'XOF',
              'validity_days': 180, 'daily_limit': 0, ...?extraPack},
          ],
          'advice': ?advice,
          'orders': orderRef == null ? [] : [_order],
        };
      case '/buy':
        buyRefs.add('${params['client_ref']}');
        orderRef = 'ACH-2026-00001';
        if (loseNextBuyResponse) {
          loseNextBuyResponse = false;
          throw http.ClientException('réseau coupé après l’envoi');
        }
        result = {'success': true, 'order': _order, 'mode': 'merchant', 'url': 'https://pay.wave.com/m/TEST/c/ci/?amount=2500'};
      case '/order/wave-ref':
        if ('${params['wave_ref']}'.trim().length < 6) {
          result = {'success': false, 'error': {'code': 'REFUSED', 'message': 'x', 'details': {'reason': 'bad_wave_ref'}}};
        } else {
          waveRefs.add('${params['wave_ref']}'.trim());
          result = {'success': true, 'order': _order};
        }
      default:
        result = {'success': true, 'remaining': 0, 'daily': 5, 'max_chars': 30000};
    }
    return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': result}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<AppDatabase> pump(WidgetTester tester, _FakeShop server) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await tester.runAsync(() => db.setSetting('ai', 'off'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          aiClientProvider.overrideWith((ref) async => AiClient(deviceId: 'device-0123456789abcdef', httpClient: server.client)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light), // la palette de l'application (couleurs « succès »…)
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShopScreen(),
        ),
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

  testWidgets('achat : réponse perdue puis réessai (même clé), lien Wave, identifiant, confirmation', (tester) async {
    final server = _FakeShop()..loseNextBuyResponse = true;
    final db = await pump(tester, server);
    await settle(tester);
    expect(find.text('Étude'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Text && RegExp(r'^2\s500\sF CFA$').hasMatch(w.data ?? '')),
      findsOneWidget,
      reason: 'prix en francs CFA, séparateurs insécables',
    );
    expect(find.text('30 quiz IA'), findsOneWidget);

    // 1er essai : la réponse se perd.
    await tester.tap(find.text('Payer avec Wave').last);
    await settle(tester);
    await tester.tap(find.text('Payer avec Wave').last); // confirmation
    await settle(tester);
    expect(find.text('Pas de connexion au service : réessayez quand vous serez connecté.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6)); // le message en bas de l'écran disparaît
    await settle(tester);

    // L'achat existe déjà côté serveur : il apparaît en attente. Réessai depuis l'offre : même clé.
    final buyButton = find.byKey(const ValueKey('buy-7'));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await settle(tester);
    await tester.tap(buyButton);
    await settle(tester);
    await tester.tap(find.text('Payer avec Wave').last);
    await settle(tester);
    expect(server.buyRefs.length, 2);
    expect(server.buyRefs[0], server.buyRefs[1], reason: 'un réessai ne doit jamais créer un second achat');

    // Wave ne s'ouvre pas dans les tests : le lien est proposé.
    expect(find.text('Wave n’a pas pu s’ouvrir. Ouvrez ce lien pour payer :'), findsOneWidget);
    expect(find.text('https://pay.wave.com/m/TEST/c/ci/?amount=2500'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await settle(tester);

    // Achat en attente, validé par un agent : l'identifiant de transaction aide.
    expect(find.text('Paiement en attente'), findsOneWidget);
    expect(find.textContaining('notre équipe le confirme'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('wave-ref-ACH-2026-00001')), 'T12');
    await tester.tap(find.byTooltip('Envoyer'));
    await settle(tester);
    expect(find.text('Cet identifiant est trop court.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('wave-ref-ACH-2026-00001')), ' T_ABC123456 ');
    await tester.tap(find.byTooltip('Envoyer'));
    await settle(tester);
    expect(find.text('Identifiant envoyé : T_ABC123456'), findsOneWidget);

    // L'agent valide ; « Vérifier » : confirmation annoncée, IA allumée, clé oubliée.
    server.paid = true;
    await tester.tap(find.byTooltip('Vérifier')); // bouton de la barre, toujours visible
    await settle(tester);
    expect(find.text('Paiement confirmé : 30 quiz IA ajoutés.'), findsOneWidget);
    expect(find.text('Payé : quiz IA ajoutés'), findsOneWidget);
    expect(find.textContaining('Code PAYE-CODE'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('ai')), 'on');
    final raw = await tester.runAsync<String?>(() => db.setting('shop_pending'));
    final refs = jsonDecode(raw!) as Map;
    expect(refs, isEmpty);
  });

  testWidgets('API Wave : message de confirmation automatique, pas de champ d’identifiant', (tester) async {
    final server = _FakeShop()
      ..autoConfirm = true
      ..orderRef = 'ACH-2026-00001';
    await pump(tester, server);
    await settle(tester);
    expect(find.textContaining('Wave confirme le paiement en quelques instants'), findsOneWidget);
    expect(find.byKey(const ValueKey('wave-ref-ACH-2026-00001')), findsNothing);
  });

  testWidgets('tarifs : prix par quiz, économie, badges et conseil d’après l’usage', (tester) async {
    final server = _FakeShop()
      ..extraPack = {'price_per_quiz': 83.33, 'saving_percent': 17, 'highlight': true, 'best_value': true, 'recommended': true}
      ..advice = {'monthly': 20, 'extra_monthly': 12, 'free_enough': false, 'daily_free': 5, 'recommended_id': 7};
    await pump(tester, server);
    await settle(tester);
    expect(find.textContaining('vous avez voulu 12 quiz IA de plus que le quota gratuit'), findsOneWidget);
    expect(find.textContaining('Conseil : Étude'), findsOneWidget);
    expect(find.text('Conseillé pour vous'), findsOneWidget);
    expect(find.text('Le plus choisi'), findsOneWidget);
    expect(find.text('Meilleur prix'), findsOneWidget);
    expect(find.text('−17 % par quiz'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Text && RegExp(r'^soit 83\s?F CFA le quiz$').hasMatch(w.data ?? '')),
        findsOneWidget, reason: 'prix par quiz arrondi au franc');
  });

  testWidgets('tarifs : le gratuit suffit, on le dit', (tester) async {
    final server = _FakeShop()..advice = {'monthly': 8, 'extra_monthly': 0, 'free_enough': true, 'daily_free': 5};
    await pump(tester, server);
    await settle(tester);
    expect(find.textContaining('vos 5 quiz IA gratuits par jour ont suffi'), findsOneWidget);
    expect(find.text('Conseillé pour vous'), findsNothing);
    expect(find.byWidgetPredicate((w) => w is Text && RegExp(r'^soit 83\s?F CFA le quiz$').hasMatch(w.data ?? '')),
        findsOneWidget, reason: 'serveur ancien : prix par quiz calculé par l’application');
  });

  test('prix lisibles', () {
    expect(AiPack.fromJson({'id': 1, 'name': 'x', 'credits': 3, 'price': 1000, 'currency': 'XOF'}).price, 1000);
  });
}
