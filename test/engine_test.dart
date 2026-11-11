import 'package:comprendre/engine/offline_quiz.dart';
import 'package:comprendre/engine/quiz_model.dart';
import 'package:comprendre/engine/text_tools.dart';
import 'package:flutter_test/flutter_test.dart';

const fr =
    '''Le baobab est un arbre emblématique des savanes africaines. Il peut vivre plus de 1000 ans, selon les botanistes de Dakar.
Son tronc stocke de grandes quantités d'eau, ce qui permet au baobab de survivre aux longues saisons sèches. Ses fruits, appelés pain de singe, sont riches en vitamine C.

Les feuilles du baobab sont consommées en sauce au Sénégal, au Mali et au Burkina Faso. Les fibres de son écorce servent à fabriquer des cordes et des paniers.
Pourtant, des chercheurs de l'université de Montpellier ont observé que plusieurs très vieux baobabs sont morts depuis 2005. Le changement climatique pourrait expliquer cette disparition.
Pour protéger le baobab, des villages replantent de jeunes arbres et limitent la coupe des branches. Ces efforts montrent que le baobab reste précieux pour les habitants des savanes.''';

const en =
    '''The Nile is the longest river in Africa. It flows north for about 6650 kilometres before reaching the Mediterranean Sea.
Ancient Egypt depended on the Nile for water, food and transport. Every year, the flood of the Nile left fertile mud along its banks.
Farmers in Egypt planted wheat and barley in this mud. The Aswan High Dam, completed in 1970, now controls the flood of the Nile.
The dam produces electricity for Egypt, but it also traps the mud that once fed the fields. Today, farmers along the Nile must buy fertilisers instead.
Scientists from Cairo study how the Nile delta is shrinking as the sea rises. Protecting the delta has become a priority for Egypt.''';

/// Texte du rapport de revue (nombres groupés, « chaque campagne », « qui les revendent »).
const cacao =
    '''La Côte d'Ivoire compte environ 30 000 000 habitants selon le recensement. Abidjan, la capitale économique, abrite près de 6 300 000 personnes. Le pays produit chaque année environ 2 200 000 tonnes de cacao, ce qui en fait le premier producteur mondial. Le cacao représente une part importante des exportations du pays. Les planteurs vendent leurs fèves à des coopératives qui les revendent aux exportateurs. Le prix bord champ est fixé par le gouvernement au début de chaque campagne. En 2024, ce prix a atteint 1 800 francs CFA par kilogramme. Les coopératives jouent un rôle essentiel dans l'organisation de la filière. La forêt ivoirienne a beaucoup reculé à cause des plantations. Le gouvernement encourage désormais l'agroforesterie pour protéger les sols.''';

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
      expect(detectLanguage(cacao), 'fr');
      expect(
        detectLanguage(
          'La economía del país depende del cacao. Los agricultores venden sus granos a las cooperativas, '
          'que los revenden a los exportadores. El gobierno fija el precio al inicio de cada campaña.',
        ),
        'es',
      );
      expect(
        detectLanguage(
          'A economia do país depende do cacau. Os agricultores vendem os grãos às cooperativas, que '
          'não pagam muito. O governo fixa o preço no início de cada campanha e isso é importante.',
        ),
        'pt',
      );
      expect(
        detectLanguage(
          'Die Wirtschaft des Landes hängt vom Kakao ab. Die Bauern verkaufen ihre Bohnen an die '
          'Genossenschaften, und der Staat legt den Preis zu Beginn jeder Saison fest.',
        ),
        'de',
      );
      expect(
        detectLanguage(
          "L'economia del paese dipende dal cacao. I contadini vendono i loro semi alle cooperative, che "
          'li rivendono agli esportatori. Il governo fissa il prezzo della campagna, ma non sempre.',
        ),
        'it',
      );
    });

    test('nombres insécables à l’affichage, même longueur', () {
      const t = 'Environ 2 200 000 tonnes en 2024, 30 000 000 habitants, page 12 et 3 chiffres.';
      final d = keepNumbersTogether(t);
      expect(d.length, t.length);
      expect(d, contains('2\u00A0200\u00A0000'));
      expect(d, contains('30\u00A0000\u00A0000'));
      expect(d, contains('page 12 et 3 chiffres'), reason: 'les autres espaces ne changent pas');
      expect(d, contains('2024, 30'));
    });

    test('empreinte d’un texte', () {
      expect(textFingerprint(fr), textFingerprint(fr));
      expect(textFingerprint(fr), isNot(textFingerprint('${fr}x')));
      expect(textFingerprint('ab'), isNot(textFingerprint('ba')));
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
            expect(
              norm.contains(normalize(stmt)),
              q.answer == 1,
              reason: 'un « vrai » doit être dans le texte, un « faux » jamais : $stmt',
            );
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

    test('nombres groupés (« 2 200 000 », « 2,200,000 ») : un seul nombre, même écriture', () {
      for (var seed = 0; seed < 60; seed++) {
        final quiz = OfflineQuizGenerator(cacao, seed: seed).generate(count: 15);
        for (final q in quiz.questions.where((q) => q.question.contains('quel nombre'))) {
          expect(q.question, isNot(contains('_____ 000')), reason: q.question);
          expect(q.question, isNot(matches(RegExp(r'\d _____|_____ \d'))), reason: q.question);
          final correct = q.choices[q.answer];
          final grouped = correct.contains(' ');
          for (final c in q.choices) {
            expect(c.contains(' '), grouped, reason: 'même écriture que la bonne réponse : ${q.choices}');
          }
        }
      }
      const enNumbers =
          'The country produced about 2,200,000 tonnes of cocoa last year, according to the ministry. '
          'Farmers sold their beans to local cooperatives in every region of the country. '
          'The cooperatives sold the beans to large exporters based in the main port. '
          'The government fixed the farm price at the start of each season for all farmers. '
          'Forests have shrunk because new plantations replaced the old trees in the south. '
          'Today the government supports agroforestry to protect the soils and the rivers.';
      var seen = false;
      for (var seed = 0; seed < 40 && !seen; seed++) {
        for (final q in OfflineQuizGenerator(enNumbers, seed: seed).generate(count: 15).questions) {
          if (!q.question.contains('which number')) continue;
          seen = true;
          expect(q.choices[q.answer], '2,200,000');
          expect(q.choices.every((c) => RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(c)), isTrue, reason: '${q.choices}');
        }
      }
      expect(seen, isTrue, reason: 'une question de nombre attendue');
    });

    test('vrai/faux équilibrés', () {
      for (final text in [fr, en, cacao]) {
        var t = 0, f = 0;
        for (var seed = 0; seed < 100; seed++) {
          for (final q in OfflineQuizGenerator(text, seed: seed).generate(count: 15).questions.where((q) => q.isTrueFalse)) {
            q.answer == 1 ? t++ : f++;
          }
        }
        expect(t + f, greaterThan(50));
        expect((t - f).abs() / (t + f), lessThan(0.25), reason: 'vrai=$t faux=$f');
      }
    });

    test('distracteurs grammaticaux : genre, élision, pas de verbe pris pour un nom', () {
      for (var seed = 0; seed < 100; seed++) {
        for (final q in OfflineQuizGenerator(cacao, seed: seed).generate(count: 15).questions) {
          final all = [q.question, ...q.choices].join('\n');
          expect(all, isNot(contains('Le campagne')), reason: all);
          expect(all, isNot(contains('le campagne')), reason: all);
          expect(q.choices, isNot(contains('revendent')), reason: all);
          expect(all, isNot(matches(RegExp(r"\bl'[bcdfgjklmnpqrstvwxz]", caseSensitive: false))), reason: all);
        }
      }
    });

    test('autre langue : refus explicite (l’IA prend le relais)', () {
      const es =
          'La economía de Costa de Marfil depende en gran medida del cacao. El país es el primer productor mundial. '
          'Los agricultores venden sus granos a cooperativas que los revenden a los exportadores. El gobierno fija el precio '
          'al inicio de cada campaña. Los bosques del país han retrocedido mucho a causa de las plantaciones.';
      expect(
        () => OfflineQuizGenerator(es).generate(),
        throwsA(isA<OfflineQuizException>().having((e) => e.reason, 'reason', 'language')),
      );
    });

    test('« un autre quiz » évite les phrases des quiz précédents', () {
      final first = OfflineQuizGenerator(fr).generate();
      final used = {for (final q in first.questions) normalize(q.quote)};
      final second = OfflineQuizGenerator(fr, seed: 7, avoid: used).generate();
      final reused = second.questions.where((q) => used.contains(normalize(q.quote))).length;
      final fresh = splitSentences(fr).where((s) => !used.contains(normalize(s.text))).length;
      // Tant qu'il reste des phrases neuves, elles passent d'abord.
      expect(reused, lessThanOrEqualTo(second.questions.length - fresh.clamp(0, second.questions.length) + 2));
    });

    test('texte trop court : refus explicite', () {
      expect(() => OfflineQuizGenerator('Bonjour. Merci.').generate(), throwsA(isA<OfflineQuizException>()));
    });

    test('sérialisation du quiz', () {
      final quiz = OfflineQuizGenerator(en).generate();
      final back = Quiz.fromJson(quiz.toJson());
      expect(back.questions.length, quiz.questions.length);
      expect(back.questions.first.answer, quiz.questions.first.answer);
      expect(
        QuizQuestion.tryParse({
          'kind': 'choice',
          'choices': ['a'],
          'answer': 3,
        }),
        isNull,
      );
    });
  });
}
