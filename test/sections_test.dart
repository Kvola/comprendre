import 'package:comprendre/engine/sections.dart';
import 'package:flutter_test/flutter_test.dart';

String _para(int n, String word) => List.generate(n, (i) => 'Phrase $i sur le $word, assez longue pour compter.').join(' ');

void main() {
  void checkCoverage(String text, List<TextSection> sections, {int max = 12000}) {
    expect(sections, isNotEmpty);
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i];
      expect(s.start, greaterThanOrEqualTo(0));
      expect(s.end, lessThanOrEqualTo(text.length));
      expect(s.start, lessThan(s.end));
      expect(s.of(text).trim(), s.of(text), reason: 'pas d’espaces en bord de partie');
      if (i > 0) expect(s.start, greaterThanOrEqualTo(sections[i - 1].end), reason: 'dans l’ordre, sans chevauchement');
      expect(s.label.trim(), isNotEmpty);
    }
    // Tout le texte utile est couvert : seul du blanc reste entre les parties.
    var covered = text.substring(0, sections.first.start);
    for (var i = 1; i < sections.length; i++) {
      covered += text.substring(sections[i - 1].end, sections[i].start);
    }
    covered += text.substring(sections.last.end);
    expect(covered.trim(), isEmpty);
  }

  test('chapitres : une partie par titre', () {
    final text = [
      'Introduction',
      _para(30, 'début'),
      'Chapitre 1 : les racines',
      _para(40, 'racine'),
      'Chapitre 2 : le tronc',
      _para(40, 'tronc'),
      'Conclusion',
      _para(30, 'fin'),
    ].join('\n\n');
    final sections = splitSections(text);
    checkCoverage(text, sections);
    expect(sections.map((s) => s.label).toList(), [
      'Introduction',
      'Chapitre 1 : les racines',
      'Chapitre 2 : le tronc',
      'Conclusion',
    ]);
    expect(sections.every((s) => s.heading), isTrue);
  });

  test('sans titres : parties d’environ 6000 caractères, entre deux paragraphes', () {
    final text = List.generate(40, (i) => _para(8, 'sujet $i')).join('\n\n');
    final sections = splitSections(text);
    checkCoverage(text, sections);
    expect(sections.length, greaterThan(2));
    for (final s in sections) {
      expect(s.length, lessThanOrEqualTo(12000));
      expect(s.heading, isFalse);
      expect(s.label, endsWith('…'));
    }
  });

  test('un titre suivi de peu de texte rejoint la partie suivante ; un long chapitre est coupé', () {
    final long = List.generate(40, (i) => _para(10, 'long $i')).join('\n\n');
    final text = ['Titre court', 'Une ligne.', 'Chapitre long', long, 'Fin', _para(20, 'fin')].join('\n\n');
    final sections = splitSections(text);
    checkCoverage(text, sections);
    expect(sections.first.label, startsWith('Titre court – Chapitre long'));
    expect(sections.where((s) => s.label.startsWith('Titre court – Chapitre long (')).length, greaterThan(1));
  });

  test('texte collé d’un seul bloc : coupé entre deux phrases', () {
    final oneLine = _para(600, 'bloc');
    final sections = splitSections(oneLine);
    checkCoverage(oneLine, sections);
    expect(sections.length, greaterThan(2));
    for (final s in sections) {
      expect(s.length, lessThanOrEqualTo(12000));
      expect(s.of(oneLine), endsWith('.'), reason: 'coupé en fin de phrase');
    }
    final lines = List.generate(300, (i) => 'Ligne $i du texte collé avec de simples retours.').join('\n');
    checkCoverage(lines, splitSections(lines));
    expect(splitSections(lines).length, greaterThan(1));
  });

  test('chapitres courts : chacun sa partie', () {
    final text = List.generate(8, (i) => 'Chapitre ${i + 1}\n\n${_para(12, 'sujet $i')}').join('\n\n');
    final sections = splitSections(text);
    checkCoverage(text, sections);
    expect(sections.map((s) => s.label).toList(), [for (var i = 1; i <= 8; i++) 'Chapitre $i']);
  });

  test('texte vide', () {
    expect(splitSections(''), isEmpty);
    expect(splitSections('   \n\n  '), isEmpty);
  });
}
