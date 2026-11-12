# Journal des versions

## 1.5.0 — 2026-11-12

- **Mes codes IA** (Réglages → Quiz IA) : les quiz IA possibles aujourd'hui, puis une carte par code (quiz restants
  et barre d'usage, date limite avec alerte « expire dans 3 jours », plafond du jour, code partagé, acheté ou reçu,
  dernier quiz IA) ; les codes terminés à part. Hors connexion, le dernier état connu, daté. Les réglages résument
  (« 1 code · 12 quiz IA restants ») et préviennent des quiz qui expirent bientôt.
- **Changer de téléphone sans aide** : saisir son code sur le nouveau téléphone propose de le transférer (nombre de
  transferts borné par le serveur) ; l'ancien téléphone le perd.
- **Retirer un code** de ce téléphone pour donner ses quiz restants à quelqu'un ; **copier** un code pour le garder.
- Saisie : bouton **Coller** qui retrouve le code dans un message copié ; « J'ai un code IA » ; un code déjà présent
  est signalé au lieu d'être refusé.
- Nécessite le serveur 19.0.1.5.0 pour le transfert, le retrait et les détails (avec un serveur 19.0.1.4.0, l'écran
  montre ce que le serveur connaît). 126 tests.

## 1.4.0 — 2026-11-12

- **Acheter des quiz IA avec Wave** (Réglages → Quiz IA → Acheter des quiz IA) : offres définies dans le back-office
  (quiz, prix, validité) ; « Payer avec Wave » ouvre Wave au bon montant ; le paiement confirmé ajoute un code IA à ce
  téléphone, sans rien saisir, et allume l'IA.
- Confirmation automatique (API Wave, webhook) ou par un agent (lien marchand) ; dans ce cas, l'acheteur peut donner
  l'identifiant de sa transaction Wave.
- Robustesse : la clé de chaque achat est gardée avant l'appel (un réessai après coupure reprend le même achat, jamais
  un second) ; l'écran revérifie toutes les 10 s et au retour de Wave ; « Ouvrir Wave » reprend un paiement inachevé.
- Nécessite le serveur 19.0.1.4.0. 122 tests.

## 1.3.0 — 2026-11-12

- **Codes IA** : un code unique (remis par une école, une entreprise, un partenaire) donne des quiz IA en plus du
  quota gratuit. Réglages → Quiz IA → **Saisir un code IA** ; l'erreur éventuelle s'affiche sous le champ (code
  inconnu, déjà utilisé sur un autre téléphone, expiré, épuisé, désactivé, trop d'essais). Un code activé allume l'IA.
  Le quota affiche le détail (gratuits + codes) et chaque code (restants, date limite, plafond du jour).
- Le quota gratuit passe d'abord ; le code qui expire le plus tôt ensuite ; seuls les quiz IA réussis comptent.
- Nécessite le serveur 19.0.1.3.0 (un serveur plus ancien répond « le code n'a pas pu être activé »). 119 tests.

## 1.2.1 — 2026-11-11

- Les grands nombres (« 30 000 000 », « 2 200 000 ») ne sont plus coupés en fin de ligne : à l'affichage, les espaces
  entre groupes de chiffres deviennent insécables (questions, propositions, explications, passages, lecture du texte).
  Les textes enregistrés ne changent pas. Remplace la 1.2.0, non publiée. 117 tests.

## 1.2.0 — 2026-11-11

Nouveautés
- **Long document : quiz sur une partie.** Au-delà de 8 000 caractères, « Quiz sur quelle partie ? » propose tout le texte
  ou une partie : les chapitres quand le document a des titres, sinon des morceaux d'environ 6 000 caractères coupés entre
  deux paragraphes (ou deux phrases pour un texte d'un seul bloc). L'IA accepte une partie même si le document entier est
  trop long pour elle ; « Un autre quiz » depuis le résultat reprend la même partie.
- **Reprise d'un quiz en cours** : les réponses sont enregistrées au fur et à mesure ; un quiz quitté (ou l'application
  fermée) reprend là où il en était. Plus de confirmation pour quitter.
- **« Revoir mes erreurs »** après un quiz : seulement les questions manquées (sans changer le meilleur score).
  **« Refaire ce quiz »** pose les questions dans un autre ordre.
- **« Un autre quiz » hors ligne** évite les phrases des quiz précédents tant qu'il en reste.
- **Texte modifié** : les quiz antérieurs portent « Le texte a été modifié depuis ce quiz » ; un passage introuvable est
  signalé au lieu de ne rien surligner.
- **Sauvegarde / restauration** de la bibliothèque (Réglages → Sauvegarde) : fichier JSON avec textes, quiz et résultats ;
  la restauration ajoute sans dupliquer ni effacer.
- **Langues** : espagnol, portugais, allemand, italien reconnus ; quiz par l'IA (serveur 19.0.1.2.0). Hors ligne, le
  français et l'anglais seulement, et l'application le dit (au lieu d'un quiz faux).

Corrections du moteur hors ligne
- Nombres écrits avec des espaces (« 2 200 000 ») ou des virgules en anglais (« 2,200,000 ») : un seul nombre, et des
  propositions écrites de la même façon (avant : seul le « 2 » était caché).
- Vrai/faux équilibrés (autant de « vrai » que de « faux ») ; avant, un texte sans fausse affirmation possible ne donnait que des « vrai ».
- Distracteurs grammaticaux : même genre connu (plus de « Le campagne »), voyelle/consonne selon l'article (« l' »,
  « la »), et un verbe après un pronom (« qui les revendent ») n'est plus pris pour un nom.
- `tool/demo_quiz.dart` fonctionne de nouveau (le moteur est du Dart pur ; l'isolat est dans `app/offline_runner.dart`).

Technique
- Base : schéma 2 (empreinte du texte, partie, progression sur chaque quiz), migration testée depuis le schéma 1.
- Délai d'attente d'un quiz IA porté à 240 s ; le serveur 19.0.1.2.0 borne ses appels à 2 × 100 s pour répondre avant.
- `scripts/gen_arb.py` redevient la source unique des textes (ceux du bandeau de mise à jour et de la version web y sont repris).
- 116 tests.

## 1.1.0 — 2026-11-09

- **Bandeau « nouvelle version »** (Android) : quand une version plus récente est publiée sur la page de téléchargement, un bandeau propose de la télécharger (« Plus tard » le masque pour cette version). Vérification au plus toutes les 12 h, silencieuse hors connexion ; une mise à jour déclarée obligatoire par le serveur ne peut pas être masquée.

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
