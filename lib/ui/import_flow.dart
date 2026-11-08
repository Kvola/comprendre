/// Obtenir un texte depuis un fichier, le scanner de documents ou une photo.
/// Chaque fonction renvoie le texte extrait (à relire dans l'éditeur), ou null
/// si l'utilisateur annule ou si une erreur a déjà été affichée.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../engine/text_tools.dart';
import '../extract/extractors.dart';
import '../extract/ocr.dart';
import '../extract/pdf_extract.dart';
import 'common.dart';

class Extracted {
  const Extracted(this.text, this.source, {this.fileName});

  final String text;

  /// `file` | `scan` | `photo`
  final String source;
  final String? fileName;
}

String extractError(BuildContext context, String code) {
  final l = context.l10n;
  return switch (code) {
    'legacy_office' => l.errLegacyOffice,
    'empty' => l.errEmpty,
    'corrupt' => l.errCorrupt,
    'encrypted' => l.errEncrypted,
    'too_large' => l.errTooLarge,
    _ => l.errUnsupported,
  };
}

Future<Extracted?> importFile(BuildContext context) async {
  final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: [...supportedExtensions, 'doc', 'ppt']);
  final file = picked.firstOrNull;
  if (file == null || !context.mounted) return null;
  final size = await file.length();
  if (size != null && size > maxImportBytes) {
    if (context.mounted) showSnack(context, extractError(context, 'too_large'));
    return null;
  }
  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  final progress = ValueNotifier<String>(context.l10n.reading);
  final l = context.l10n;
  try {
    final text = await _withProgress(context, progress, () async {
      if (extensionOf(file.name) == 'pdf') {
        return const PdfExtractor().extract(bytes, onProgress: (d, t) => progress.value = l.readingPages(d, t));
      }
      return cleanText(extractText(file.name, bytes));
    });
    return Extracted(text, 'file', fileName: file.name);
  } on ExtractException catch (e) {
    if (context.mounted) showSnack(context, extractError(context, e.code));
  } catch (_) {
    if (context.mounted) showSnack(context, extractError(context, 'corrupt'));
  } finally {
    progress.dispose();
  }
  return null;
}

Future<Extracted?> scanDocument(BuildContext context) async {
  const ocr = OcrService();
  List<String>? pages;
  try {
    pages = await ocr.scanDocument();
  } catch (_) {
    if (context.mounted) showSnack(context, context.l10n.errScanner);
    return null;
  }
  if (pages == null || !context.mounted) return null;
  return _recognize(context, pages, 'scan');
}

Future<Extracted?> photoText(BuildContext context) async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null || !context.mounted) return null;
  return _recognize(context, [image.path], 'photo');
}

Future<Extracted?> _recognize(BuildContext context, List<String> paths, String source) async {
  final l = context.l10n;
  final progress = ValueNotifier<String>(l.recognizing);
  try {
    final text = await _withProgress(
      context,
      progress,
      () => const OcrService().recognizeFiles(
        paths,
        onProgress: (d, t) => progress.value = t > 1 ? l.readingPages(d, t) : l.recognizing,
      ),
    );
    if (text.trim().isEmpty) {
      if (context.mounted) showSnack(context, l.errNoTextInImage);
      return null;
    }
    return Extracted(text, source);
  } catch (_) {
    if (context.mounted) showSnack(context, l.errOcr);
    return null;
  } finally {
    progress.dispose();
  }
}

/// Affiche une boîte de progression (non annulable) pendant [work].
Future<T> _withProgress<T>(BuildContext context, ValueNotifier<String> label, Future<T> Function() work) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 20),
            Expanded(child: ValueListenableBuilder(valueListenable: label, builder: (_, v, _) => Text(v))),
          ],
        ),
      ),
    ),
  );
  try {
    return await work();
  } finally {
    nav.pop();
  }
}
