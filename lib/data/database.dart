/// Base locale (Drift / SQLite) : les textes de l'utilisateur, leurs quiz et les essais.
/// Tout reste sur le téléphone.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../engine/quiz_model.dart';
import '../engine/sections.dart';
import '../engine/text_tools.dart';
import 'web_database.dart';

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

  /// Empreinte du texte complet au moment du quiz ([textFingerprint]) : un texte
  /// modifié depuis rend le quiz « ancien » (ses citations peuvent avoir disparu).
  /// Null pour les quiz d'avant la version 2.
  TextColumn get bodyHash => text().nullable()();

  /// Partie du texte sur laquelle porte le quiz (null : tout le texte).
  IntColumn get sectionStart => integer().nullable()();
  IntColumn get sectionEnd => integer().nullable()();
  TextColumn get sectionLabel => text().nullable()();

  /// Quiz en cours : ordre des questions, réponses données (JSON) ; null sinon.
  TextColumn get progressJson => text().nullable()();
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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'comprendre', web: webDatabaseOptions()));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(quizzes, quizzes.bodyHash);
        await m.addColumn(quizzes, quizzes.sectionStart);
        await m.addColumn(quizzes, quizzes.sectionEnd);
        await m.addColumn(quizzes, quizzes.sectionLabel);
        await m.addColumn(quizzes, quizzes.progressJson);
      }
    },
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

  Future<int> addDocument({
    required String title,
    required String body,
    required String source,
    String? fileName,
    required String lang,
  }) {
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
  /// [body] : le texte complet au moment du quiz (son empreinte est gardée).
  Future<int> saveQuiz(int documentId, Quiz quiz, {String? body, TextSection? section}) async {
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
          bodyHash: Value(body == null ? null : textFingerprint(body)),
          sectionStart: Value(section?.start),
          sectionEnd: Value(section?.end),
          sectionLabel: Value(section?.label),
        ),
      );
      await (update(
        documents,
      )..where((d) => d.id.equals(documentId))).write(DocumentsCompanion(updatedAt: Value(DateTime.now())));
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
          QuizSummary(quiz: StoredQuiz.fromRow(r.readTable(quizzes)), bestScore: r.read(best), attempts: r.read(tries) ?? 0),
      ],
    );
  }

  Future<void> deleteQuiz(int id) => (delete(quizzes)..where((q) => q.id.equals(id))).go();

  /// Citations (normalisées) des quiz déjà faits sur ce texte : un nouveau quiz hors
  /// ligne pose d'autres questions.
  Future<Set<String>> usedQuotes(int documentId) async {
    final rows = await (select(quizzes)..where((q) => q.documentId.equals(documentId))).get();
    return {
      for (final r in rows)
        for (final q in StoredQuiz.fromRow(r).quiz.questions)
          if (q.quote.isNotEmpty) normalize(q.quote),
    };
  }

  /// Progression d'un quiz en cours (null : aucun, ou terminé).
  Future<void> saveProgress(int quizId, QuizProgress? progress) => (update(quizzes)..where((q) => q.id.equals(quizId))).write(
    QuizzesCompanion(progressJson: Value(progress == null ? null : jsonEncode(progress.toJson()))),
  );

  Future<int> recordAttempt(int quizId, {required int score, required int total, required List<int> answers}) => into(attempts)
      .insert(
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

  Stream<Map<String, String>> watchSettings() => select(settings).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
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

/// Un quiz commencé : ordre des questions (indices) et réponses déjà données.
class QuizProgress {
  const QuizProgress({required this.order, required this.answers});

  final List<int> order;
  final List<int> answers;

  Map<String, dynamic> toJson() => {'order': order, 'answers': answers};

  /// Null si illisible ou incohérent avec un quiz de [total] questions.
  static QuizProgress? tryParse(String? json, int total) {
    if (json == null) return null;
    try {
      final m = jsonDecode(json) as Map;
      final order = [for (final i in m['order'] as List) (i as num).toInt()];
      final answers = [for (final a in m['answers'] as List) (a as num).toInt()];
      final valid =
          order.isNotEmpty &&
          order.every((i) => i >= 0 && i < total) &&
          order.toSet().length == order.length &&
          answers.length <= order.length;
      return valid ? QuizProgress(order: order, answers: answers) : null;
    } catch (_) {
      return null;
    }
  }
}

class StoredQuiz {
  const StoredQuiz({
    required this.id,
    required this.documentId,
    required this.quiz,
    required this.createdAt,
    this.bodyHash,
    this.section,
    this.progressJson,
  });

  factory StoredQuiz.fromRow(QuizRow row) {
    final list = jsonDecode(row.questionsJson) as List;
    return StoredQuiz(
      id: row.id,
      documentId: row.documentId,
      createdAt: row.createdAt,
      bodyHash: row.bodyHash,
      progressJson: row.progressJson,
      section: row.sectionStart != null && row.sectionEnd != null
          ? TextSection(row.sectionStart!, row.sectionEnd!, row.sectionLabel ?? '')
          : null,
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
  final String? bodyHash;
  final TextSection? section;
  final String? progressJson;

  QuizProgress? get progress => QuizProgress.tryParse(progressJson, quiz.questions.length);

  /// Le texte a-t-il changé depuis ce quiz ? Pour un quiz d'avant la version 2
  /// (sans empreinte), on vérifie que toutes ses citations sont encore dans le texte.
  bool isStale(String body) {
    if (bodyHash != null) return bodyHash != textFingerprint(body);
    return quiz.questions.any((q) => q.quote.isNotEmpty && findQuote(body, q.quote) == null);
  }
}

class QuizSummary {
  const QuizSummary({required this.quiz, required this.bestScore, required this.attempts});

  final StoredQuiz quiz;
  final int? bestScore;
  final int attempts;
}
