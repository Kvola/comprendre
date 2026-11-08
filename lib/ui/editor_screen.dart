import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../engine/text_tools.dart';
import 'common.dart';
import 'document_screen.dart';

/// Nombre minimal de caractères pour proposer un quiz.
const minQuizChars = 150;

/// Saisie d'un texte, ou relecture d'un texte extrait (scan, fichier) ;
/// avec [documentId], modification d'un texte existant.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.initialText, this.source = 'typed', this.fileName, this.documentId, this.initialTitle});

  final String? initialText;
  final String source;
  final String? fileName;
  final int? documentId;
  final String? initialTitle;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final _title = TextEditingController(text: widget.initialTitle ?? _titleFromFile(widget.fileName));
  late final _text = TextEditingController(text: widget.initialText ?? '');
  String? _lang; // null = détectée automatiquement
  bool _saving = false;

  bool get _editing => widget.documentId != null;
  bool get _extracted => widget.source != 'typed' && !_editing;

  static String _titleFromFile(String? name) {
    if (name == null) return '';
    final dot = name.lastIndexOf('.');
    return (dot > 0 ? name.substring(0, dot) : name).replaceAll(RegExp(r'[_]+'), ' ').trim();
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  String get _detected => detectLanguage(_text.text);
  String get _effectiveLang => _lang ?? _detected;

  bool get _dirty =>
      _text.text.trim() != (widget.initialText ?? '').trim() || _title.text.trim() != (widget.initialTitle ?? _titleFromFile(widget.fileName));

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (t.isEmpty) {
      showSnack(context, context.l10n.clipboardEmpty);
      return;
    }
    final sel = _text.selection;
    final cur = _text.text;
    final start = sel.isValid ? sel.start : cur.length, end = sel.isValid ? sel.end : cur.length;
    _text.value = TextEditingValue(
      text: cur.replaceRange(start, end, t),
      selection: TextSelection.collapsed(offset: start + t.length),
    );
  }

  String _autoTitle(String body) {
    final first = splitSentences(body).firstOrNull?.text ?? body;
    final words = wordsOf(first);
    final t = first.length <= 60 ? first : '${words.take(8).join(' ')}…';
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _submit() async {
    final body = cleanText(_text.text);
    if (body.length < minQuizChars) {
      showSnack(context, context.l10n.textTooShort(minQuizChars));
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final title = _title.text.trim().isEmpty ? _autoTitle(body) : _title.text.trim();
    final nav = Navigator.of(context);
    if (_editing) {
      await db.updateDocument(widget.documentId!, title: title, body: body, lang: _effectiveLang);
      nav.pop();
      return;
    }
    final id = await db.addDocument(title: title, body: body, source: widget.source, fileName: widget.fileName, lang: _effectiveLang);
    nav.pushReplacement(MaterialPageRoute(builder: (_) => DocumentScreen(documentId: id, autoCreateQuiz: true)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final count = _text.text.trim().length;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await confirm(context, title: l.discardTitle, body: l.discardBody, action: l.discard, destructive: true)) {
          nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.editorTitle),
          actions: [IconButton(tooltip: l.paste, icon: const Icon(Icons.content_paste), onPressed: _paste)],
        ),
        body: ListView(
          padding: scrollPadding(context),
          children: [
            if (_extracted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(l.reviewExtracted, style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.titleLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.textLabel, hintText: l.textHint, alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Text(l.charsCount(count), style: theme.textTheme.bodySmall, textAlign: TextAlign.end),
            const SizedBox(height: 16),
            Text(l.languageOfText, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'fr', label: Text(l.langFr)),
                ButtonSegment(value: 'en', label: Text(l.langEn)),
              ],
              selected: {_effectiveLang},
              onSelectionChanged: (s) => setState(() => _lang = s.first),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: FilledButton.icon(
            onPressed: _saving || count == 0 ? null : _submit,
            icon: Icon(_editing ? Icons.check : Icons.quiz_outlined),
            label: Text(_editing ? l.save : l.createQuiz),
          ),
        ),
      ),
    );
  }
}
