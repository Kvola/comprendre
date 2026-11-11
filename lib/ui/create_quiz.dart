/// Parcours « créer un quiz » : consentement IA (une fois), choix d'une partie
/// pour un long texte, attente avec possibilité de passer en hors ligne, puis
/// ouverture du quiz.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/quiz_service.dart';
import '../engine/sections.dart';
import '../remote/ai_client.dart';
import 'common.dart';
import 'quiz_screen.dart';

/// Demande (une fois) si l'utilisateur veut l'IA. Renvoie le choix, ou null s'il ferme la boîte.
Future<bool?> askAiConsent(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final quota = await ref.read(quotaProvider.future).timeout(const Duration(seconds: 4), onTimeout: () => null);
  if (!context.mounted) return null;
  final choice = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.auto_awesome),
      title: Text(l.aiConsentTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.aiConsentBody),
            if (quota != null && quota.daily > 0) ...[
              const SizedBox(height: 12),
              Text(l.aiFreePerDay(quota.daily), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.aiConsentNo)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.aiConsentYes)),
      ],
    ),
  );
  if (choice != null) await ref.read(databaseProvider).setSetting('ai', choice ? 'on' : 'off');
  return choice;
}

/// Choix « tout le texte » ou une partie. Renvoie `(partie ou null)` ; null si l'utilisateur ferme.
Future<(TextSection?,)?> chooseSection(BuildContext context, String body, {int? aiMaxChars}) {
  final l = context.l10n;
  final sections = splitSections(body);
  return showDialog<(TextSection?,)>(
    context: context,
    builder: (c) {
      final theme = Theme.of(c);
      Widget option(String title, String subtitle, (TextSection?,) value, {IconData icon = Icons.article_outlined}) => ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        onTap: () => Navigator.pop(c, value),
      );
      return AlertDialog(
        title: Text(l.chooseSectionTitle),
        contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8), child: Text(l.chooseSectionBody(body.length))),
              option(
                l.wholeText,
                aiMaxChars != null && body.length > aiMaxChars ? l.wholeTextTooLongForAi(aiMaxChars) : l.charsCount(body.length),
                (null,),
                icon: Icons.menu_book_outlined,
              ),
              const Divider(),
              for (final s in sections) option(s.label, l.charsCount(s.length), (s,)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel))],
      );
    },
  );
}

/// [replace] : le nouveau quiz remplace l'écran courant (« Un autre quiz » depuis un résultat).
/// [section] : la partie déjà choisie (« Un autre quiz » sur la même partie) ; sinon,
/// pour un long texte, l'utilisateur la choisit.
Future<void> createQuizFlow(
  BuildContext context,
  WidgetRef ref, {
  required int documentId,
  bool another = false,
  bool replace = false,
  TextSection? section,
}) async {
  final l = context.l10n;
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final db = ref.read(databaseProvider);
  final doc = await db.document(documentId);
  if (doc == null || !context.mounted) return;
  // Une partie choisie avant une modification du texte n'a plus de sens.
  if (section != null && section.end > doc.body.length) section = null;
  final settings = ref.read(settingsProvider).value;
  var aiMode = settings?.aiMode ?? 'ask';
  if (aiMode == 'ask') {
    final choice = await askAiConsent(context, ref);
    if (!context.mounted) return;
    aiMode = choice == true ? 'on' : 'off';
  }
  final count = settings?.questionCount ?? 10;

  // L'IA d'abord si permise : le quota (rapide) dit si le service est joignable,
  // s'il reste des quiz, la longueur et les langues acceptées.
  var useAi = aiMode == 'on';
  AiQuota? quota;
  Fallback? early;
  if (useAi) {
    _showProgress(context, l.creatingQuiz, l.creatingOffline, null);
    ref.invalidate(quotaProvider);
    quota = await ref.read(quotaProvider.future).timeout(const Duration(seconds: 8), onTimeout: () => null);
    nav.pop();
    early = switch (quota) {
      null => Fallback.network,
      AiQuota(enabled: false) => Fallback.disabled,
      AiQuota(limited: 'failures') => Fallback.failures,
      AiQuota(remaining: <= 0) => Fallback.quota,
      _ => null,
    };
    if (early != null) useAi = false;
  }
  if (!context.mounted) return;

  if (section == null && doc.body.length > sectionThreshold) {
    final choice = await chooseSection(context, doc.body, aiMaxChars: useAi ? quota?.maxChars : null);
    if (choice == null || !context.mounted) return;
    section = choice.$1;
  }
  final quizLength = section?.length ?? doc.body.length;
  final aiWillRun =
      useAi &&
      quizLength >= aiMinChars &&
      (quota?.languages.contains(doc.lang) ?? false) &&
      quizLength <= (quota?.maxChars ?? quizLength);

  final skip = Completer<void>();
  _showProgress(context, l.creatingQuiz, aiWillRun ? l.creatingAi : l.creatingOffline, aiWillRun ? skip : null);
  QuizOutcome? outcome;
  Object? error;
  try {
    final service = await ref.read(quizServiceProvider.future);
    outcome = await service.create(
      documentId: documentId,
      text: doc.body,
      lang: doc.lang,
      count: count,
      useAi: useAi,
      maxChars: quota?.maxChars,
      another: another,
      skipAi: skip.future,
      section: section,
      aiLanguages: quota?.languages ?? const {'fr', 'en'},
      early: early,
    );
  } catch (e) {
    error = e;
  } finally {
    nav.pop();
  }
  if (outcome == null) {
    final message = switch (error) {
      QuizTooShort() => l.quizTooShort,
      QuizLanguageUnsupported(why: null) => l.langNeedsAiOff,
      QuizLanguageUnsupported(:final why?, :final param) => l.langNeedsAiFailed(fallbackReason(l, why, param)),
      _ => l.whyOther,
    };
    messenger.showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 8)));
    return;
  }
  ref.invalidate(quotaProvider);
  final why = outcome.fallback;
  if (why != null && why != Fallback.cancelled) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.fallbackNotice(fallbackReason(l, why, outcome.param))), duration: const Duration(seconds: 6)),
    );
  }
  final route = MaterialPageRoute<void>(builder: (_) => QuizScreen(quizId: outcome!.quizId));
  replace ? nav.pushReplacement(route) : nav.push(route);
}

void _showProgress(BuildContext context, String title, String body, Completer<void>? skip) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const LinearProgressIndicator(), const SizedBox(height: 16), Text(body)],
        ),
        actions: [
          if (skip != null)
            TextButton(
              onPressed: () {
                if (!skip.isCompleted) skip.complete();
              },
              child: Text(c.l10n.useOfflineNow),
            ),
        ],
      ),
    ),
  );
}
