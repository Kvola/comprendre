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

Future<Quiz> _syncOffline(String text, {String? lang, int? seed, int count = 10, Set<String> avoid = const {}}) async =>
    OfflineQuizGenerator(text, lang: lang, seed: seed, avoid: avoid).generate(count: count);

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

  /// Bouton retour de la barre (application en français : « Retour »).
  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Retour').last);
    await settle(tester);
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
    var quizzes = (await tester.runAsync(() => db.watchQuizzes(docs.single.id).first))!;
    expect(quizzes.single.attempts, 1);
    expect(quizzes.single.quiz.progress, isNull, reason: 'quiz terminé : plus de progression');

    // Toujours la première proposition : il y a des erreurs à revoir.
    final retry = find.byKey(const ValueKey('retry-mistakes'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await settle(tester);
    expect(find.textContaining('Erreur 1 sur'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      if (find.text('Mes erreurs').evaluate().isNotEmpty) break;
      await tester.tap(find.byKey(const ValueKey('option-0')));
      await settle(tester);
      final next = find.text('Suivante').evaluate().isNotEmpty ? find.text('Suivante') : find.text('Voir le résultat');
      await tester.tap(next);
      await settle(tester);
    }
    expect(find.text('Mes erreurs'), findsOneWidget);
    expect(find.textContaining('Ce tour ne change pas votre meilleur score'), findsOneWidget);
    quizzes = (await tester.runAsync(() => db.watchQuizzes(docs.single.id).first))!;
    expect(quizzes.single.attempts, 1, reason: 'le tour des erreurs n’est pas un essai complet');
  });

  testWidgets('un quiz quitté en cours reprend là où il en était', (tester) async {
    final db = await pumpApp(tester);
    await tester.runAsync(() => db.setSetting('ai', 'off'));
    await tester.tap(find.text('Écrire ou coller'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, fr);
    await settle(tester);
    await tester.tap(find.text('Créer le quiz'));
    await settle(tester);
    expect(find.textContaining('Question 1 sur'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('option-0')));
    await settle(tester);
    await tester.tap(find.text('Suivante'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('option-1')));
    await settle(tester);

    // Retour à la fiche du texte : sans confirmation, la progression est gardée.
    await goBack(tester);
    expect(find.textContaining('En cours : 2 réponse(s) sur'), findsOneWidget);

    await tester.tap(find.textContaining('En cours'));
    await settle(tester);
    expect(find.text('Reprise là où vous en étiez.'), findsOneWidget);
    expect(find.textContaining('Question 2 sur'), findsOneWidget);
    expect(find.text('Suivante'), findsOneWidget, reason: 'la question déjà répondue garde son explication');
  });

  testWidgets('long texte : choix d’une partie, rappelée sur la fiche du quiz', (tester) async {
    final db = await pumpApp(tester);
    await tester.runAsync(() => db.setSetting('ai', 'off'));
    final long = List.generate(12, (i) => 'Chapitre ${i + 1}\n\n$fr').join('\n\n');
    final docId = (await tester.runAsync(() => db.addDocument(title: 'Long', body: long, source: 'typed', lang: 'fr')))!;
    await settle(tester);
    await tester.tap(find.text('Long'));
    await settle(tester);
    await tester.tap(find.text('Nouveau quiz'));
    await settle(tester);
    expect(find.text('Quiz sur quelle partie ?'), findsOneWidget);
    expect(find.text('Tout le texte'), findsOneWidget);
    await tester.tap(find.text('Chapitre 2'));
    await settle(tester);
    expect(find.textContaining('Question 1 sur'), findsOneWidget);
    final quiz = (await tester.runAsync(() => db.watchQuizzes(docId).first))!.single.quiz;
    expect(quiz.section?.label, 'Chapitre 2');
    for (final q in quiz.quiz.questions) {
      expect(quiz.section!.of(long), contains(q.quote.substring(0, 20)), reason: 'question tirée de la partie choisie');
    }
    await goBack(tester);
    expect(find.textContaining('Partie : Chapitre 2'), findsOneWidget);
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
