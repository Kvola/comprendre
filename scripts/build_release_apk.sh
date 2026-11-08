#!/usr/bin/env bash
# Construit les APK de version finale, un par type de processeur (plus légers) :
#   dist/Comprendre-<version>.apk          téléphones récents (arm64), le bon dans 95 % des cas
#   dist/Comprendre-<version>-ancien.apk   anciens téléphones 32 bits (armeabi-v7a)
#
# Les tests passent d’abord : un APK ne part jamais avec un test en échec.
# Serveur IA : https://iyf.ebng.world (COMPRENDRE_SERVER pour un autre). Signature : clé de android/key.properties si le fichier
# existe, sinon clé de développement (avertissement affiché).
set -euo pipefail
cd "$(dirname "$0")/.."

flutter test
flutter build apk --release --split-per-abi ${COMPRENDRE_SERVER:+--dart-define=COMPRENDRE_SERVER=$COMPRENDRE_SERVER}

version=$(grep '^version:' pubspec.yaml | sed -E 's/version: *([^+]+).*/\1/')
out=build/app/outputs/flutter-apk
mkdir -p dist
cp "$out/app-arm64-v8a-release.apk" "dist/Comprendre-$version.apk"
cp "$out/app-armeabi-v7a-release.apk" "dist/Comprendre-$version-ancien.apk"

# Empreintes SHA-256 : permettent de vérifier qu'un APK reçu (WhatsApp, Drive…)
# est bien celui-ci (`shasum -a 256 -c Comprendre-<version>.sha256` dans dist/).
(cd dist && shasum -a 256 "Comprendre-$version.apk" "Comprendre-$version-ancien.apk" > "Comprendre-$version.sha256")

if [ -f android/key.properties ]; then
  echo "Signé avec la clé de publication (android/key.properties)."
else
  echo "ATTENTION : signé avec la clé de DÉVELOPPEMENT (android/key.properties absent)."
fi
ls -lh dist/Comprendre-"$version"*.apk | awk '{print $5, $9}'
echo "Empreintes : dist/Comprendre-$version.sha256"
