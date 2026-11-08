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
    'summaryTitle': ('En bref', 'In short'),
    # Création du quiz
    'creatingQuiz': ('Création du quiz…', 'Creating the quiz…'),
    'creatingAi': ('L’IA lit votre texte et prépare des questions de compréhension. Cela peut prendre jusqu’à une minute.',
                   'The AI is reading your text and preparing comprehension questions. This can take up to a minute.'),
    'creatingOffline': ('Préparation des questions à partir du texte…', 'Preparing questions from the text…'),
    'useOfflineNow': ('Créer hors ligne maintenant', 'Create offline now'),
    'quizTooShort': ('Ce texte est trop court ou trop pauvre pour un quiz. Ajoutez quelques phrases complètes.',
                     'This text is too short or too thin for a quiz. Add a few complete sentences.'),
    'fallbackNotice': ('Quiz créé hors ligne : {reason}', 'Quiz created offline: {reason}'),
    'whyNetwork': ('pas de connexion au service IA.', 'no connection to the AI service.'),
    'whyQuota': ('quota IA du jour atteint.', 'today’s AI quota is used up.'),
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
    'quitQuizTitle': ('Quitter le quiz ?', 'Leave the quiz?'),
    'quitQuizBody': ('Vos réponses à ce quiz ne seront pas enregistrées.', 'Your answers to this quiz will not be saved.'),
    'quit': ('Quitter', 'Leave'),
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
}


def placeholders(text):
    names = []
    for m in re.finditer(r'\{([A-Za-z]\w*)(?:\}|,\s*plural)', text):
        if m.group(1) not in names and m.group(1) not in ('other',):
            names.append(m.group(1))
    return names


INT = ('count', 'done', 'total', 'score', 'index')


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
