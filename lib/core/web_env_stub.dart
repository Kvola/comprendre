import 'dart:typed_data';

/// Version native : pas de navigateur.

/// L'application est-elle ouverte depuis l'écran d'accueil (PWA installée) ?
bool runningStandalone() => false;

/// Demande au navigateur de ne pas effacer les données de l'application quand
/// la place manque. Rend vrai si c'est accordé.
Future<bool> requestPersistentStorage() async => false;

/// Adresse de base de la page (`<base href>`), pour trouver les fichiers servis
/// à côté de l'application (sqlite3.wasm…).
Uri webBaseUri() => Uri.base;

/// Fait télécharger [bytes] par le navigateur sous le nom [filename].
bool downloadBytes(Uint8List bytes, String filename, String mimeType) => false;
