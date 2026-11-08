import 'package:comprendre/engine/offline_quiz.dart';
import 'package:comprendre/engine/quiz_model.dart';
import 'package:comprendre/engine/text_tools.dart';
import 'package:flutter_test/flutter_test.dart';

const fr = '''Le baobab est un arbre emblématique des savanes africaines. Il peut vivre plus de 1000 ans, selon les botanistes de Dakar.
Son tronc stocke de grandes quantités d'eau, ce qui permet au baobab de survivre aux longues saisons sèches. Ses fruits, appelés pain de singe, sont riches en vitamine C.

Les feuilles du baobab sont consommées en sauce au Sénégal, au Mali et au Burkina Faso. Les fibres de son écorce servent à fabriquer des cordes et des paniers.
Pourtant, des chercheurs de l'université de Montpellier ont observé que plusieurs très vieux baobabs sont morts depuis 2005. Le changement climatique pourrait expliquer cette disparition.
Pour protéger le baobab, des villages replantent de jeunes arbres et limitent la coupe des branches. Ces efforts montrent que le baobab reste précieux pour les habitants des savanes.''';

const en = '''The Nile is the longest river in Africa. It flows north for about 6650 kilometres before reaching the Mediterranean Sea.
Ancient Egypt depended on the Nile for water, food and transport. Every year, the flood of the Nile left fertile mud along its banks.
Farmers in Egypt planted wheat and barley in this mud. The Aswan High Dam, completed in 1970, now controls the flood of the Nile.
The dam produces electricity for Egypt, but it also traps the mud that once fed the fields. Today, farmers along the Nile must buy fertilisers instead.
Scientists from Cairo study how the Nile delta is shrinking as the sea rises. Protecting the delta has become a priority for Egypt.''';

void main() {
  group('Outils de texte', () {
    test('normalisation identique au serveur', () {
      expect(normalize("L’Été, déjà !"), 'l ete deja');
      expect(normalize('Cœur'), 'coeur');
    });

    test('phrases : abréviations et décimales ne coupent pas', () {
      final s = splitSentences('M. Dupont mesure 1.85 mètre. Il habite à Abidjan, etc. Sa sœur aussi. Fin');
      expect(s.map((x) => x.text).toList(), ['M. Dupont mesure 1.85 mètre.', 'Il habite à Abidjan, etc. Sa sœur aussi.', 'Fin']);
    });

    test('positions des phrases dans le texte', () {
      for (final s in splitSentences(fr)) {
        expect(fr.substring(s.start, s.start + s.text.length), s.text);
      }
    });

    test('nettoyage des textes extraits (césure, lignes coupées)', () {
      expect(cleanText('Le gouver-\nnement a décidé\nde changer.\n\n\n\nFin.'), 'Le gouvernement a décidé de changer.\n\nFin.');
    });

    test('retrouver une citation dans le texte d’origine', () {
      const t = 'Il dit :\n« L’Été  sera-t-il chaud ? »\nOui.';
      final r = findQuote(t, 'l ete sera t il chaud');
      expect(r, isNotNull);
      expect(t.substring(r!.$1, r.$2), 'L’Été  sera-t-il chaud');
      expect(findQuote(t, 'hiver'), isNull);
      expect(findQuote(t, '   '), isNull);
      final q = findQuote(fr, 'Le changement climatique pourrait expliquer cette disparition.');
      expect(fr.substring(q!.$1, q.$2), 'Le changement climatique pourrait expliquer cette disparition.');
    });

    test('détection de la langue', () {
      expect(detectLanguage(fr), 'fr');
      expect(detectLanguage(en), 'en');
    });
  });

  group('Générateur hors ligne', () {
    for (final (lang, text) in [('fr', fr), ('en', en)]) {
      test('quiz juste par construction ($lang)', () {
        final quiz = OfflineQuizGenerator(text).generate(count: 10);
        expect(quiz.lang, lang);
        expect(quiz.engine, QuizEngine.offline);
        expect(quiz.questions.length, greaterThanOrEqualTo(6));
        final norm = normalize(text);
        for (final q in quiz.questions) {
          expect(norm.contains(normalize(q.quote)), isTrue, reason: 'citation hors du texte : ${q.quote}');
          expect(q.question.trim(), isNotEmpty);
          expect(q.explanation.trim(), isNotEmpty);
          if (q.isTrueFalse) {
            expect(q.choices, isEmpty);
            expect([0, 1], contains(q.answer));
            final stmt = q.question.split('\n').last.replaceAll(RegExp(r'^[«“]\s*|\s*[»”]$'), '');
            expect(norm.contains(normalize(stmt)), q.answer == 1,
                reason: 'un « vrai » doit être dans le texte, un « faux » jamais : $stmt');
          } else {
            expect(q.choices.length, greaterThanOrEqualTo(3));
            expect(q.answer, inInclusiveRange(0, q.choices.length - 1));
            expect(q.choices.map(normalize).toSet().length, q.choices.length, reason: 'propositions en double');
          }
        }
        // Les « affirmations » fausses ne figurent jamais dans le texte.
        for (final q in quiz.questions.where((q) => q.question.contains('affirmations') || q.question.contains('statements'))) {
          for (var i = 0; i < q.choices.length; i++) {
            expect(norm.contains(normalize(q.choices[i])), i == q.answer, reason: q.choices[i]);
          }
        }
        // Variété : plusieurs types de questions.
        expect(quiz.questions.map((q) => q.skill).toSet().length, greaterThanOrEqualTo(2));
      });
    }

    test('même texte : même quiz ; autre graine : autre quiz', () {
      final a = OfflineQuizGenerator(fr).generate().questions.map((q) => q.question).toList();
      final b = OfflineQuizGenerator(fr).generate().questions.map((q) => q.question).toList();
      final c = OfflineQuizGenerator(fr, seed: 42).generate().questions.map((q) => q.question).toList();
      expect(a, b);
      expect(c, isNot(a));
    });

    test('texte trop court : refus explicite', () {
      expect(() => OfflineQuizGenerator('Bonjour. Merci.').generate(), throwsA(isA<OfflineQuizException>()));
    });

    test('sérialisation du quiz', () {
      final quiz = OfflineQuizGenerator(en).generate();
      final back = Quiz.fromJson(quiz.toJson());
      expect(back.questions.length, quiz.questions.length);
      expect(back.questions.first.answer, quiz.questions.first.answer);
      expect(QuizQuestion.tryParse({'kind': 'choice', 'choices': ['a'], 'answer': 3}), isNull);
    });
  });
}
