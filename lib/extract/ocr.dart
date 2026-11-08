/// Reconnaissance de texte (OCR) sur l'appareil, avec ML Kit : rien ne quitte le téléphone.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../engine/text_tools.dart';

class OcrService {
  const OcrService();

  /// Texte d'une image (photo, page scannée). Les blocs deviennent des paragraphes.
  Future<String> recognizeFile(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return blocksToText([for (final b in result.blocks) b.lines.map((l) => l.text).toList()]);
    } finally {
      await recognizer.close();
    }
  }

  /// Plusieurs pages, dans l'ordre.
  Future<String> recognizeFiles(List<String> paths, {void Function(int done, int total)? onProgress}) async {
    final parts = <String>[];
    for (var i = 0; i < paths.length; i++) {
      parts.add(await recognizeFile(paths[i]));
      onProgress?.call(i + 1, paths.length);
    }
    return cleanText(parts.where((p) => p.trim().isNotEmpty).join('\n\n'));
  }

  /// Ouvre le scanner de documents (cadrage, redressement, plusieurs pages).
  /// Renvoie les images des pages, ou null si l'utilisateur annule.
  Future<List<String>?> scanDocument({int pageLimit = 20}) async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: pageLimit,
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final images = result.images;
      return (images == null || images.isEmpty) ? null : images;
    } on PlatformException catch (e) {
      final msg = '${e.code} ${e.message}'.toLowerCase();
      if (msg.contains('cancel')) return null;
      rethrow;
    } finally {
      await scanner.close();
    }
  }

  /// Rend une image BGRA (page de PDF) en PNG temporaire, pour l'OCR.
  Future<String> bgraToTempPng(Uint8List bgra, int width, int height, String name) async {
    final image = await _decode(bgra, width, height);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      return file.path;
    } finally {
      image.dispose();
    }
  }

  Future<ui.Image> _decode(Uint8List bgra, int w, int h) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(bgra, w, h, ui.PixelFormat.bgra8888, completer.complete);
    return completer.future;
  }
}

/// Les lignes reconnues d'un bloc sont recollées (une phrase coupée par le cadrage) ;
/// chaque bloc devient un paragraphe.
String blocksToText(List<List<String>> blocks) =>
    cleanText(blocks.map((lines) => lines.join('\n')).where((b) => b.trim().isNotEmpty).join('\n\n'));
