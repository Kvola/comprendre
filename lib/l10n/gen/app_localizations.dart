import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'Un quiz pour comprendre n’importe quel texte'**
  String get tagline;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @questionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String questionsCount(int count);

  /// No description provided for @quizzesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun quiz} =1{1 quiz} other{{count} quiz}}'**
  String quizzesCount(int count);

  /// No description provided for @charsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} caractères'**
  String charsCount(int count);

  /// No description provided for @libraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes textes'**
  String get libraryTitle;

  /// No description provided for @emptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comprenez ce que vous lisez'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez ou collez un texte, scannez une page ou importez un fichier (PDF, Word, PowerPoint…). Comprendre en tire un quiz pour vérifier et approfondir votre compréhension.'**
  String get emptyBody;

  /// No description provided for @newText.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau texte'**
  String get newText;

  /// No description provided for @sourceTyped.
  ///
  /// In fr, this message translates to:
  /// **'Écrire ou coller'**
  String get sourceTyped;

  /// No description provided for @sourceTypedHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le texte, ou collez-le'**
  String get sourceTypedHint;

  /// No description provided for @sourceScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un document'**
  String get sourceScan;

  /// No description provided for @sourceScanHint.
  ///
  /// In fr, this message translates to:
  /// **'Une ou plusieurs pages, avec l’appareil photo'**
  String get sourceScanHint;

  /// No description provided for @sourcePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Texte d’une photo'**
  String get sourcePhoto;

  /// No description provided for @sourcePhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Une image de votre galerie'**
  String get sourcePhotoHint;

  /// No description provided for @sourceFile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier'**
  String get sourceFile;

  /// No description provided for @sourceFileHint.
  ///
  /// In fr, this message translates to:
  /// **'PDF, Word, PowerPoint, OpenDocument, EPUB, texte…'**
  String get sourceFileHint;

  /// No description provided for @deleteTextTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce texte ?'**
  String get deleteTextTitle;

  /// No description provided for @deleteTextBody.
  ///
  /// In fr, this message translates to:
  /// **'Le texte et ses quiz seront supprimés de ce téléphone.'**
  String get deleteTextBody;

  /// No description provided for @textDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Texte supprimé'**
  String get textDeleted;

  /// No description provided for @editorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre texte'**
  String get editorTitle;

  /// No description provided for @titleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre (facultatif)'**
  String get titleLabel;

  /// No description provided for @textLabel.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get textLabel;

  /// No description provided for @textHint.
  ///
  /// In fr, this message translates to:
  /// **'Collez ou écrivez ici le texte à comprendre…'**
  String get textHint;

  /// No description provided for @paste.
  ///
  /// In fr, this message translates to:
  /// **'Coller'**
  String get paste;

  /// No description provided for @clipboardEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le presse-papiers ne contient pas de texte.'**
  String get clipboardEmpty;

  /// No description provided for @reviewExtracted.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez le texte : vous pouvez le corriger ou en retirer des parties avant de créer le quiz.'**
  String get reviewExtracted;

  /// No description provided for @textTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un peu de texte : {count} caractères au moins.'**
  String textTooShort(int count);

  /// No description provided for @languageOfText.
  ///
  /// In fr, this message translates to:
  /// **'Langue du texte'**
  String get languageOfText;

  /// No description provided for @langFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFr;

  /// No description provided for @langEn.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get langEn;

  /// No description provided for @langEs.
  ///
  /// In fr, this message translates to:
  /// **'Espagnol'**
  String get langEs;

  /// No description provided for @langPt.
  ///
  /// In fr, this message translates to:
  /// **'Portugais'**
  String get langPt;

  /// No description provided for @langDe.
  ///
  /// In fr, this message translates to:
  /// **'Allemand'**
  String get langDe;

  /// No description provided for @langIt.
  ///
  /// In fr, this message translates to:
  /// **'Italien'**
  String get langIt;

  /// No description provided for @langNeedsAiNote.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne, les quiz ne se font qu’en français et en anglais : pour un texte dans cette langue, l’IA (avec une connexion) est nécessaire.'**
  String get langNeedsAiNote;

  /// No description provided for @createQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Créer le quiz'**
  String get createQuiz;

  /// No description provided for @saveText.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le texte'**
  String get saveText;

  /// No description provided for @discardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner ce texte ?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous avez saisi sera perdu.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get discard;

  /// No description provided for @reading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du fichier…'**
  String get reading;

  /// No description provided for @readingPages.
  ///
  /// In fr, this message translates to:
  /// **'Lecture : page {done} sur {total}'**
  String readingPages(int done, int total);

  /// No description provided for @recognizing.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance du texte…'**
  String get recognizing;

  /// No description provided for @errUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Ce type de fichier n’est pas pris en charge.'**
  String get errUnsupported;

  /// No description provided for @errLegacyOffice.
  ///
  /// In fr, this message translates to:
  /// **'Ancien format Office (.doc, .ppt) : enregistrez-le en .docx, .pptx ou PDF, puis importez-le.'**
  String get errLegacyOffice;

  /// No description provided for @errEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun texte n’a été trouvé dans ce document.'**
  String get errEmpty;

  /// No description provided for @errCorrupt.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier est illisible ou endommagé.'**
  String get errCorrupt;

  /// No description provided for @errEncrypted.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier est protégé par un mot de passe.'**
  String get errEncrypted;

  /// No description provided for @errTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier est trop volumineux (40 Mo au plus).'**
  String get errTooLarge;

  /// No description provided for @errOcr.
  ///
  /// In fr, this message translates to:
  /// **'La reconnaissance du texte a échoué. Essayez une photo plus nette et bien éclairée.'**
  String get errOcr;

  /// No description provided for @errNoTextInImage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun texte n’a été reconnu sur cette image.'**
  String get errNoTextInImage;

  /// No description provided for @errScanner.
  ///
  /// In fr, this message translates to:
  /// **'Le scanner de documents n’est pas disponible sur cet appareil.'**
  String get errScanner;

  /// No description provided for @readText.
  ///
  /// In fr, this message translates to:
  /// **'Lire le texte'**
  String get readText;

  /// No description provided for @hideText.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le texte'**
  String get hideText;

  /// No description provided for @quizzesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get quizzesTitle;

  /// No description provided for @noQuizYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de quiz pour ce texte.'**
  String get noQuizYet;

  /// No description provided for @newQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau quiz'**
  String get newQuiz;

  /// No description provided for @anotherQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Un autre quiz'**
  String get anotherQuiz;

  /// No description provided for @bestScore.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur score : {score}/{total}'**
  String bestScore(int score, int total);

  /// No description provided for @notTried.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore fait'**
  String get notTried;

  /// No description provided for @engineAi.
  ///
  /// In fr, this message translates to:
  /// **'Quiz IA'**
  String get engineAi;

  /// No description provided for @engineOffline.
  ///
  /// In fr, this message translates to:
  /// **'Quiz hors ligne'**
  String get engineOffline;

  /// No description provided for @deleteQuizTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce quiz ?'**
  String get deleteQuizTitle;

  /// No description provided for @staleQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Le texte a été modifié depuis ce quiz'**
  String get staleQuiz;

  /// No description provided for @quizInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours : {done} réponse(s) sur {total}'**
  String quizInProgress(int done, int total);

  /// No description provided for @quoteNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce passage n’est plus dans le texte : le texte a été modifié depuis ce quiz.'**
  String get quoteNotFound;

  /// No description provided for @summaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'En bref'**
  String get summaryTitle;

  /// No description provided for @creatingQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Création du quiz…'**
  String get creatingQuiz;

  /// No description provided for @creatingAi.
  ///
  /// In fr, this message translates to:
  /// **'L’IA lit votre texte et prépare des questions de compréhension. Cela peut prendre une à deux minutes.'**
  String get creatingAi;

  /// No description provided for @creatingOffline.
  ///
  /// In fr, this message translates to:
  /// **'Préparation des questions à partir du texte…'**
  String get creatingOffline;

  /// No description provided for @useOfflineNow.
  ///
  /// In fr, this message translates to:
  /// **'Créer hors ligne maintenant'**
  String get useOfflineNow;

  /// No description provided for @quizTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte est trop court ou trop pauvre pour un quiz. Ajoutez quelques phrases complètes.'**
  String get quizTooShort;

  /// No description provided for @fallbackNotice.
  ///
  /// In fr, this message translates to:
  /// **'Quiz créé hors ligne : {reason}'**
  String fallbackNotice(String reason);

  /// No description provided for @whyNetwork.
  ///
  /// In fr, this message translates to:
  /// **'pas de connexion au service IA.'**
  String get whyNetwork;

  /// No description provided for @whyQuota.
  ///
  /// In fr, this message translates to:
  /// **'quota IA du jour atteint.'**
  String get whyQuota;

  /// No description provided for @whyFailures.
  ///
  /// In fr, this message translates to:
  /// **'l’IA a échoué plusieurs fois aujourd’hui sur vos textes ; elle sera de nouveau disponible demain.'**
  String get whyFailures;

  /// No description provided for @whyLanguage.
  ///
  /// In fr, this message translates to:
  /// **'le service IA ne gère pas encore cette langue.'**
  String get whyLanguage;

  /// No description provided for @langNeedsAiOff.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne, les quiz ne se font qu’en français et en anglais. Pour ce texte, activez l’IA dans les réglages.'**
  String get langNeedsAiOff;

  /// No description provided for @langNeedsAiFailed.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne, les quiz ne se font qu’en français et en anglais, et l’IA n’a pas pu créer ce quiz : {reason}'**
  String langNeedsAiFailed(String reason);

  /// No description provided for @chooseSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quiz sur quelle partie ?'**
  String get chooseSectionTitle;

  /// No description provided for @chooseSectionBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte est long ({count} caractères) : un quiz sur une partie est plus utile.'**
  String chooseSectionBody(int count);

  /// No description provided for @wholeText.
  ///
  /// In fr, this message translates to:
  /// **'Tout le texte'**
  String get wholeText;

  /// No description provided for @wholeTextTooLongForAi.
  ///
  /// In fr, this message translates to:
  /// **'Trop long pour l’IA ({count} caractères au plus) : quiz hors ligne'**
  String wholeTextTooLongForAi(int count);

  /// No description provided for @sectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Partie : {label}'**
  String sectionLabel(String label);

  /// No description provided for @whyTooLong.
  ///
  /// In fr, this message translates to:
  /// **'texte trop long pour l’IA ({count} caractères au plus).'**
  String whyTooLong(int count);

  /// No description provided for @whyBusy.
  ///
  /// In fr, this message translates to:
  /// **'le service IA est très demandé, réessayez plus tard.'**
  String get whyBusy;

  /// No description provided for @whyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'le service IA est momentanément indisponible.'**
  String get whyUnavailable;

  /// No description provided for @whyRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'trop de demandes, réessayez dans {count} min.'**
  String whyRateLimited(int count);

  /// No description provided for @whyDisabled.
  ///
  /// In fr, this message translates to:
  /// **'le service IA est désactivé.'**
  String get whyDisabled;

  /// No description provided for @whyUnverified.
  ///
  /// In fr, this message translates to:
  /// **'les questions de l’IA n’ont pas pu être vérifiées dans le texte.'**
  String get whyUnverified;

  /// No description provided for @whyRefusedContent.
  ///
  /// In fr, this message translates to:
  /// **'l’IA ne peut pas traiter ce texte.'**
  String get whyRefusedContent;

  /// No description provided for @whyOther.
  ///
  /// In fr, this message translates to:
  /// **'le service IA n’a pas répondu correctement.'**
  String get whyOther;

  /// No description provided for @whyCancelled.
  ///
  /// In fr, this message translates to:
  /// **'vous avez choisi de ne pas attendre.'**
  String get whyCancelled;

  /// No description provided for @aiConsentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l’IA ?'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentBody.
  ///
  /// In fr, this message translates to:
  /// **'Avec une connexion Internet, Comprendre peut demander à une IA (Claude, d’Anthropic) des questions plus riches : idée principale, causes et conséquences, sens des mots, déductions.\n\nPour cela, le texte est envoyé à notre serveur puis à l’IA, seulement pour créer le quiz : il n’est pas conservé. Aucun compte, aucune donnée personnelle.\n\nSans IA, le quiz est créé sur votre téléphone, sans rien envoyer.'**
  String get aiConsentBody;

  /// No description provided for @aiConsentYes.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l’IA'**
  String get aiConsentYes;

  /// No description provided for @aiConsentNo.
  ///
  /// In fr, this message translates to:
  /// **'Rester hors ligne'**
  String get aiConsentNo;

  /// No description provided for @aiFreePerDay.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 quiz IA gratuit par jour} other{{count} quiz IA gratuits par jour}}'**
  String aiFreePerDay(int count);

  /// No description provided for @questionOf.
  ///
  /// In fr, this message translates to:
  /// **'Question {index} sur {total}'**
  String questionOf(int index, int total);

  /// No description provided for @trueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vrai'**
  String get trueLabel;

  /// No description provided for @falseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Faux'**
  String get falseLabel;

  /// No description provided for @correct.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait'**
  String get incorrect;

  /// No description provided for @theAnswerWas.
  ///
  /// In fr, this message translates to:
  /// **'La bonne réponse : {answer}'**
  String theAnswerWas(String answer);

  /// No description provided for @inTheText.
  ///
  /// In fr, this message translates to:
  /// **'Dans le texte'**
  String get inTheText;

  /// No description provided for @showInText.
  ///
  /// In fr, this message translates to:
  /// **'Voir dans le texte'**
  String get showInText;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivante'**
  String get next;

  /// No description provided for @seeResults.
  ///
  /// In fr, this message translates to:
  /// **'Voir le résultat'**
  String get seeResults;

  /// No description provided for @progressResumed.
  ///
  /// In fr, this message translates to:
  /// **'Reprise là où vous en étiez.'**
  String get progressResumed;

  /// No description provided for @reviewMistakesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes erreurs'**
  String get reviewMistakesTitle;

  /// No description provided for @mistakeOf.
  ///
  /// In fr, this message translates to:
  /// **'Erreur {index} sur {total}'**
  String mistakeOf(int index, int total);

  /// No description provided for @skillMainIdea.
  ///
  /// In fr, this message translates to:
  /// **'Idée principale'**
  String get skillMainIdea;

  /// No description provided for @skillDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail'**
  String get skillDetail;

  /// No description provided for @skillVocabulary.
  ///
  /// In fr, this message translates to:
  /// **'Vocabulaire'**
  String get skillVocabulary;

  /// No description provided for @skillInference.
  ///
  /// In fr, this message translates to:
  /// **'Déduction'**
  String get skillInference;

  /// No description provided for @skillStructure.
  ///
  /// In fr, this message translates to:
  /// **'Structure'**
  String get skillStructure;

  /// No description provided for @skillCause.
  ///
  /// In fr, this message translates to:
  /// **'Cause et effet'**
  String get skillCause;

  /// No description provided for @resultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résultat'**
  String get resultTitle;

  /// No description provided for @scoreOutOf.
  ///
  /// In fr, this message translates to:
  /// **'{score} sur {total}'**
  String scoreOutOf(int score, int total);

  /// No description provided for @resultGreat.
  ///
  /// In fr, this message translates to:
  /// **'Excellent : vous avez bien compris ce texte.'**
  String get resultGreat;

  /// No description provided for @resultGood.
  ///
  /// In fr, this message translates to:
  /// **'Bien : relisez les passages des questions manquées.'**
  String get resultGood;

  /// No description provided for @resultLow.
  ///
  /// In fr, this message translates to:
  /// **'Relisez le texte tranquillement, puis réessayez : chaque explication renvoie au passage.'**
  String get resultLow;

  /// No description provided for @reviewAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Revoir les réponses'**
  String get reviewAnswers;

  /// No description provided for @yourAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse : {answer}'**
  String yourAnswer(String answer);

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Refaire ce quiz'**
  String get tryAgain;

  /// No description provided for @retryMistakes.
  ///
  /// In fr, this message translates to:
  /// **'Revoir mes erreurs'**
  String get retryMistakes;

  /// No description provided for @mistakesResult.
  ///
  /// In fr, this message translates to:
  /// **'Erreurs revues : {score} sur {total} maintenant justes'**
  String mistakesResult(int score, int total);

  /// No description provided for @mistakesResultHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce tour ne change pas votre meilleur score : refaites tout le quiz pour cela.'**
  String get mistakesResultHint;

  /// No description provided for @backToText.
  ///
  /// In fr, this message translates to:
  /// **'Retour au texte'**
  String get backToText;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @appLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l’application'**
  String get appLanguage;

  /// No description provided for @systemDefault.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get systemDefault;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @questionsPerQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Questions par quiz'**
  String get questionsPerQuiz;

  /// No description provided for @aiSection.
  ///
  /// In fr, this message translates to:
  /// **'Quiz IA'**
  String get aiSection;

  /// No description provided for @aiUse.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l’IA quand c’est possible'**
  String get aiUse;

  /// No description provided for @aiUseHint.
  ///
  /// In fr, this message translates to:
  /// **'Le texte est envoyé à l’IA pour créer le quiz, puis oublié. Sinon, tout reste sur le téléphone.'**
  String get aiUseHint;

  /// No description provided for @aiRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Plus de quiz IA aujourd’hui} =1{Encore 1 quiz IA aujourd’hui} other{Encore {count} quiz IA aujourd’hui}}'**
  String aiRemaining(int count);

  /// No description provided for @aiQuotaUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Quota IA : connexion nécessaire'**
  String get aiQuotaUnknown;

  /// No description provided for @aiRemainingDetail.
  ///
  /// In fr, this message translates to:
  /// **'{free} du quota gratuit + {codes} avec vos codes IA'**
  String aiRemainingDetail(int free, int codes);

  /// No description provided for @aiCodeEnter.
  ///
  /// In fr, this message translates to:
  /// **'J’ai un code IA'**
  String get aiCodeEnter;

  /// No description provided for @aiCodeEnterHint.
  ///
  /// In fr, this message translates to:
  /// **'Un code reçu de votre école, de votre entreprise ou d’un partenaire, pour plus de quiz IA.'**
  String get aiCodeEnterHint;

  /// No description provided for @aiCodeDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code IA'**
  String get aiCodeDialogTitle;

  /// No description provided for @aiCodeDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code tel qu’il vous a été donné (majuscules, espaces et tirets ne comptent pas). Il sera lié à ce téléphone.'**
  String get aiCodeDialogBody;

  /// No description provided for @aiCodeField.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get aiCodeField;

  /// No description provided for @aiCodeActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get aiCodeActivate;

  /// No description provided for @aiCodeActivated.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Code activé : 1 quiz IA disponible.} other{Code activé : {count} quiz IA disponibles.}}'**
  String aiCodeActivated(int count);

  /// No description provided for @aiCodeActivatedAiOn.
  ///
  /// In fr, this message translates to:
  /// **'L’IA est activée pour vos quiz.'**
  String get aiCodeActivatedAiOn;

  /// No description provided for @aiCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code {code}'**
  String aiCodeTitle(String code);

  /// No description provided for @aiCodeLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Plus de quiz IA sur ce code} =1{1 quiz IA restant} other{{count} quiz IA restants}}'**
  String aiCodeLeft(int count);

  /// No description provided for @aiCodeUntil.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’au {date}'**
  String aiCodeUntil(String date);

  /// No description provided for @aiCodeExpired.
  ///
  /// In fr, this message translates to:
  /// **'expiré'**
  String get aiCodeExpired;

  /// No description provided for @aiCodeDailyDone.
  ///
  /// In fr, this message translates to:
  /// **'plafond du jour atteint'**
  String get aiCodeDailyDone;

  /// No description provided for @aiCodeErrUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Ce code IA n’existe pas. Vérifiez-le.'**
  String get aiCodeErrUnknown;

  /// No description provided for @aiCodeErrDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Ce code IA a été désactivé.'**
  String get aiCodeErrDisabled;

  /// No description provided for @aiCodeErrExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code IA a expiré.'**
  String get aiCodeErrExpired;

  /// No description provided for @aiCodeErrExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Tous les quiz IA de ce code ont déjà été utilisés.'**
  String get aiCodeErrExhausted;

  /// No description provided for @aiCodeErrTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce code IA est déjà utilisé sur un autre téléphone et ne peut plus être transféré. Demandez à la personne qui vous l’a donné de libérer le code.'**
  String get aiCodeErrTaken;

  /// No description provided for @aiCodeErrFull.
  ///
  /// In fr, this message translates to:
  /// **'Ce code IA est déjà utilisé sur tous les téléphones prévus. Demandez à la personne qui vous l’a donné.'**
  String get aiCodeErrFull;

  /// No description provided for @aiCodeErrRate.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais : réessayez dans {count} min.'**
  String aiCodeErrRate(int count);

  /// No description provided for @aiCodeErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion au service : réessayez quand vous serez connecté.'**
  String get aiCodeErrNetwork;

  /// No description provided for @aiCodeErrOther.
  ///
  /// In fr, this message translates to:
  /// **'Le code n’a pas pu être activé. Réessayez plus tard.'**
  String get aiCodeErrOther;

  /// No description provided for @aiCodePaste.
  ///
  /// In fr, this message translates to:
  /// **'Coller'**
  String get aiCodePaste;

  /// No description provided for @aiCodePasteEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code dans le presse-papiers.'**
  String get aiCodePasteEmpty;

  /// No description provided for @aiCodeAlready.
  ///
  /// In fr, this message translates to:
  /// **'Ce code est déjà sur ce téléphone.'**
  String get aiCodeAlready;

  /// No description provided for @aiCodeTransferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transférer ce code ici ?'**
  String get aiCodeTransferTitle;

  /// No description provided for @aiCodeTransferBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ce code IA est utilisé sur un autre téléphone. Si c’est le vôtre (changement de téléphone), transférez-le : l’autre téléphone ne pourra plus s’en servir. C’est le dernier transfert permis.} other{Ce code IA est utilisé sur un autre téléphone. Si c’est le vôtre (changement de téléphone), transférez-le : l’autre téléphone ne pourra plus s’en servir. Encore {count} transferts permis.}}'**
  String aiCodeTransferBody(int count);

  /// No description provided for @aiCodeTransferAction.
  ///
  /// In fr, this message translates to:
  /// **'Transférer'**
  String get aiCodeTransferAction;

  /// No description provided for @aiCodeTransferred.
  ///
  /// In fr, this message translates to:
  /// **'Code transféré sur ce téléphone.'**
  String get aiCodeTransferred;

  /// No description provided for @myCodes.
  ///
  /// In fr, this message translates to:
  /// **'Mes codes IA'**
  String get myCodes;

  /// No description provided for @myCodesBuy.
  ///
  /// In fr, this message translates to:
  /// **'Acheter'**
  String get myCodesBuy;

  /// No description provided for @myCodesNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code IA sur ce téléphone'**
  String get myCodesNone;

  /// No description provided for @myCodesSummary.
  ///
  /// In fr, this message translates to:
  /// **'{codes, plural, =1{1 code} other{{codes} codes}} · {count, plural, =0{plus de quiz IA} =1{1 quiz IA restant} other{{count} quiz IA restants}}'**
  String myCodesSummary(int codes, int count);

  /// No description provided for @myCodesExpireSoon.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 quiz IA expire {when}} other{{count} quiz IA expirent {when}}}'**
  String myCodesExpireSoon(int count, String when);

  /// No description provided for @whenToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd’hui'**
  String get whenToday;

  /// No description provided for @whenTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'demain'**
  String get whenTomorrow;

  /// No description provided for @whenInDays.
  ///
  /// In fr, this message translates to:
  /// **'dans {count} jours'**
  String whenInDays(int count);

  /// No description provided for @whenOnDate.
  ///
  /// In fr, this message translates to:
  /// **'le {date}'**
  String whenOnDate(String date);

  /// No description provided for @myCodesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Vos codes servent quand le quota gratuit du jour est épuisé, en commençant par celui qui expire le premier.'**
  String get myCodesIntro;

  /// No description provided for @myCodesEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Un code IA vous donne des quiz IA en plus du quota gratuit. Vous pouvez en recevoir un (école, entreprise, partenaire) ou en acheter.'**
  String get myCodesEmptyBody;

  /// No description provided for @myCodesToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get myCodesToday;

  /// No description provided for @myCodesEnded.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get myCodesEnded;

  /// No description provided for @myCodesOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion : état au {date}.'**
  String myCodesOffline(String date);

  /// No description provided for @myCodesOfflineNone.
  ///
  /// In fr, this message translates to:
  /// **'Connexion nécessaire pour voir vos codes IA.'**
  String get myCodesOfflineNone;

  /// No description provided for @codeUsedOf.
  ///
  /// In fr, this message translates to:
  /// **'{used} utilisés sur {total}'**
  String codeUsedOf(int used, int total);

  /// No description provided for @codeExpiresWhen.
  ///
  /// In fr, this message translates to:
  /// **'Expire {when}'**
  String codeExpiresWhen(String when);

  /// No description provided for @codeNoExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Sans date limite'**
  String get codeNoExpiry;

  /// No description provided for @codeDailyLimit.
  ///
  /// In fr, this message translates to:
  /// **'{count} par jour au plus'**
  String codeDailyLimit(int count);

  /// No description provided for @codeDailyLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{plus rien aujourd’hui} =1{encore 1 aujourd’hui} other{encore {count} aujourd’hui}}'**
  String codeDailyLeft(int count);

  /// No description provided for @codeShared.
  ///
  /// In fr, this message translates to:
  /// **'Partagé : {count} téléphones au plus · {mine} par vous'**
  String codeShared(int count, int mine);

  /// No description provided for @codeBought.
  ///
  /// In fr, this message translates to:
  /// **'Acheté'**
  String get codeBought;

  /// No description provided for @codeGift.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get codeGift;

  /// No description provided for @codeStateExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Épuisé'**
  String get codeStateExhausted;

  /// No description provided for @codeStateExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get codeStateExpired;

  /// No description provided for @codeStateDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get codeStateDisabled;

  /// No description provided for @codeLastUsed.
  ///
  /// In fr, this message translates to:
  /// **'Dernier quiz IA : {date}'**
  String codeLastUsed(String date);

  /// No description provided for @codeCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get codeCopy;

  /// No description provided for @codeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code copié.'**
  String get codeCopied;

  /// No description provided for @codeRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de ce téléphone'**
  String get codeRemove;

  /// No description provided for @codeRemoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce code ?'**
  String get codeRemoveTitle;

  /// No description provided for @codeRemoveBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Le code disparaît de ce téléphone.} =1{Le code disparaît de ce téléphone ; le quiz IA restant reste sur le code : vous pouvez le donner à quelqu’un, qui le saisira sur son téléphone.} other{Le code disparaît de ce téléphone ; les {count} quiz IA restants restent sur le code : vous pouvez le donner à quelqu’un, qui le saisira sur son téléphone.}}'**
  String codeRemoveBody(int count);

  /// No description provided for @codeRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Code retiré de ce téléphone.'**
  String get codeRemoved;

  /// No description provided for @codeRemoveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le code n’a pas pu être retiré. Réessayez quand vous serez connecté.'**
  String get codeRemoveFailed;

  /// No description provided for @shopEntry.
  ///
  /// In fr, this message translates to:
  /// **'Acheter des quiz IA'**
  String get shopEntry;

  /// No description provided for @shopEntryHint.
  ///
  /// In fr, this message translates to:
  /// **'Payez avec Wave : les quiz IA sont ajoutés à ce téléphone.'**
  String get shopEntryHint;

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Acheter des quiz IA'**
  String get shopTitle;

  /// No description provided for @shopIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une offre et payez avec Wave. Dès que le paiement est confirmé, vos quiz IA sont ajoutés à ce téléphone, sans code à saisir.'**
  String get shopIntro;

  /// No description provided for @shopNoOffer.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre n’est proposée pour le moment.'**
  String get shopNoOffer;

  /// No description provided for @shopOffline.
  ///
  /// In fr, this message translates to:
  /// **'Connexion nécessaire pour voir les offres.'**
  String get shopOffline;

  /// No description provided for @shopCredits.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 quiz IA} other{{count} quiz IA}}'**
  String shopCredits(int count);

  /// No description provided for @shopValidity.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{valable 1 jour} other{valables {count} jours}}'**
  String shopValidity(int count);

  /// No description provided for @shopNoExpiry.
  ///
  /// In fr, this message translates to:
  /// **'sans limite de durée'**
  String get shopNoExpiry;

  /// No description provided for @shopDailyLimit.
  ///
  /// In fr, this message translates to:
  /// **'{count} par jour au plus'**
  String shopDailyLimit(int count);

  /// No description provided for @shopBuy.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec Wave'**
  String get shopBuy;

  /// No description provided for @shopConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec Wave ?'**
  String get shopConfirmTitle;

  /// No description provided for @shopConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{pack} : {credits}, pour {price}. L’application Wave va s’ouvrir pour le paiement.'**
  String shopConfirmBody(String pack, String credits, String price);

  /// No description provided for @shopOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Wave n’a pas pu s’ouvrir. Ouvrez ce lien pour payer :'**
  String get shopOpenFailed;

  /// No description provided for @shopCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get shopCopyLink;

  /// No description provided for @shopLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié.'**
  String get shopLinkCopied;

  /// No description provided for @shopMyOrders.
  ///
  /// In fr, this message translates to:
  /// **'Mes achats'**
  String get shopMyOrders;

  /// No description provided for @shopOrderPending.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en attente'**
  String get shopOrderPending;

  /// No description provided for @shopOrderDone.
  ///
  /// In fr, this message translates to:
  /// **'Payé : quiz IA ajoutés'**
  String get shopOrderDone;

  /// No description provided for @shopOrderRef.
  ///
  /// In fr, this message translates to:
  /// **'Achat {ref}'**
  String shopOrderRef(String ref);

  /// No description provided for @shopWaitAuto.
  ///
  /// In fr, this message translates to:
  /// **'Wave confirme le paiement en quelques instants ; vos quiz IA sont alors ajoutés automatiquement.'**
  String get shopWaitAuto;

  /// No description provided for @shopWaitAgent.
  ///
  /// In fr, this message translates to:
  /// **'Après votre paiement Wave, notre équipe le confirme (en général dans la journée). Vos quiz IA sont alors ajoutés automatiquement.'**
  String get shopWaitAgent;

  /// No description provided for @shopWaveRefLabel.
  ///
  /// In fr, this message translates to:
  /// **'ID de la transaction Wave (facultatif)'**
  String get shopWaveRefLabel;

  /// No description provided for @shopWaveRefHint.
  ///
  /// In fr, this message translates to:
  /// **'Dans Wave : touchez le paiement, puis copiez son identifiant. Il aide à retrouver votre paiement.'**
  String get shopWaveRefHint;

  /// No description provided for @shopWaveRefSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get shopWaveRefSend;

  /// No description provided for @shopWaveRefSent.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant envoyé : {ref}'**
  String shopWaveRefSent(String ref);

  /// No description provided for @shopPayAgain.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Wave'**
  String get shopPayAgain;

  /// No description provided for @shopCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get shopCheck;

  /// No description provided for @shopConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Paiement confirmé : 1 quiz IA ajouté.} other{Paiement confirmé : {count} quiz IA ajoutés.}}'**
  String shopConfirmed(int count);

  /// No description provided for @shopPerQuiz.
  ///
  /// In fr, this message translates to:
  /// **'soit {price} le quiz'**
  String shopPerQuiz(String price);

  /// No description provided for @shopSaving.
  ///
  /// In fr, this message translates to:
  /// **'−{count} % par quiz'**
  String shopSaving(int count);

  /// No description provided for @shopBestValue.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur prix'**
  String get shopBestValue;

  /// No description provided for @shopPopular.
  ///
  /// In fr, this message translates to:
  /// **'Le plus choisi'**
  String get shopPopular;

  /// No description provided for @shopRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Conseillé pour vous'**
  String get shopRecommended;

  /// No description provided for @shopAdviceNeed.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ces 30 derniers jours, vous avez voulu 1 quiz IA de plus que le quota gratuit.} other{Ces 30 derniers jours, vous avez voulu {count} quiz IA de plus que le quota gratuit.}} Conseil : {pack}, de quoi tenir environ 3 mois sans quiz perdus.'**
  String shopAdviceNeed(int count, String pack);

  /// No description provided for @shopAdviceFree.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Ces 30 derniers jours, votre quiz IA gratuit par jour a suffi.} other{Ces 30 derniers jours, vos {count} quiz IA gratuits par jour ont suffi.}} Un achat ne sert que les jours où vous en voulez plus : les quiz gratuits passent toujours en premier.'**
  String shopAdviceFree(int count);

  /// No description provided for @shopErrUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Cette offre n’est plus proposée.'**
  String get shopErrUnavailable;

  /// No description provided for @shopErrPayment.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n’est pas disponible pour le moment. Réessayez plus tard.'**
  String get shopErrPayment;

  /// No description provided for @shopErrRefShort.
  ///
  /// In fr, this message translates to:
  /// **'Cet identifiant est trop court.'**
  String get shopErrRefShort;

  /// No description provided for @shopErrRefUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cet identifiant a déjà été donné pour un autre paiement.'**
  String get shopErrRefUsed;

  /// No description provided for @backupSection.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backupSection;

  /// No description provided for @backupExport.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder ma bibliothèque'**
  String get backupExport;

  /// No description provided for @backupExportHint.
  ///
  /// In fr, this message translates to:
  /// **'Un fichier avec vos textes, quiz et résultats, à garder ou à transférer sur un autre téléphone.'**
  String get backupExportHint;

  /// No description provided for @backupImport.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get backupImport;

  /// No description provided for @backupImportHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les textes du fichier ; ceux déjà présents ne sont pas dupliqués.'**
  String get backupImportHint;

  /// No description provided for @backupSaved.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde enregistrée.'**
  String get backupSaved;

  /// No description provided for @backupEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre bibliothèque est vide : rien à sauvegarder.'**
  String get backupEmpty;

  /// No description provided for @backupFailed.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde n’a pas pu être enregistrée.'**
  String get backupFailed;

  /// No description provided for @restoreDone.
  ///
  /// In fr, this message translates to:
  /// **'Restauration : {added} texte(s) ajouté(s), {skipped} déjà présent(s).'**
  String restoreDone(int added, int skipped);

  /// No description provided for @backupInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n’est pas une sauvegarde de Comprendre.'**
  String get backupInvalid;

  /// No description provided for @backupNewer.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde vient d’une version plus récente de Comprendre : mettez l’application à jour.'**
  String get backupNewer;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre vous aide à comprendre un texte en vous posant des questions dessus. Chaque réponse est justifiée par un passage du texte.'**
  String get aboutBody;

  /// No description provided for @privacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In fr, this message translates to:
  /// **'Vos textes et vos résultats restent sur ce téléphone. Pour un quiz IA, le texte est envoyé de façon chiffrée à notre serveur et à l’IA (Claude, d’Anthropic), qui ne le conservent pas. Un identifiant aléatoire, sans lien avec vous, sert seulement à compter le quota gratuit.'**
  String get privacyBody;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @emptyBodyWeb.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez ou collez un texte, ou importez un fichier (PDF, Word, PowerPoint…). Comprendre en tire un quiz pour vérifier et approfondir votre compréhension.'**
  String get emptyBodyWeb;

  /// No description provided for @updateAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} disponible'**
  String updateAvailable(String version);

  /// No description provided for @updateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour obligatoire : version {version}'**
  String updateRequired(String version);

  /// No description provided for @updateRequiredHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette version n’est plus prise en charge : installez la nouvelle pour continuer.'**
  String get updateRequiredHint;

  /// No description provided for @updateDownload.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get updateDownload;

  /// No description provided for @updateLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get updateLater;

  /// No description provided for @webInstallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Installez l’application Android'**
  String get webInstallTitle;

  /// No description provided for @webInstallBody.
  ///
  /// In fr, this message translates to:
  /// **'Plus fluide au quotidien, et vos données ne dépendent plus du navigateur.'**
  String get webInstallBody;

  /// No description provided for @webInstallAction.
  ///
  /// In fr, this message translates to:
  /// **'Installer'**
  String get webInstallAction;

  /// No description provided for @homeScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez l’application à l’écran d’accueil'**
  String get homeScreenTitle;

  /// No description provided for @homeScreenBody.
  ///
  /// In fr, this message translates to:
  /// **'Touchez Partager (le carré avec une flèche), puis « Sur l’écran d’accueil ». L’application s’ouvrira en plein écran et vos données seront mieux conservées.'**
  String get homeScreenBody;

  /// No description provided for @homeScreenDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get homeScreenDismiss;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
