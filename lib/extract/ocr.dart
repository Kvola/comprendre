/// Reconnaissance de texte (OCR) sur l'appareil : rien ne quitte le téléphone.
///
/// ML Kit n'existe que sur Android et iOS. Dans un navigateur, [OcrService]
/// est une coquille vide et `ocrSupported` est faux : le scanner et la photo ne
/// sont pas proposés, et ML Kit n'entre même pas dans la construction web.
library;

import '../engine/text_tools.dart';

export 'ocr_mlkit.dart' if (dart.library.js_interop) 'ocr_web.dart';

/// Les lignes reconnues d'un bloc sont recollées (une phrase coupée par le cadrage) ;
/// chaque bloc devient un paragraphe.
String blocksToText(List<List<String>> blocks) =>
    cleanText(blocks.map((lines) => lines.join('\n')).where((b) => b.trim().isNotEmpty).join('\n\n'));
