import '../core/background.dart';
import '../engine/offline_quiz.dart';
import '../engine/quiz_model.dart';

/// Génère un quiz hors ligne dans un isolat (un long PDF ne fige pas l'interface ;
/// dans un navigateur, sur le fil courant). Lève [OfflineQuizException] si le
/// texte ne suffit pas ou si sa langue n'est pas gérée hors ligne.
Future<Quiz> generateOfflineQuiz(String text, {String? lang, int? seed, int count = 10, Set<String> avoid = const {}}) =>
    runInBackground(() => OfflineQuizGenerator(text, lang: lang, seed: seed, avoid: avoid).generate(count: count));
