# Journal des versions

## 1.0.1 — 2026-11-08

- Nouvelle identité visuelle : une page dont un passage est surligné, éclairée par une idée qui porte une coche
  (lire, comprendre, vérifier) ; distincte de l'icône du Quiz Biblique (livre ouvert).
  Icône redessinée, plus lisible en petit ; logos FR/EN (horizontal et vertical) dans `assets/branding/`,
  générés par `scripts/branding.py` ; symbole affiché sur l'accueil et dans « À propos ».
- **APK signés avec la clé définitive** (SHA-256 `87:0C:92:26:…:71:43`) : une version antérieure (clé de développement)
  doit être désinstallée avant d'installer celle-ci.

## 1.0.0 — 2026-11-08

Première version.

- Texte saisi ou collé, scanné, lu sur une photo (OCR sur l'appareil) ou importé :
  PDF (texte natif, OCR des pages scannées), DOCX, PPTX, XLSX, ODT, ODP, EPUB, RTF, HTML, TXT, Markdown.
- Relecture et correction du texte reconnu avant le quiz ; langue détectée (français / anglais).
- Quiz hors ligne juste par construction : thème, texte à trous, nombres et dates, vrai/faux,
  affirmation fidèle au texte, ordre des idées ; « un autre quiz » donne d'autres questions.
- Quiz IA facultatif (Claude, par le serveur), avec consentement, quota gratuit quotidien par appareil
  et repli automatique hors ligne expliqué.
- Chaque réponse expliquée, avec le passage du texte surligné.
- Résultat, revue des réponses, meilleur score par quiz.
- Français et anglais, thème clair / sombre (contrastes WCAG vérifiés), zones système respectées.
