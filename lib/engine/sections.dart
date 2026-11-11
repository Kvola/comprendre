/// Découpage d'un long texte en parties, pour faire un quiz sur un passage
/// (un chapitre, une partie d'un PDF) plutôt que sur un livre entier.
/// Logique pure, testée.
library;

import 'text_tools.dart';

/// Au-delà de cette longueur, l'application propose de choisir une partie.
const sectionThreshold = 8000;

class TextSection {
  const TextSection(this.start, this.end, this.label, {this.heading = false});

  /// Position dans le texte complet : `text.substring(start, end)`.
  final int start;
  final int end;

  /// Titre trouvé dans le texte ([heading]), sinon ses premiers mots.
  final String label;
  final bool heading;

  int get length => end - start;

  String of(String text) => text.substring(start, end);

  @override
  String toString() => 'TextSection($start, $end, $label)';
}

class _Para {
  _Para(this.start, this.end, this.text);

  final int start;
  final int end;
  final String text;
}

/// Un paragraphe plus long que [max] (texte collé sans lignes vides, PDF d'un
/// seul bloc) est coupé aux retours à la ligne, sinon entre deux phrases.
List<_Para> _splitLong(_Para p, String text, int max, int target) {
  if (p.end - p.start <= max) return [p];
  final pieces = <(int, int)>[];
  for (final line in RegExp(r'[^\n]+').allMatches(text.substring(p.start, p.end))) {
    pieces.add((p.start + line.start, p.start + line.end));
  }
  final units = <(int, int)>[];
  for (final (a, b) in pieces) {
    if (b - a <= target) {
      units.add((a, b));
    } else {
      for (final sentence in splitSentences(text.substring(a, b))) {
        units.add((a + sentence.start, a + sentence.start + sentence.text.length));
      }
    }
  }
  final out = <_Para>[];
  int? start;
  var end = 0;
  for (final (a, b) in units) {
    if (start != null && b - start > target) {
      out.add(_Para(start, end, text.substring(start, end)));
      start = null;
    }
    start ??= a;
    end = b;
  }
  if (start != null) out.add(_Para(start, end, text.substring(start, end)));
  return out;
}

List<_Para> _paragraphs(String text) {
  final out = <_Para>[];
  var start = 0;
  void push(int end) {
    final raw = text.substring(start, end);
    final lead = raw.length - raw.trimLeft().length;
    final t = raw.trim();
    if (t.isNotEmpty) out.add(_Para(start + lead, start + lead + t.length, t));
  }

  for (final m in RegExp(r'\n\s*\n').allMatches(text)) {
    push(m.start);
    start = m.end;
  }
  push(text.length);
  return out;
}

/// Un titre : court, sur une ligne, sans ponctuation finale de phrase, avec des lettres.
bool _isHeading(String p) =>
    p.length <= 80 &&
    !p.contains('\n') &&
    RegExp(r'\p{L}', unicode: true).hasMatch(p) &&
    !RegExp(r'[.!?;:,…»"”)]$').hasMatch(p) &&
    wordsOf(p).length <= 12;

String _firstWords(String s, int n) {
  final matches = RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(s).toList();
  if (matches.length <= n) return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return '${s.substring(0, matches[n - 1].end).replaceAll(RegExp(r'\s+'), ' ').trim()}…';
}

/// Parties du texte, dans l'ordre, qui couvrent tout le texte utile.
///
/// - S'il y a au moins deux titres, une partie par titre (les parties trop
///   courtes sont regroupées avec la suivante, les trop longues coupées).
/// - Sinon, des parties d'environ [target] caractères, coupées entre deux paragraphes.
/// Aucune partie ne dépasse [max] caractères, sauf un paragraphe seul plus long.
List<TextSection> splitSections(String text, {int target = 6000, int max = 12000, int min = 1500}) {
  final paras = [for (final p in _paragraphs(text)) ..._splitLong(p, text, max, target)];
  if (paras.isEmpty) return const [];
  final headings = [
    for (var i = 0; i < paras.length; i++)
      if (_isHeading(paras[i].text) && i + 1 < paras.length) i,
  ];

  // Groupes de paragraphes : un par titre (le début avant le premier titre en est un aussi).
  // [titles] : les titres de chaque groupe (plusieurs après un regroupement).
  final groups = <List<_Para>>[];
  final titles = <List<String>>[];
  if (headings.length >= 2) {
    var current = <_Para>[];
    for (var i = 0; i < paras.length; i++) {
      if (headings.contains(i) && current.isNotEmpty) {
        groups.add(current);
        current = [];
      }
      current.add(paras[i]);
    }
    groups.add(current);
    for (final g in groups) {
      titles.add(headings.contains(paras.indexOf(g.first)) ? [g.first.text] : []);
    }
  } else {
    groups.add(paras);
    titles.add([]);
  }

  // Regroupe les parties trop courtes avec la suivante : un titre suivi d'une ligne, un
  // court préambule. Un chapitre titré reste seul tant qu'il a un peu de contenu.
  for (var i = 0; i < groups.length - 1;) {
    final len = groups[i].last.end - groups[i].first.start;
    final small = len < (titles[i].isEmpty ? min : 400);
    if (small) {
      // une partie trop longue après regroupement est recoupée plus bas
      groups[i] = [...groups[i], ...groups[i + 1]];
      titles[i] = [...titles[i], ...titles[i + 1]];
      groups.removeAt(i + 1);
      titles.removeAt(i + 1);
    } else {
      i++;
    }
  }

  final out = <TextSection>[];
  for (var g = 0; g < groups.length; g++) {
    final group = groups[g];
    final t = titles[g];
    final title = t.isEmpty ? null : (t.length == 1 ? t.first : '${t.first} – ${t.last}');
    // Coupe en morceaux d'environ [target] (jamais plus de [max]) entre deux paragraphes.
    final chunks = <List<_Para>>[];
    var cur = <_Para>[];
    for (final p in group) {
      final curLen = cur.isEmpty ? 0 : cur.last.end - cur.first.start;
      final withP = cur.isEmpty ? p.end - p.start : p.end - cur.first.start;
      final limit = headings.length >= 2 ? max : target;
      if (cur.isNotEmpty && withP > limit && curLen >= min) {
        chunks.add(cur);
        cur = [];
      }
      cur.add(p);
    }
    if (cur.isNotEmpty) {
      // Un dernier morceau minuscule rejoint le précédent.
      if (chunks.isNotEmpty && cur.last.end - cur.first.start < min && cur.last.end - chunks.last.first.start <= max) {
        chunks.last.addAll(cur);
      } else {
        chunks.add(cur);
      }
    }
    for (var c = 0; c < chunks.length; c++) {
      final chunk = chunks[c];
      final start = chunk.first.start, end = chunk.last.end;
      final String label;
      if (title != null) {
        label = chunks.length > 1 ? '$title (${c + 1}/${chunks.length})' : title;
      } else {
        label = _firstWords(chunk.first.text, 8);
      }
      out.add(TextSection(start, end, label, heading: title != null));
    }
  }
  return out;
}
