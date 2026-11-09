/// Générateur de quiz HORS LIGNE : tout est tiré du texte lui-même, donc juste
/// par construction. Logique pure (pas de Flutter), testée.
///
/// Types de questions :
/// - **thème** : de quoi parle principalement le texte (nom dominant) ;
/// - **texte à trous** : un nom ou un nom propre retiré d'une phrase ;
/// - **chiffres et dates** : un nombre retiré, avec des nombres voisins ;
/// - **vrai/faux** : une phrase exacte, ou la même avec un nom échangé ;
/// - **« selon le texte »** : laquelle de ces affirmations figure dans le texte ;
/// - **ordre** : laquelle de ces idées vient en premier.
///
/// Pour rester grammatical sans analyseur, on n'échange que des **noms** (mot
/// précédé d'un déterminant), de même nombre et de genre compatible, ou des
/// noms propres entre eux (« Burkina Faso » est un seul nom). Chaque question
/// garde sa phrase source (citation), pour la retrouver dans le texte.
library;

import 'dart:math';

import '../core/background.dart';
import 'quiz_model.dart';
import 'text_tools.dart';

class OfflineQuizException implements Exception {
  OfflineQuizException(this.reason);

  /// `too_short` : pas assez de matière pour un quiz utile.
  final String reason;

  @override
  String toString() => 'OfflineQuizException($reason)';
}

const _detFr = {
  'le': 'm', 'un': 'm', 'ce': 'm', 'cet': 'm', 'du': 'm', 'au': 'm', 'son': null, 'mon': null, 'ton': null, //
  'la': 'f', 'une': 'f', 'cette': 'f', 'sa': 'f', 'ma': 'f', 'ta': 'f', //
  'l': null, 'les': null, 'des': null, 'aux': null, 'ces': null, 'ses': null, 'leur': null, 'leurs': null, //
  'mes': null, 'tes': null, 'notre': null, 'nos': null, 'votre': null, 'vos': null, 'chaque': null, //
  'plusieurs': null, 'quelques': null, 'certains': null, 'certaines': null,
};
const _detEn = {
  'the', 'a', 'an', 'this', 'these', 'those', 'his', 'her', 'its', 'their', 'our', 'your', 'my', 'each', //
  'every', 'some', 'many', 'several', 'few',
};

/// Adjectifs placés avant le nom (« aux longues saisons ») : ce ne sont pas des noms.
const _preAdjFr = {
  'grand', 'grande', 'grands', 'grandes', 'petit', 'petite', 'petits', 'petites', 'long', 'longue', 'longs', 'longues', //
  'jeune', 'jeunes', 'vieux', 'vieil', 'vieille', 'vieilles', 'beau', 'bel', 'belle', 'beaux', 'belles', 'bon', 'bonne', //
  'bons', 'bonnes', 'mauvais', 'mauvaise', 'mauvaises', 'nouveau', 'nouvel', 'nouvelle', 'nouveaux', 'nouvelles', //
  'premier', 'première', 'premiers', 'premières', 'dernier', 'dernière', 'derniers', 'dernières', 'gros', 'grosse', //
  'grosses', 'haut', 'haute', 'hauts', 'hautes', 'seul', 'seule', 'seuls', 'seules', 'meilleur', 'meilleure', //
  'meilleurs', 'meilleures', 'second', 'seconde', 'deuxième', 'troisième', 'principal', 'principale', 'principaux', //
  'principales', 'ancien', 'ancienne', 'anciens', 'anciennes', 'vrai', 'vraie', 'vrais', 'vraies', 'faux', 'fausse', //
  'certain', 'certaine', 'différents', 'différentes', 'nombreux', 'nombreuses', 'simple', 'simples', 'immense', 'immenses',
};

/// Un terme du texte (nom commun regroupé singulier/pluriel, nom propre ou nombre).
class _Term {
  _Term(this.key, this.kind);

  final String key;
  final String kind; // noun | proper | number
  final forms = <String, int>{}; // formes rencontrées
  final sentences = <int>{};
  final genders = <String>{};
  int count = 0;
  int articled = 0; // occurrences précédées d'un article (« the Nile », « au Mali »)
  double score = 0;

  String get surface => (forms.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

  String? get gender => genders.length == 1 ? genders.first : null;
}

/// Un emplacement échangeable dans une phrase.
class _Slot {
  _Slot(this.surface, this.term, this.det);

  final String surface; // tel qu'écrit dans la phrase (peut contenir des espaces)
  final _Term term;
  final String? det; // déterminant qui précède (minuscule), pour les noms
}

class OfflineQuizGenerator {
  OfflineQuizGenerator(this.text, {String? lang, int? seed})
    : lang = lang ?? detectLanguage(text),
      _rnd = Random(seed ?? stableSeed(text));

  final String text;
  final String lang;
  final Random _rnd;

  late final List<Sentence> _sentences = splitSentences(text);
  late final String _normText = normalize(text);
  final _terms = <String, _Term>{};
  final _slots = <int, List<_Slot>>{};
  final _usedAnswers = <String, int>{};

  bool get _fr => lang != 'en';

  // ------------------------------------------------------------------ //
  // Analyse : termes et emplacements
  // ------------------------------------------------------------------ //
  bool _plural(String w) {
    final l = w.toLowerCase();
    return _fr ? (l.endsWith('s') || l.endsWith('x')) && l.length > 3 : l.endsWith('s') && !l.endsWith('ss') && l.length > 3;
  }

  String _stem(String w) {
    final k = normalize(w);
    if (k.length > 4 && _plural(w)) return k.substring(0, k.length - 1);
    return k;
  }

  void _analyse() {
    final stop = _fr ? stopwordsFr : stopwordsEn;
    final upper = RegExp(r'^\p{Lu}', unicode: true);
    for (final s in _sentences) {
      final words = s.words;
      final slots = _slots[s.index] = [];
      for (var i = 0; i < words.length; i++) {
        final w = words[i];
        final lower = w.toLowerCase();
        _Term? term;
        var surface = w;
        String? det;
        if (RegExp(r'^\d[\d.,]*$').hasMatch(w)) {
          term = _terms.putIfAbsent('#$w', () => _Term('#$w', 'number'));
        } else if (i > 0 && upper.hasMatch(w) && !stop.contains(lower) && w.length > 1) {
          // Nom propre, éventuellement sur plusieurs mots (« Burkina Faso », « Aswan High Dam »).
          var j = i + 1;
          while (j < words.length && upper.hasMatch(words[j]) && !stop.contains(words[j].toLowerCase())) {
            j++;
          }
          surface = words.sublist(i, j).join(' ');
          final key = 'P${normalize(surface)}';
          term = _terms.putIfAbsent(key, () => _Term(key, 'proper'));
          if (_isDet(words[i - 1])) {
            det = words[i - 1].toLowerCase();
            term.articled++;
          }
          i = j - 1;
        } else if (w.length >= 4 && !stop.contains(lower) && !_adjectiveBefore(words, i) && _detBefore(words, i) != null) {
          // Nom : précédé d'un déterminant, éventuellement avec un adjectif entre les deux.
          det = _detBefore(words, i);
          final key = 'N${_stem(w)}';
          term = _terms.putIfAbsent(key, () => _Term(key, 'noun'));
          final g = _fr ? _detFr[det] : null;
          if (g != null) term.genders.add(g);
        }
        if (term == null) continue;
        term.count++;
        term.sentences.add(s.index);
        term.forms[surface] = (term.forms[surface] ?? 0) + 1;
        if (term.kind != 'number') slots.add(_Slot(surface, term, det));
      }
    }
    // Un nom commun compte aussi quand il apparaît sans déterminant (« de baobab »).
    final counts = <String, int>{};
    for (final w in wordsOf(text)) {
      counts['N${_stem(w)}'] = (counts['N${_stem(w)}'] ?? 0) + 1;
    }
    for (final t in _terms.values) {
      if (t.kind == 'noun') t.count = max(t.count, counts[t.key] ?? 0);
      final boost = switch (t.kind) { 'proper' => 1.4, 'number' => 0.8, _ => 1.0 };
      final spread = t.sentences.length / max(1, _sentences.length);
      t.score = t.count * boost * (1 + 2 * spread) + min(t.key.length, 12) / 24;
    }
  }

  /// Le mot en position [i] est-il un adjectif placé avant un nom ?
  bool _adjectiveBefore(List<String> words, int i) {
    final lower = words[i].toLowerCase();
    if (_fr) return _preAdjFr.contains(lower);
    // En anglais l'adjectif précède le nom : « the longest river », « fertile mud ».
    if (i + 1 >= words.length) return false;
    final next = words[i + 1];
    return RegExp(r'^\p{Ll}', unicode: true).hasMatch(next) && next.length >= 3 && !stopwordsEn.contains(next) &&
        !RegExp(r'(ed|ing|ly|s)$').hasMatch(next) || lower.endsWith('est');
  }

  String? _detBefore(List<String> words, int i) {
    if (i > 0 && _isDet(words[i - 1])) return words[i - 1].toLowerCase();
    if (i > 1 && _isDet(words[i - 2]) && _adjectiveBefore(words, i - 1)) return words[i - 2].toLowerCase();
    return null;
  }

  bool _isDet(String w) => _fr ? _detFr.containsKey(w.toLowerCase()) : _detEn.contains(w.toLowerCase());

  /// Termes du plus important au moins important (calculé une fois, après l'analyse).
  late final List<_Term> _ranked = _terms.values.toList()..sort((a, b) => b.score.compareTo(a.score));

  // ------------------------------------------------------------------ //
  // Génération
  // ------------------------------------------------------------------ //
  Quiz generate({int count = 10}) {
    _analyse();
    final usable = _sentences.where(_sentenceOk).toList();
    final swappable = _terms.values.where((t) => t.kind != 'number').length;
    if (usable.length < 3 || swappable < 5) throw OfflineQuizException('too_short');
    final questions = <QuizQuestion>[];
    final usedSentences = <int>{};

    bool add(QuizQuestion? q, [int? sentence]) {
      if (q == null || questions.length >= count) return false;
      if (questions.any((x) => x.question == q.question || x.quote == q.quote && x.skill == q.skill)) return false;
      questions.add(q);
      if (sentence != null) usedSentences.add(sentence);
      return true;
    }

    add(_mainTopic());
    final ordered = _spread(usable); // début, fin, puis vers le milieu
    const plan = ['cloze', 'statement', 'number', 'truefalse', 'cloze', 'order', 'cloze', 'truefalse', 'statement', 'cloze'];
    var p = 0, cursor = 0, guard = 0;
    while (questions.length < count && guard++ < count * 15) {
      final type = plan[p++ % plan.length];
      var pool = ordered.where((s) => !usedSentences.contains(s.index)).toList();
      if (pool.isEmpty) pool = ordered; // texte court : on réutilise des phrases, pas les questions
      final s = pool[cursor++ % pool.length];
      switch (type) {
        case 'cloze':
          add(_cloze(s), s.index);
        case 'number':
          final q = _number(pool);
          if (q != null) add(q.$1, q.$2);
        case 'truefalse':
          add(_trueFalse(s), s.index);
        case 'statement':
          add(_statement(s), s.index);
        case 'order':
          add(_order(usable));
      }
    }
    if (questions.length < 3) throw OfflineQuizException('too_short');
    return Quiz(engine: QuizEngine.offline, title: _title(), summary: '', questions: questions, lang: lang);
  }

  bool _sentenceOk(Sentence s) {
    final n = s.words.length;
    return n >= 6 && n <= 45;
  }

  List<Sentence> _spread(List<Sentence> list) {
    final out = <Sentence>[];
    var lo = 0, hi = list.length - 1;
    while (lo <= hi) {
      out.add(list[lo++]);
      if (lo <= hi) out.add(list[hi--]);
    }
    return out;
  }

  String _title() => _sentences.isEmpty ? '' : _excerpt(_sentences.first.text, 8);

  /// Les [n] premiers mots d'une phrase, tels qu'écrits (ponctuation et apostrophes conservées).
  String _excerpt(String s, int n) {
    final matches = RegExp(r"[\p{L}\p{N}]+", unicode: true).allMatches(s).toList();
    if (matches.length <= n) return s;
    return '${s.substring(0, matches[n - 1].end)}…';
  }

  RegExp _wordRe(String surface) =>
      RegExp('(?<![\\p{L}\\p{N}])${surface.split(' ').map(RegExp.escape).join(r'\s+')}(?![\\p{L}\\p{N}])', unicode: true);

  // -- Distracteurs ------------------------------------------------------
  /// Formes de remplacement pour [slot] : même nature, même nombre, genre compatible,
  /// absentes de la phrase [exclude]. Les plus importantes du texte d'abord (plausibles).
  List<String> _replacements(_Slot slot, {required String exclude, int n = 3}) {
    final ex = normalize(exclude);
    final term = slot.term;
    final wantPlural = term.kind == 'noun' ? _plural(slot.surface) : null;
    final slotGender = _fr && term.kind == 'noun' && slot.det != null ? _detFr[slot.det] : null;
    final scored = <(String, double)>[];
    for (final t in _ranked) {
      if (t.key == term.key || t.kind != term.kind) continue;
      String? form;
      if (t.kind == 'noun') {
        // Forme de même nombre ; genre : jamais contraire, inconnu en dernier recours.
        if (slotGender != null && t.gender != null && t.gender != slotGender) continue;
        final forms = t.forms.keys.where((f) => _plural(f) == wantPlural).toList();
        if (forms.isEmpty) continue;
        form = forms.first;
        if (!_fr && (slot.det == 'a' || slot.det == 'an')) {
          final vowel = RegExp(r'^[aeiouAEIOU]').hasMatch(form);
          if (vowel != (slot.det == 'an')) continue;
        }
        if (slot.surface[0] == slot.surface[0].toUpperCase() && form[0] != form[0].toUpperCase()) {
          form = form[0].toUpperCase() + form.substring(1);
        }
      } else {
        // Nom propre : avec article seulement contre un autre qui en prend un (« the Nile » / « the Sahara »).
        if (t.kind == 'proper' && (slot.det != null) != (t.articled * 2 > t.count)) continue;
        form = t.surface;
      }
      if (_wordRe(normalize(form)).hasMatch(ex)) continue;
      final penalty = (term.kind == 'noun' && slotGender != null && t.gender == null) ? 0.5 : 1.0;
      scored.add((form, t.score * penalty));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(8).map((e) => e.$1).toList()..shuffle(_rnd);
    final seen = <String>{normalize(slot.surface)};
    return [for (final f in top) if (seen.add(normalize(f))) f].take(n).toList();
  }

  /// Emplacements d'une phrase, les moins déjà utilisés comme réponse d'abord, puis les plus importants.
  List<_Slot> _slotsOf(Sentence s) {
    final list = [...?_slots[s.index]];
    list.sort((a, b) {
      final ua = _usedAnswers[a.term.key] ?? 0, ub = _usedAnswers[b.term.key] ?? 0;
      return ua != ub ? ua.compareTo(ub) : b.term.score.compareTo(a.term.score);
    });
    return list;
  }

  void _markUsed(_Term t) => _usedAnswers[t.key] = (_usedAnswers[t.key] ?? 0) + 1;

  // -- Thème principal ---------------------------------------------------
  QuizQuestion? _mainTopic() {
    final candidates = _ranked.where((t) => t.kind != 'number').toList();
    if (candidates.length < 6) return null;
    final top = candidates.first;
    if (top.sentences.length < 2 || top.count < 3) return null; // pas de thème qui domine nettement
    // Distracteurs : des noms du texte, peu présents (des détails, pas le thème).
    // Ni un mot répété, ni un mot de la phrase qui présente le thème (« le baobab est un ARBRE ») :
    // ce serait une réponse à moitié juste.
    final first = top.sentences.reduce(min);
    final rare = candidates
        .skip(1)
        .where((t) => t.sentences.length == 1 && t.count == 1 && !t.sentences.contains(first))
        .toList()
      ..shuffle(_rnd);
    if (rare.length < 3) return null;
    final quote = _sentences[top.sentences.reduce(min)].text;
    String cap(String s) => s[0].toUpperCase() + s.substring(1);
    final answer = cap(top.surface);
    return _shuffled(
      question: _fr ? 'De quoi ce texte parle-t-il principalement ?' : 'What is this text mainly about?',
      correct: answer,
      options: [answer, ...rare.take(3).map((t) => cap(t.surface))],
      explanation: _fr
          ? '« ${top.surface} » revient ${top.count} fois, du début à la fin : c’est le sujet central. Les autres ne sont que des détails.'
          : '“${top.surface}” appears ${top.count} times, from start to finish: it is the central subject. The others are details.',
      quote: quote,
      skill: 'main_idea',
    );
  }

  // -- Texte à trous -----------------------------------------------------
  QuizQuestion? _cloze(Sentence s) {
    for (final slot in _slotsOf(s)) {
      if ((_usedAnswers[slot.term.key] ?? 0) >= 2) continue;
      final options = _replacements(slot, exclude: s.text);
      if (options.length < 3) continue;
      final blanked = s.text.replaceFirst(_wordRe(slot.surface), '_____');
      if (blanked == s.text) continue;
      _markUsed(slot.term);
      return _shuffled(
        question: _fr ? 'Complétez selon le texte :\n« $blanked »' : 'Complete according to the text:\n“$blanked”',
        correct: slot.surface,
        options: [slot.surface, ...options],
        explanation: _fr ? 'Le texte dit : « ${s.text} »' : 'The text says: “${s.text}”',
        quote: s.text,
        skill: slot.term.kind == 'proper' ? 'detail' : 'vocabulary',
      );
    }
    return null;
  }

  // -- Chiffres et dates --------------------------------------------------
  (QuizQuestion, int)? _number(List<Sentence> candidates) {
    for (final s in candidates) {
      final m = RegExp(r'(?<![\d.,])(\d{1,4}(?:[.,]\d+)?)(?![\d.,]?\d)').firstMatch(s.text);
      if (m == null || s.words.length < 6) continue;
      final raw = m[1]!;
      final value = double.tryParse(raw.replaceAll(',', '.'));
      if (value == null || value == 0) continue;
      final decimal = raw.contains(RegExp(r'[.,]'));
      final isYear = !decimal && value >= 1000 && value <= 2100 && raw.length == 4;
      final candidatesV = isYear
          ? [value - 10, value + 10, value - 50, value + 25, value - 5]
          : value < 10 && !decimal
          ? [value + 1, value + 2, value - 1, value * 3, value + 5]
          : [value * 2, value / 2, value * 1.5, value * 10, value + 10];
      final options = <String>{raw};
      for (final v in candidatesV) {
        if (options.length == 4) break;
        if (v <= 0 || v == value) continue;
        final t = decimal ? v.toStringAsFixed(raw.split(RegExp(r'[.,]')).last.length).replaceAll('.', raw.contains(',') ? ',' : '.') : v.round().toString();
        if (!_normText.contains(' ${normalize(t)} ') || t == raw) options.add(t);
      }
      if (options.length < 4) continue;
      final blanked = s.text.replaceRange(m.start, m.end, '_____');
      final q = _shuffled(
        question: _fr
            ? 'Selon le texte, quel nombre complète la phrase ?\n« $blanked »'
            : 'According to the text, which number completes the sentence?\n“$blanked”',
        correct: raw,
        options: options.toList(),
        explanation: _fr ? 'Le texte dit : « ${s.text} »' : 'The text says: “${s.text}”',
        quote: s.text,
        skill: 'detail',
      );
      if (q != null) return (q, s.index);
    }
    return null;
  }

  // -- Vrai / faux ---------------------------------------------------------
  QuizQuestion? _trueFalse(Sentence s) {
    if (s.words.length > 30) return null;
    String ask(String stmt) => _fr ? 'Vrai ou faux, selon le texte ?\n« $stmt »' : 'True or false, according to the text?\n“$stmt”';
    if (_rnd.nextBool()) {
      final altered = _alter(s);
      if (altered != null) {
        return QuizQuestion(
          kind: 'truefalse',
          question: ask(altered.$1),
          choices: const [],
          answer: 0,
          explanation: _fr
              ? 'Faux : le texte parle de « ${altered.$2} », pas de « ${altered.$3} ». Il dit : « ${s.text} »'
              : 'False: the text mentions “${altered.$2}”, not “${altered.$3}”. It says: “${s.text}”',
          quote: s.text,
          skill: 'detail',
        );
      }
    }
    return QuizQuestion(
      kind: 'truefalse',
      question: ask(s.text),
      choices: const [],
      answer: 1,
      explanation: _fr ? 'Vrai : c’est exactement ce que dit le texte.' : 'True: this is exactly what the text says.',
      quote: s.text,
      skill: 'detail',
    );
  }

  /// La phrase avec un nom remplacé par un autre nom du texte.
  /// Renvoie (phrase modifiée, mot d'origine, mot de remplacement), ou null.
  (String, String, String)? _alter(Sentence s) {
    for (final slot in _slotsOf(s)) {
      final repl = _replacements(slot, exclude: s.text, n: 1);
      if (repl.isEmpty) continue;
      final altered = s.text.replaceFirst(_wordRe(slot.surface), repl.first);
      // Jamais une « fausse » phrase qui figurerait quelque part dans le texte.
      if (altered == s.text || _normText.contains(normalize(altered))) continue;
      return (altered, slot.surface, repl.first);
    }
    return null;
  }

  // -- « Selon le texte » --------------------------------------------------
  QuizQuestion? _statement(Sentence s) {
    if (s.words.length > 28) return null;
    final others = <String>{};
    final pool = _spread(_sentences.where((x) => x.index != s.index && _sentenceOk(x) && x.words.length <= 28).toList())..shuffle(_rnd);
    for (final other in pool) {
      if (others.length == 3) break;
      final a = _alter(other);
      if (a != null) others.add(a.$1);
    }
    if (others.length < 3) return null;
    return _shuffled(
      question: _fr ? 'Laquelle de ces affirmations figure dans le texte ?' : 'Which of these statements is in the text?',
      correct: s.text,
      options: [s.text, ...others],
      explanation: _fr
          ? 'Seule cette phrase est fidèle au texte ; dans les autres, un mot a été changé.'
          : 'Only this sentence matches the text; in the others, one word was changed.',
      quote: s.text,
      skill: 'detail',
    );
  }

  // -- Ordre des idées -----------------------------------------------------
  QuizQuestion? _order(List<Sentence> usable) {
    if (usable.length < 6) return null;
    final picks = <Sentence>[];
    final step = usable.length ~/ 4;
    for (var k = 0; k < 4; k++) {
      final i = min(usable.length - 1, k * step + _rnd.nextInt(max(1, step)));
      if (!picks.any((p) => p.index == usable[i].index)) picks.add(usable[i]);
    }
    if (picks.length < 3) return null;
    final first = picks.reduce((a, b) => a.index < b.index ? a : b);
    return _shuffled(
      question: _fr ? 'Dans le texte, laquelle de ces idées vient en premier ?' : 'In the text, which of these ideas comes first?',
      correct: _excerpt(first.text, 12),
      options: [for (final p in picks) _excerpt(p.text, 12)],
      explanation: _fr
          ? 'Le texte commence par cette idée avant d’aborder les autres.'
          : 'The text starts with this idea before moving on to the others.',
      quote: first.text,
      skill: 'structure',
    );
  }

  QuizQuestion? _shuffled({
    required String question,
    required String correct,
    required List<String> options,
    required String explanation,
    required String quote,
    String skill = 'detail',
  }) {
    final unique = <String, String>{};
    for (final o in options) {
      unique.putIfAbsent(normalize(o), () => o);
    }
    if (unique.length < 3) return null;
    final list = unique.values.toList()..shuffle(_rnd);
    final answer = list.indexOf(correct);
    if (answer < 0) return null;
    return QuizQuestion(
      kind: 'choice',
      question: question,
      choices: list,
      answer: answer,
      explanation: explanation,
      quote: quote,
      skill: skill,
    );
  }
}

/// Génère un quiz hors ligne dans un isolat (un long PDF ne fige pas l'interface ;
/// dans un navigateur, sur le fil courant). Lève [OfflineQuizException] si le
/// texte ne suffit pas.
Future<Quiz> generateOfflineQuiz(String text, {String? lang, int? seed, int count = 10}) =>
    runInBackground(() => OfflineQuizGenerator(text, lang: lang, seed: seed).generate(count: count));
