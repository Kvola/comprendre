import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/theme.dart';
import '../engine/text_tools.dart';
import 'common.dart';

/// Lecture du texte, avec un passage surligné (citation d'une question) vers
/// lequel l'écran défile.
class TextViewScreen extends ConsumerStatefulWidget {
  const TextViewScreen({super.key, required this.documentId, this.highlight});

  final int documentId;
  final String? highlight;

  @override
  ConsumerState<TextViewScreen> createState() => _TextViewScreenState();
}

class _Paragraph {
  const _Paragraph(this.text, this.start);

  final String text;
  final int start;
}

class _TextViewScreenState extends ConsumerState<TextViewScreen> {
  final _scroll = ScrollController();
  final _targetKey = GlobalKey();
  bool _scrolled = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static List<_Paragraph> _paragraphs(String text) {
    final out = <_Paragraph>[];
    var start = 0;
    for (final m in RegExp(r'\n\s*\n').allMatches(text)) {
      if (m.start > start) out.add(_Paragraph(text.substring(start, m.start), start));
      start = m.end;
    }
    if (start < text.length) out.add(_Paragraph(text.substring(start), start));
    return out;
  }

  /// Le paragraphe surligné peut être loin : on saute d'abord à une position
  /// estimée (la liste est paresseuse), puis on l'amène précisément à l'écran.
  void _scrollToTarget(int index, int count) {
    if (_scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (_targetKey.currentContext == null) pos.jumpTo(pos.maxScrollExtent * index / count);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _targetKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.25, duration: const Duration(milliseconds: 300));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(documentProvider(widget.documentId)).value;
    if (doc == null) return Scaffold(appBar: AppBar());
    final theme = Theme.of(context);
    final p = context.palette;
    final paragraphs = _paragraphs(doc.body);
    final range = widget.highlight == null ? null : findQuote(doc.body, widget.highlight!);
    final missing = widget.highlight != null && widget.highlight!.trim().isNotEmpty && range == null;
    var target = -1;
    if (range != null) {
      target = paragraphs.lastIndexWhere((x) => x.start <= range.$1);
      if (target >= 0) _scrollToTarget(target, paragraphs.length);
    }
    final style = theme.textTheme.bodyLarge?.copyWith(height: 1.55, fontSize: 17);
    return Scaffold(
      appBar: AppBar(title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          padding: scrollPadding(context),
          itemCount: paragraphs.length + (missing ? 1 : 0),
          itemBuilder: (c, item) {
            if (missing && item == 0) {
              // Le texte a été modifié depuis le quiz : la citation n'y est plus.
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: theme.colorScheme.onTertiaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(context.l10n.quoteNotFound, style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final i = item - (missing ? 1 : 0);
            final para = paragraphs[i];
            Widget text;
            if (range != null && range.$1 < para.start + para.text.length && range.$2 > para.start) {
              // Le passage peut déborder sur le paragraphe suivant : on surligne la partie de chacun.
              final a = (range.$1 - para.start).clamp(0, para.text.length);
              final b = (range.$2 - para.start).clamp(0, para.text.length);
              text = Text.rich(
                TextSpan(
                  style: style,
                  children: [
                    TextSpan(text: para.text.substring(0, a)),
                    TextSpan(
                      text: para.text.substring(a, b),
                      style: TextStyle(backgroundColor: p.highlight, color: p.onHighlight),
                    ),
                    TextSpan(text: para.text.substring(b)),
                  ],
                ),
              );
            } else {
              text = Text(para.text, style: style);
            }
            return Padding(key: i == target ? _targetKey : null, padding: const EdgeInsets.only(bottom: 14), child: text);
          },
        ),
      ),
    );
  }
}
