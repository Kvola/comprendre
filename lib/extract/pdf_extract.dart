/// Texte d'un PDF : texte natif de chaque page ; une page sans texte (scannée,
/// photographiée) passe par l'OCR sur l'appareil.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../engine/text_tools.dart';
import 'extractors.dart';
import 'ocr.dart';

/// Pages lues au maximum (un livre entier ne fait pas un quiz utile).
const maxPdfPages = 300;

/// Pages scannées passées à l'OCR au maximum (c'est lent).
const maxOcrPages = 30;

class PdfExtractor {
  const PdfExtractor({this.ocr = const OcrService()});

  final OcrService ocr;

  /// [onProgress] : (pages traitées, total) pour la barre de progression.
  Future<String> extract(Uint8List bytes, {void Function(int done, int total)? onProgress}) async {
    if (bytes.length > maxImportBytes) throw ExtractException('too_large');
    await pdfrxFlutterInitialize();
    final PdfDocument doc;
    try {
      doc = await PdfDocument.openData(bytes, sourceName: 'import-${bytes.length}-${bytes.hashCode}');
    } on PdfPasswordException {
      throw ExtractException('encrypted');
    } catch (_) {
      throw ExtractException('corrupt');
    }
    try {
      final total = min(doc.pages.length, maxPdfPages);
      final parts = <String>[];
      var ocrDone = 0;
      for (var i = 0; i < total; i++) {
        final page = doc.pages[i];
        var text = (await page.loadText())?.fullText ?? '';
        if (text.trim().length < 40 && ocrDone < maxOcrPages) {
          ocrDone++;
          final scanned = await _ocrPage(page, i);
          if (scanned.trim().length > text.trim().length) text = scanned;
        }
        parts.add(text);
        onProgress?.call(i + 1, total);
      }
      final out = cleanText(parts.where((p) => p.trim().isNotEmpty).join('\n\n'));
      if (out.isEmpty) throw ExtractException('empty');
      return out;
    } finally {
      await doc.dispose();
    }
  }

  Future<String> _ocrPage(PdfPage page, int index) async {
    // ~200 dpi, borné : assez net pour l'OCR sans saturer la mémoire.
    final scale = min(200 / 72, 2400 / max(page.width, page.height));
    final w = (page.width * scale).round(), h = (page.height * scale).round();
    final image = await page.render(fullWidth: w.toDouble(), fullHeight: h.toDouble(), backgroundColor: 0xFFFFFFFF);
    if (image == null) return '';
    try {
      final path = await ocr.bgraToTempPng(image.pixels, image.width, image.height, 'pdf-page-$index');
      return await ocr.recognizeFile(path);
    } catch (_) {
      return ''; // une page illisible n'empêche pas de lire les autres
    } finally {
      image.dispose();
    }
  }
}
