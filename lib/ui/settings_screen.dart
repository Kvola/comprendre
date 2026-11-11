import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/version.dart';
import '../core/web_env.dart';
import '../data/backup.dart';
import '../data/database.dart';
import 'common.dart';

/// Enregistre toute la bibliothèque dans un fichier choisi par l'utilisateur.
Future<void> exportLibrary(BuildContext context, AppDatabase db) async {
  final l = context.l10n;
  try {
    if ((await db.select(db.documents).get()).isEmpty) {
      if (context.mounted) showSnack(context, l.backupEmpty);
      return;
    }
    final bytes = Uint8List.fromList(utf8.encode(await exportBackup(db, appVersion: appVersion)));
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final name = 'comprendre-sauvegarde-$day.json';
    final bool saved;
    if (kIsWeb) {
      saved = downloadBytes(bytes, name, 'application/json');
    } else {
      saved = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'application/json') != null;
    }
    if (saved && context.mounted) showSnack(context, l.backupSaved);
  } catch (_) {
    if (context.mounted) showSnack(context, l.backupFailed);
  }
}

/// Ajoute à la bibliothèque les textes d'un fichier de sauvegarde.
Future<void> restoreLibrary(BuildContext context, AppDatabase db) async {
  final l = context.l10n;
  final picked = await FilePicker.pickFiles(type: FileType.any);
  final file = picked.firstOrNull;
  if (file == null || !context.mounted) return;
  try {
    final result = await importBackup(db, utf8.decode(await file.readAsBytes(), allowMalformed: true));
    if (context.mounted) showSnack(context, l.restoreDone(result.added, result.skipped));
  } on BackupException catch (e) {
    if (context.mounted) showSnack(context, e.code == 'newer' ? l.backupNewer : l.backupInvalid);
  } catch (_) {
    if (context.mounted) showSnack(context, l.backupInvalid);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final s = ref.watch(settingsProvider).value;
    final db = ref.read(databaseProvider);
    if (s == null) return Scaffold(appBar: AppBar(title: Text(l.settings)));
    final aiOn = s.aiMode == 'on';
    final quota = aiOn ? ref.watch(quotaProvider) : null;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
    );

    Widget segmented<T extends Object>(T value, List<(T, String)> options, ValueChanged<T> onChanged) => SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final (v, label) in options)
            ButtonSegment(
              value: v,
              label: Text(label, textAlign: TextAlign.center),
            ),
        ],
        selected: {value},
        onSelectionChanged: (sel) => onChanged(sel.first),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          section(l.appLanguage),
          segmented<String>(s.localeCode ?? 'system', [
            ('system', l.systemDefault),
            ('fr', 'Français'),
            ('en', 'English'),
          ], (v) => db.setSetting('locale', v)),
          section(l.theme),
          segmented<String>(s.themeMode, [
            ('system', l.themeSystem),
            ('light', l.themeLight),
            ('dark', l.themeDark),
          ], (v) => db.setSetting('theme', v)),
          section(l.questionsPerQuiz),
          segmented<int>(s.questionCount, [(5, '5'), (10, '10'), (15, '15')], (v) => db.setSetting('questions', '$v')),
          section(l.aiSection),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: aiOn,
                  onChanged: (v) => db.setSetting('ai', v ? 'on' : 'off'),
                  title: Text(l.aiUse),
                  subtitle: Text(l.aiUseHint),
                  isThreeLine: true,
                ),
                if (aiOn)
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(switch (quota?.value) {
                      final q? => l.aiRemaining(q.remaining),
                      _ => quota?.isLoading == true ? '…' : l.aiQuotaUnknown,
                    }),
                    trailing: IconButton(
                      tooltip: l.retry,
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(quotaProvider),
                    ),
                  ),
              ],
            ),
          ),
          section(l.backupSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('backup-export'),
                  leading: const Icon(Icons.save_alt),
                  title: Text(l.backupExport),
                  subtitle: Text(l.backupExportHint),
                  onTap: () => exportLibrary(context, db),
                ),
                ListTile(
                  key: const ValueKey('backup-import'),
                  leading: const Icon(Icons.settings_backup_restore),
                  title: Text(l.backupImport),
                  subtitle: Text(l.backupImportHint),
                  onTap: () => restoreLibrary(context, db),
                ),
              ],
            ),
          ),
          section(l.about),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/branding/icon-full.png', width: 48, height: 48, excludeFromSemantics: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.appTitle, style: theme.textTheme.titleLarge)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.aboutBody, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Text(l.privacyTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(l.privacyBody, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Text(l.version(appVersion), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
