/// Base locale (Drift / SQLite) : les textes de l'utilisateur, leurs quiz et les essais.
/// Tout reste sur le téléphone.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../engine/quiz_model.dart';

part 'database.g.dart';

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  /// `typed` | `scan` | `photo` | `file` | `paste`
  TextColumn get source => text().withDefault(const Constant('typed'))();
  TextColumn get fileName => text().nullable()();
  TextColumn get lang => text().withDefault(const Constant('fr'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('QuizRow')
class Quizzes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id, onDelete: KeyAction.cascade)();

  /// `offline` | `ai`
  TextColumn get engine => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get questionsJson => text()();
  TextColumn get lang => text().withDefault(const Constant('fr'))();
  DateTimeColumn get createdAt => dateTime()();
}

class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quizId => integer().references(Quizzes, #id, onDelete: KeyAction.cascade)();
  IntColumn get score => integer()();
  IntColumn get total => integer()();

  /// Réponse choisie pour chaque question (indice ; -1 si passée).
  TextColumn get answersJson => text()();
  DateTimeColumn get finishedAt => dateTime()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Documents, Quizzes, Attempts, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'comprendre'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---------------------------------------------------------------- //
  // Documents
  // ---------------------------------------------------------------- //
  Stream<List<DocumentSummary>> watchLibrary() {
    final lastQuiz = quizzes.createdAt.max();
    final count = quizzes.id.count();
    final q = selectOnly(documents).join([leftOuterJoin(quizzes, quizzes.documentId.equalsExp(documents.id))])
      ..addColumns([documents.id, documents.title, documents.source, documents.lang, documents.updatedAt, lastQuiz, count])
      ..groupBy([documents.id])
      ..orderBy([OrderingTerm.desc(documents.updatedAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          DocumentSummary(
            id: r.read(documents.id)!,
            title: r.read(documents.title)!,
            source: r.read(documents.source)!,
            lang: r.read(documents.lang)!,
            updatedAt: r.read(documents.updatedAt)!,
            quizCount: r.read(count) ?? 0,
          ),
      ],
    );
  }

  Future<int> addDocument({required String title, required String body, required String source, String? fileName, required String lang}) {
    final now = DateTime.now();
    return into(documents).insert(
      DocumentsCompanion.insert(
        title: title,
        body: body,
        source: Value(source),
        fileName: Value(fileName),
        lang: Value(lang),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Document?> document(int id) => (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();

  Stream<Document?> watchDocument(int id) => (select(documents)..where((d) => d.id.equals(id))).watchSingleOrNull();

  Future<void> updateDocument(int id, {String? title, String? body, String? lang}) =>
      (update(documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(
          title: title == null ? const Value.absent() : Value(title),
          body: body == null ? const Value.absent() : Value(body),
          lang: lang == null ? const Value.absent() : Value(lang),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteDocument(int id) => (delete(documents)..where((d) => d.id.equals(id))).go();

  // ---------------------------------------------------------------- //
  // Quiz et essais
  // ---------------------------------------------------------------- //
  Future<int> saveQuiz(int documentId, Quiz quiz) async {
    return transaction(() async {
      final id = await into(quizzes).insert(
        QuizzesCompanion.insert(
          documentId: documentId,
          engine: quiz.engine.name,
          title: Value(quiz.title),
          summary: Value(quiz.summary),
          questionsJson: jsonEncode([for (final q in quiz.questions) q.toJson()]),
          lang: Value(quiz.lang),
          createdAt: DateTime.now(),
        ),
      );
      await (update(documents)..where((d) => d.id.equals(documentId))).write(DocumentsCompanion(updatedAt: Value(DateTime.now())));
      return id;
    });
  }

  Future<StoredQuiz?> quiz(int id) async {
    final row = await (select(quizzes)..where((q) => q.id.equals(id))).getSingleOrNull();
    return row == null ? null : StoredQuiz.fromRow(row);
  }

  Stream<List<QuizSummary>> watchQuizzes(int documentId) {
    final best = attempts.score.max();
    final tries = attempts.id.count();
    final q = select(quizzes).join([leftOuterJoin(attempts, attempts.quizId.equalsExp(quizzes.id))])
      ..where(quizzes.documentId.equals(documentId))
      ..addColumns([best, tries])
      ..groupBy([quizzes.id])
      ..orderBy([OrderingTerm.desc(quizzes.createdAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          QuizSummary(
            quiz: StoredQuiz.fromRow(r.readTable(quizzes)),
            bestScore: r.read(best),
            attempts: r.read(tries) ?? 0,
          ),
      ],
    );
  }

  Future<void> deleteQuiz(int id) => (delete(quizzes)..where((q) => q.id.equals(id))).go();

  Future<int> recordAttempt(int quizId, {required int score, required int total, required List<int> answers}) =>
      into(attempts).insert(
        AttemptsCompanion.insert(
          quizId: quizId,
          score: score,
          total: total,
          answersJson: jsonEncode(answers),
          finishedAt: DateTime.now(),
        ),
      );

  // ---------------------------------------------------------------- //
  // Réglages
  // ---------------------------------------------------------------- //
  Future<String?> setting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Stream<Map<String, String>> watchSettings() =>
      select(settings).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Future<void> setSetting(String key, String value) => into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}

class DocumentSummary {
  const DocumentSummary({
    required this.id,
    required this.title,
    required this.source,
    required this.lang,
    required this.updatedAt,
    required this.quizCount,
  });

  final int id;
  final String title;
  final String source;
  final String lang;
  final DateTime updatedAt;
  final int quizCount;
}

class StoredQuiz {
  const StoredQuiz({required this.id, required this.documentId, required this.quiz, required this.createdAt});

  factory StoredQuiz.fromRow(QuizRow row) {
    final list = jsonDecode(row.questionsJson) as List;
    return StoredQuiz(
      id: row.id,
      documentId: row.documentId,
      createdAt: row.createdAt,
      quiz: Quiz(
        engine: row.engine == 'ai' ? QuizEngine.ai : QuizEngine.offline,
        title: row.title,
        summary: row.summary,
        lang: row.lang,
        questions: [for (final q in list) ?QuizQuestion.tryParse(q)],
      ),
    );
  }

  final int id;
  final int documentId;
  final Quiz quiz;
  final DateTime createdAt;
}

class QuizSummary {
  const QuizSummary({required this.quiz, required this.bestScore, required this.attempts});

  final StoredQuiz quiz;
  final int? bestScore;
  final int attempts;
}
