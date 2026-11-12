// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Comprendre';

  @override
  String get tagline => 'Un quiz pour comprendre n’importe quel texte';

  @override
  String get close => 'Fermer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get share => 'Partager';

  @override
  String get retry => 'Réessayer';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get undo => 'Annuler';

  @override
  String questionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String quizzesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quiz',
      one: '1 quiz',
      zero: 'Aucun quiz',
    );
    return '$_temp0';
  }

  @override
  String charsCount(int count) {
    return '$count caractères';
  }

  @override
  String get libraryTitle => 'Mes textes';

  @override
  String get emptyTitle => 'Comprenez ce que vous lisez';

  @override
  String get emptyBody =>
      'Écrivez ou collez un texte, scannez une page ou importez un fichier (PDF, Word, PowerPoint…). Comprendre en tire un quiz pour vérifier et approfondir votre compréhension.';

  @override
  String get newText => 'Nouveau texte';

  @override
  String get sourceTyped => 'Écrire ou coller';

  @override
  String get sourceTypedHint => 'Saisissez le texte, ou collez-le';

  @override
  String get sourceScan => 'Scanner un document';

  @override
  String get sourceScanHint => 'Une ou plusieurs pages, avec l’appareil photo';

  @override
  String get sourcePhoto => 'Texte d’une photo';

  @override
  String get sourcePhotoHint => 'Une image de votre galerie';

  @override
  String get sourceFile => 'Importer un fichier';

  @override
  String get sourceFileHint =>
      'PDF, Word, PowerPoint, OpenDocument, EPUB, texte…';

  @override
  String get deleteTextTitle => 'Supprimer ce texte ?';

  @override
  String get deleteTextBody =>
      'Le texte et ses quiz seront supprimés de ce téléphone.';

  @override
  String get textDeleted => 'Texte supprimé';

  @override
  String get editorTitle => 'Votre texte';

  @override
  String get titleLabel => 'Titre (facultatif)';

  @override
  String get textLabel => 'Texte';

  @override
  String get textHint => 'Collez ou écrivez ici le texte à comprendre…';

  @override
  String get paste => 'Coller';

  @override
  String get clipboardEmpty => 'Le presse-papiers ne contient pas de texte.';

  @override
  String get reviewExtracted =>
      'Vérifiez le texte : vous pouvez le corriger ou en retirer des parties avant de créer le quiz.';

  @override
  String textTooShort(int count) {
    return 'Ajoutez un peu de texte : $count caractères au moins.';
  }

  @override
  String get languageOfText => 'Langue du texte';

  @override
  String get langFr => 'Français';

  @override
  String get langEn => 'Anglais';

  @override
  String get langEs => 'Espagnol';

  @override
  String get langPt => 'Portugais';

  @override
  String get langDe => 'Allemand';

  @override
  String get langIt => 'Italien';

  @override
  String get langNeedsAiNote =>
      'Hors ligne, les quiz ne se font qu’en français et en anglais : pour un texte dans cette langue, l’IA (avec une connexion) est nécessaire.';

  @override
  String get createQuiz => 'Créer le quiz';

  @override
  String get saveText => 'Enregistrer le texte';

  @override
  String get discardTitle => 'Abandonner ce texte ?';

  @override
  String get discardBody => 'Ce que vous avez saisi sera perdu.';

  @override
  String get discard => 'Abandonner';

  @override
  String get reading => 'Lecture du fichier…';

  @override
  String readingPages(int done, int total) {
    return 'Lecture : page $done sur $total';
  }

  @override
  String get recognizing => 'Reconnaissance du texte…';

  @override
  String get errUnsupported => 'Ce type de fichier n’est pas pris en charge.';

  @override
  String get errLegacyOffice =>
      'Ancien format Office (.doc, .ppt) : enregistrez-le en .docx, .pptx ou PDF, puis importez-le.';

  @override
  String get errEmpty => 'Aucun texte n’a été trouvé dans ce document.';

  @override
  String get errCorrupt => 'Ce fichier est illisible ou endommagé.';

  @override
  String get errEncrypted => 'Ce fichier est protégé par un mot de passe.';

  @override
  String get errTooLarge => 'Ce fichier est trop volumineux (40 Mo au plus).';

  @override
  String get errOcr =>
      'La reconnaissance du texte a échoué. Essayez une photo plus nette et bien éclairée.';

  @override
  String get errNoTextInImage => 'Aucun texte n’a été reconnu sur cette image.';

  @override
  String get errScanner =>
      'Le scanner de documents n’est pas disponible sur cet appareil.';

  @override
  String get readText => 'Lire le texte';

  @override
  String get hideText => 'Masquer le texte';

  @override
  String get quizzesTitle => 'Quiz';

  @override
  String get noQuizYet => 'Pas encore de quiz pour ce texte.';

  @override
  String get newQuiz => 'Nouveau quiz';

  @override
  String get anotherQuiz => 'Un autre quiz';

  @override
  String bestScore(int score, int total) {
    return 'Meilleur score : $score/$total';
  }

  @override
  String get notTried => 'Pas encore fait';

  @override
  String get engineAi => 'Quiz IA';

  @override
  String get engineOffline => 'Quiz hors ligne';

  @override
  String get deleteQuizTitle => 'Supprimer ce quiz ?';

  @override
  String get staleQuiz => 'Le texte a été modifié depuis ce quiz';

  @override
  String quizInProgress(int done, int total) {
    return 'En cours : $done réponse(s) sur $total';
  }

  @override
  String get quoteNotFound =>
      'Ce passage n’est plus dans le texte : le texte a été modifié depuis ce quiz.';

  @override
  String get summaryTitle => 'En bref';

  @override
  String get creatingQuiz => 'Création du quiz…';

  @override
  String get creatingAi =>
      'L’IA lit votre texte et prépare des questions de compréhension. Cela peut prendre une à deux minutes.';

  @override
  String get creatingOffline => 'Préparation des questions à partir du texte…';

  @override
  String get useOfflineNow => 'Créer hors ligne maintenant';

  @override
  String get quizTooShort =>
      'Ce texte est trop court ou trop pauvre pour un quiz. Ajoutez quelques phrases complètes.';

  @override
  String fallbackNotice(String reason) {
    return 'Quiz créé hors ligne : $reason';
  }

  @override
  String get whyNetwork => 'pas de connexion au service IA.';

  @override
  String get whyQuota => 'quota IA du jour atteint.';

  @override
  String get whyFailures =>
      'l’IA a échoué plusieurs fois aujourd’hui sur vos textes ; elle sera de nouveau disponible demain.';

  @override
  String get whyLanguage => 'le service IA ne gère pas encore cette langue.';

  @override
  String get langNeedsAiOff =>
      'Hors ligne, les quiz ne se font qu’en français et en anglais. Pour ce texte, activez l’IA dans les réglages.';

  @override
  String langNeedsAiFailed(String reason) {
    return 'Hors ligne, les quiz ne se font qu’en français et en anglais, et l’IA n’a pas pu créer ce quiz : $reason';
  }

  @override
  String get chooseSectionTitle => 'Quiz sur quelle partie ?';

  @override
  String chooseSectionBody(int count) {
    return 'Ce texte est long ($count caractères) : un quiz sur une partie est plus utile.';
  }

  @override
  String get wholeText => 'Tout le texte';

  @override
  String wholeTextTooLongForAi(int count) {
    return 'Trop long pour l’IA ($count caractères au plus) : quiz hors ligne';
  }

  @override
  String sectionLabel(String label) {
    return 'Partie : $label';
  }

  @override
  String whyTooLong(int count) {
    return 'texte trop long pour l’IA ($count caractères au plus).';
  }

  @override
  String get whyBusy => 'le service IA est très demandé, réessayez plus tard.';

  @override
  String get whyUnavailable => 'le service IA est momentanément indisponible.';

  @override
  String whyRateLimited(int count) {
    return 'trop de demandes, réessayez dans $count min.';
  }

  @override
  String get whyDisabled => 'le service IA est désactivé.';

  @override
  String get whyUnverified =>
      'les questions de l’IA n’ont pas pu être vérifiées dans le texte.';

  @override
  String get whyRefusedContent => 'l’IA ne peut pas traiter ce texte.';

  @override
  String get whyOther => 'le service IA n’a pas répondu correctement.';

  @override
  String get whyCancelled => 'vous avez choisi de ne pas attendre.';

  @override
  String get aiConsentTitle => 'Utiliser l’IA ?';

  @override
  String get aiConsentBody =>
      'Avec une connexion Internet, Comprendre peut demander à une IA (Claude, d’Anthropic) des questions plus riches : idée principale, causes et conséquences, sens des mots, déductions.\n\nPour cela, le texte est envoyé à notre serveur puis à l’IA, seulement pour créer le quiz : il n’est pas conservé. Aucun compte, aucune donnée personnelle.\n\nSans IA, le quiz est créé sur votre téléphone, sans rien envoyer.';

  @override
  String get aiConsentYes => 'Utiliser l’IA';

  @override
  String get aiConsentNo => 'Rester hors ligne';

  @override
  String aiFreePerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quiz IA gratuits par jour',
      one: '1 quiz IA gratuit par jour',
    );
    return '$_temp0';
  }

  @override
  String questionOf(int index, int total) {
    return 'Question $index sur $total';
  }

  @override
  String get trueLabel => 'Vrai';

  @override
  String get falseLabel => 'Faux';

  @override
  String get correct => 'Bonne réponse';

  @override
  String get incorrect => 'Pas tout à fait';

  @override
  String theAnswerWas(String answer) {
    return 'La bonne réponse : $answer';
  }

  @override
  String get inTheText => 'Dans le texte';

  @override
  String get showInText => 'Voir dans le texte';

  @override
  String get next => 'Suivante';

  @override
  String get seeResults => 'Voir le résultat';

  @override
  String get progressResumed => 'Reprise là où vous en étiez.';

  @override
  String get reviewMistakesTitle => 'Mes erreurs';

  @override
  String mistakeOf(int index, int total) {
    return 'Erreur $index sur $total';
  }

  @override
  String get skillMainIdea => 'Idée principale';

  @override
  String get skillDetail => 'Détail';

  @override
  String get skillVocabulary => 'Vocabulaire';

  @override
  String get skillInference => 'Déduction';

  @override
  String get skillStructure => 'Structure';

  @override
  String get skillCause => 'Cause et effet';

  @override
  String get resultTitle => 'Résultat';

  @override
  String scoreOutOf(int score, int total) {
    return '$score sur $total';
  }

  @override
  String get resultGreat => 'Excellent : vous avez bien compris ce texte.';

  @override
  String get resultGood =>
      'Bien : relisez les passages des questions manquées.';

  @override
  String get resultLow =>
      'Relisez le texte tranquillement, puis réessayez : chaque explication renvoie au passage.';

  @override
  String get reviewAnswers => 'Revoir les réponses';

  @override
  String yourAnswer(String answer) {
    return 'Votre réponse : $answer';
  }

  @override
  String get tryAgain => 'Refaire ce quiz';

  @override
  String get retryMistakes => 'Revoir mes erreurs';

  @override
  String mistakesResult(int score, int total) {
    return 'Erreurs revues : $score sur $total maintenant justes';
  }

  @override
  String get mistakesResultHint =>
      'Ce tour ne change pas votre meilleur score : refaites tout le quiz pour cela.';

  @override
  String get backToText => 'Retour au texte';

  @override
  String get settings => 'Réglages';

  @override
  String get appLanguage => 'Langue de l’application';

  @override
  String get systemDefault => 'Langue du téléphone';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Automatique';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get questionsPerQuiz => 'Questions par quiz';

  @override
  String get aiSection => 'Quiz IA';

  @override
  String get aiUse => 'Utiliser l’IA quand c’est possible';

  @override
  String get aiUseHint =>
      'Le texte est envoyé à l’IA pour créer le quiz, puis oublié. Sinon, tout reste sur le téléphone.';

  @override
  String aiRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count quiz IA aujourd’hui',
      one: 'Encore 1 quiz IA aujourd’hui',
      zero: 'Plus de quiz IA aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String get aiQuotaUnknown => 'Quota IA : connexion nécessaire';

  @override
  String aiRemainingDetail(int free, int codes) {
    return '$free du quota gratuit + $codes avec vos codes IA';
  }

  @override
  String get aiCodeEnter => 'Saisir un code IA';

  @override
  String get aiCodeEnterHint =>
      'Un code reçu de votre école, de votre entreprise ou d’un partenaire, pour plus de quiz IA.';

  @override
  String get aiCodeDialogTitle => 'Code IA';

  @override
  String get aiCodeDialogBody =>
      'Saisissez le code tel qu’il vous a été donné (majuscules, espaces et tirets ne comptent pas). Il sera lié à ce téléphone.';

  @override
  String get aiCodeField => 'Code';

  @override
  String get aiCodeActivate => 'Activer';

  @override
  String aiCodeActivated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code activé : $count quiz IA disponibles.',
      one: 'Code activé : 1 quiz IA disponible.',
    );
    return '$_temp0';
  }

  @override
  String get aiCodeActivatedAiOn => 'L’IA est activée pour vos quiz.';

  @override
  String aiCodeTitle(String code) {
    return 'Code $code';
  }

  @override
  String aiCodeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quiz IA restants',
      one: '1 quiz IA restant',
      zero: 'Plus de quiz IA sur ce code',
    );
    return '$_temp0';
  }

  @override
  String aiCodeUntil(String date) {
    return 'jusqu’au $date';
  }

  @override
  String get aiCodeExpired => 'expiré';

  @override
  String get aiCodeDailyDone => 'plafond du jour atteint';

  @override
  String get aiCodeErrUnknown => 'Ce code IA n’existe pas. Vérifiez-le.';

  @override
  String get aiCodeErrDisabled => 'Ce code IA a été désactivé.';

  @override
  String get aiCodeErrExpired => 'Ce code IA a expiré.';

  @override
  String get aiCodeErrExhausted =>
      'Tous les quiz IA de ce code ont déjà été utilisés.';

  @override
  String get aiCodeErrTaken =>
      'Ce code IA est déjà utilisé sur un autre téléphone. Pour changer de téléphone, demandez à la personne qui vous l’a donné de libérer le code.';

  @override
  String aiCodeErrRate(int count) {
    return 'Trop d’essais : réessayez dans $count min.';
  }

  @override
  String get aiCodeErrNetwork =>
      'Pas de connexion au service : réessayez quand vous serez connecté.';

  @override
  String get aiCodeErrOther =>
      'Le code n’a pas pu être activé. Réessayez plus tard.';

  @override
  String get backupSection => 'Sauvegarde';

  @override
  String get backupExport => 'Sauvegarder ma bibliothèque';

  @override
  String get backupExportHint =>
      'Un fichier avec vos textes, quiz et résultats, à garder ou à transférer sur un autre téléphone.';

  @override
  String get backupImport => 'Restaurer une sauvegarde';

  @override
  String get backupImportHint =>
      'Ajoute les textes du fichier ; ceux déjà présents ne sont pas dupliqués.';

  @override
  String get backupSaved => 'Sauvegarde enregistrée.';

  @override
  String get backupEmpty => 'Votre bibliothèque est vide : rien à sauvegarder.';

  @override
  String get backupFailed => 'La sauvegarde n’a pas pu être enregistrée.';

  @override
  String restoreDone(int added, int skipped) {
    return 'Restauration : $added texte(s) ajouté(s), $skipped déjà présent(s).';
  }

  @override
  String get backupInvalid =>
      'Ce fichier n’est pas une sauvegarde de Comprendre.';

  @override
  String get backupNewer =>
      'Cette sauvegarde vient d’une version plus récente de Comprendre : mettez l’application à jour.';

  @override
  String get about => 'À propos';

  @override
  String get aboutBody =>
      'Comprendre vous aide à comprendre un texte en vous posant des questions dessus. Chaque réponse est justifiée par un passage du texte.';

  @override
  String get privacyTitle => 'Confidentialité';

  @override
  String get privacyBody =>
      'Vos textes et vos résultats restent sur ce téléphone. Pour un quiz IA, le texte est envoyé de façon chiffrée à notre serveur et à l’IA (Claude, d’Anthropic), qui ne le conservent pas. Un identifiant aléatoire, sans lien avec vous, sert seulement à compter le quota gratuit.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get emptyBodyWeb =>
      'Écrivez ou collez un texte, ou importez un fichier (PDF, Word, PowerPoint…). Comprendre en tire un quiz pour vérifier et approfondir votre compréhension.';

  @override
  String updateAvailable(String version) {
    return 'Version $version disponible';
  }

  @override
  String updateRequired(String version) {
    return 'Mise à jour obligatoire : version $version';
  }

  @override
  String get updateRequiredHint =>
      'Cette version n’est plus prise en charge : installez la nouvelle pour continuer.';

  @override
  String get updateDownload => 'Télécharger';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get webInstallTitle => 'Installez l’application Android';

  @override
  String get webInstallBody =>
      'Plus fluide au quotidien, et vos données ne dépendent plus du navigateur.';

  @override
  String get webInstallAction => 'Installer';

  @override
  String get homeScreenTitle => 'Ajoutez l’application à l’écran d’accueil';

  @override
  String get homeScreenBody =>
      'Touchez Partager (le carré avec une flèche), puis « Sur l’écran d’accueil ». L’application s’ouvrira en plein écran et vos données seront mieux conservées.';

  @override
  String get homeScreenDismiss => 'Compris';
}
