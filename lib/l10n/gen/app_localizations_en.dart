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
  String get summaryTitle => 'In short';

  @override
  String get creatingQuiz => 'Creating the quiz…';

  @override
  String get creatingAi =>
      'The AI is reading your text and preparing comprehension questions. This can take up to a minute.';

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
  String get quitQuizTitle => 'Leave the quiz?';

  @override
  String get quitQuizBody => 'Your answers to this quiz will not be saved.';

  @override
  String get quit => 'Leave';

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
}
