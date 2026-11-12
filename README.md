# Comprendre (Understand)

Application mobile (Flutter) qui aide à **comprendre un texte** en posant des
questions dessus. Le texte peut être saisi ou collé, scanné (une ou plusieurs
pages), lu sur une photo, ou importé d'un fichier : PDF (y compris scanné),
Word (.docx), PowerPoint (.pptx), Excel (.xlsx, texte des cellules),
OpenDocument (.odt, .odp), EPUB, RTF, HTML, texte, Markdown.

Chaque réponse est expliquée et renvoie au **passage du texte** qui la
justifie (surligné dans le texte).

## Deux moteurs

| | Hors ligne (par défaut, toujours disponible) | IA (facultatif, avec connexion) |
|---|---|---|
| Où | sur le téléphone | serveur Odoo `comprendre_backend` → Claude (Anthropic) |
| Questions | thème, texte à trous, chiffres et dates, vrai/faux, « laquelle figure dans le texte », ordre des idées | idée principale, détails, causes et conséquences, sens des mots, déductions, résumé |
| Langues | français, anglais | français, anglais, espagnol, portugais, allemand, italien |
| Justesse | par construction (tout est tiré du texte) | chaque citation est vérifiée dans le texte par le serveur ; sinon la question est écartée |
| Données | rien n'est envoyé | le texte est envoyé pour créer le quiz, non conservé ; identifiant d'appareil aléatoire (quota) |

Des **codes IA** (créés dans le back-office) donnent des quiz IA en plus du quota gratuit : Réglages → Quiz IA → Saisir un code IA (`lib/ui/ai_code.dart`, `/comprendre/api/v1/redeem`). Des quiz IA s'**achètent** aussi avec Wave (`lib/ui/shop_screen.dart`, `/shop`, `/buy`, `/orders`) : le paiement confirmé délivre un code IA activé sur le téléphone.

L'IA n'est utilisée qu'après accord explicite (demandé au premier quiz,
modifiable dans les réglages). En cas d'échec, quel qu'il soit (pas de
réseau, quota du jour atteint, texte trop long, service indisponible…), le
quiz est créé hors ligne et l'application dit pourquoi.

La clé de l'API Claude reste sur le serveur ; l'application n'en contient aucune.

## Organisation

```
lib/engine/    text_tools (normalisation, phrases, langue, citations), offline_quiz, sections (parties d'un long texte), quiz_model — Dart pur, testé
lib/extract/   extractors (formats bureautiques, Dart pur, testé), pdf_extract (pdfrx + OCR), ocr (ML Kit)
lib/remote/    ai_client (JSON-RPC vers /comprendre/api/v1)
lib/data/      database (Drift, schéma 2 : textes, quiz avec partie/empreinte/progression, essais, réglages), backup (sauvegarde JSON)
lib/app/       providers (Riverpod), quiz_service (IA puis repli hors ligne), offline_runner (isolat), settings, version
lib/ui/        écrans : bibliothèque, saisie, texte, quiz, lecture surlignée, réglages
scripts/       gen_arb.py (textes FR/EN), branding.py + svg2png.swift (icône, logos, icône du module), build_release_apk.sh
```

## Développement

```bash
python3 scripts/gen_arb.py && flutter gen-l10n     # après une modification des textes
dart run build_runner build                         # après une modification de la base
flutter test                                        # 122 tests
dart run tool/demo_quiz.dart texte.txt [graine]     # voir le quiz hors ligne d'un texte
# Serveur local (odoo_dev, port 8096) depuis l'émulateur :
flutter run --dart-define=COMPRENDRE_SERVER=http://10.0.2.2:8096
```

## Version finale

```bash
./scripts/build_release_apk.sh      # tests, puis dist/Comprendre-<version>.apk (+ -ancien.apk, .sha256)
```

Signature : `android/key.properties` (jamais versionné) ; sans ce fichier,
clé de développement (avertissement). Les règles R8 de `android/app/proguard-rules.pro`
sont indispensables au scanner de documents et à l'OCR en version finale.

**La clé définitive existe depuis le 8 novembre 2026** (version 1.0.1) : `~/comprendre-cles/` sur le Mac de développement, alias `comprendre`, RSA 4096, valable environ 27 ans ; mots de passe dans `android/key.properties` (ignoré par Git) et dans ce dossier. Empreinte SHA-256 du certificat : `87:0C:92:26:EE:CC:D1:5A:B5:3F:5A:07:60:A2:1A:A8:BF:A5:3E:A3:65:B3:82:50:82:5B:4E:AD:06:88:71:43`. Les APK antérieurs, signés avec la clé de développement, doivent être désinstallés avant d'installer la 1.0.1 (Android refuse la mise à jour) ; ensuite les mises à jour s'installent normalement.

Le scanner de documents utilise un module des services Google Play,
téléchargé par le téléphone au premier usage.
