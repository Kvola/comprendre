import 'dart:async';
import 'dart:convert';

import 'package:comprendre/core/app_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Réponse du serveur telle que la renvoie `mobile_app_release` (JSON-RPC).
Map<String, Object?> rpc(Map<String, Object?> result) => {'jsonrpc': '2.0', 'id': null, 'result': result};

Map<String, Object?> payload({
  String version = '2.0.0+9',
  bool available = true,
  bool mandatory = false,
  Object? notes = 'Corrections et nouveautés.',
  Object? download = 'https://iyf.ebng.world/apps/demo/download',
  Object? page = 'https://iyf.ebng.world/apps/demo',
}) => {
  'status': 'success',
  'app': 'demo',
  'latest_version': version,
  'latest_build': buildNumberOf(version),
  'current_build': 5,
  'update_available': available,
  'mandatory': mandatory,
  'min_supported_version': '',
  'release_notes': notes,
  'published_at': '2026-11-01 10:00:00',
  'download_url': download,
  'page_url': page,
};

/// Faux serveur : compte les appels et garde le dernier corps reçu.
class FakeUpdateServer {
  FakeUpdateServer(this.answer);

  Object? Function() answer;
  int calls = 0;
  http.Request? last;
  int status = 200;

  late final client = MockClient((req) async {
    calls++;
    last = req;
    final a = answer();
    return http.Response(a is String ? a : jsonEncode(a), status, headers: {'content-type': 'application/json'});
  });
}

void main() {
  group('parse', () {
    test('numéro de build', () {
      expect(buildNumberOf('1.4.0+5'), 5);
      expect(buildNumberOf('1.4.0'), isNull);
      expect(buildNumberOf(null), isNull);
      expect(buildNumberOf('1.4.0+x'), isNull);
    });

    test('mise à jour proposée', () {
      final info = parseAppUpdateResponse(rpc(payload()))!;
      expect(info.latestVersion, '2.0.0+9');
      expect(info.displayVersion, '2.0.0');
      expect(info.latestBuild, 9);
      expect(info.mandatory, isFalse);
      expect(info.releaseNotes, 'Corrections et nouveautés.');
      expect(info.links.first.toString(), 'https://iyf.ebng.world/apps/demo/download');
      expect(info.links.last.toString(), 'https://iyf.ebng.world/apps/demo');
    });

    test('obligatoire', () {
      expect(parseAppUpdateResponse(rpc(payload(mandatory: true)))!.mandatory, isTrue);
    });

    test('rien à proposer ou réponse inexploitable → null', () {
      expect(parseAppUpdateResponse(rpc(payload(available: false))), isNull);
      expect(
        parseAppUpdateResponse(rpc({'status': 'error', 'error_code': 'unknown_app', 'update_available': false})),
        isNull,
      );
      expect(parseAppUpdateResponse(rpc({...payload(), 'status': 'error'})), isNull);
      expect(
        parseAppUpdateResponse({
          'jsonrpc': '2.0',
          'error': {'code': 200, 'message': 'Odoo Server Error'},
        }),
        isNull,
      );
      expect(parseAppUpdateResponse(null), isNull);
      expect(parseAppUpdateResponse('oops'), isNull);
      expect(parseAppUpdateResponse([1, 2]), isNull);
      expect(parseAppUpdateResponse({'result': 'oops'}), isNull);
      expect(parseAppUpdateResponse(rpc({...payload(), 'update_available': 'true'})), isNull);
      expect(parseAppUpdateResponse(rpc({...payload(), 'latest_version': 9})), isNull);
      expect(parseAppUpdateResponse(rpc({...payload(), 'latest_version': ''})), isNull);
      // Aucune adresse utilisable : rien à ouvrir, donc rien à proposer.
      expect(parseAppUpdateResponse(rpc(payload(download: false, page: 'javascript:alert(1)'))), isNull);
    });

    test('champs vides à la mode Odoo (false) tolérés', () {
      final info = parseAppUpdateResponse(rpc(payload(notes: false, download: '')))!;
      expect(info.releaseNotes, '');
      expect(info.links.single.toString(), 'https://iyf.ebng.world/apps/demo');
    });

    test('notes tronquées sur une ligne', () {
      final info = AppUpdateInfo(latestVersion: '2.0.0+9', releaseNotes: 'a\n\n  b ${'x' * 300}');
      final short = info.shortNotes(40);
      expect(short.length, lessThanOrEqualTo(40));
      expect(short, startsWith('a b x'));
      expect(short, endsWith('…'));
      expect(const AppUpdateInfo(latestVersion: '1', releaseNotes: 'court').shortNotes(), 'court');
    });

    test('aller-retour JSON (cache)', () {
      final info = parseAppUpdateResponse(rpc(payload(mandatory: true)))!;
      expect(AppUpdateInfo.fromJson(jsonDecode(jsonEncode(info.toJson()))), info);
    });
  });

  group('checker', () {
    late MemoryAppUpdateStore store;
    late DateTime now;
    late FakeUpdateServer server;
    var installed = '1.4.0+5';

    AppUpdateChecker checker({http.Client? client, Duration timeout = const Duration(seconds: 8)}) => AppUpdateChecker(
      server: 'https://iyf.ebng.world/',
      slug: 'demo',
      store: store,
      currentVersion: () async => installed,
      client: client ?? server.client,
      now: () => now,
      timeout: timeout,
    );

    setUp(() {
      store = MemoryAppUpdateStore();
      now = DateTime.utc(2026, 11, 9, 8);
      installed = '1.4.0+5';
      server = FakeUpdateServer(() => rpc(payload()));
    });

    test('requête conforme au contrat', () async {
      final info = await checker().check();
      expect(info?.latestVersion, '2.0.0+9');
      final req = server.last!;
      expect(req.method, 'POST');
      expect(req.url.toString(), 'https://iyf.ebng.world/apps/demo/latest');
      expect(req.headers['content-type'], startsWith('application/json'));
      final body = jsonDecode(req.body) as Map;
      expect(body['jsonrpc'], '2.0');
      expect(body['params'], {'current_version': '1.4.0+5'});
      expect(checker().pageUri.toString(), 'https://iyf.ebng.world/apps/demo');
    });

    test('au plus une requête toutes les 12 h, la réponse est gardée', () async {
      final c = checker();
      expect(await c.check(), isNotNull);
      now = now.add(const Duration(hours: 11, minutes: 59));
      expect(await c.check(), isNotNull, reason: 'réponse en cache');
      expect(server.calls, 1);
      now = now.add(const Duration(minutes: 2));
      server.answer = () => rpc(payload(available: false));
      expect(await c.check(), isNull);
      expect(server.calls, 2);
      // Survit au redémarrage (même stockage, nouveau checker).
      now = now.add(const Duration(hours: 1));
      expect(await checker().check(), isNull);
      expect(server.calls, 2);
    });

    test('horloge revenue en arrière : on redemande', () async {
      await checker().check();
      now = now.subtract(const Duration(days: 1));
      await checker().check();
      expect(server.calls, 2);
    });

    test('hors ligne : pas de bandeau, pas de créneau consommé', () async {
      final offline = MockClient((_) async => throw http.ClientException('offline'));
      expect(await checker(client: offline).check(), isNull);
      expect(await store.read(AppUpdateChecker.keyLastCheck), isNull);
      expect(await checker().check(), isNotNull, reason: 'réessaie dès le retour du réseau');
    });

    test('délai dépassé → null', () async {
      final never = MockClient((_) => Completer<http.Response>().future);
      final c = checker(client: never, timeout: const Duration(milliseconds: 20));
      expect(await c.check(), isNull);
    });

    test('erreur serveur, JSON invalide, status error → null', () async {
      server.status = 500;
      expect(await checker().check(), isNull);
      now = now.add(const Duration(hours: 13));
      server
        ..status = 200
        ..answer = () => '<html>proxy</html>';
      expect(await checker().check(), isNull);
      now = now.add(const Duration(hours: 13));
      server.answer = () => rpc({'status': 'error', 'error_code': 'unknown_app', 'update_available': false});
      expect(await checker().check(), isNull);
    });

    test('version installée inconnue → rien', () async {
      installed = '';
      expect(await checker().check(), isNull);
      expect(server.calls, 0);
    });

    test('« Plus tard » masque ce build, pas le suivant', () async {
      final c = checker();
      final info = (await c.check())!;
      await c.dismiss(info);
      expect(await c.check(), isNull);
      now = now.add(const Duration(hours: 13));
      server.answer = () => rpc(payload(version: '2.1.0+10'));
      expect((await c.check())?.latestBuild, 10);
    });

    test('obligatoire : ne se masque pas', () async {
      server.answer = () => rpc(payload(mandatory: true));
      final c = checker();
      final info = (await c.check())!;
      await store.write(AppUpdateChecker.keyDismissed, info.id);
      await c.dismiss(info);
      expect((await c.check())?.mandatory, isTrue);
    });

    test('cache périmé par la mise à jour installée', () async {
      final c = checker();
      expect(await c.check(), isNotNull);
      installed = '2.0.0+9';
      expect(await c.check(), isNull);
      expect(server.calls, 1);
    });

    test('appels simultanés : une seule requête', () async {
      final c = checker();
      await Future.wait([c.check(), c.check(), c.check()]);
      expect(server.calls, 1);
    });

    test('stockage en panne → null, sans lever', () async {
      store = _BrokenStore();
      expect(await checker().check(), isNull);
    });
  });

  group('bandeau', () {
    const strings = AppUpdateStrings(
      available: _available,
      required: _required,
      requiredHint: 'Obligatoire pour continuer.',
      download: 'Télécharger',
      later: 'Plus tard',
      webInstallTitle: 'Installez l’application Android',
      webInstallBody: 'Plus pratique.',
      webInstallAction: 'Installer',
      webInstallDismiss: 'Fermer',
    );

    late MemoryAppUpdateStore store;
    late List<Uri> opened;

    setUp(() {
      store = MemoryAppUpdateStore();
      opened = [];
    });

    Future<void> pumpHost(WidgetTester tester, {AppUpdateChecker? checker, Uri? webInstallUrl}) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppUpdateHost(
            checker: checker,
            webInstallUrl: webInstallUrl,
            store: store,
            strings: (_) => strings,
            launch: (uri) async {
              opened.add(uri);
              return true;
            },
            child: child!,
          ),
          home: Scaffold(
            appBar: AppBar(title: const Text('Accueil')),
            body: const Text('contenu'),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }

    AppUpdateChecker checkerFor(Map<String, Object?> result) => AppUpdateChecker(
      server: 'https://iyf.ebng.world',
      slug: 'demo',
      store: store,
      currentVersion: () async => '1.4.0+5',
      client: FakeUpdateServer(() => rpc(result)).client,
    );

    testWidgets('sans vérification : rien que l’application', (tester) async {
      await pumpHost(tester);
      expect(find.text('contenu'), findsOneWidget);
      expect(find.text('Télécharger'), findsNothing);
    });

    testWidgets('version disponible : télécharger, puis « Plus tard » retenu', (tester) async {
      await pumpHost(tester, checker: checkerFor(payload()));
      expect(find.text('Version 2.0.0 disponible'), findsOneWidget);
      expect(find.text('Corrections et nouveautés.'), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget, reason: 'l’écran reste en place sous le bandeau');

      await tester.tap(find.text('Télécharger'));
      await tester.pump();
      expect(opened.single.toString(), 'https://iyf.ebng.world/apps/demo/download');

      await tester.tap(find.text('Plus tard'));
      await tester.pump();
      expect(find.text('Version 2.0.0 disponible'), findsNothing);
      expect(await store.read(AppUpdateChecker.keyDismissed), '9');
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('page publique si l’APK ne s’ouvre pas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppUpdateHost(
            checker: checkerFor(payload()),
            strings: (_) => strings,
            launch: (uri) async {
              opened.add(uri);
              return uri.path.endsWith('/demo');
            },
            child: child!,
          ),
          home: const Scaffold(),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await tester.tap(find.text('Télécharger'));
      await tester.pump();
      expect(opened.map((u) => u.path), ['/apps/demo/download', '/apps/demo']);
    });

    testWidgets('obligatoire : pas de « Plus tard »', (tester) async {
      await pumpHost(tester, checker: checkerFor(payload(mandatory: true)));
      expect(find.text('Mise à jour obligatoire : 2.0.0'), findsOneWidget);
      expect(find.textContaining('Obligatoire pour continuer.'), findsOneWidget);
      expect(find.text('Plus tard'), findsNothing);
      expect(find.text('Télécharger'), findsOneWidget);
    });

    testWidgets('web : invitation à installer, fermeture retenue', (tester) async {
      final url = Uri.parse('https://iyf.ebng.world/apps/demo');
      await pumpHost(tester, webInstallUrl: url);
      expect(find.text('Installez l’application Android'), findsOneWidget);
      await tester.tap(find.text('Installer'));
      await tester.pump();
      expect(opened.single, url);
      await tester.tap(find.text('Fermer'));
      await tester.pump();
      expect(find.text('Installez l’application Android'), findsNothing);
      expect(await store.read(AppUpdateChecker.keyWebInstallDismissed), isNotNull);

      await tester.pumpWidget(const SizedBox());
      await pumpHost(tester, webInstallUrl: url);
      expect(find.text('Installez l’application Android'), findsNothing);
    });
  });
  test('le décalage par processeur des APK est retiré avant d’interroger le serveur', () {
    expect(serverVersionOf('1.5.0', '2006'), '1.5.0+6', reason: 'arm64-v8a');
    expect(serverVersionOf('1.5.0', '1006'), '1.5.0+6', reason: 'armeabi-v7a');
    expect(serverVersionOf('1.5.0', '4006'), '1.5.0+6', reason: 'x86_64');
    expect(serverVersionOf('1.5.0', '6'), '1.5.0+6', reason: 'APK universel');
    expect(serverVersionOf('1.5.0', ''), '1.5.0');
    expect(serverVersionOf('', '6'), isNull);
  });

}

String _available(String v) => 'Version $v disponible';
String _required(String v) => 'Mise à jour obligatoire : $v';

class _BrokenStore extends MemoryAppUpdateStore {
  @override
  Future<String?> read(String key) async => throw StateError('disk');
}
