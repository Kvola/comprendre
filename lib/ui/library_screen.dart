import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../data/database.dart';
import 'common.dart';
import 'document_screen.dart';
import 'editor_screen.dart';
import 'import_flow.dart';
import 'settings_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final library = ref.watch(libraryProvider);
    final docs = library.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: docs == null || docs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showNewTextSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l.newText),
            ),
      body: switch (docs) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const _EmptyLibrary(),
        _ => ListView.separated(
          padding: scrollPadding(context, extraBottom: 72),
          itemCount: docs.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (c, i) => i == 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l.libraryTitle, style: Theme.of(c).textTheme.titleMedium),
                )
              : _DocumentCard(docs[i - 1]),
        ),
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard(this.doc);

  final DocumentSummary doc;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(doc.updatedAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(sourceIcon(doc.source)),
        ),
        title: Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${l.quizzesCount(doc.quizCount)} · $date'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentScreen(documentId: doc.id))),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      padding: scrollPadding(context),
      children: [
        const SizedBox(height: 12),
        // Le symbole de l'application (livre éclairé par une idée).
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/branding/icon-full.png', width: 104, height: 104, excludeFromSemantics: true),
          ),
        ),
        const SizedBox(height: 16),
        Text(l.emptyTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(l.emptyBody, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ...sourceTiles(context),
      ],
    );
  }
}

/// Les quatre façons d'apporter un texte (écran vide et feuille « Nouveau texte »).
List<Widget> sourceTiles(BuildContext context, {VoidCallback? before, bool inSheet = false}) {
  final l = context.l10n;
  Widget tile(IconData icon, String title, String hint, Future<Extracted?> Function(BuildContext) get, {bool typed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        // Dans la feuille (même fond que les cartes), une teinte plus marquée les distingue.
        color: inSheet ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text(hint),
          onTap: () async {
            final nav = Navigator.of(context);
            before?.call();
            if (typed) {
              nav.push(MaterialPageRoute(builder: (_) => const EditorScreen()));
              return;
            }
            final extracted = await get(nav.context);
            if (extracted == null) return;
            nav.push(
              MaterialPageRoute(
                builder: (_) => EditorScreen(initialText: extracted.text, source: extracted.source, fileName: extracted.fileName),
              ),
            );
          },
        ),
      ),
    );
  }

  return [
    tile(Icons.edit_note, l.sourceTyped, l.sourceTypedHint, (_) async => null, typed: true),
    tile(Icons.document_scanner_outlined, l.sourceScan, l.sourceScanHint, scanDocument),
    tile(Icons.image_outlined, l.sourcePhoto, l.sourcePhotoHint, photoText),
    tile(Icons.upload_file, l.sourceFile, l.sourceFileHint, importFile),
  ];
}

void showNewTextSheet(BuildContext context) {
  final rootContext = context;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(sheet.l10n.newText, style: Theme.of(sheet).textTheme.titleLarge),
            ),
            // Les actions partent du contexte de l'écran : la feuille est fermée avant.
            ...sourceTiles(rootContext, before: () => Navigator.pop(sheet), inSheet: true),
          ],
        ),
      ),
    ),
  );
}
