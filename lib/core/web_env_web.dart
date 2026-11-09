import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Version navigateur. Chaque appel est protégé : un navigateur ancien ou
/// bridé (navigation privée, réglages d'entreprise) ne doit jamais faire
/// tomber l'application pour une fonction de confort.

bool runningStandalone() {
  try {
    if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
    // Safari sur iPhone ne connaît pas `display-mode` dans les vieilles
    // versions : il expose `navigator.standalone`.
    final standalone = (web.window.navigator as JSObject).getProperty<JSAny?>('standalone'.toJS);
    return standalone.dartify() == true;
  } catch (_) {
    return false;
  }
}

Future<bool> requestPersistentStorage() async {
  try {
    final storage = web.window.navigator.storage;
    if ((await storage.persisted().toDart).toDart) return true;
    return (await storage.persist().toDart).toDart;
  } catch (_) {
    return false;
  }
}

Uri webBaseUri() {
  try {
    return Uri.parse(web.document.baseURI);
  } catch (_) {
    return Uri.base;
  }
}

bool downloadBytes(Uint8List bytes, String filename, String mimeType) {
  try {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    web.document.body?.append(a);
    a.click();
    a.remove();
    // Laisser au navigateur le temps de lancer le téléchargement.
    Future<void>.delayed(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
    return true;
  } catch (_) {
    return false;
  }
}
