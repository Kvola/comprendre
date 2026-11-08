/// Un quiz (même forme que la réponse du serveur, pour les deux moteurs).
library;

enum QuizEngine { offline, ai }

class QuizQuestion {
  const QuizQuestion({
    required this.kind,
    required this.question,
    required this.choices,
    required this.answer,
    required this.explanation,
    required this.quote,
    this.skill = 'detail',
  });

  /// `choice` (propositions) ou `truefalse`.
  final String kind;
  final String question;

  /// Propositions (vide pour un vrai/faux).
  final List<String> choices;

  /// Indice de la bonne proposition ; pour un vrai/faux, 1 = vrai, 0 = faux.
  final int answer;
  final String explanation;

  /// Passage du texte qui justifie la réponse (recopié mot pour mot).
  final String quote;
  final String skill;

  bool get isTrueFalse => kind == 'truefalse';

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'question': question,
    'choices': choices,
    'answer': answer,
    'explanation': explanation,
    'quote': quote,
    'skill': skill,
  };

  static QuizQuestion? tryParse(Object? j) {
    if (j is! Map) return null;
    final kind = j['kind'];
    final answer = j['answer'];
    final choices = (j['choices'] is List) ? (j['choices'] as List).map((c) => '$c').toList() : <String>[];
    if (kind != 'choice' && kind != 'truefalse') return null;
    if (answer is! num) return null;
    if (kind == 'choice' && (choices.length < 2 || answer < 0 || answer >= choices.length)) return null;
    if (kind == 'truefalse' && answer != 0 && answer != 1) return null;
    return QuizQuestion(
      kind: kind as String,
      question: '${j['question'] ?? ''}',
      choices: kind == 'choice' ? choices : const [],
      answer: answer.toInt(),
      explanation: '${j['explanation'] ?? ''}',
      quote: '${j['quote'] ?? ''}',
      skill: '${j['skill'] ?? 'detail'}',
    );
  }
}

class Quiz {
  const Quiz({required this.engine, required this.title, required this.summary, required this.questions, required this.lang});

  final QuizEngine engine;
  final String title;
  final String summary;
  final List<QuizQuestion> questions;
  final String lang;

  Map<String, dynamic> toJson() => {
    'engine': engine.name,
    'title': title,
    'summary': summary,
    'lang': lang,
    'questions': [for (final q in questions) q.toJson()],
  };

  static Quiz fromJson(Map<String, dynamic> j) => Quiz(
    engine: j['engine'] == 'ai' ? QuizEngine.ai : QuizEngine.offline,
    title: '${j['title'] ?? ''}',
    summary: '${j['summary'] ?? ''}',
    lang: '${j['lang'] ?? 'fr'}',
    questions: [
      for (final q in (j['questions'] as List? ?? const [])) ?QuizQuestion.tryParse(q),
    ],
  );
}
