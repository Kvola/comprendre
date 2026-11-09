import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../core/web_env.dart';

/// Base de données de la version web : SQLite compilé en WebAssembly, dans un
/// worker. Les deux fichiers sont servis à côté de l'application (dossier
/// `web/`, tenus à jour par `scripts/build_web.sh` selon pubspec.lock).
///
/// Adresses calculées depuis `<base href>` et non relatives à la page : un
/// lien profond (`…/web/#/reglages`) ou une page ouverte sans barre finale ne
/// doit pas envoyer chercher `sqlite3.wasm` ailleurs — l'échec serait muet et
/// l'application démarrerait sans ses données.
///
/// Ignoré hors navigateur.
DriftWebOptions webDatabaseOptions() => DriftWebOptions(
  sqlite3Wasm: webBaseUri().resolve('sqlite3.wasm'),
  driftWorker: webBaseUri().resolve('drift_worker.js'),
  onResult: _report,
);

/// Où les données sont rangées. `inMemory` = navigateur sans stockage durable
/// (navigation privée…) : tout serait perdu à la fermeture de l'onglet.
@visibleForTesting
String? lastWebStorage;

void _report(WasmDatabaseResult result) {
  lastWebStorage = result.chosenImplementation.name;
  if (kDebugMode && result.missingFeatures.isNotEmpty) {
    debugPrint('Base web : ${result.chosenImplementation.name}, manque ${result.missingFeatures}');
  }
}
