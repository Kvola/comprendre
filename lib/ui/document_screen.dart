import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../app/providers.dart';
import '../core/theme.dart';
import '../core/web_env.dart';
import '../data/database.dart';
import '../engine/quiz_model.dart';
import 'common.dart';
import 'create_quiz.dart';
import 'editor_screen.dart';
import 'quiz_screen.dart';
import 'text_view_screen.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.documentId, this.autoCreateQuiz = false});

  final int documentId;

  /// Juste après la saisie : le quiz est créé tout de suite.
  final bool autoCreateQuiz;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoCreateQuiz) WidgetsBinding.instance.addPostFrameCallback((_) => _create(another: false));
  }

  Future<void> _create({required bool another}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await createQuizFlow(context, ref, documentId: widget.documentId, another: another);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(Document doc) async {
    if (!kIsWeb) {
      await SharePlus.instance.share(ShareParams(text: doc.body, subject: doc.title));
      return;
    }
    // Navigateur : le partage du système quand il existe (téléphone), sinon le
    // texte est téléchargé (.txt) plutôt qu'envoyé dans un lien `mailto:` trop long.
    try {
      await SharePlus.instance.share(ShareParams(text: doc.body, subject: doc.title, mailToFallbackEnabled: false));
    } catch (_) {
      final name = doc.title.replaceAll(RegExp(r'[\\/:*?"<>|]+'), ' ').replaceAll(RegExp(r'[.\s]+$'), '').trim();
      downloadBytes(utf8.encode(doc.body), '${name.isEmpty ? 'texte' : name}.txt', 'text/plain;charset=utf-8');
    }
  }

  Future<void> _delete(Document doc) async {
    final l = context.l10n;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirm(context, title: l.deleteTextTitle, body: l.deleteTextBody, action: l.delete, destructive: true)) return;
    await ref.read(databaseProvider).deleteDocument(doc.id);
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.textDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final doc = ref.watch(documentProvider(widget.documentId)).value;
    final quizzes = ref.watch(quizzesProvider(widget.documentId)).value ?? const [];
    if (doc == null) return Scaffold(appBar: AppBar());
    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EditorScreen(documentId: doc.id, initialText: doc.body, initialTitle: doc.title, source: doc.source),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'share') _share(doc);
              if (v == 'delete') _delete(doc);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'share',
                child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(l.share)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: context.palette.wrong),
                  title: Text(l.delete),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TextViewScreen(documentId: doc.id))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.body, maxLines: 6, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(l.readText, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            '${langLabel(l, doc.lang)} · ${l.charsCount(doc.body.length)}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l.quizzesTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (quizzes.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l.noQuizYet))
          else
            for (final q in quizzes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuizTile(q, stale: q.quiz.isStale(doc.body)),
              ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: FilledButton.icon(
          onPressed: _busy ? null : () => _create(another: quizzes.isNotEmpty),
          icon: const Icon(Icons.quiz_outlined),
          label: Text(quizzes.isEmpty ? l.newQuiz : l.anotherQuiz),
        ),
      ),
    );
  }
}

class _QuizTile extends ConsumerWidget {
  const _QuizTile(this.summary, {required this.stale});

  final QuizSummary summary;

  /// Le texte a changé depuis ce quiz.
  final bool stale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final quiz = summary.quiz.quiz;
    final ai = quiz.engine == QuizEngine.ai;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(summary.quiz.createdAt);
    final total = quiz.questions.length;
    final progress = summary.quiz.progress;
    final theme = Theme.of(context);
    final lines = [
      if (summary.quiz.section case final s?) l.sectionLabel(s.label),
      if (progress != null && progress.answers.isNotEmpty) l.quizInProgress(progress.answers.length, progress.order.length),
      // Le meilleur score reste visible pendant un nouvel essai.
      if (summary.bestScore != null)
        l.bestScore(summary.bestScore!, total)
      else if (progress == null || progress.answers.isEmpty)
        l.notTried,
      date,
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
        leading: CircleAvatar(
          backgroundColor: ai ? scheme.tertiaryContainer : scheme.secondaryContainer,
          foregroundColor: ai ? scheme.onTertiaryContainer : scheme.onSecondaryContainer,
          child: Icon(ai ? Icons.auto_awesome : Icons.offline_bolt_outlined),
        ),
        title: Text('${ai ? l.engineAi : l.engineOffline} · ${l.questionsCount(total)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lines.join('\n')),
            if (stale)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(l.staleQuiz, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(quizId: summary.quiz.id))),
        trailing: IconButton(
          tooltip: l.delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            if (await confirm(context, title: l.deleteQuizTitle, action: l.delete, destructive: true)) {
              await ref.read(databaseProvider).deleteQuiz(summary.quiz.id);
            }
          },
        ),
      ),
    );
  }
}
