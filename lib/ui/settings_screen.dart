import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/version.dart';
import 'common.dart';

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
        segments: [for (final (v, label) in options) ButtonSegment(value: v, label: Text(label, textAlign: TextAlign.center))],
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
          segmented<String>(s.localeCode ?? 'system', [('system', l.systemDefault), ('fr', 'Français'), ('en', 'English')],
              (v) => db.setSetting('locale', v)),
          section(l.theme),
          segmented<String>(s.themeMode, [('system', l.themeSystem), ('light', l.themeLight), ('dark', l.themeDark)],
              (v) => db.setSetting('theme', v)),
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
