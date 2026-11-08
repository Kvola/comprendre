/// Extraction du texte des fichiers importés (logique pure Dart, testée).
///
/// Formats : txt, md, csv, html, docx, pptx, xlsx (texte des cellules), odt, odp,
/// epub, rtf. Le PDF passe par `pdf_extract.dart` (moteur natif + OCR des pages
/// scannées). Les anciens formats binaires (.doc, .ppt) ne sont pas lisibles :
/// on demande de les enregistrer en .docx/.pptx/.pdf.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class ExtractException implements Exception {
  ExtractException(this.code);

  /// `unsupported` | `legacy_office` | `empty` | `corrupt` | `encrypted` | `too_large`
  final String code;

  @override
  String toString() => 'ExtractException($code)';
}

/// Extensions acceptées par le sélecteur de fichiers.
const supportedExtensions = [
  'txt', 'md', 'markdown', 'csv', 'html', 'htm', 'docx', 'pptx', 'xlsx', 'odt', 'odp', 'epub', 'rtf', 'pdf', //
];

/// Taille maximale d'un fichier importé (au-delà, l'appareil peine et le quiz n'aurait pas de sens).
const maxImportBytes = 40 * 1024 * 1024;

String extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// Texte d'un fichier non-PDF. Lève [ExtractException].
String extractText(String fileName, Uint8List bytes) {
  if (bytes.length > maxImportBytes) throw ExtractException('too_large');
  final ext = extensionOf(fileName);
  final String text;
  try {
    text = switch (ext) {
      'txt' || 'md' || 'markdown' || 'csv' => decodeTextBytes(bytes),
      'html' || 'htm' => htmlToText(decodeTextBytes(bytes)),
      'docx' => _docx(bytes),
      'pptx' => _pptx(bytes),
      'xlsx' => _xlsx(bytes),
      'odt' || 'odp' => _odf(bytes),
      'epub' => _epub(bytes),
      'rtf' => rtfToText(decodeTextBytes(bytes)),
      'doc' || 'ppt' || 'xls' => throw ExtractException('legacy_office'),
      _ => throw ExtractException('unsupported'),
    };
  } on ExtractException {
    rethrow;
  } on FormatException {
    throw ExtractException('corrupt');
  } on XmlException {
    throw ExtractException('corrupt');
  }
  final out = text.trim();
  if (out.isEmpty) throw ExtractException('empty');
  return out;
}

/// UTF-8 (avec ou sans BOM), UTF-16 (BOM), sinon Latin-1 / Windows-1252.
String decodeTextBytes(Uint8List b) {
  if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) return _utf16(b.sublist(2), little: true);
  if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) return _utf16(b.sublist(2), little: false);
  final start = (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) ? 3 : 0;
  try {
    return utf8.decode(b.sublist(start));
  } on FormatException {
    return b.map(cp1252Char).join();
  }
}

/// Caractères Windows-1252 de 0x80 à 0x9F (guillemets, tirets, œ, €…) ; Latin-1 ailleurs.
const _cp1252 = {
  0x80: '€', 0x82: '‚', 0x83: 'ƒ', 0x84: '„', 0x85: '…', 0x86: '†', 0x87: '‡', 0x88: 'ˆ', 0x89: '‰', 0x8A: 'Š', //
  0x8B: '‹', 0x8C: 'Œ', 0x8E: 'Ž', 0x91: '‘', 0x92: '’', 0x93: '“', 0x94: '”', 0x95: '•', 0x96: '–', 0x97: '—', //
  0x98: '˜', 0x99: '™', 0x9A: 'š', 0x9B: '›', 0x9C: 'œ', 0x9E: 'ž', 0x9F: 'Ÿ',
};

String cp1252Char(int b) => _cp1252[b] ?? String.fromCharCode(b);

String _utf16(Uint8List b, {required bool little}) {
  final units = <int>[];
  for (var i = 0; i + 1 < b.length; i += 2) {
    units.add(little ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1]);
  }
  return String.fromCharCodes(units);
}

// ---------------------------------------------------------------------- //
// HTML
// ---------------------------------------------------------------------- //
const _entities = {
  'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ', 'laquo': '«', 'raquo': '»', //
  'rsquo': '’', 'lsquo': '‘', 'rdquo': '”', 'ldquo': '“', 'hellip': '…', 'mdash': '—', 'ndash': '–', 'oelig': 'œ', //
  'eacute': 'é', 'egrave': 'è', 'ecirc': 'ê', 'agrave': 'à', 'acirc': 'â', 'ccedil': 'ç', 'ocirc': 'ô', 'ucirc': 'û', //
  'ugrave': 'ù', 'icirc': 'î', 'iuml': 'ï', 'euml': 'ë', 'Eacute': 'É', 'Agrave': 'À', 'Ccedil': 'Ç',
};

String decodeEntities(String s) => s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
  final e = m[1]!;
  if (e.startsWith('#x')) return String.fromCharCode(int.tryParse(e.substring(2), radix: 16) ?? 0x20);
  if (e.startsWith('#')) return String.fromCharCode(int.tryParse(e.substring(1)) ?? 0x20);
  return _entities[e] ?? m[0]!;
});

/// Texte lisible d'une page HTML : blocs → paragraphes ; scripts, styles et menus ignorés.
String htmlToText(String html) {
  var s = html.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');
  s = s.replaceAll(
    RegExp(r'<(script|style|noscript|nav|header|footer|svg|head)\b.*?</\1\s*>', caseSensitive: false, dotAll: true),
    ' ',
  );
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</?(p|div|h[1-6]|li|tr|section|article|blockquote|pre|ul|ol|table)\b[^>]*>', caseSensitive: false), '\n\n');
  s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
  s = decodeEntities(s);
  return _tidy(s);
}

String _tidy(String s) => s
    .replaceAll(RegExp(r'[ \t\u00a0]+'), ' ')
    .split('\n')
    .map((l) => l.trim())
    .join('\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

// ---------------------------------------------------------------------- //
// Formats bureautiques (archives ZIP de XML)
// ---------------------------------------------------------------------- //
Archive _zip(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
    // Un fichier Office protégé par mot de passe est un conteneur OLE, pas un ZIP.
    if (bytes.length > 8 && bytes[0] == 0xD0 && bytes[1] == 0xCF) throw ExtractException('encrypted');
    throw ExtractException('corrupt');
  }
  return ZipDecoder().decodeBytes(bytes);
}

XmlDocument? _xmlIn(Archive a, String name) {
  final f = a.findFile(name);
  if (f == null) return null;
  return XmlDocument.parse(utf8.decode(f.content, allowMalformed: true));
}

/// Paragraphes d'un document XML : [para] = nom local du paragraphe, [run] = nom local du texte.
String _paragraphs(XmlDocument doc, {required String para, required String run, String? tab, String? br}) {
  final out = StringBuffer();
  for (final p in doc.descendants.whereType<XmlElement>().where((e) => e.name.local == para)) {
    final line = StringBuffer();
    for (final e in p.descendants.whereType<XmlElement>()) {
      final n = e.name.local;
      if (n == run) {
        line.write(e.innerText);
      } else if (n == tab) {
        line.write('\t');
      } else if (n == br) {
        line.write('\n');
      }
    }
    final t = line.toString().trim();
    if (t.isNotEmpty) out.writeln(t);
  }
  return out.toString();
}

String _docx(Uint8List bytes) {
  final a = _zip(bytes);
  final doc = _xmlIn(a, 'word/document.xml');
  if (doc == null) throw ExtractException('corrupt');
  // Paragraphes séparés par une ligne vide : ce sont de vrais paragraphes pour le découpage en phrases.
  return _paragraphs(doc, para: 'p', run: 't', tab: 'tab', br: 'br').replaceAll('\n', '\n\n');
}

int _num(String name) => int.tryParse(RegExp(r'(\d+)\.xml$').firstMatch(name)?.group(1) ?? '') ?? 0;

String _pptx(Uint8List bytes) {
  final a = _zip(bytes);
  final slides = a.files.where((f) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name)).toList()
    ..sort((x, y) => _num(x.name).compareTo(_num(y.name)));
  final out = StringBuffer();
  for (final f in slides) {
    final doc = XmlDocument.parse(utf8.decode(f.content, allowMalformed: true));
    final t = _paragraphs(doc, para: 'p', run: 't', br: 'br').trim();
    if (t.isEmpty) continue;
    // Chaque ligne d'une diapositive est une idée : on la termine pour le découpage en phrases.
    out.writeln(t.split('\n').map(_terminate).join('\n'));
    out.writeln();
  }
  return out.toString();
}

/// Une puce de diapositive sans ponctuation finale reçoit un point.
String _terminate(String line) {
  final l = line.trim();
  if (l.isEmpty || RegExp(r'[.!?…:;»"”)]$').hasMatch(l)) return l;
  return '$l.';
}

String _xlsx(Uint8List bytes) {
  final a = _zip(bytes);
  final doc = _xmlIn(a, 'xl/sharedStrings.xml');
  if (doc == null) return '';
  final cells = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'si').map((e) => e.innerText.trim());
  return cells.where((c) => c.isNotEmpty).map(_terminate).join('\n');
}

String _odf(Uint8List bytes) {
  final a = _zip(bytes);
  final doc = _xmlIn(a, 'content.xml');
  if (doc == null) throw ExtractException('corrupt');
  final out = StringBuffer();
  final presentation = doc.descendants.whereType<XmlElement>().any((e) => e.name.local == 'presentation');
  for (final p in doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'p' || e.name.local == 'h')) {
    // Un paragraphe imbriqué (dans une note, une cellule) est traité pour lui-même.
    if (p.ancestors.whereType<XmlElement>().any((x) => x.name.local == 'p' || x.name.local == 'h')) continue;
    final b = StringBuffer();
    void walk(XmlNode n) {
      for (final c in n.children) {
        if (c is XmlText) {
          b.write(c.value);
        } else if (c is XmlElement) {
          switch (c.name.local) {
            case 's':
              b.write(' ' * (int.tryParse(c.getAttribute('text:c') ?? c.getAttribute('c') ?? '') ?? 1));
            case 'tab':
              b.write('\t');
            case 'line-break':
              b.write('\n');
            case 'note':
              break; // notes de bas de page : hors du fil du texte
            default:
              walk(c);
          }
        }
      }
    }

    walk(p);
    final t = b.toString().trim();
    if (t.isNotEmpty) out.writeln(presentation ? _terminate(t) : '$t\n');
  }
  return out.toString();
}

String _epub(Uint8List bytes) {
  final a = _zip(bytes);
  final container = _xmlIn(a, 'META-INF/container.xml');
  final opfPath = container?.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 'rootfile')
      .firstOrNull
      ?.getAttribute('full-path');
  final out = StringBuffer();
  List<String> chapters;
  if (opfPath != null && a.findFile(opfPath) != null) {
    final opf = _xmlIn(a, opfPath)!;
    final base = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
    final manifest = {
      for (final e in opf.descendants.whereType<XmlElement>().where((e) => e.name.local == 'item'))
        e.getAttribute('id'): e.getAttribute('href'),
    };
    chapters = [
      for (final e in opf.descendants.whereType<XmlElement>().where((e) => e.name.local == 'itemref'))
        if (manifest[e.getAttribute('idref')] case final href?) base + Uri.decodeFull(href),
    ];
  } else {
    chapters = a.files.where((f) => RegExp(r'\.x?html?$').hasMatch(f.name)).map((f) => f.name).toList()..sort();
  }
  for (final c in chapters) {
    final f = a.findFile(c);
    if (f == null) continue;
    out.writeln(htmlToText(utf8.decode(f.content, allowMalformed: true)));
    out.writeln();
  }
  return out.toString();
}

// ---------------------------------------------------------------------- //
// RTF (lecture simple : texte, paragraphes, caractères spéciaux)
// ---------------------------------------------------------------------- //
const _rtfSkip = {
  'fonttbl', 'colortbl', 'stylesheet', 'info', 'pict', 'header', 'footer', 'headerl', 'headerr', 'footerl', //
  'footerr', 'footnote', 'listtable', 'listoverridetable', 'rsidtbl', 'generator', 'xmlnstbl', 'themedata', //
  'colorschememapping', 'latentstyles', 'datastore', 'fldinst', 'object', 'filetbl', 'revtbl',
};

String rtfToText(String rtf) {
  final out = StringBuffer();
  final stack = <(bool, int)>[]; // (groupe ignoré, uc)
  var skip = false;
  var uc = 1; // caractères de repli après \uN
  var pendingSkip = 0;
  var i = 0;
  while (i < rtf.length) {
    final ch = rtf[i];
    if (ch == '{') {
      stack.add((skip, uc));
      i++;
      if (rtf.startsWith(r'{\*', i - 1)) skip = true;
      continue;
    }
    if (ch == '}') {
      if (stack.isNotEmpty) (skip, uc) = stack.removeLast();
      i++;
      continue;
    }
    if (ch == '\\') {
      final m = RegExp(r"\\([a-zA-Z]+)(-?\d+)? ?|\\'([0-9a-fA-F]{2})|\\(.)", dotAll: true).matchAsPrefix(rtf, i);
      if (m == null) {
        i++;
        continue;
      }
      i = m.end;
      if (m[3] != null) {
        if (pendingSkip > 0) {
          pendingSkip--;
        } else if (!skip) {
          out.write(cp1252Char(int.parse(m[3]!, radix: 16)));
        }
        continue;
      }
      if (m[4] != null) {
        final c = m[4]!;
        if (!skip && (c == '\\' || c == '{' || c == '}')) out.write(c);
        if (!skip && c == '~') out.write(' ');
        if (!skip && (c == '\n' || c == '\r')) out.write('\n'); // « \ » en fin de ligne = paragraphe
        continue;
      }
      final word = m[1]!;
      final arg = m[2] == null ? null : int.parse(m[2]!);
      if (_rtfSkip.contains(word)) {
        skip = true;
      } else if (word == 'uc') {
        uc = arg ?? 1;
      } else if (word == 'u' && arg != null) {
        if (!skip) out.writeCharCode(arg < 0 ? arg + 65536 : arg);
        pendingSkip = uc;
      } else if (!skip) {
        switch (word) {
          case 'par' || 'line' || 'sect' || 'page':
            out.write('\n');
          case 'tab' || 'cell':
            out.write('\t');
          case 'row':
            out.write('\n');
          case 'emdash':
            out.write('—');
          case 'endash':
            out.write('–');
          case 'lquote':
            out.write('‘');
          case 'rquote':
            out.write('’');
          case 'ldblquote':
            out.write('“');
          case 'rdblquote':
            out.write('”');
          case 'bullet':
            out.write('•');
        }
      }
      continue;
    }
    if (ch == '\r' || ch == '\n') {
      i++;
      continue;
    }
    if (pendingSkip > 0) {
      pendingSkip--;
    } else if (!skip) {
      out.write(ch);
    }
    i++;
  }
  return _tidy(out.toString().replaceAll('\n', '\n\n'));
}
