// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Understand';

  @override
  String get tagline => 'A quiz to understand any text';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get retry => 'Try again';

  @override
  String get continueLabel => 'Continue';

  @override
  String get undo => 'Undo';

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
      other: '$count quizzes',
      one: '1 quiz',
      zero: 'No quiz yet',
    );
    return '$_temp0';
  }

  @override
  String charsCount(int count) {
    return '$count characters';
  }

  @override
  String get libraryTitle => 'My texts';

  @override
  String get emptyTitle => 'Understand what you read';

  @override
  String get emptyBody =>
      'Type or paste a text, scan a page or import a file (PDF, Word, PowerPoint…). Understand turns it into a quiz to check and deepen your understanding.';

  @override
  String get newText => 'New text';

  @override
  String get sourceTyped => 'Type or paste';

  @override
  String get sourceTypedHint => 'Type the text, or paste it';

  @override
  String get sourceScan => 'Scan a document';

  @override
  String get sourceScanHint => 'One or more pages, with the camera';

  @override
  String get sourcePhoto => 'Text from a photo';

  @override
  String get sourcePhotoHint => 'A picture from your gallery';

  @override
  String get sourceFile => 'Import a file';

  @override
  String get sourceFileHint =>
      'PDF, Word, PowerPoint, OpenDocument, EPUB, text…';

  @override
  String get deleteTextTitle => 'Delete this text?';

  @override
  String get deleteTextBody =>
      'The text and its quizzes will be removed from this phone.';

  @override
  String get textDeleted => 'Text deleted';

  @override
  String get editorTitle => 'Your text';

  @override
  String get titleLabel => 'Title (optional)';

  @override
  String get textLabel => 'Text';

  @override
  String get textHint => 'Paste or type the text to understand here…';

  @override
  String get paste => 'Paste';

  @override
  String get clipboardEmpty => 'The clipboard has no text.';

  @override
  String get reviewExtracted =>
      'Check the text: you can correct it or remove parts before creating the quiz.';

  @override
  String textTooShort(int count) {
    return 'Add a bit more text: at least $count characters.';
  }

  @override
  String get languageOfText => 'Language of the text';

  @override
  String get langFr => 'French';

  @override
  String get langEn => 'English';

  @override
  String get langEs => 'Spanish';

  @override
  String get langPt => 'Portuguese';

  @override
  String get langDe => 'German';

  @override
  String get langIt => 'Italian';

  @override
  String get langNeedsAiNote =>
      'Offline, quizzes are only made in French and English: for a text in this language, the AI (with a connection) is needed.';

  @override
  String get createQuiz => 'Create the quiz';

  @override
  String get saveText => 'Save the text';

  @override
  String get discardTitle => 'Discard this text?';

  @override
  String get discardBody => 'What you typed will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get reading => 'Reading the file…';

  @override
  String readingPages(int done, int total) {
    return 'Reading: page $done of $total';
  }

  @override
  String get recognizing => 'Recognising the text…';

  @override
  String get errUnsupported => 'This type of file is not supported.';

  @override
  String get errLegacyOffice =>
      'Old Office format (.doc, .ppt): save it as .docx, .pptx or PDF, then import it.';

  @override
  String get errEmpty => 'No text was found in this document.';

  @override
  String get errCorrupt => 'This file is unreadable or damaged.';

  @override
  String get errEncrypted => 'This file is password-protected.';

  @override
  String get errTooLarge => 'This file is too large (40 MB max).';

  @override
  String get errOcr =>
      'Text recognition failed. Try a sharper, well-lit picture.';

  @override
  String get errNoTextInImage => 'No text was recognised in this picture.';

  @override
  String get errScanner =>
      'The document scanner is not available on this device.';

  @override
  String get readText => 'Read the text';

  @override
  String get hideText => 'Hide the text';

  @override
  String get quizzesTitle => 'Quizzes';

  @override
  String get noQuizYet => 'No quiz for this text yet.';

  @override
  String get newQuiz => 'New quiz';

  @override
  String get anotherQuiz => 'Another quiz';

  @override
  String bestScore(int score, int total) {
    return 'Best score: $score/$total';
  }

  @override
  String get notTried => 'Not taken yet';

  @override
  String get engineAi => 'AI quiz';

  @override
  String get engineOffline => 'Offline quiz';

  @override
  String get deleteQuizTitle => 'Delete this quiz?';

  @override
  String get staleQuiz => 'The text has changed since this quiz';

  @override
  String quizInProgress(int done, int total) {
    return 'In progress: $done of $total answered';
  }

  @override
  String get quoteNotFound =>
      'This passage is no longer in the text: the text has changed since this quiz.';

  @override
  String get summaryTitle => 'In short';

  @override
  String get creatingQuiz => 'Creating the quiz…';

  @override
  String get creatingAi =>
      'The AI is reading your text and preparing comprehension questions. This can take one or two minutes.';

  @override
  String get creatingOffline => 'Preparing questions from the text…';

  @override
  String get useOfflineNow => 'Create offline now';

  @override
  String get quizTooShort =>
      'This text is too short or too thin for a quiz. Add a few complete sentences.';

  @override
  String fallbackNotice(String reason) {
    return 'Quiz created offline: $reason';
  }

  @override
  String get whyNetwork => 'no connection to the AI service.';

  @override
  String get whyQuota => 'today’s AI quota is used up.';

  @override
  String get whyFailures =>
      'the AI failed several times today on your texts; it will be available again tomorrow.';

  @override
  String get whyLanguage => 'the AI service does not handle this language yet.';

  @override
  String get langNeedsAiOff =>
      'Offline, quizzes are only made in French and English. For this text, turn on the AI in the settings.';

  @override
  String langNeedsAiFailed(String reason) {
    return 'Offline, quizzes are only made in French and English, and the AI could not create this quiz: $reason';
  }

  @override
  String get chooseSectionTitle => 'Quiz on which part?';

  @override
  String chooseSectionBody(int count) {
    return 'This text is long ($count characters): a quiz on one part is more useful.';
  }

  @override
  String get wholeText => 'The whole text';

  @override
  String wholeTextTooLongForAi(int count) {
    return 'Too long for the AI ($count characters max): offline quiz';
  }

  @override
  String sectionLabel(String label) {
    return 'Part: $label';
  }

  @override
  String whyTooLong(int count) {
    return 'text too long for the AI ($count characters max).';
  }

  @override
  String get whyBusy => 'the AI service is busy, try again later.';

  @override
  String get whyUnavailable => 'the AI service is temporarily unavailable.';

  @override
  String whyRateLimited(int count) {
    return 'too many requests, try again in $count min.';
  }

  @override
  String get whyDisabled => 'the AI service is turned off.';

  @override
  String get whyUnverified =>
      'the AI questions could not be checked against the text.';

  @override
  String get whyRefusedContent => 'the AI cannot process this text.';

  @override
  String get whyOther => 'the AI service did not respond properly.';

  @override
  String get whyCancelled => 'you chose not to wait.';

  @override
  String get aiConsentTitle => 'Use the AI?';

  @override
  String get aiConsentBody =>
      'With an Internet connection, Understand can ask an AI (Claude, by Anthropic) for richer questions: main idea, causes and consequences, word meaning, inferences.\n\nTo do so, the text is sent to our server and then to the AI, only to create the quiz: it is not kept. No account, no personal data.\n\nWithout the AI, the quiz is created on your phone, without sending anything.';

  @override
  String get aiConsentYes => 'Use the AI';

  @override
  String get aiConsentNo => 'Stay offline';

  @override
  String aiFreePerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count free AI quizzes per day',
      one: '1 free AI quiz per day',
    );
    return '$_temp0';
  }

  @override
  String questionOf(int index, int total) {
    return 'Question $index of $total';
  }

  @override
  String get trueLabel => 'True';

  @override
  String get falseLabel => 'False';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Not quite';

  @override
  String theAnswerWas(String answer) {
    return 'The right answer: $answer';
  }

  @override
  String get inTheText => 'In the text';

  @override
  String get showInText => 'Show in the text';

  @override
  String get next => 'Next';

  @override
  String get seeResults => 'See the result';

  @override
  String get progressResumed => 'Picking up where you left off.';

  @override
  String get reviewMistakesTitle => 'My mistakes';

  @override
  String mistakeOf(int index, int total) {
    return 'Mistake $index of $total';
  }

  @override
  String get skillMainIdea => 'Main idea';

  @override
  String get skillDetail => 'Detail';

  @override
  String get skillVocabulary => 'Vocabulary';

  @override
  String get skillInference => 'Inference';

  @override
  String get skillStructure => 'Structure';

  @override
  String get skillCause => 'Cause and effect';

  @override
  String get resultTitle => 'Result';

  @override
  String scoreOutOf(int score, int total) {
    return '$score out of $total';
  }

  @override
  String get resultGreat => 'Excellent: you understood this text well.';

  @override
  String get resultGood => 'Good: reread the passages of the missed questions.';

  @override
  String get resultLow =>
      'Reread the text calmly, then try again: each explanation points to the passage.';

  @override
  String get reviewAnswers => 'Review the answers';

  @override
  String yourAnswer(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String get tryAgain => 'Take this quiz again';

  @override
  String get retryMistakes => 'Retry my mistakes';

  @override
  String mistakesResult(int score, int total) {
    return 'Mistakes reviewed: $score of $total now right';
  }

  @override
  String get mistakesResultHint =>
      'This round does not change your best score: take the whole quiz again for that.';

  @override
  String get backToText => 'Back to the text';

  @override
  String get settings => 'Settings';

  @override
  String get appLanguage => 'App language';

  @override
  String get systemDefault => 'Phone language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get questionsPerQuiz => 'Questions per quiz';

  @override
  String get aiSection => 'AI quizzes';

  @override
  String get aiUse => 'Use the AI when possible';

  @override
  String get aiUseHint =>
      'The text is sent to the AI to create the quiz, then forgotten. Otherwise, everything stays on the phone.';

  @override
  String aiRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI quizzes left today',
      one: '1 AI quiz left today',
      zero: 'No AI quiz left today',
    );
    return '$_temp0';
  }

  @override
  String get aiQuotaUnknown => 'AI quota: connection needed';

  @override
  String aiRemainingDetail(int free, int codes) {
    return '$free from the free quota + $codes from your AI codes';
  }

  @override
  String get aiCodeEnter => 'I have an AI code';

  @override
  String get aiCodeEnterHint =>
      'A code from your school, company or a partner, for more AI quizzes.';

  @override
  String get aiCodeDialogTitle => 'AI code';

  @override
  String get aiCodeDialogBody =>
      'Type the code as you received it (capitals, spaces and dashes do not matter). It will be linked to this phone.';

  @override
  String get aiCodeField => 'Code';

  @override
  String get aiCodeActivate => 'Activate';

  @override
  String aiCodeActivated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code activated: $count AI quizzes available.',
      one: 'Code activated: 1 AI quiz available.',
    );
    return '$_temp0';
  }

  @override
  String get aiCodeActivatedAiOn => 'The AI is now on for your quizzes.';

  @override
  String aiCodeTitle(String code) {
    return 'Code $code';
  }

  @override
  String aiCodeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI quizzes left',
      one: '1 AI quiz left',
      zero: 'No AI quiz left on this code',
    );
    return '$_temp0';
  }

  @override
  String aiCodeUntil(String date) {
    return 'until $date';
  }

  @override
  String get aiCodeExpired => 'expired';

  @override
  String get aiCodeDailyDone => 'daily limit reached';

  @override
  String get aiCodeErrUnknown => 'This AI code does not exist. Check it.';

  @override
  String get aiCodeErrDisabled => 'This AI code has been turned off.';

  @override
  String get aiCodeErrExpired => 'This AI code has expired.';

  @override
  String get aiCodeErrExhausted =>
      'All the AI quizzes of this code have been used.';

  @override
  String get aiCodeErrTaken =>
      'This AI code is already used on another phone and can no longer be moved. Ask the person who gave it to you to release the code.';

  @override
  String get aiCodeErrFull =>
      'This AI code is already used on all the phones it allows. Ask the person who gave it to you.';

  @override
  String aiCodeErrRate(int count) {
    return 'Too many attempts: try again in $count min.';
  }

  @override
  String get aiCodeErrNetwork =>
      'No connection to the service: try again when you are online.';

  @override
  String get aiCodeErrOther =>
      'The code could not be activated. Try again later.';

  @override
  String get aiCodePaste => 'Paste';

  @override
  String get aiCodePasteEmpty => 'No code on the clipboard.';

  @override
  String get aiCodeAlready => 'This code is already on this phone.';

  @override
  String get aiCodeTransferTitle => 'Move this code here?';

  @override
  String aiCodeTransferBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This AI code is used on another phone. If it is yours (new phone), move it: the other phone will no longer be able to use it. $count moves left.',
      one: 'This AI code is used on another phone. If it is yours (new phone), move it: the other phone will no longer be able to use it. This is the last move allowed.',
    );
    return '$_temp0';
  }

  @override
  String get aiCodeTransferAction => 'Move it';

  @override
  String get aiCodeTransferred => 'Code moved to this phone.';

  @override
  String get myCodes => 'My AI codes';

  @override
  String get myCodesBuy => 'Buy';

  @override
  String get myCodesNone => 'No AI code on this phone';

  @override
  String myCodesSummary(int codes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      codes,
      locale: localeName,
      other: '$codes codes',
      one: '1 code',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI quizzes left',
      one: '1 AI quiz left',
      zero: 'no AI quiz left',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String myCodesExpireSoon(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI quizzes expire $when',
      one: '1 AI quiz expires $when',
    );
    return '$_temp0';
  }

  @override
  String get whenToday => 'today';

  @override
  String get whenTomorrow => 'tomorrow';

  @override
  String whenInDays(int count) {
    return 'in $count days';
  }

  @override
  String whenOnDate(String date) {
    return 'on $date';
  }

  @override
  String get myCodesIntro =>
      'Your codes are used once the free daily quota is used up, starting with the one that expires first.';

  @override
  String get myCodesEmptyBody =>
      'An AI code gives you AI quizzes on top of the free quota. You can receive one (school, company, partner) or buy one.';

  @override
  String get myCodesToday => 'Today';

  @override
  String get myCodesEnded => 'Finished';

  @override
  String myCodesOffline(String date) {
    return 'Offline: status as of $date.';
  }

  @override
  String get myCodesOfflineNone =>
      'A connection is needed to see your AI codes.';

  @override
  String codeUsedOf(int used, int total) {
    return '$used used out of $total';
  }

  @override
  String codeExpiresWhen(String when) {
    return 'Expires $when';
  }

  @override
  String get codeNoExpiry => 'No end date';

  @override
  String codeDailyLimit(int count) {
    return 'at most $count a day';
  }

  @override
  String codeDailyLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more today',
      one: '1 more today',
      zero: 'none left today',
    );
    return '$_temp0';
  }

  @override
  String codeShared(int count, int mine) {
    return 'Shared: up to $count phones · $mine by you';
  }

  @override
  String get codeBought => 'Bought';

  @override
  String get codeGift => 'Received';

  @override
  String get codeStateExhausted => 'Used up';

  @override
  String get codeStateExpired => 'Expired';

  @override
  String get codeStateDisabled => 'Turned off';

  @override
  String codeLastUsed(String date) {
    return 'Last AI quiz: $date';
  }

  @override
  String get codeCopy => 'Copy the code';

  @override
  String get codeCopied => 'Code copied.';

  @override
  String get codeRemove => 'Remove from this phone';

  @override
  String get codeRemoveTitle => 'Remove this code?';

  @override
  String codeRemoveBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The code disappears from this phone; the $count remaining AI quizzes stay on the code: you can give it to someone, who will enter it on their phone.',
      one: 'The code disappears from this phone; the remaining AI quiz stays on the code: you can give it to someone, who will enter it on their phone.',
      zero: 'The code disappears from this phone.',
    );
    return '$_temp0';
  }

  @override
  String get codeRemoved => 'Code removed from this phone.';

  @override
  String get codeRemoveFailed =>
      'The code could not be removed. Try again when you are online.';

  @override
  String get shopEntry => 'Buy AI quizzes';

  @override
  String get shopEntryHint =>
      'Pay with Wave: the AI quizzes are added to this phone.';

  @override
  String get shopTitle => 'Buy AI quizzes';

  @override
  String get shopIntro =>
      'Choose an offer and pay with Wave. As soon as the payment is confirmed, your AI quizzes are added to this phone, with no code to type.';

  @override
  String get shopNoOffer => 'No offer is available at the moment.';

  @override
  String get shopOffline => 'A connection is needed to see the offers.';

  @override
  String shopCredits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI quizzes',
      one: '1 AI quiz',
    );
    return '$_temp0';
  }

  @override
  String shopValidity(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'valid $count days',
      one: 'valid 1 day',
    );
    return '$_temp0';
  }

  @override
  String get shopNoExpiry => 'no time limit';

  @override
  String shopDailyLimit(int count) {
    return 'at most $count a day';
  }

  @override
  String get shopBuy => 'Pay with Wave';

  @override
  String get shopConfirmTitle => 'Pay with Wave?';

  @override
  String shopConfirmBody(String pack, String credits, String price) {
    return '$pack: $credits, for $price. The Wave app will open for the payment.';
  }

  @override
  String get shopOpenFailed =>
      'Wave could not be opened. Open this link to pay:';

  @override
  String get shopCopyLink => 'Copy the link';

  @override
  String get shopLinkCopied => 'Link copied.';

  @override
  String get shopMyOrders => 'My purchases';

  @override
  String get shopOrderPending => 'Payment pending';

  @override
  String get shopOrderDone => 'Paid: AI quizzes added';

  @override
  String shopOrderRef(String ref) {
    return 'Purchase $ref';
  }

  @override
  String get shopWaitAuto =>
      'Wave confirms the payment within moments; your AI quizzes are then added automatically.';

  @override
  String get shopWaitAgent =>
      'After your Wave payment, our team confirms it (usually the same day). Your AI quizzes are then added automatically.';

  @override
  String get shopWaveRefLabel => 'Wave transaction ID (optional)';

  @override
  String get shopWaveRefHint =>
      'In Wave: tap the payment, then copy its ID. It helps find your payment.';

  @override
  String get shopWaveRefSend => 'Send';

  @override
  String shopWaveRefSent(String ref) {
    return 'ID sent: $ref';
  }

  @override
  String get shopPayAgain => 'Open Wave';

  @override
  String get shopCheck => 'Check';

  @override
  String shopConfirmed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Payment confirmed: $count AI quizzes added.',
      one: 'Payment confirmed: 1 AI quiz added.',
    );
    return '$_temp0';
  }

  @override
  String get shopErrUnavailable => 'This offer is no longer available.';

  @override
  String get shopErrPayment =>
      'Payment is not available at the moment. Try again later.';

  @override
  String get shopErrRefShort => 'This ID is too short.';

  @override
  String get shopErrRefUsed => 'This ID was already given for another payment.';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupExport => 'Back up my library';

  @override
  String get backupExportHint =>
      'A file with your texts, quizzes and results, to keep or move to another phone.';

  @override
  String get backupImport => 'Restore a backup';

  @override
  String get backupImportHint =>
      'Adds the texts from the file; those already here are not duplicated.';

  @override
  String get backupSaved => 'Backup saved.';

  @override
  String get backupEmpty => 'Your library is empty: nothing to back up.';

  @override
  String get backupFailed => 'The backup could not be saved.';

  @override
  String restoreDone(int added, int skipped) {
    return 'Restore: $added text(s) added, $skipped already here.';
  }

  @override
  String get backupInvalid => 'This file is not an Understand backup.';

  @override
  String get backupNewer =>
      'This backup comes from a newer version of Understand: update the app.';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Understand helps you understand a text by asking you questions about it. Every answer is backed by a passage of the text.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Your texts and results stay on this phone. For an AI quiz, the text is sent encrypted to our server and to the AI (Claude, by Anthropic), which do not keep it. A random identifier, unrelated to you, is used only to count the free quota.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get emptyBodyWeb =>
      'Type or paste a text, or import a file (PDF, Word, PowerPoint…). Understand turns it into a quiz to check and deepen your understanding.';

  @override
  String updateAvailable(String version) {
    return 'Version $version available';
  }

  @override
  String updateRequired(String version) {
    return 'Update required: version $version';
  }

  @override
  String get updateRequiredHint =>
      'This version is no longer supported: install the new one to continue.';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateLater => 'Later';

  @override
  String get webInstallTitle => 'Install the Android app';

  @override
  String get webInstallBody =>
      'Smoother every day, and your data no longer depends on the browser.';

  @override
  String get webInstallAction => 'Install';

  @override
  String get homeScreenTitle => 'Add the app to your Home Screen';

  @override
  String get homeScreenBody =>
      'Tap Share (the square with an arrow), then “Add to Home Screen”. The app will open full screen and your data will be kept more reliably.';

  @override
  String get homeScreenDismiss => 'Got it';
}
