/// Sauvegarde de la bibliothèque dans un fichier (JSON) et restauration.
///
/// Tout vit sur le téléphone : cette sauvegarde permet de changer de téléphone
/// ou de réinstaller sans perdre ses textes, ses quiz et ses résultats. Les
/// réglages et l'identifiant d'appareil ne sont pas sauvegardés.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../engine/quiz_model.dart';
import 'database.dart';

const backupFormat = 'comprendre-backup';
const backupVersion = 1;

class BackupException implements Exception {
  BackupException(this.code);

  /// `invalid` (pas une sauvegarde de Comprendre) | `newer` (version plus récente de l'application)
  final String code;

  @override
  String toString() => 'BackupException($code)';
}

class RestoreResult {
  const RestoreResult({required this.added, required this.skipped, required this.quizzes});

  /// Textes ajoutés ; textes déjà présents (même titre et même contenu), laissés tels quels.
  final int added;
  final int skipped;
  final int quizzes;
}

String _date(DateTime d) => d.toUtc().toIso8601String();

DateTime _parseDate(Object? v) => (v is String ? DateTime.tryParse(v)?.toLocal() : null) ?? DateTime.now();

/// Toute la bibliothèque, en JSON.
Future<String> exportBackup(AppDatabase db, {String appVersion = ''}) async {
  final docs = await (db.select(db.documents)..orderBy([(d) => OrderingTerm.asc(d.id)])).get();
  final quizRows = await db.select(db.quizzes).get();
  final attemptRows = await db.select(db.attempts).get();
  final attemptsByQuiz = <int, List<Attempt>>{};
  for (final a in attemptRows) {
    attemptsByQuiz.putIfAbsent(a.quizId, () => []).add(a);
  }
  final quizzesByDoc = <int, List<QuizRow>>{};
  for (final q in quizRows) {
    quizzesByDoc.putIfAbsent(q.documentId, () => []).add(q);
  }
  return const JsonEncoder.withIndent(' ').convert({
    'format': backupFormat,
    'version': backupVersion,
    'app': appVersion,
    'exportedAt': _date(DateTime.now()),
    'documents': [
      for (final d in docs)
        {
          'title': d.title,
          'body': d.body,
          'source': d.source,
          'fileName': d.fileName,
          'lang': d.lang,
          'createdAt': _date(d.createdAt),
          'updatedAt': _date(d.updatedAt),
          'quizzes': [
            for (final q in quizzesByDoc[d.id] ?? const <QuizRow>[])
              {
                'engine': q.engine,
                'title': q.title,
                'summary': q.summary,
                'lang': q.lang,
                'createdAt': _date(q.createdAt),
                'questions': jsonDecode(q.questionsJson),
                'bodyHash': q.bodyHash,
                'sectionStart': q.sectionStart,
                'sectionEnd': q.sectionEnd,
                'sectionLabel': q.sectionLabel,
                'attempts': [
                  for (final a in attemptsByQuiz[q.id] ?? const <Attempt>[])
                    {'score': a.score, 'total': a.total, 'answers': jsonDecode(a.answersJson), 'finishedAt': _date(a.finishedAt)},
                ],
              },
          ],
        },
    ],
  });
}

/// Ajoute à la bibliothèque les textes d'une sauvegarde (sans rien effacer).
/// Un texte déjà présent (même titre, même contenu) n'est pas dupliqué.
/// Tout ou rien : en cas d'erreur, la bibliothèque est inchangée.
Future<RestoreResult> importBackup(AppDatabase db, String json) async {
  final Object? data;
  try {
    data = jsonDecode(json);
  } on FormatException {
    throw BackupException('invalid');
  }
  if (data is! Map || data['format'] != backupFormat || data['documents'] is! List) throw BackupException('invalid');
  if (data['version'] is! num || (data['version'] as num) > backupVersion) throw BackupException('newer');
  final documents = data['documents'] as List;

  return db.transaction(() async {
    var added = 0, skipped = 0, quizCount = 0;
    final existing = await db.select(db.documents).get();
    final known = {for (final d in existing) '${d.title}\u0000${d.body}'};
    for (final d in documents) {
      if (d is! Map || d['body'] is! String || (d['body'] as String).trim().isEmpty) continue;
      final title = d['title'] is String ? d['title'] as String : '';
      final body = d['body'] as String;
      if (!known.add('$title\u0000$body')) {
        skipped++;
        continue;
      }
      final docId = await db
          .into(db.documents)
          .insert(
            DocumentsCompanion.insert(
              title: title,
              body: body,
              source: Value(d['source'] is String ? d['source'] as String : 'typed'),
              fileName: Value(d['fileName'] is String ? d['fileName'] as String : null),
              lang: Value(d['lang'] is String ? d['lang'] as String : 'fr'),
              createdAt: _parseDate(d['createdAt']),
              updatedAt: _parseDate(d['updatedAt']),
            ),
          );
      added++;
      for (final q in (d['quizzes'] is List ? d['quizzes'] as List : const [])) {
        if (q is! Map || q['questions'] is! List) continue;
        final questions = [for (final x in q['questions'] as List) ?QuizQuestion.tryParse(x)];
        if (questions.isEmpty) continue;
        int? asInt(Object? v) => v is num ? v.toInt() : null;
        final start = asInt(q['sectionStart']), end = asInt(q['sectionEnd']);
        final validSection = start != null && end != null && start >= 0 && start < end && end <= body.length;
        final quizId = await db
            .into(db.quizzes)
            .insert(
              QuizzesCompanion.insert(
                documentId: docId,
                engine: q['engine'] == 'ai' ? 'ai' : 'offline',
                title: Value(q['title'] is String ? q['title'] as String : ''),
                summary: Value(q['summary'] is String ? q['summary'] as String : ''),
                lang: Value(q['lang'] is String ? q['lang'] as String : 'fr'),
                questionsJson: jsonEncode([for (final x in questions) x.toJson()]),
                createdAt: _parseDate(q['createdAt']),
                bodyHash: Value(q['bodyHash'] is String ? q['bodyHash'] as String : null),
                sectionStart: Value(validSection ? start : null),
                sectionEnd: Value(validSection ? end : null),
                sectionLabel: Value(validSection && q['sectionLabel'] is String ? q['sectionLabel'] as String : null),
              ),
            );
        quizCount++;
        for (final a in (q['attempts'] is List ? q['attempts'] as List : const [])) {
          if (a is! Map || a['score'] is! num || a['total'] is! num) continue;
          await db
              .into(db.attempts)
              .insert(
                AttemptsCompanion.insert(
                  quizId: quizId,
                  score: (a['score'] as num).toInt(),
                  total: (a['total'] as num).toInt(),
                  answersJson: jsonEncode(a['answers'] is List ? a['answers'] : const []),
                  finishedAt: _parseDate(a['finishedAt']),
                ),
              );
        }
      }
    }
    return RestoreResult(added: added, skipped: skipped, quizzes: quizCount);
  });
}
