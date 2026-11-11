/// Outils de texte : normalisation, phrases, mots, langue. Logique pure, testée.
library;

const _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae', 'ß': 'ss',
};

/// Forme de comparaison : minuscules, sans accents ni ponctuation, espaces simples.
/// Même règle que le serveur (contrôle des citations).
String normalize(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final f = _fold[ch] ?? ch;
    final c = f.codeUnitAt(0);
    final word = f.length > 1 || (c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39);
    b.write(word ? f : ' ');
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Nettoie un texte extrait (PDF, OCR…) : césures de fin de ligne, espaces, lignes vides.
String cleanText(String raw) {
  var t = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll(' ', ' ').replaceAll('­', '');
  t = t.replaceAllMapped(RegExp(r'(\p{L})-\n(\p{Ll})', unicode: true), (m) => '${m[1]}${m[2]}'); // césure
  t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
  // Une ligne coupée au milieu d'une phrase (PDF, photo) est recollée ; un vrai paragraphe (ligne vide) reste.
  t = t.replaceAllMapped(RegExp(r'([^\n.!?:;»"”])\n(?!\n)(\p{Ll})', unicode: true), (m) => '${m[1]} ${m[2]}');
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.split('\n').map((l) => l.trim()).join('\n').trim();
}

const _abbrev = {
  'm', 'mm', 'mme', 'mlle', 'dr', 'pr', 'st', 'ste', 'etc', 'cf', 'ex', 'p', 'pp', 'vol', 'chap', 'fig', 'n', 'no', //
  'mr',
  'mrs',
  'ms',
  'prof',
  'jr',
  'sr',
  'vs',
  'e.g',
  'i.e',
  'inc',
  'ltd',
  'av',
  'apr',
  'env',
  'janv',
  'févr',
  'sept',
  'oct',
  'nov',
  'déc',
};

/// Phrases d'un texte, avec leur position (caractère de début) pour les retrouver.
class Sentence {
  const Sentence(this.text, this.start, this.index);

  final String text;
  final int start;
  final int index;

  List<String> get words => wordsOf(text);
}

List<Sentence> splitSentences(String text) {
  final out = <Sentence>[];
  var start = 0;
  void push(int end) {
    final raw = text.substring(start, end);
    final trimmedLeft = raw.length - raw.trimLeft().length;
    final s = raw.trim();
    if (s.isNotEmpty && RegExp(r'\p{L}', unicode: true).hasMatch(s)) {
      out.add(Sentence(s, start + trimmedLeft, out.length));
    }
    start = end;
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '\n' && i + 1 < text.length && text[i + 1] == '\n') {
      push(i);
      continue;
    }
    if (ch != '.' && ch != '!' && ch != '?' && ch != '…') continue;
    // Absorbe la ponctuation et les guillemets fermants qui suivent.
    var j = i + 1;
    while (j < text.length && '.!?…»"”’)'.contains(text[j])) {
      j++;
    }
    if (j < text.length && text[j] != ' ' && text[j] != '\n') continue; // 3.5, e.g.x
    if (ch == '.') {
      final before = RegExp(r'(\p{L}+)\.$', unicode: true).firstMatch(text.substring(start, i + 1));
      final w = before?.group(1)?.toLowerCase();
      if (w != null && (_abbrev.contains(w) || (w.length == 1 && w.toUpperCase() == before!.group(1)))) continue;
    }
    // Une fin de phrase est suivie d'une majuscule, d'un chiffre, d'un guillemet ou de la fin.
    var k = j;
    while (k < text.length && (text[k] == ' ' || text[k] == '\n')) {
      k++;
    }
    if (k < text.length && !RegExp(r'[\p{Lu}\d«"“(—–-]', unicode: true).hasMatch(text[k])) continue;
    push(j);
  }
  push(text.length);
  return out;
}

/// Mots d'une phrase (lettres, chiffres, traits d'union internes), apostrophes séparées (« l'arbre » → l, arbre).
List<String> wordsOf(String s) =>
    RegExp(r"[\p{L}\p{N}]+(?:[-][\p{L}\p{N}]+)*", unicode: true).allMatches(s).map((m) => m[0]!).toList();

const stopwordsFr = {
  'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'd', 'l', 'au', 'aux', 'et', 'ou', 'mais', 'donc', 'or', 'ni', 'car', //
  'que',
  'qui',
  'quoi',
  'dont',
  'où',
  'ce',
  'cet',
  'cette',
  'ces',
  'se',
  'sa',
  'son',
  'ses',
  'leur',
  'leurs',
  'mon',
  'ma',
  'mes', //
  'ton',
  'ta',
  'tes',
  'notre',
  'nos',
  'votre',
  'vos',
  'il',
  'elle',
  'ils',
  'elles',
  'on',
  'nous',
  'vous',
  'je',
  'tu',
  'me',
  'te', //
  'lui', 'y', 'en', 'ne', 'pas', 'plus', 'moins', 'très', 'trop', 'peu', 'est', 'sont', 'était', 'étaient', 'être', 'été', //
  'a',
  'ont',
  'avait',
  'avaient',
  'avoir',
  'eu',
  'fait',
  'faire',
  'peut',
  'peuvent',
  'pour',
  'par',
  'avec',
  'sans',
  'sur',
  'sous', //
  'dans', 'entre', 'vers', 'chez', 'depuis', 'pendant', 'avant', 'après', 'comme', 'si', 'aussi', 'ainsi', 'alors', 'tout', //
  'tous', 'toute', 'toutes', 'autre', 'autres', 'même', 'mêmes', 'bien', 'encore', 'déjà', 'toujours', 'jamais', 'cela', 'ça', //
  'ceci', 'celui', 'celle', 'ceux', 'celles', 'quand', 'lorsque', 'puis', 'enfin', 'c', 's', 'n', 'j', 'm', 't', 'qu', //
  'sera', 'seront', 'serait', 'fut', 'avons', 'avez', 'suis', 'es', 'sommes', 'êtes', 'chaque', 'plusieurs', 'certains',
};

const stopwordsEn = {
  'the', 'a', 'an', 'and', 'or', 'but', 'so', 'nor', 'for', 'yet', 'of', 'to', 'in', 'on', 'at', 'by', 'with', 'from', 'as', //
  'is', 'are', 'was', 'were', 'be', 'been', 'being', 'am', 'has', 'have', 'had', 'do', 'does', 'did', 'will', 'would', 'can', //
  'could', 'should', 'may', 'might', 'must', 'shall', 'it', 'its', 'this', 'that', 'these', 'those', 'he', 'she', 'they', 'we', //
  'you',
  'i',
  'him',
  'her',
  'them',
  'us',
  'me',
  'his',
  'their',
  'our',
  'your',
  'my',
  'not',
  'no',
  'more',
  'most',
  'less',
  'very', //
  'too', 'also', 'than', 'then', 'there', 'here', 'when', 'where', 'which', 'who', 'whom', 'whose', 'what', 'why', 'how', 'if', //
  'into', 'over', 'under', 'about', 'after', 'before', 'between', 'during', 'since', 'until', 'while', 'all', 'any', 'each', //
  'some', 'such', 'other', 'only', 'own', 'same', 'just', 's', 't', 'up', 'out', 'many', 'much', 'one', 'like', 'even', 'still',
};

/// Langues reconnues (saisie, IA). Le moteur hors ligne ne sait faire que [offlineLanguages].
const textLanguages = ['fr', 'en', 'es', 'pt', 'de', 'it'];
const offlineLanguages = {'fr', 'en'};

/// Mots outils très fréquents des autres langues (assez pour reconnaître la langue,
/// pas pour fabriquer des questions).
const _stopwordsOther = {
  'es': {
    'el', 'la', 'los', 'las', 'de', 'del', 'que', 'y', 'en', 'un', 'una', 'por', 'para', 'con', 'no', 'su', 'sus', //
    'al', 'lo', 'es', 'se', 'como', 'más', 'pero', 'este', 'esta', 'porque', 'muy', 'sin', 'sobre', 'también', 'son', //
    'está', 'fue', 'ha', 'han', 'entre', 'cuando', 'hay', 'desde', 'todo', 'ya', 'ser', 'era', 'eso', 'hasta',
  },
  'pt': {
    'o', 'os', 'a', 'as', 'de', 'do', 'da', 'dos', 'das', 'que', 'e', 'em', 'no', 'na', 'nos', 'nas', 'um', 'uma', //
    'com', 'não', 'mais', 'ao', 'pelo', 'pela', 'é', 'foi', 'são', 'está', 'mas', 'como', 'também', 'isso', 'seu', //
    'sua', 'já', 'muito', 'quando', 'entre', 'para', 'por', 'se', 'ser', 'tem', 'até', 'ou', 'pelos', 'pelas',
  },
  'de': {
    'der', 'die', 'das', 'und', 'ist', 'nicht', 'ein', 'eine', 'zu', 'den', 'von', 'mit', 'sich', 'des', 'auf', 'für', //
    'im', 'dem', 'auch', 'es', 'an', 'werden', 'aus', 'er', 'hat', 'dass', 'sie', 'nach', 'wird', 'bei', 'einer', //
    'um', 'noch', 'wie', 'einem', 'über', 'so', 'zum', 'war', 'haben', 'nur', 'oder', 'aber', 'vor', 'zur', 'bis', 'durch',
  },
  'it': {
    'il', 'di', 'che', 'e', 'la', 'per', 'un', 'una', 'del', 'della', 'non', 'sono', 'con', 'gli', 'le', 'si', 'da', //
    'nel', 'nella', 'è', 'al', 'alla', 'anche', 'come', 'più', 'ma', 'dei', 'delle', 'questo', 'questa', 'ha', 'hanno', //
    'essere', 'molto', 'tra', 'quando', 'ancora', 'lo', 'degli', 'nei', 'sul', 'sulla', 'era', 'perché', 'loro',
  },
};

/// Langue probable du texte, parmi [textLanguages] (mots outils les plus présents ;
/// le français l'emporte en cas de doute).
String detectLanguage(String text) {
  final scores = {for (final l in textLanguages) l: 0};
  for (final w in wordsOf(text.toLowerCase()).take(3000)) {
    if (stopwordsFr.contains(w)) scores['fr'] = scores['fr']! + 1;
    if (stopwordsEn.contains(w)) scores['en'] = scores['en']! + 1;
    for (final MapEntry(:key, :value) in _stopwordsOther.entries) {
      if (value.contains(w)) scores[key] = scores[key]! + 1;
    }
  }
  var best = 'fr';
  for (final l in textLanguages) {
    // Le français (grande liste de mots outils) part avec un avantage : une autre
    // langue doit nettement dépasser.
    final threshold = l == 'fr' ? 0 : scores['fr']! * 1.2;
    if (scores[l]! > threshold && scores[l]! > scores[best]! * (best == 'fr' ? 1.2 : 1)) best = l;
  }
  return best;
}

/// Graine stable tirée du texte (FNV-1a) : le même texte donne le même quiz, sauf si l'on en demande un autre.
int stableSeed(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// Position (début, fin) de [quote] dans [text], en ignorant casse, accents,
/// ponctuation et retours à la ligne ; null si la citation est introuvable.
(int, int)? findQuote(String text, String quote) {
  final target = normalize(quote);
  if (target.isEmpty) return null;
  // Texte normalisé caractère par caractère, avec la position d'origine de chacun.
  final norm = StringBuffer();
  final origin = <int>[];
  var lastSpace = true;
  final lower = text.toLowerCase();
  for (var i = 0; i < lower.length; i++) {
    final f = _fold[lower[i]] ?? lower[i];
    final c = f.codeUnitAt(0);
    final word = f.length > 1 || (c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39);
    if (word) {
      for (var k = 0; k < f.length; k++) {
        norm.write(f[k]);
        origin.add(i);
      }
      lastSpace = false;
    } else if (!lastSpace) {
      norm.write(' ');
      origin.add(i);
      lastSpace = true;
    }
  }
  final hay = norm.toString();
  final at = hay.indexOf(target);
  if (at < 0) return null;
  var end = origin[at + target.length - 1] + 1;
  // La ponctuation qui termine la citation fait partie du passage surligné.
  while (end < text.length && '.!?…'.contains(text[end])) {
    end++;
  }
  return (origin[at], end);
}

/// Empreinte d'un texte (sa longueur et deux hachages de 31 bits, sûrs aussi
/// dans un navigateur) : sert à savoir si un texte a changé depuis un quiz.
String textFingerprint(String s) {
  var h2 = 0x811c9dc5;
  for (var i = s.length - 1; i >= 0; i--) {
    h2 ^= s.codeUnitAt(i);
    h2 = (h2 * 0x01000193) & 0x7fffffff;
  }
  return '${s.length}-${stableSeed(s).toRadixString(36)}-${h2.toRadixString(36)}';
}
