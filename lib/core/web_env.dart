/// Ce que l'application a besoin de savoir du navigateur quand elle tourne en
/// version web (PWA), et rien de plus.
///
/// Fichier AUTONOME, identique dans chaque application (Quiz biblique,
/// Comprendre, Kavola Pro, Kavola) : le corriger ici, puis le recopier tel
/// quel dans les autres, avec `web_env_stub.dart` et `web_env_web.dart`.
///
/// Hors navigateur, chaque fonction rend une valeur neutre : on peut l'appeler
/// sans se demander sur quelle plateforme on est.
library;

export 'web_env_stub.dart' if (dart.library.js_interop) 'web_env_web.dart';
