import 'package:flutter/foundation.dart';

/// Exécute [task] hors du fil de l'interface quand la plateforme le permet.
///
/// Sur téléphone : un isolat, comme `Isolate.run`. Dans un navigateur, les
/// isolats n'existent pas (`Isolate.run` y lève une erreur) : `compute` s'y
/// replie sur le fil courant — un peu moins fluide, mais juste.
Future<R> runInBackground<R>(R Function() task) => compute(_call<R>, task);

R _call<R>(R Function() task) => task();
