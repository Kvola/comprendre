/// Création d'un quiz : l'IA quand elle est permise et joignable, sinon (ou en
/// cas d'échec, quel qu'il soit) le moteur hors ligne. L'utilisateur obtient
/// toujours un quiz ; on lui dit seulement pourquoi il est « hors ligne ».
library;

import 'dart:async';
import 'dart:math';

import '../data/database.dart';
import '../engine/offline_quiz.dart';
import '../engine/quiz_model.dart';
import '../engine/sections.dart';
import '../engine/text_tools.dart';
import '../remote/ai_client.dart';
import 'offline_runner.dart';

/// Pourquoi le quiz a été créé hors ligne (null : il vient de l'IA, ou l'IA n'était pas demandée).
enum Fallback {
  network,
  quota,
  failures,
  tooLong,
  busy,
  unavailable,
  rateLimited,
  disabled,
  unverified,
  refusedContent,
  language,
  other,
  cancelled,
}

class QuizOutcome {
  const QuizOutcome(this.quizId, {this.fallback, this.param, this.remaining});

  final int quizId;
  final Fallback? fallback;

  /// Valeur du message (minutes d'attente, nombre de caractères maximal).
  final int? param;

  /// Quiz IA restants aujourd'hui (si l'IA a répondu).
  final int? remaining;
}

/// Le texte ne suffit pas pour un quiz (même hors ligne).
class QuizTooShort implements Exception {}

/// Langue que le moteur hors ligne ne sait pas traiter, et l'IA n'a pas pu servir :
/// [why] dit pourquoi (null : l'IA n'était pas demandée).
class QuizLanguageUnsupported implements Exception {
  QuizLanguageUnsupported(this.why, [this.param]);

  final Fallback? why;
  final int? param;
}

/// Le serveur refuse les textes plus courts (inutile de consommer le quota).
const aiMinChars = 200;

typedef OfflineGenerator = Future<Quiz> Function(String text, {String? lang, int? seed, int count, Set<String> avoid});

class QuizService {
  QuizService(this.db, this.ai, {this.offline = generateOfflineQuiz});

  final AppDatabase db;
  final AiClient? ai;
  final OfflineGenerator offline;

  /// [text] : le texte complet du document ; [section] : la partie choisie (null : tout).
  /// [another] : un nouveau quiz sur un texte déjà travaillé (autre tirage hors ligne).
  /// [skipAi] : terminé par l'utilisateur (« Créer hors ligne maintenant ») pendant l'appel IA.
  /// [aiLanguages] : langues acceptées par le serveur (voir [AiQuota.languages]).
  Future<QuizOutcome> create({
    required int documentId,
    required String text,
    required String lang,
    required int count,
    required bool useAi,
    int? maxChars,
    bool another = false,
    Future<void>? skipAi,
    TextSection? section,
    Set<String> aiLanguages = const {'fr', 'en'},
    Fallback? early,
  }) async {
    final quizText = section?.of(text) ?? text;
    Fallback? why = early;
    int? param;
    if (useAi && ai != null && quizText.length >= aiMinChars) {
      if (!aiLanguages.contains(lang)) {
        why = Fallback.language;
      } else if (maxChars != null && quizText.length > maxChars) {
        why = Fallback.tooLong;
        param = maxChars;
      } else {
        try {
          final request = ai!.generate(quizText, lang: lang, count: count);
          final AiResult? result = skipAi == null
              ? await request
              : await Future.any<AiResult?>([request, skipAi.then((_) => null)]);
          if (result == null) {
            why = Fallback.cancelled;
            unawaited(request.then((_) {}, onError: (_) {})); // la réponse tardive est ignorée
          } else {
            final id = await db.saveQuiz(documentId, result.quiz, body: text, section: section);
            return QuizOutcome(id, remaining: result.remaining);
          }
        } on AiException catch (e) {
          (why, param) = fallbackFor(e);
        } catch (_) {
          why = Fallback.other;
        }
      }
    }
    if (!offlineLanguages.contains(lang)) throw QuizLanguageUnsupported(why, param);
    final Quiz quiz;
    try {
      quiz = await offline(
        quizText,
        lang: lang,
        seed: another ? Random().nextInt(1 << 31) : null,
        count: count,
        avoid: await db.usedQuotes(documentId),
      );
    } on OfflineQuizException catch (e) {
      if (e.reason == 'language') throw QuizLanguageUnsupported(why, param);
      throw QuizTooShort();
    }
    final id = await db.saveQuiz(documentId, quiz, body: text, section: section);
    return QuizOutcome(id, fallback: why, param: param);
  }
}

(Fallback, int?) fallbackFor(AiException e) {
  if (e.isNetwork || e.code == 'SERVER') return (Fallback.network, null);
  if (e.code == 'AUTH_010') return (Fallback.rateLimited, e.minutes ?? 10);
  return switch (e.reason) {
    'quota' || 'network_quota' || 'blocked' => (Fallback.quota, null),
    'failures' => (Fallback.failures, null),
    'too_long' => (Fallback.tooLong, null),
    'busy' => (Fallback.busy, null),
    'unavailable' || 'not_configured' => (Fallback.unavailable, null),
    'disabled' => (Fallback.disabled, null),
    'unverified' || 'bad_response' => (Fallback.unverified, null),
    'refused_content' => (Fallback.refusedContent, null),
    _ => (Fallback.other, null),
  };
}
