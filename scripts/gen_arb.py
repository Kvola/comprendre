#!/usr/bin/env python3
"""Source unique des textes de l'interface -> lib/l10n/app_fr.arb et app_en.arb.

    python3 scripts/gen_arb.py && flutter gen-l10n
"""
import json
import pathlib
import re

S = {
    'appTitle': ('Comprendre', 'Understand'),
    'tagline': ('Un quiz pour comprendre n’importe quel texte', 'A quiz to understand any text'),
    # Commun
    'close': ('Fermer', 'Close'),
    'cancel': ('Annuler', 'Cancel'),
    'delete': ('Supprimer', 'Delete'),
    'save': ('Enregistrer', 'Save'),
    'edit': ('Modifier', 'Edit'),
    'share': ('Partager', 'Share'),
    'retry': ('Réessayer', 'Try again'),
    'continueLabel': ('Continuer', 'Continue'),
    'undo': ('Annuler', 'Undo'),
    'questionsCount': ('{count, plural, =1{1 question} other{{count} questions}}',
                       '{count, plural, =1{1 question} other{{count} questions}}'),
    'quizzesCount': ('{count, plural, =0{Aucun quiz} =1{1 quiz} other{{count} quiz}}',
                     '{count, plural, =0{No quiz yet} =1{1 quiz} other{{count} quizzes}}'),
    'charsCount': ('{count} caractères', '{count} characters'),
    # Bibliothèque
    'libraryTitle': ('Mes textes', 'My texts'),
    'emptyTitle': ('Comprenez ce que vous lisez', 'Understand what you read'),
    'emptyBody': ('Écrivez ou collez un texte, scannez une page ou importez un fichier (PDF, Word, PowerPoint…). '
                  'Comprendre en tire un quiz pour vérifier et approfondir votre compréhension.',
                  'Type or paste a text, scan a page or import a file (PDF, Word, PowerPoint…). '
                  'Understand turns it into a quiz to check and deepen your understanding.'),
    'newText': ('Nouveau texte', 'New text'),
    'sourceTyped': ('Écrire ou coller', 'Type or paste'),
    'sourceTypedHint': ('Saisissez le texte, ou collez-le', 'Type the text, or paste it'),
    'sourceScan': ('Scanner un document', 'Scan a document'),
    'sourceScanHint': ('Une ou plusieurs pages, avec l’appareil photo', 'One or more pages, with the camera'),
    'sourcePhoto': ('Texte d’une photo', 'Text from a photo'),
    'sourcePhotoHint': ('Une image de votre galerie', 'A picture from your gallery'),
    'sourceFile': ('Importer un fichier', 'Import a file'),
    'sourceFileHint': ('PDF, Word, PowerPoint, OpenDocument, EPUB, texte…', 'PDF, Word, PowerPoint, OpenDocument, EPUB, text…'),
    'deleteTextTitle': ('Supprimer ce texte ?', 'Delete this text?'),
    'deleteTextBody': ('Le texte et ses quiz seront supprimés de ce téléphone.', 'The text and its quizzes will be removed from this phone.'),
    'textDeleted': ('Texte supprimé', 'Text deleted'),
    # Saisie / aperçu
    'editorTitle': ('Votre texte', 'Your text'),
    'titleLabel': ('Titre (facultatif)', 'Title (optional)'),
    'textLabel': ('Texte', 'Text'),
    'textHint': ('Collez ou écrivez ici le texte à comprendre…', 'Paste or type the text to understand here…'),
    'paste': ('Coller', 'Paste'),
    'clipboardEmpty': ('Le presse-papiers ne contient pas de texte.', 'The clipboard has no text.'),
    'reviewExtracted': ('Vérifiez le texte : vous pouvez le corriger ou en retirer des parties avant de créer le quiz.',
                        'Check the text: you can correct it or remove parts before creating the quiz.'),
    'textTooShort': ('Ajoutez un peu de texte : {count} caractères au moins.', 'Add a bit more text: at least {count} characters.'),
    'languageOfText': ('Langue du texte', 'Language of the text'),
    'langFr': ('Français', 'French'),
    'langEn': ('Anglais', 'English'),
    'langEs': ('Espagnol', 'Spanish'),
    'langPt': ('Portugais', 'Portuguese'),
    'langDe': ('Allemand', 'German'),
    'langIt': ('Italien', 'Italian'),
    'langNeedsAiNote': ('Hors ligne, les quiz ne se font qu’en français et en anglais : pour un texte dans cette langue, '
                        'l’IA (avec une connexion) est nécessaire.',
                        'Offline, quizzes are only made in French and English: for a text in this language, '
                        'the AI (with a connection) is needed.'),
    'createQuiz': ('Créer le quiz', 'Create the quiz'),
    'saveText': ('Enregistrer le texte', 'Save the text'),
    'discardTitle': ('Abandonner ce texte ?', 'Discard this text?'),
    'discardBody': ('Ce que vous avez saisi sera perdu.', 'What you typed will be lost.'),
    'discard': ('Abandonner', 'Discard'),
    # Import / OCR
    'reading': ('Lecture du fichier…', 'Reading the file…'),
    'readingPages': ('Lecture : page {done} sur {total}', 'Reading: page {done} of {total}'),
    'recognizing': ('Reconnaissance du texte…', 'Recognising the text…'),
    'errUnsupported': ('Ce type de fichier n’est pas pris en charge.', 'This type of file is not supported.'),
    'errLegacyOffice': ('Ancien format Office (.doc, .ppt) : enregistrez-le en .docx, .pptx ou PDF, puis importez-le.',
                        'Old Office format (.doc, .ppt): save it as .docx, .pptx or PDF, then import it.'),
    'errEmpty': ('Aucun texte n’a été trouvé dans ce document.', 'No text was found in this document.'),
    'errCorrupt': ('Ce fichier est illisible ou endommagé.', 'This file is unreadable or damaged.'),
    'errEncrypted': ('Ce fichier est protégé par un mot de passe.', 'This file is password-protected.'),
    'errTooLarge': ('Ce fichier est trop volumineux (40 Mo au plus).', 'This file is too large (40 MB max).'),
    'errOcr': ('La reconnaissance du texte a échoué. Essayez une photo plus nette et bien éclairée.',
               'Text recognition failed. Try a sharper, well-lit picture.'),
    'errNoTextInImage': ('Aucun texte n’a été reconnu sur cette image.', 'No text was recognised in this picture.'),
    'errScanner': ('Le scanner de documents n’est pas disponible sur cet appareil.', 'The document scanner is not available on this device.'),
    # Document
    'readText': ('Lire le texte', 'Read the text'),
    'hideText': ('Masquer le texte', 'Hide the text'),
    'quizzesTitle': ('Quiz', 'Quizzes'),
    'noQuizYet': ('Pas encore de quiz pour ce texte.', 'No quiz for this text yet.'),
    'newQuiz': ('Nouveau quiz', 'New quiz'),
    'anotherQuiz': ('Un autre quiz', 'Another quiz'),
    'bestScore': ('Meilleur score : {score}/{total}', 'Best score: {score}/{total}'),
    'notTried': ('Pas encore fait', 'Not taken yet'),
    'engineAi': ('Quiz IA', 'AI quiz'),
    'engineOffline': ('Quiz hors ligne', 'Offline quiz'),
    'deleteQuizTitle': ('Supprimer ce quiz ?', 'Delete this quiz?'),
    'staleQuiz': ('Le texte a été modifié depuis ce quiz', 'The text has changed since this quiz'),
    'quizInProgress': ('En cours : {done} réponse(s) sur {total}', 'In progress: {done} of {total} answered'),
    'quoteNotFound': ('Ce passage n’est plus dans le texte : le texte a été modifié depuis ce quiz.',
                      'This passage is no longer in the text: the text has changed since this quiz.'),
    'summaryTitle': ('En bref', 'In short'),
    # Création du quiz
    'creatingQuiz': ('Création du quiz…', 'Creating the quiz…'),
    'creatingAi': ('L’IA lit votre texte et prépare des questions de compréhension. Cela peut prendre une à deux minutes.',
                   'The AI is reading your text and preparing comprehension questions. This can take one or two minutes.'),
    'creatingOffline': ('Préparation des questions à partir du texte…', 'Preparing questions from the text…'),
    'useOfflineNow': ('Créer hors ligne maintenant', 'Create offline now'),
    'quizTooShort': ('Ce texte est trop court ou trop pauvre pour un quiz. Ajoutez quelques phrases complètes.',
                     'This text is too short or too thin for a quiz. Add a few complete sentences.'),
    'fallbackNotice': ('Quiz créé hors ligne : {reason}', 'Quiz created offline: {reason}'),
    'whyNetwork': ('pas de connexion au service IA.', 'no connection to the AI service.'),
    'whyQuota': ('quota IA du jour atteint.', 'today’s AI quota is used up.'),
    'whyFailures': ('l’IA a échoué plusieurs fois aujourd’hui sur vos textes ; elle sera de nouveau disponible demain.',
                    'the AI failed several times today on your texts; it will be available again tomorrow.'),
    'whyLanguage': ('le service IA ne gère pas encore cette langue.', 'the AI service does not handle this language yet.'),
    'langNeedsAiOff': ('Hors ligne, les quiz ne se font qu’en français et en anglais. Pour ce texte, activez l’IA dans les réglages.',
                       'Offline, quizzes are only made in French and English. For this text, turn on the AI in the settings.'),
    'langNeedsAiFailed': ('Hors ligne, les quiz ne se font qu’en français et en anglais, et l’IA n’a pas pu créer ce quiz : {reason}',
                          'Offline, quizzes are only made in French and English, and the AI could not create this quiz: {reason}'),
    # Parties d'un long texte
    'chooseSectionTitle': ('Quiz sur quelle partie ?', 'Quiz on which part?'),
    'chooseSectionBody': ('Ce texte est long ({count} caractères) : un quiz sur une partie est plus utile.',
                          'This text is long ({count} characters): a quiz on one part is more useful.'),
    'wholeText': ('Tout le texte', 'The whole text'),
    'wholeTextTooLongForAi': ('Trop long pour l’IA ({count} caractères au plus) : quiz hors ligne',
                              'Too long for the AI ({count} characters max): offline quiz'),
    'sectionLabel': ('Partie : {label}', 'Part: {label}'),
    'whyTooLong': ('texte trop long pour l’IA ({count} caractères au plus).', 'text too long for the AI ({count} characters max).'),
    'whyBusy': ('le service IA est très demandé, réessayez plus tard.', 'the AI service is busy, try again later.'),
    'whyUnavailable': ('le service IA est momentanément indisponible.', 'the AI service is temporarily unavailable.'),
    'whyRateLimited': ('trop de demandes, réessayez dans {count} min.', 'too many requests, try again in {count} min.'),
    'whyDisabled': ('le service IA est désactivé.', 'the AI service is turned off.'),
    'whyUnverified': ('les questions de l’IA n’ont pas pu être vérifiées dans le texte.', 'the AI questions could not be checked against the text.'),
    'whyRefusedContent': ('l’IA ne peut pas traiter ce texte.', 'the AI cannot process this text.'),
    'whyOther': ('le service IA n’a pas répondu correctement.', 'the AI service did not respond properly.'),
    'whyCancelled': ('vous avez choisi de ne pas attendre.', 'you chose not to wait.'),
    # Consentement IA
    'aiConsentTitle': ('Utiliser l’IA ?', 'Use the AI?'),
    'aiConsentBody': ('Avec une connexion Internet, Comprendre peut demander à une IA (Claude, d’Anthropic) des questions plus riches : '
                      'idée principale, causes et conséquences, sens des mots, déductions.\n\n'
                      'Pour cela, le texte est envoyé à notre serveur puis à l’IA, seulement pour créer le quiz : il n’est pas conservé. '
                      'Aucun compte, aucune donnée personnelle.\n\n'
                      'Sans IA, le quiz est créé sur votre téléphone, sans rien envoyer.',
                      'With an Internet connection, Understand can ask an AI (Claude, by Anthropic) for richer questions: '
                      'main idea, causes and consequences, word meaning, inferences.\n\n'
                      'To do so, the text is sent to our server and then to the AI, only to create the quiz: it is not kept. '
                      'No account, no personal data.\n\n'
                      'Without the AI, the quiz is created on your phone, without sending anything.'),
    'aiConsentYes': ('Utiliser l’IA', 'Use the AI'),
    'aiConsentNo': ('Rester hors ligne', 'Stay offline'),
    'aiFreePerDay': ('{count, plural, =1{1 quiz IA gratuit par jour} other{{count} quiz IA gratuits par jour}}',
                     '{count, plural, =1{1 free AI quiz per day} other{{count} free AI quizzes per day}}'),
    # Quiz
    'questionOf': ('Question {index} sur {total}', 'Question {index} of {total}'),
    'trueLabel': ('Vrai', 'True'),
    'falseLabel': ('Faux', 'False'),
    'correct': ('Bonne réponse', 'Correct'),
    'incorrect': ('Pas tout à fait', 'Not quite'),
    'theAnswerWas': ('La bonne réponse : {answer}', 'The right answer: {answer}'),
    'inTheText': ('Dans le texte', 'In the text'),
    'showInText': ('Voir dans le texte', 'Show in the text'),
    'next': ('Suivante', 'Next'),
    'seeResults': ('Voir le résultat', 'See the result'),
    'progressResumed': ('Reprise là où vous en étiez.', 'Picking up where you left off.'),
    'reviewMistakesTitle': ('Mes erreurs', 'My mistakes'),
    'mistakeOf': ('Erreur {index} sur {total}', 'Mistake {index} of {total}'),
    'skillMainIdea': ('Idée principale', 'Main idea'),
    'skillDetail': ('Détail', 'Detail'),
    'skillVocabulary': ('Vocabulaire', 'Vocabulary'),
    'skillInference': ('Déduction', 'Inference'),
    'skillStructure': ('Structure', 'Structure'),
    'skillCause': ('Cause et effet', 'Cause and effect'),
    # Résultat
    'resultTitle': ('Résultat', 'Result'),
    'scoreOutOf': ('{score} sur {total}', '{score} out of {total}'),
    'resultGreat': ('Excellent : vous avez bien compris ce texte.', 'Excellent: you understood this text well.'),
    'resultGood': ('Bien : relisez les passages des questions manquées.', 'Good: reread the passages of the missed questions.'),
    'resultLow': ('Relisez le texte tranquillement, puis réessayez : chaque explication renvoie au passage.',
                  'Reread the text calmly, then try again: each explanation points to the passage.'),
    'reviewAnswers': ('Revoir les réponses', 'Review the answers'),
    'yourAnswer': ('Votre réponse : {answer}', 'Your answer: {answer}'),
    'tryAgain': ('Refaire ce quiz', 'Take this quiz again'),
    'retryMistakes': ('Revoir mes erreurs', 'Retry my mistakes'),
    'mistakesResult': ('Erreurs revues : {score} sur {total} maintenant justes', 'Mistakes reviewed: {score} of {total} now right'),
    'mistakesResultHint': ('Ce tour ne change pas votre meilleur score : refaites tout le quiz pour cela.',
                           'This round does not change your best score: take the whole quiz again for that.'),
    'backToText': ('Retour au texte', 'Back to the text'),
    # Réglages
    'settings': ('Réglages', 'Settings'),
    'appLanguage': ('Langue de l’application', 'App language'),
    'systemDefault': ('Langue du téléphone', 'Phone language'),
    'theme': ('Thème', 'Theme'),
    'themeSystem': ('Automatique', 'Automatic'),
    'themeLight': ('Clair', 'Light'),
    'themeDark': ('Sombre', 'Dark'),
    'questionsPerQuiz': ('Questions par quiz', 'Questions per quiz'),
    'aiSection': ('Quiz IA', 'AI quizzes'),
    'aiUse': ('Utiliser l’IA quand c’est possible', 'Use the AI when possible'),
    'aiUseHint': ('Le texte est envoyé à l’IA pour créer le quiz, puis oublié. Sinon, tout reste sur le téléphone.',
                  'The text is sent to the AI to create the quiz, then forgotten. Otherwise, everything stays on the phone.'),
    'aiRemaining': ('{count, plural, =0{Plus de quiz IA aujourd’hui} =1{Encore 1 quiz IA aujourd’hui} other{Encore {count} quiz IA aujourd’hui}}',
                    '{count, plural, =0{No AI quiz left today} =1{1 AI quiz left today} other{{count} AI quizzes left today}}'),
    'aiQuotaUnknown': ('Quota IA : connexion nécessaire', 'AI quota: connection needed'),
    # Codes IA
    'aiRemainingDetail': ('{free} du quota gratuit + {codes} avec vos codes IA', '{free} from the free quota + {codes} from your AI codes'),
    'aiCodeEnter': ('J’ai un code IA', 'I have an AI code'),
    'aiCodeEnterHint': ('Un code reçu de votre école, de votre entreprise ou d’un partenaire, pour plus de quiz IA.',
                        'A code from your school, company or a partner, for more AI quizzes.'),
    'aiCodeDialogTitle': ('Code IA', 'AI code'),
    'aiCodeDialogBody': ('Saisissez le code tel qu’il vous a été donné (majuscules, espaces et tirets ne comptent pas). '
                         'Il sera lié à ce téléphone.',
                         'Type the code as you received it (capitals, spaces and dashes do not matter). '
                         'It will be linked to this phone.'),
    'aiCodeField': ('Code', 'Code'),
    'aiCodeActivate': ('Activer', 'Activate'),
    'aiCodeActivated': ('{count, plural, =1{Code activé : 1 quiz IA disponible.} other{Code activé : {count} quiz IA disponibles.}}',
                        '{count, plural, =1{Code activated: 1 AI quiz available.} other{Code activated: {count} AI quizzes available.}}'),
    'aiCodeActivatedAiOn': ('L’IA est activée pour vos quiz.', 'The AI is now on for your quizzes.'),
    'aiCodeTitle': ('Code {code}', 'Code {code}'),
    'aiCodeLeft': ('{count, plural, =0{Plus de quiz IA sur ce code} =1{1 quiz IA restant} other{{count} quiz IA restants}}',
                   '{count, plural, =0{No AI quiz left on this code} =1{1 AI quiz left} other{{count} AI quizzes left}}'),
    'aiCodeUntil': ('jusqu’au {date}', 'until {date}'),
    'aiCodeExpired': ('expiré', 'expired'),
    'aiCodeDailyDone': ('plafond du jour atteint', 'daily limit reached'),
    'aiCodeErrUnknown': ('Ce code IA n’existe pas. Vérifiez-le.', 'This AI code does not exist. Check it.'),
    'aiCodeErrDisabled': ('Ce code IA a été désactivé.', 'This AI code has been turned off.'),
    'aiCodeErrExpired': ('Ce code IA a expiré.', 'This AI code has expired.'),
    'aiCodeErrExhausted': ('Tous les quiz IA de ce code ont déjà été utilisés.', 'All the AI quizzes of this code have been used.'),
    'aiCodeErrTaken': ('Ce code IA est déjà utilisé sur un autre téléphone et ne peut plus être transféré. Demandez à la '
                       'personne qui vous l’a donné de libérer le code.',
                       'This AI code is already used on another phone and can no longer be moved. Ask the person who gave '
                       'it to you to release the code.'),
    'aiCodeErrFull': ('Ce code IA est déjà utilisé sur tous les téléphones prévus. Demandez à la personne qui vous l’a donné.',
                      'This AI code is already used on all the phones it allows. Ask the person who gave it to you.'),
    'aiCodeErrRate': ('Trop d’essais : réessayez dans {count} min.', 'Too many attempts: try again in {count} min.'),
    'aiCodeErrNetwork': ('Pas de connexion au service : réessayez quand vous serez connecté.',
                         'No connection to the service: try again when you are online.'),
    'aiCodeErrOther': ('Le code n’a pas pu être activé. Réessayez plus tard.', 'The code could not be activated. Try again later.'),
    # Mes codes IA (1.5)
    'aiCodePaste': ('Coller', 'Paste'),
    'aiCodePasteEmpty': ('Aucun code dans le presse-papiers.', 'No code on the clipboard.'),
    'aiCodeAlready': ('Ce code est déjà sur ce téléphone.', 'This code is already on this phone.'),
    'aiCodeTransferTitle': ('Transférer ce code ici ?', 'Move this code here?'),
    'aiCodeTransferBody': ('{count, plural, =1{Ce code IA est utilisé sur un autre téléphone. Si c’est le vôtre (changement de '
                           'téléphone), transférez-le : l’autre téléphone ne pourra plus s’en servir. C’est le dernier '
                           'transfert permis.} other{Ce code IA est utilisé sur un autre téléphone. Si c’est le vôtre '
                           '(changement de téléphone), transférez-le : l’autre téléphone ne pourra plus s’en servir. '
                           'Encore {count} transferts permis.}}',
                           '{count, plural, =1{This AI code is used on another phone. If it is yours (new phone), move it: '
                           'the other phone will no longer be able to use it. This is the last move allowed.} other{This AI '
                           'code is used on another phone. If it is yours (new phone), move it: the other phone will no '
                           'longer be able to use it. {count} moves left.}}'),
    'aiCodeTransferAction': ('Transférer', 'Move it'),
    'aiCodeTransferred': ('Code transféré sur ce téléphone.', 'Code moved to this phone.'),
    'myCodes': ('Mes codes IA', 'My AI codes'),
    'myCodesBuy': ('Acheter', 'Buy'),
    'myCodesNone': ('Aucun code IA sur ce téléphone', 'No AI code on this phone'),
    'myCodesSummary': ('{codes, plural, =1{1 code} other{{codes} codes}} · {count, plural, =0{plus de quiz IA} =1{1 quiz IA restant} other{{count} quiz IA restants}}',
                       '{codes, plural, =1{1 code} other{{codes} codes}} · {count, plural, =0{no AI quiz left} =1{1 AI quiz left} other{{count} AI quizzes left}}'),
    'myCodesExpireSoon': ('{count, plural, =1{1 quiz IA expire {when}} other{{count} quiz IA expirent {when}}}',
                          '{count, plural, =1{1 AI quiz expires {when}} other{{count} AI quizzes expire {when}}}'),
    'whenToday': ('aujourd’hui', 'today'),
    'whenTomorrow': ('demain', 'tomorrow'),
    'whenInDays': ('dans {count} jours', 'in {count} days'),
    'whenOnDate': ('le {date}', 'on {date}'),
    'myCodesIntro': ('Vos codes servent quand le quota gratuit du jour est épuisé, en commençant par celui qui expire le premier.',
                     'Your codes are used once the free daily quota is used up, starting with the one that expires first.'),
    'myCodesEmptyBody': ('Un code IA vous donne des quiz IA en plus du quota gratuit. Vous pouvez en recevoir un (école, '
                         'entreprise, partenaire) ou en acheter.',
                         'An AI code gives you AI quizzes on top of the free quota. You can receive one (school, company, '
                         'partner) or buy one.'),
    'myCodesToday': ('Aujourd’hui', 'Today'),
    'myCodesEnded': ('Terminés', 'Finished'),
    'myCodesOffline': ('Hors connexion : état au {date}.', 'Offline: status as of {date}.'),
    'myCodesOfflineNone': ('Connexion nécessaire pour voir vos codes IA.', 'A connection is needed to see your AI codes.'),
    'codeUsedOf': ('{used} utilisés sur {total}', '{used} used out of {total}'),
    'codeExpiresWhen': ('Expire {when}', 'Expires {when}'),
    'codeNoExpiry': ('Sans date limite', 'No end date'),
    'codeDailyLimit': ('{count} par jour au plus', 'at most {count} a day'),
    'codeDailyLeft': ('{count, plural, =0{plus rien aujourd’hui} =1{encore 1 aujourd’hui} other{encore {count} aujourd’hui}}',
                      '{count, plural, =0{none left today} =1{1 more today} other{{count} more today}}'),
    'codeShared': ('Partagé : {count} téléphones au plus · {mine} par vous', 'Shared: up to {count} phones · {mine} by you'),
    'codeBought': ('Acheté', 'Bought'),
    'codeGift': ('Reçu', 'Received'),
    'codeStateExhausted': ('Épuisé', 'Used up'),
    'codeStateExpired': ('Expiré', 'Expired'),
    'codeStateDisabled': ('Désactivé', 'Turned off'),
    'codeLastUsed': ('Dernier quiz IA : {date}', 'Last AI quiz: {date}'),
    'codeCopy': ('Copier le code', 'Copy the code'),
    'codeCopied': ('Code copié.', 'Code copied.'),
    'codeRemove': ('Retirer de ce téléphone', 'Remove from this phone'),
    'codeRemoveTitle': ('Retirer ce code ?', 'Remove this code?'),
    'codeRemoveBody': ('{count, plural, =0{Le code disparaît de ce téléphone.} =1{Le code disparaît de ce téléphone ; le quiz '
                       'IA restant reste sur le code : vous pouvez le donner à quelqu’un, qui le saisira sur son téléphone.} '
                       'other{Le code disparaît de ce téléphone ; les {count} quiz IA restants restent sur le code : vous '
                       'pouvez le donner à quelqu’un, qui le saisira sur son téléphone.}}',
                       '{count, plural, =0{The code disappears from this phone.} =1{The code disappears from this phone; '
                       'the remaining AI quiz stays on the code: you can give it to someone, who will enter it on their '
                       'phone.} other{The code disappears from this phone; the {count} remaining AI quizzes stay on the '
                       'code: you can give it to someone, who will enter it on their phone.}}'),
    'codeRemoved': ('Code retiré de ce téléphone.', 'Code removed from this phone.'),
    'codeRemoveFailed': ('Le code n’a pas pu être retiré. Réessayez quand vous serez connecté.',
                         'The code could not be removed. Try again when you are online.'),
    # Achat de quiz IA (Wave)
    'shopEntry': ('Acheter des quiz IA', 'Buy AI quizzes'),
    'shopEntryHint': ('Payez avec Wave : les quiz IA sont ajoutés à ce téléphone.', 'Pay with Wave: the AI quizzes are added to this phone.'),
    'shopTitle': ('Acheter des quiz IA', 'Buy AI quizzes'),
    'shopIntro': ('Choisissez une offre et payez avec Wave. Dès que le paiement est confirmé, vos quiz IA sont ajoutés à '
                  'ce téléphone, sans code à saisir.',
                  'Choose an offer and pay with Wave. As soon as the payment is confirmed, your AI quizzes are added to '
                  'this phone, with no code to type.'),
    'shopNoOffer': ('Aucune offre n’est proposée pour le moment.', 'No offer is available at the moment.'),
    'shopOffline': ('Connexion nécessaire pour voir les offres.', 'A connection is needed to see the offers.'),
    'shopCredits': ('{count, plural, =1{1 quiz IA} other{{count} quiz IA}}', '{count, plural, =1{1 AI quiz} other{{count} AI quizzes}}'),
    'shopValidity': ('{count, plural, =1{valable 1 jour} other{valables {count} jours}}', '{count, plural, =1{valid 1 day} other{valid {count} days}}'),
    'shopNoExpiry': ('sans limite de durée', 'no time limit'),
    'shopDailyLimit': ('{count} par jour au plus', 'at most {count} a day'),
    'shopBuy': ('Payer avec Wave', 'Pay with Wave'),
    'shopConfirmTitle': ('Payer avec Wave ?', 'Pay with Wave?'),
    'shopConfirmBody': ('{pack} : {credits}, pour {price}. L’application Wave va s’ouvrir pour le paiement.',
                        '{pack}: {credits}, for {price}. The Wave app will open for the payment.'),
    'shopOpenFailed': ('Wave n’a pas pu s’ouvrir. Ouvrez ce lien pour payer :', 'Wave could not be opened. Open this link to pay:'),
    'shopCopyLink': ('Copier le lien', 'Copy the link'),
    'shopLinkCopied': ('Lien copié.', 'Link copied.'),
    'shopMyOrders': ('Mes achats', 'My purchases'),
    'shopOrderPending': ('Paiement en attente', 'Payment pending'),
    'shopOrderDone': ('Payé : quiz IA ajoutés', 'Paid: AI quizzes added'),
    'shopOrderRef': ('Achat {ref}', 'Purchase {ref}'),
    'shopWaitAuto': ('Wave confirme le paiement en quelques instants ; vos quiz IA sont alors ajoutés automatiquement.',
                     'Wave confirms the payment within moments; your AI quizzes are then added automatically.'),
    'shopWaitAgent': ('Après votre paiement Wave, notre équipe le confirme (en général dans la journée). Vos quiz IA sont alors '
                      'ajoutés automatiquement.',
                      'After your Wave payment, our team confirms it (usually the same day). Your AI quizzes are then '
                      'added automatically.'),
    'shopWaveRefLabel': ('ID de la transaction Wave (facultatif)', 'Wave transaction ID (optional)'),
    'shopWaveRefHint': ('Dans Wave : touchez le paiement, puis copiez son identifiant. Il aide à retrouver votre paiement.',
                        'In Wave: tap the payment, then copy its ID. It helps find your payment.'),
    'shopWaveRefSend': ('Envoyer', 'Send'),
    'shopWaveRefSent': ('Identifiant envoyé : {ref}', 'ID sent: {ref}'),
    'shopPayAgain': ('Ouvrir Wave', 'Open Wave'),
    'shopCheck': ('Vérifier', 'Check'),
    'shopConfirmed': ('{count, plural, =1{Paiement confirmé : 1 quiz IA ajouté.} other{Paiement confirmé : {count} quiz IA ajoutés.}}',
                      '{count, plural, =1{Payment confirmed: 1 AI quiz added.} other{Payment confirmed: {count} AI quizzes added.}}'),
    # Tarifs (1.6)
    'shopPerQuiz': ('soit {price} le quiz', 'that is {price} per quiz'),
    'shopSaving': ('−{count} % par quiz', '−{count}% per quiz'),
    'shopBestValue': ('Meilleur prix', 'Best price'),
    'shopPopular': ('Le plus choisi', 'Most popular'),
    'shopRecommended': ('Conseillé pour vous', 'Recommended for you'),
    'shopAdviceNeed': ('{count, plural, =1{Ces 30 derniers jours, vous avez voulu 1 quiz IA de plus que le quota gratuit.} '
                       'other{Ces 30 derniers jours, vous avez voulu {count} quiz IA de plus que le quota gratuit.}} '
                       'Conseil : {pack}, de quoi tenir environ 3 mois sans quiz perdus.',
                       '{count, plural, =1{Over the last 30 days, you wanted 1 AI quiz more than the free quota.} '
                       'other{Over the last 30 days, you wanted {count} AI quizzes more than the free quota.}} '
                       'Our advice: {pack}, enough for about 3 months with no quiz wasted.'),
    'shopAdviceFree': ('{count, plural, =1{Ces 30 derniers jours, votre quiz IA gratuit par jour a suffi.} other{Ces 30 '
                       'derniers jours, vos {count} quiz IA gratuits par jour ont suffi.}} Un achat ne sert que les jours où '
                       'vous en voulez plus : les quiz gratuits passent toujours en premier.',
                       '{count, plural, =1{Over the last 30 days, your free AI quiz per day was enough.} other{Over the last '
                       '30 days, your {count} free AI quizzes per day were enough.}} A purchase only helps on days when you '
                       'want more: free quizzes are always used first.'),
    'shopErrUnavailable': ('Cette offre n’est plus proposée.', 'This offer is no longer available.'),
    'shopErrPayment': ('Le paiement n’est pas disponible pour le moment. Réessayez plus tard.',
                       'Payment is not available at the moment. Try again later.'),
    'shopErrRefShort': ('Cet identifiant est trop court.', 'This ID is too short.'),
    'shopErrRefUsed': ('Cet identifiant a déjà été donné pour un autre paiement.', 'This ID was already given for another payment.'),
    'backupSection': ('Sauvegarde', 'Backup'),
    'backupExport': ('Sauvegarder ma bibliothèque', 'Back up my library'),
    'backupExportHint': ('Un fichier avec vos textes, quiz et résultats, à garder ou à transférer sur un autre téléphone.',
                         'A file with your texts, quizzes and results, to keep or move to another phone.'),
    'backupImport': ('Restaurer une sauvegarde', 'Restore a backup'),
    'backupImportHint': ('Ajoute les textes du fichier ; ceux déjà présents ne sont pas dupliqués.',
                         'Adds the texts from the file; those already here are not duplicated.'),
    'backupSaved': ('Sauvegarde enregistrée.', 'Backup saved.'),
    'backupEmpty': ('Votre bibliothèque est vide : rien à sauvegarder.', 'Your library is empty: nothing to back up.'),
    'backupFailed': ('La sauvegarde n’a pas pu être enregistrée.', 'The backup could not be saved.'),
    'restoreDone': ('Restauration : {added} texte(s) ajouté(s), {skipped} déjà présent(s).',
                    'Restore: {added} text(s) added, {skipped} already here.'),
    'backupInvalid': ('Ce fichier n’est pas une sauvegarde de Comprendre.', 'This file is not an Understand backup.'),
    'backupNewer': ('Cette sauvegarde vient d’une version plus récente de Comprendre : mettez l’application à jour.',
                    'This backup comes from a newer version of Understand: update the app.'),
    'about': ('À propos', 'About'),
    'aboutBody': ('Comprendre vous aide à comprendre un texte en vous posant des questions dessus. '
                  'Chaque réponse est justifiée par un passage du texte.',
                  'Understand helps you understand a text by asking you questions about it. '
                  'Every answer is backed by a passage of the text.'),
    'privacyTitle': ('Confidentialité', 'Privacy'),
    'privacyBody': ('Vos textes et vos résultats restent sur ce téléphone. Pour un quiz IA, le texte est envoyé de façon chiffrée '
                    'à notre serveur et à l’IA (Claude, d’Anthropic), qui ne le conservent pas. Un identifiant aléatoire, '
                    'sans lien avec vous, sert seulement à compter le quota gratuit.',
                    'Your texts and results stay on this phone. For an AI quiz, the text is sent encrypted to our server '
                    'and to the AI (Claude, by Anthropic), which do not keep it. A random identifier, unrelated to you, '
                    'is used only to count the free quota.'),
    'version': ('Version {version}', 'Version {version}'),
    # Mise à jour de l'application, version web (ajoutés directement dans les .arb jusqu'à la 1.1.0)
    'emptyBodyWeb': ("Écrivez ou collez un texte, ou importez un fichier (PDF, Word, PowerPoint…). Comprendre en tire un quiz pour vérifier et approfondir votre compréhension.", "Type or paste a text, or import a file (PDF, Word, PowerPoint…). Understand turns it into a quiz to check and deepen your understanding."),
    'updateAvailable': ("Version {version} disponible", "Version {version} available"),
    'updateRequired': ("Mise à jour obligatoire : version {version}", "Update required: version {version}"),
    'updateRequiredHint': ("Cette version n’est plus prise en charge : installez la nouvelle pour continuer.", "This version is no longer supported: install the new one to continue."),
    'updateDownload': ("Télécharger", "Download"),
    'updateLater': ("Plus tard", "Later"),
    'webInstallTitle': ("Installez l’application Android", "Install the Android app"),
    'webInstallBody': ("Plus fluide au quotidien, et vos données ne dépendent plus du navigateur.", "Smoother every day, and your data no longer depends on the browser."),
    'webInstallAction': ("Installer", "Install"),
    'homeScreenTitle': ("Ajoutez l’application à l’écran d’accueil", "Add the app to your Home Screen"),
    'homeScreenBody': ("Touchez Partager (le carré avec une flèche), puis « Sur l’écran d’accueil ». L’application s’ouvrira en plein écran et vos données seront mieux conservées.", "Tap Share (the square with an arrow), then “Add to Home Screen”. The app will open full screen and your data will be kept more reliably."),
    'homeScreenDismiss': ("Compris", "Got it"),
}


def placeholders(text):
    names = []
    for m in re.finditer(r'\{([A-Za-z]\w*)(?:\}|,\s*plural)', text):
        if m.group(1) not in names and m.group(1) not in ('other',):
            names.append(m.group(1))
    return names


INT = ('count', 'done', 'total', 'score', 'index', 'added', 'skipped', 'free', 'codes', 'used', 'mine')


def build(index):
    arb = {'@@locale': ('fr', 'en')[index]}
    for key, pair in S.items():
        arb[key] = pair[index]
        ph = placeholders(pair[0])
        if ph:
            arb[f'@{key}'] = {'placeholders': {p: {'type': 'int'} if p in INT else {'type': 'String'} for p in ph}}
    return arb


def main():
    out = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
    out.mkdir(parents=True, exist_ok=True)
    for key, (fr, en) in S.items():
        if set(placeholders(fr)) != set(placeholders(en)):
            raise SystemExit(f'Paramètres différents pour {key}')
    for i, lang in enumerate(('fr', 'en')):
        (out / f'app_{lang}.arb').write_text(json.dumps(build(i), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'{len(S)} textes écrits dans {out}')


if __name__ == '__main__':
    main()
