#!/usr/bin/env bash
# Construit la version web (PWA) de Comprendre et l'empaquette pour le serveur.
#
#   scripts/build_web.sh
#
# Produit dist/Comprendre-<version>-web.zip (+ .sha256), à déposer dans le
# back-office Odoo, sur la version de l'application (champ « Version web »).
# Le serveur la sert alors à l'adresse /apps/comprendre/web/.
#
# L'ADRESSE EST GRAVÉE DANS LA CONSTRUCTION
#
# `--base-href` doit être exactement l'adresse de service. Sinon : page
# blanche, sans aucune erreur visible. Le serveur refuse d'ailleurs une archive
# construite pour une autre adresse.
set -euo pipefail
cd "$(dirname "$0")/.."

SLUG=comprendre
BASE="/apps/comprendre/web/"
version=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
[ -n "$version" ] || { echo "Version introuvable dans pubspec.yaml" >&2; exit 1; }

# SQLite en WebAssembly et le worker de drift, aux versions EXACTES de
# pubspec.lock : un module d'une autre version peut refuser de s'ouvrir, et
# l'application démarrerait sans ses données — écran vide, sans erreur.
#
# Le worker est COMPILÉ ici (tool/drift_worker.dart) et non téléchargé : celui
# que publie drift embarque SES liaisons sqlite3, qui ne s'accordent pas
# toujours avec le sqlite3.wasm de pubspec.lock (constaté avec sqlite3 3.9.1).
lockver() { awk -v p="  $1:" '$0==p{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock; }
sqlite=$(lockver sqlite3); drift=$(lockver drift)
want="sqlite3 $sqlite / drift $drift (worker compilé)"
if [ "$(cat web/.wasm-versions 2>/dev/null)" != "$want" ] || [ ! -s web/sqlite3.wasm ] || [ ! -s web/drift_worker.js ]; then
  echo "Préparation de $want"
  curl -fsSL -o web/sqlite3.wasm.tmp "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite/sqlite3.wasm"
  dart compile js -O4 -o web/drift_worker.js.tmp tool/drift_worker.dart >/dev/null
  rm -f web/drift_worker.js.tmp.deps web/drift_worker.js.tmp.map
  mv web/sqlite3.wasm.tmp web/sqlite3.wasm
  mv web/drift_worker.js.tmp web/drift_worker.js
  echo "$want" > web/.wasm-versions
fi

flutter build web --release --base-href "$BASE" --no-web-resources-cdn --no-source-maps

# Moteurs graphiques inutiles à une construction JavaScript : seul CanvasKit
# (canvaskit/ et sa variante chromium/) est chargé. skwasm et wimp ne servent
# qu'avec --wasm, webparagraph qu'avec une option expérimentale non activée ;
# les .symbols ne servent qu'au débogage. Une dizaine de Mo en moins à
# télécharger. Garde-fou : si Flutter change de moteur, on s'arrête.
grep -q '"renderer":"canvaskit"' build/web/flutter_bootstrap.js || { echo "Moteur inattendu : revoir le tri des fichiers" >&2; exit 1; }
grep -q 'preferWebParagraph' web/index.html && { echo "webparagraph demandé : ne pas le retirer" >&2; exit 1; }
rm -rf build/web/canvaskit/skwasm* build/web/canvaskit/wimp* build/web/canvaskit/webparagraph
find build/web -name '*.symbols' -delete
# Service worker déprécié de Flutter : jamais enregistré (voir web/flutter_bootstrap.js).
rm -f build/web/flutter_service_worker.js
tail -n 3 build/web/flutter_bootstrap.js | grep -q '^_flutter.loader.load();$' || { echo "flutter_bootstrap.js enregistrerait le service worker de Flutter" >&2; exit 1; }
[ -s build/web/canvaskit/canvaskit.wasm ] && [ -s build/web/canvaskit/chromium/canvaskit.wasm ] || { echo "CanvasKit manquant" >&2; exit 1; }

# Le service worker change à chaque construction : c'est ce qui fait installer
# la nouvelle version aux navigateurs.
stamp="$version-$(date -u +%Y%m%d%H%M%S)"
sed -i.bak "s/__BUILD_VERSION__/$stamp/" build/web/sw.js && rm build/web/sw.js.bak

# Contrôles : mieux vaut échouer ici qu'en production sur une page blanche.
grep -q "<base href=\"$BASE\">" build/web/index.html || { echo "base href incorrect" >&2; exit 1; }
grep -q "__BUILD_VERSION__" build/web/sw.js && { echo "sw.js non tamponné" >&2; exit 1; }
for f in index.html main.dart.js flutter_bootstrap.js manifest.json sw.js favicon.png icons/Icon-192.png sqlite3.wasm drift_worker.js; do
  [ -s "build/web/$f" ] || { echo "Manque build/web/$f" >&2; exit 1; }
done

mkdir -p dist
out="dist/Comprendre-${version%%+*}-web.zip"
rm -f "$out" "$out.sha256"
(cd build/web && zip -qrX "../../$out" . -x '.last_build_id' -x '.wasm-versions' -x '*.DS_Store')
(cd dist && shasum -a 256 "$(basename "$out")" > "$(basename "$out").sha256")
echo "Version web $version : $out ($(du -h "$out" | cut -f1))"
echo "À déposer dans Odoo > Applications > Versions > $version > Version web."
