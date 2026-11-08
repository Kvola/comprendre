import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:comprendre/extract/extractors.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _fixture(String name) => File('test/fixtures/$name').readAsBytesSync();

Uint8List _zip(Map<String, String> files) {
  final a = Archive();
  files.forEach((name, content) {
    final data = utf8.encode(content);
    a.addFile(ArchiveFile(name, data.length, data));
  });
  return Uint8List.fromList(ZipEncoder().encode(a));
}

void main() {
  void expectSample(String text) {
    expect(text, contains('L’éléphant d’Afrique est le plus grand animal terrestre.'));
    expect(text, contains('appelée matriarche'));
    expect(text, contains('« véritable »'));
    // Deux paragraphes distincts.
    expect(text.indexOf('terrestre.') < text.indexOf('Il vit'), isTrue);
    expect(text, contains('\n'));
  }

  test('docx (Word)', () => expectSample(extractText('a.docx', _fixture('sample.docx'))));
  test('odt (LibreOffice)', () => expectSample(extractText('a.odt', _fixture('sample.odt'))));
  test('rtf', () => expectSample(extractText('a.rtf', _fixture('sample.rtf'))));
  test('html', () => expectSample(extractText('a.html', _fixture('sample.html'))));
  test('txt', () => expectSample(extractText('a.TXT', _fixture('source.txt'))));

  test('txt : encodages (BOM UTF-8, UTF-16, Latin-1)', () {
    expect(decodeTextBytes(Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('Été')])), 'Été');
    expect(decodeTextBytes(Uint8List.fromList([0xFF, 0xFE, 0xC9, 0x00, 0x74, 0x00])), 'Ét');
    expect(decodeTextBytes(Uint8List.fromList(latin1.encode('café'))), 'café');
  });

  test('pptx : diapositives dans l’ordre, puces terminées', () {
    String slide(String body) =>
        '<p:sld xmlns:p="p" xmlns:a="a"><p:cSld><p:spTree><p:sp><p:txBody>$body</p:txBody></p:sp></p:spTree></p:cSld></p:sld>';
    final bytes = _zip({
      'ppt/slides/slide10.xml': slide('<a:p><a:r><a:t>Conclusion finale</a:t></a:r></a:p>'),
      'ppt/slides/slide2.xml': slide('<a:p><a:r><a:t>Le soleil </a:t></a:r><a:r><a:t>est une étoile</a:t></a:r></a:p>'),
      'ppt/slides/slide1.xml': slide('<a:p><a:r><a:t>Introduction !</a:t></a:r></a:p>'),
    });
    final t = extractText('cours.pptx', bytes);
    expect(t.indexOf('Introduction !') < t.indexOf('Le soleil est une étoile.'), isTrue);
    expect(t.indexOf('étoile.') < t.indexOf('Conclusion finale.'), isTrue);
  });

  test('epub : chapitres dans l’ordre de lecture', () {
    final bytes = _zip({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml':
          '<container><rootfiles><rootfile full-path="OEBPS/content.opf"/></rootfiles></container>',
      'OEBPS/content.opf': '<package><manifest><item id="b" href="ch%202.xhtml"/><item id="a" href="ch1.xhtml"/>'
          '</manifest><spine><itemref idref="a"/><itemref idref="b"/></spine></package>',
      'OEBPS/ch1.xhtml': '<html><head><title>X</title><style>p{}</style></head><body><p>Premier chapitre.</p></body></html>',
      'OEBPS/ch 2.xhtml': '<html><body><h1>Deux</h1><p>Second&nbsp;chapitre &amp; fin.</p></body></html>',
    });
    final t = extractText('livre.epub', bytes);
    expect(t, isNot(contains('X')));
    expect(t.indexOf('Premier chapitre.') < t.indexOf('Second chapitre & fin.'), isTrue);
  });

  test('html : scripts, styles et menus ignorés ; entités décodées', () {
    final t = htmlToText('<html><script>var a=1;</script><nav>Menu</nav><p>Bonjour&#160;&eacute;l&egrave;ve&nbsp;!</p>'
        '<p>Deux<br>lignes</p></html>');
    expect(t, 'Bonjour élève !\n\nDeux\nlignes');
  });

  test('rtf : unicode et caractères échappés', () {
    expect(rtfToText(r"{\rtf1\ansi{\fonttbl{\f0 Arial;}}\uc1 C\u339?ur \'e9t\'e9 \{ok\}\par Fin}"), 'Cœur été {ok}\n\nFin');
  });

  test('erreurs claires', () {
    expect(() => extractText('a.doc', Uint8List(10)), throwsA(isA<ExtractException>().having((e) => e.code, 'code', 'legacy_office')));
    expect(() => extractText('a.docx', Uint8List.fromList(utf8.encode('pas un zip'))),
        throwsA(isA<ExtractException>().having((e) => e.code, 'code', 'corrupt')));
    expect(() => extractText('a.exe', Uint8List(4)), throwsA(isA<ExtractException>().having((e) => e.code, 'code', 'unsupported')));
    expect(() => extractText('a.txt', Uint8List.fromList(utf8.encode('   '))),
        throwsA(isA<ExtractException>().having((e) => e.code, 'code', 'empty')));
    final ole = Uint8List(16)..[0] = 0xD0..[1] = 0xCF;
    expect(() => extractText('a.docx', ole), throwsA(isA<ExtractException>().having((e) => e.code, 'code', 'encrypted')));
  });
}
