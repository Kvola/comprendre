import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/theme.dart';
import '../data/database.dart';
import '../engine/quiz_model.dart';
import '../engine/text_tools.dart';
import 'common.dart';
import 'create_quiz.dart';
import 'text_view_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.quizId});

  final int quizId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  StoredQuiz? _stored;

  /// Questions de ce tour (indices dans le quiz), dans l'ordre où elles sont posées.
  List<int> _order = const [];
  int _index = 0;
  final _answers = <int>[]; // réponse choisie pour chaque question déjà répondue, dans l'ordre de [_order]
  bool _finished = false;

  /// Tour « mes erreurs » : seulement les questions manquées ; ni progression ni score enregistrés.
  bool _mistakesRound = false;

  /// Questions manquées au dernier tour complet (indices dans le quiz).
  List<int> _lastMistakes = const [];
  final _scroll = ScrollController();

  bool get _revealed => _answers.length > _index;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await ref.read(databaseProvider).quiz(widget.quizId);
    if (!mounted || stored == null) return;
    final total = stored.quiz.questions.length;
    final progress = stored.progress;
    setState(() {
      _stored = stored;
      if (progress != null) {
        _order = progress.order;
        _answers.addAll(progress.answers);
        // Une question déjà répondue reste affichée avec son explication.
        _index = progress.answers.isEmpty ? 0 : progress.answers.length - 1;
      } else {
        _order = [for (var i = 0; i < total; i++) i];
      }
    });
    if (progress != null && progress.answers.isNotEmpty) showSnack(context, context.l10n.progressResumed);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  QuizQuestion _question(int position) => _stored!.quiz.questions[_order[position]];

  void _answer(int choice) {
    if (_revealed) return;
    setState(() => _answers.add(choice));
    if (!_mistakesRound) {
      unawaited(ref.read(databaseProvider).saveProgress(_stored!.id, QuizProgress(order: _order, answers: List.of(_answers))));
    }
    // Fait apparaître l'explication sous les propositions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _order.length) {
      setState(() => _index++);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    final stored = _stored!;
    final mistakes = [
      for (var i = 0; i < _order.length; i++)
        if (_answers[i] != _question(i).answer) _order[i],
    ];
    if (!_mistakesRound) {
      // Réponses rangées dans l'ordre des questions du quiz (-1 : non posée).
      final byQuestion = List.filled(stored.quiz.questions.length, -1);
      for (var i = 0; i < _order.length; i++) {
        byQuestion[_order[i]] = _answers[i];
      }
      final db = ref.read(databaseProvider);
      await db.recordAttempt(stored.id, score: _score, total: _order.length, answers: byQuestion);
      await db.saveProgress(stored.id, null);
      _lastMistakes = mistakes;
    }
    if (!mounted) return;
    setState(() => _finished = true);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  int get _score => [
    for (var i = 0; i < _answers.length; i++)
      if (_answers[i] == _question(i).answer) i,
  ].length;

  /// Nouveau tour : tout le quiz dans un autre ordre, ou seulement les erreurs.
  void _restart({required bool mistakes}) {
    final order = mistakes ? List.of(_lastMistakes) : [for (var i = 0; i < _stored!.quiz.questions.length; i++) i];
    order.shuffle(Random());
    setState(() {
      _mistakesRound = mistakes;
      _order = order;
      _index = 0;
      _answers.clear();
      _finished = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stored = _stored;
    if (stored == null || _order.isEmpty) return Scaffold(appBar: AppBar());
    final total = _order.length;
    final title = _finished
        ? (_mistakesRound ? l.reviewMistakesTitle : l.resultTitle)
        : (_mistakesRound ? l.mistakeOf(_index + 1, total) : l.questionOf(_index + 1, total));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: _finished
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: (_index + (_revealed ? 1 : 0)) / total),
              ),
      ),
      body: _finished ? _results(stored) : _questionView(stored),
      bottomNavigationBar: _finished
          ? _resultActions(stored)
          : _revealed
          ? BottomBar(
              child: FilledButton(onPressed: _next, child: Text(_index + 1 < total ? l.next : l.seeResults)),
            )
          : null,
    );
  }

  // ------------------------------------------------------------------ //
  // Question
  // ------------------------------------------------------------------ //
  Widget _questionView(StoredQuiz stored) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final q = _question(_index);
    final chosen = _revealed ? _answers[_index] : null;
    final options = q.isTrueFalse ? [l.trueLabel, l.falseLabel] : q.choices;
    // Vrai/faux : l'option 0 affichée est « Vrai » (réponse 1).
    int valueOf(int displayIndex) => q.isTrueFalse ? 1 - displayIndex : displayIndex;
    return ListView(
      controller: _scroll,
      padding: scrollPadding(context),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text(skillLabel(l, q.skill)), visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 8),
        Text(keepNumbersTogether(q.question), style: theme.textTheme.titleLarge?.copyWith(height: 1.35)),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Option(
              key: ValueKey('option-$i'),
              label: keepNumbersTogether(options[i]),
              state: chosen == null
                  ? _OptionState.idle
                  : valueOf(i) == q.answer
                  ? _OptionState.correct
                  : valueOf(i) == chosen
                  ? _OptionState.wrong
                  : _OptionState.dimmed,
              onTap: chosen == null ? () => _answer(valueOf(i)) : null,
            ),
          ),
        if (chosen != null) ...[const SizedBox(height: 8), _Feedback(question: q, chosen: chosen, documentId: stored.documentId)],
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Résultat
  // ------------------------------------------------------------------ //
  Widget _results(StoredQuiz stored) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final quiz = stored.quiz;
    final total = _order.length;
    final score = _score;
    final ratio = score / total;
    return ListView(
      controller: _scroll,
      padding: scrollPadding(context),
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: ratio >= 0.5 ? context.palette.success : theme.colorScheme.primary,
                ),
                Center(
                  child: Text(
                    l.scoreOutOf(score, total),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_mistakesRound) ...[
          Text(l.mistakesResult(score, total), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(l.mistakesResultHint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ] else
          Text(
            ratio >= 0.8 ? l.resultGreat : (ratio >= 0.5 ? l.resultGood : l.resultLow),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        if (!_mistakesRound && _lastMistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonalIcon(
              key: const ValueKey('retry-mistakes'),
              onPressed: () => _restart(mistakes: true),
              icon: const Icon(Icons.replay),
              label: Text(l.retryMistakes),
            ),
          ),
        ],
        if (quiz.summary.isNotEmpty) ...[
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.summaryTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(quiz.summary, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(l.reviewAnswers, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < total; i++) _ReviewTile(question: _question(i), chosen: _answers[i], documentId: stored.documentId),
      ],
    );
  }

  Widget _resultActions(StoredQuiz stored) {
    final l = context.l10n;
    final doc = ref.read(documentProvider(stored.documentId)).value;
    // « Un autre quiz » sur la même partie, si le texte n'a pas changé depuis.
    final section = doc != null && !stored.isStale(doc.body) ? stored.section : null;
    return BottomBar(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _restart(mistakes: false),
              child: Text(l.tryAgain, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              // L'écran reste en place pendant la création, puis le nouveau quiz le remplace.
              onPressed: () =>
                  createQuizFlow(context, ref, documentId: stored.documentId, another: true, replace: true, section: section),
              child: Text(l.anotherQuiz, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({super.key, required this.label, required this.state, this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.palette;
    final (bg, fg, border, icon) = switch (state) {
      _OptionState.idle => (scheme.surfaceContainerLow, scheme.onSurface, scheme.outlineVariant, null),
      _OptionState.correct => (p.successContainer, p.onSuccessContainer, p.success, Icons.check_circle),
      _OptionState.wrong => (p.wrongContainer, p.onWrongContainer, p.wrong, Icons.cancel),
      _OptionState.dimmed => (scheme.surfaceContainerLow, scheme.onSurfaceVariant, scheme.outlineVariant, null),
    };
    return Semantics(
      button: onTap != null,
      selected: state == _OptionState.correct || state == _OptionState.wrong,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: state == _OptionState.idle || state == _OptionState.dimmed ? 1 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: TextStyle(color: fg, fontSize: 16, height: 1.3)),
                  ),
                  if (icon != null) ...[const SizedBox(width: 12), Icon(icon, color: border)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bonne ou mauvaise réponse, explication et passage du texte.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.question, required this.chosen, required this.documentId});

  final QuizQuestion question;
  final int chosen;
  final int documentId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = context.palette;
    final ok = chosen == question.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.info, color: ok ? p.success : p.wrong),
            const SizedBox(width: 8),
            Text(
              ok ? l.correct : l.incorrect,
              style: theme.textTheme.titleMedium?.copyWith(color: ok ? p.success : p.wrong, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(keepNumbersTogether(question.explanation), style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
        if (question.quote.isNotEmpty) ...[const SizedBox(height: 12), QuoteBox(quote: question.quote, documentId: documentId)],
      ],
    );
  }
}

/// Encadré « Dans le texte » avec le lien vers le passage surligné.
class QuoteBox extends StatelessWidget {
  const QuoteBox({super.key, required this.quote, required this.documentId});

  final String quote;
  final int documentId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.quoteBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: p.quoteBar, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.inTheText, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 6),
          Text(keepNumbersTogether(quote), style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, height: 1.4)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TextViewScreen(documentId: documentId, highlight: quote),
                ),
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(l.showInText),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.question, required this.chosen, required this.documentId});

  final QuizQuestion question;
  final int chosen;
  final int documentId;

  String _label(BuildContext context, int value) {
    final l = context.l10n;
    if (question.isTrueFalse) return value == 1 ? l.trueLabel : l.falseLabel;
    return value >= 0 && value < question.choices.length ? keepNumbersTogether(question.choices[value]) : '—';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final ok = chosen == question.answer;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? p.success : p.wrong),
        title: Text(keepNumbersTogether(question.question), maxLines: 3, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!ok) Text(l.yourAnswer(_label(context, chosen)), style: TextStyle(color: p.wrong)),
          Text(
            l.theAnswerWas(_label(context, question.answer)),
            style: TextStyle(color: p.success, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(keepNumbersTogether(question.explanation)),
          if (question.quote.isNotEmpty) ...[const SizedBox(height: 10), QuoteBox(quote: question.quote, documentId: documentId)],
        ],
      ),
    );
  }
}
