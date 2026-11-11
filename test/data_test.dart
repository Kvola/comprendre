import 'dart:convert';

import 'package:comprendre/app/quiz_service.dart';
import 'package:comprendre/data/backup.dart';
import 'package:comprendre/data/database.dart';
import 'package:comprendre/engine/offline_quiz.dart';
import 'package:comprendre/engine/quiz_model.dart';
import 'package:comprendre/engine/sections.dart';
import 'package:comprendre/remote/ai_client.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'engine_test.dart' show fr;

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

/// Générateur hors ligne synchrone qui note ce qu'on lui demande.
class _Offline {
  final calls = <({String text, Set<String> avoid})>[];

  Future<Quiz> call(String text, {String? lang, int? seed, int count = 10, Set<String> avoid = const {}}) async {
    calls.add((text: text, avoid: avoid));
    return OfflineQuizGenerator(text, lang: lang, seed: seed, avoid: avoid).generate(count: count);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Migration', () {
    test('une base 1.1.0 (schéma 1) passe au schéma 2 sans perte', () async {
      final quizJson = jsonEncode([
        {'kind': 'truefalse', 'question': 'Q', 'choices': [], 'answer': 1, 'explanation': 'E', 'quote': 'Le baobab est un arbre'},
      ]);
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
              CREATE TABLE documents (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL,
                source TEXT NOT NULL DEFAULT 'typed', file_name TEXT NULL, lang TEXT NOT NULL DEFAULT 'fr',
                created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
              CREATE TABLE quizzes (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                document_id INTEGER NOT NULL REFERENCES documents (id) ON DELETE CASCADE, engine TEXT NOT NULL,
                title TEXT NOT NULL DEFAULT '', summary TEXT NOT NULL DEFAULT '', questions_json TEXT NOT NULL,
                lang TEXT NOT NULL DEFAULT 'fr', created_at INTEGER NOT NULL);
              CREATE TABLE attempts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                quiz_id INTEGER NOT NULL REFERENCES quizzes (id) ON DELETE CASCADE, score INTEGER NOT NULL,
                total INTEGER NOT NULL, answers_json TEXT NOT NULL, finished_at INTEGER NOT NULL);
              CREATE TABLE settings ("key" TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY ("key"));
              INSERT INTO documents (title, body, created_at, updated_at) VALUES ('Baobab', '${fr.replaceAll("'", "''")}', 1, 1);
              INSERT INTO quizzes (document_id, engine, questions_json, created_at) VALUES (1, 'offline', '$quizJson', 1);
              INSERT INTO attempts (quiz_id, score, total, answers_json, finished_at) VALUES (1, 1, 1, '[1]', 1);
              PRAGMA user_version = 1;
            ''');
          },
        ),
      );
      addTearDown(db.close);
      final stored = (await db.quiz(1))!;
      expect(stored.bodyHash, isNull);
      expect(stored.section, isNull);
      expect(stored.progress, isNull);
      expect(stored.isStale(fr), isFalse, reason: 'ancien quiz : ses citations sont toujours dans le texte');
      expect(stored.isStale('Un tout autre texte.'), isTrue);
      final summary = (await db.watchQuizzes(1).first).single;
      expect((summary.attempts, summary.bestScore), (1, 1));
      // Les nouvelles colonnes sont utilisables.
      await db.saveProgress(1, const QuizProgress(order: [0], answers: []));
      expect((await db.quiz(1))!.progress?.order, [0]);
    });
  });

  group('Quiz enregistrés', () {
    test('empreinte, partie, progression, texte modifié', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final docId = await db.addDocument(title: 'B', body: fr, source: 'typed', lang: 'fr');
      final quiz = OfflineQuizGenerator(fr).generate();
      const section = TextSection(0, 120, 'Début');
      final id = await db.saveQuiz(docId, quiz, body: fr, section: section);
      var stored = (await db.quiz(id))!;
      expect(stored.isStale(fr), isFalse);
      expect(stored.isStale('$fr Nouvelle phrase.'), isTrue);
      expect((stored.section!.start, stored.section!.end, stored.section!.label), (0, 120, 'Début'));

      await db.saveProgress(id, const QuizProgress(order: [2, 0, 1], answers: [1]));
      stored = (await db.quiz(id))!;
      expect(stored.progress!.order, [2, 0, 1]);
      expect(stored.progress!.answers, [1]);
      await db.saveProgress(id, null);
      expect((await db.quiz(id))!.progress, isNull);

      expect(await db.usedQuotes(docId), isNotEmpty);
    });

    test('progression illisible ou incohérente : ignorée', () {
      expect(QuizProgress.tryParse('pas du json', 5), isNull);
      expect(QuizProgress.tryParse('{"order":[0,7],"answers":[]}', 5), isNull, reason: 'question inexistante');
      expect(QuizProgress.tryParse('{"order":[1,1],"answers":[]}', 5), isNull, reason: 'doublon');
      expect(QuizProgress.tryParse('{"order":[0],"answers":[1,0]}', 5), isNull, reason: 'trop de réponses');
      expect(QuizProgress.tryParse('{"order":[],"answers":[]}', 5), isNull);
      expect(QuizProgress.tryParse('{"order":[4,0],"answers":[1]}', 5)?.order, [4, 0]);
    });
  });

  group('Sauvegarde', () {
    test('aller-retour complet, sans doublon à la deuxième restauration', () async {
      final a = _memoryDb();
      final b = _memoryDb();
      addTearDown(a.close);
      addTearDown(b.close);
      final docId = await a.addDocument(title: 'Baobab', body: fr, source: 'file', fileName: 'baobab.pdf', lang: 'fr');
      final quizId = await a.saveQuiz(
        docId,
        OfflineQuizGenerator(fr).generate(),
        body: fr,
        section: const TextSection(0, 100, 'P1'),
      );
      await a.recordAttempt(quizId, score: 7, total: 10, answers: List.filled(10, 0));
      await a.addDocument(title: 'Vide de quiz', body: 'Un autre texte.', source: 'typed', lang: 'en');

      final json = await exportBackup(a, appVersion: '1.2.0');
      var r = await importBackup(b, json);
      expect((r.added, r.skipped, r.quizzes), (2, 0, 1));
      final docs = await b.watchLibrary().first;
      expect(docs.map((d) => d.title).toSet(), {'Baobab', 'Vide de quiz'});
      final restoredDoc = (await b.document(docs.firstWhere((d) => d.title == 'Baobab').id))!;
      expect((restoredDoc.body, restoredDoc.source, restoredDoc.fileName, restoredDoc.lang), (fr, 'file', 'baobab.pdf', 'fr'));
      final q = (await b.watchQuizzes(restoredDoc.id).first).single;
      expect((q.bestScore, q.attempts), (7, 1));
      expect(q.quiz.isStale(fr), isFalse, reason: 'l’empreinte du texte est gardée');
      expect(q.quiz.section?.label, 'P1');

      r = await importBackup(b, json);
      expect((r.added, r.skipped), (0, 2));
      expect((await b.watchLibrary().first).length, 2);
    });

    test('fichier invalide ou trop récent : refus, bibliothèque intacte', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      for (final bad in ['pas du json', '[]', '{"format":"autre","version":1,"documents":[]}']) {
        await expectLater(importBackup(db, bad), throwsA(isA<BackupException>().having((e) => e.code, 'code', 'invalid')));
      }
      await expectLater(
        importBackup(db, '{"format":"comprendre-backup","version":99,"documents":[]}'),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', 'newer')),
      );
      // Entrées abîmées ignorées une à une.
      final r = await importBackup(
        db,
        jsonEncode({
          'format': backupFormat,
          'version': 1,
          'documents': [
            {'title': 'Sans corps'},
            {
              'title': 'Ok',
              'body': fr,
              'quizzes': [
                {
                  'questions': [
                    {'kind': 'x'},
                  ],
                },
                'n’importe quoi',
              ],
            },
          ],
        }),
      );
      expect((r.added, r.quizzes), (1, 0));
    });
  });

  group('Service de quiz', () {
    MockClient fakeServer({required Map<String, dynamic> result, List<Map<String, dynamic>>? requests}) =>
        MockClient((req) async {
          requests?.add(jsonDecode(req.body)['params'] as Map<String, dynamic>);
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': result}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

    Map<String, dynamic> aiQuiz(String quote) => {
      'success': true,
      'title': 'T',
      'summary': 'S',
      'remaining': 3,
      'questions': [
        for (var i = 0; i < 3; i++)
          {
            'kind': 'truefalse',
            'question': 'Q$i',
            'choices': [],
            'answer': 1,
            'explanation': 'E',
            'quote': quote,
            'skill': 'detail',
          },
      ],
    };

    test('une partie seulement est envoyée à l’IA ; le quiz garde la partie et l’empreinte', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final docId = await db.addDocument(title: 'B', body: fr, source: 'typed', lang: 'fr');
      final requests = <Map<String, dynamic>>[];
      final ai = AiClient(
        deviceId: 'device-0123456789abcdef',
        httpClient: fakeServer(result: aiQuiz('Le baobab'), requests: requests),
      );
      final sections = splitSections(fr, target: 300, min: 100);
      final part = sections.first;
      final out = await QuizService(
        db,
        ai,
        offline: _Offline().call,
      ).create(documentId: docId, text: fr, lang: 'fr', count: 5, useAi: true, section: part);
      expect(out.fallback, isNull);
      expect(requests.single['text'], part.of(fr));
      final stored = (await db.quiz(out.quizId))!;
      expect(stored.quiz.engine, QuizEngine.ai);
      expect(stored.section?.start, part.start);
      expect(stored.isStale(fr), isFalse);
    });

    test('autre langue : l’IA si le serveur la connaît ; sinon refus explicite', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      const es =
          'La economía de Costa de Marfil depende en gran medida del cacao. El país es el primer productor mundial de '
          'cacao. Los agricultores venden sus granos a cooperativas que los revenden a los exportadores. El gobierno fija el precio.';
      final docId = await db.addDocument(title: 'Cacao', body: es, source: 'typed', lang: 'es');
      final requests = <Map<String, dynamic>>[];
      final ai = AiClient(
        deviceId: 'device-0123456789abcdef',
        httpClient: fakeServer(result: aiQuiz('El país es el primer'), requests: requests),
      );
      final service = QuizService(db, ai, offline: _Offline().call);

      final out = await service.create(
        documentId: docId,
        text: es,
        lang: 'es',
        count: 5,
        useAi: true,
        aiLanguages: const {'fr', 'en', 'es'},
      );
      expect(out.fallback, isNull);
      expect(requests.single['lang'], 'es');

      // Serveur ancien (fr/en seulement) : pas d'envoi, et pas de quiz hors ligne possible.
      await expectLater(
        service.create(documentId: docId, text: es, lang: 'es', count: 5, useAi: true),
        throwsA(isA<QuizLanguageUnsupported>().having((e) => e.why, 'why', Fallback.language)),
      );
      expect(requests.length, 1);
      // IA non demandée.
      await expectLater(
        service.create(documentId: docId, text: es, lang: 'es', count: 5, useAi: false),
        throwsA(isA<QuizLanguageUnsupported>().having((e) => e.why, 'why', isNull)),
      );
    });

    test('échecs répétés côté serveur : motif « failures » ; « un autre quiz » évite les phrases déjà vues', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final docId = await db.addDocument(title: 'B', body: fr, source: 'typed', lang: 'fr');
      final ai = AiClient(
        deviceId: 'device-0123456789abcdef',
        httpClient: fakeServer(
          result: {
            'success': false,
            'error': {
              'code': 'REFUSED',
              'message': 'x',
              'details': {'reason': 'failures'},
            },
          },
        ),
      );
      final offline = _Offline();
      final service = QuizService(db, ai, offline: offline.call);
      final first = await service.create(documentId: docId, text: fr, lang: 'fr', count: 5, useAi: true);
      expect(first.fallback, Fallback.failures);
      expect(offline.calls.last.avoid, isEmpty);
      await service.create(documentId: docId, text: fr, lang: 'fr', count: 5, useAi: false, another: true);
      expect(offline.calls.last.avoid, isNotEmpty);
    });

    test('quota : champs du serveur 1.2.0, valeurs par défaut d’un serveur ancien', () async {
      final recent = AiClient(
        deviceId: 'device-0123456789abcdef',
        httpClient: fakeServer(
          result: {
            'success': true,
            'remaining': 0,
            'daily': 5,
            'max_chars': 30000,
            'enabled': true,
            'limited': 'failures',
            'languages': ['fr', 'en', 'es'],
          },
        ),
      );
      final q = await recent.quota();
      expect(q.limited, 'failures');
      expect(q.languages, {'fr', 'en', 'es'});
      final old = AiClient(
        deviceId: 'device-0123456789abcdef',
        httpClient: fakeServer(result: {'success': true, 'remaining': 2, 'daily': 5, 'max_chars': 30000, 'enabled': true}),
      );
      final o = await old.quota();
      expect(o.limited, '');
      expect(o.languages, {'fr', 'en'});
      expect(AiClient.quizTimeout, const Duration(seconds: 240));
    });
  });
}
