import 'package:comprendre/app.dart';
import 'package:comprendre/app/providers.dart';
import 'package:comprendre/app/quiz_service.dart';
import 'package:comprendre/app/version.dart';
import 'package:comprendre/data/database.dart';
import 'package:comprendre/engine/offline_quiz.dart';
import 'package:comprendre/engine/quiz_model.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'engine_test.dart' show fr;

Future<Quiz> _syncOffline(String text, {String? lang, int? seed, int count = 10}) async =>
    OfflineQuizGenerator(text, lang: lang, seed: seed).generate(count: count);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// La base travaille en temps réel : on alterne temps réel et images.
  Future<void> settle(WidgetTester tester, [int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1)); // fin des animations de page
  }

  Future<AppDatabase> pumpApp(WidgetTester tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await tester.runAsync(() => db.setSetting('locale', 'fr'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          quotaProvider.overrideWith((ref) async => null),
          quizServiceProvider.overrideWith((ref) async => QuizService(db, null, offline: _syncOffline)),
        ],
        child: const ComprendreApp(),
      ),
    );
    await settle(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    });
    return db;
  }

  testWidgets('saisie → consentement → quiz → résultat enregistré', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Comprenez ce que vous lisez'), findsOneWidget);

    await tester.tap(find.text('Écrire ou coller'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, fr);
    await settle(tester);
    await tester.tap(find.text('Créer le quiz'));
    await settle(tester);

    // Premier quiz : on demande si l'utilisateur veut l'IA ; il reste hors ligne.
    expect(find.text('Utiliser l’IA ?'), findsOneWidget);
    await tester.tap(find.text('Rester hors ligne'));
    await settle(tester);
    expect(await tester.runAsync(() => db.setting('ai')), 'off');

    expect(find.textContaining('Question 1 sur'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      if (find.text('Résultat').evaluate().isNotEmpty) break;
      await tester.tap(find.byKey(const ValueKey('option-0')));
      await settle(tester);
      // L'explication et la citation apparaissent après la réponse.
      expect(find.text('Dans le texte'), findsWidgets);
      final next = find.text('Suivante').evaluate().isNotEmpty ? find.text('Suivante') : find.text('Voir le résultat');
      await tester.tap(next);
      await settle(tester);
    }
    expect(find.text('Résultat'), findsOneWidget);
    expect(find.text('Revoir les réponses'), findsOneWidget);

    final docs = (await tester.runAsync(() => db.watchLibrary().first))!;
    expect(docs.single.quizCount, 1);
    expect(docs.single.title, startsWith('Le baobab est un arbre'));
    final quizzes = (await tester.runAsync(() => db.watchQuizzes(docs.single.id).first))!;
    expect(quizzes.single.attempts, 1);
  });

  testWidgets('texte trop court : message, pas de document', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Écrire ou coller'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Trop court.');
    await settle(tester);
    await tester.tap(find.text('Créer le quiz'));
    await settle(tester);
    expect(find.textContaining('150 caractères au moins'), findsOneWidget);
    expect(await tester.runAsync(() => db.watchLibrary().first), isEmpty);
  });

  test('la version affichée suit pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: (\S+)\+', multiLine: true).firstMatch(pubspec)![1], appVersion);
  });
}
