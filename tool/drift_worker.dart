// Worker de drift pour la version web, compilé par scripts/build_web.sh avec
// les versions de pubspec.lock : il charge sqlite3.wasm avec les mêmes
// liaisons sqlite3 que l'application.
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
