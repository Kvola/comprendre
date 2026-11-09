/// Version navigateur de [OcrService] : pas de ML Kit, donc pas d'OCR.
/// À importer via `ocr.dart`.
library;

import 'dart:typed_data';

/// Le scanner de documents et la reconnaissance de texte sont disponibles.
const ocrSupported = false;

/// Mêmes signatures que la version ML Kit ; rien n'y mène quand
/// [ocrSupported] est faux.
class OcrService {
  const OcrService();

  Future<String> recognizeFile(String path) => throw UnsupportedError('OCR');

  Future<String> recognizeFiles(List<String> paths, {void Function(int done, int total)? onProgress}) =>
      throw UnsupportedError('OCR');

  Future<List<String>?> scanDocument({int pageLimit = 20}) => throw UnsupportedError('OCR');

  Future<String> bgraToTempPng(Uint8List bgra, int width, int height, String name) => throw UnsupportedError('OCR');
}
