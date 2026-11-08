/// Parcours « créer un quiz » : consentement IA (une fois), attente avec
/// possibilité de passer en hors ligne, puis ouverture du quiz.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/quiz_service.dart';
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

/// [replace] : le nouveau quiz remplace l'écran courant (« Un autre quiz » depuis un résultat).
Future<void> createQuizFlow(
  BuildContext context,
  WidgetRef ref, {
  required int documentId,
  bool another = false,
  bool replace = false,
}) async {
  final l = context.l10n;
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final db = ref.read(databaseProvider);
  final doc = await db.document(documentId);
  if (doc == null || !context.mounted) return;
  var settings = ref.read(settingsProvider).value;
  var aiMode = settings?.aiMode ?? 'ask';
  if (aiMode == 'ask') {
    final choice = await askAiConsent(context, ref);
    if (!context.mounted) return;
    aiMode = choice == true ? 'on' : 'off';
  }
  final count = settings?.questionCount ?? 10;

  // L'IA d'abord si permise : le quota (rapide) dit si le service est joignable et s'il reste des quiz.
  var useAi = aiMode == 'on' && doc.body.length >= aiMinChars;
  AiQuota? quota;
  Fallback? early;
  if (useAi) {
    _showProgress(context, l.creatingQuiz, l.creatingOffline, null);
    ref.invalidate(quotaProvider);
    quota = await ref.read(quotaProvider.future).timeout(const Duration(seconds: 8), onTimeout: () => null);
    nav.pop();
    if (quota == null) {
      early = Fallback.network;
    } else if (!quota.enabled) {
      early = Fallback.disabled;
    } else if (quota.remaining <= 0) {
      early = Fallback.quota;
    }
    if (early != null) useAi = false;
  }
  if (!context.mounted) return;

  final skip = Completer<void>();
  _showProgress(context, l.creatingQuiz, useAi ? l.creatingAi : l.creatingOffline, useAi ? skip : null);
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
    );
  } catch (e) {
    error = e;
  } finally {
    nav.pop();
  }
  if (outcome == null) {
    messenger.showSnackBar(SnackBar(content: Text(error is QuizTooShort ? l.quizTooShort : l.whyOther)));
    return;
  }
  ref.invalidate(quotaProvider);
  final why = outcome.fallback ?? early;
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
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(body),
          ],
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
