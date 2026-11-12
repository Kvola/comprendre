/// « Mes codes IA » : ce que le téléphone peut faire aujourd'hui, chaque code (reste,
/// date limite, plafond, partage), et ce qu'on peut en faire (copier, retirer pour le
/// donner, en ajouter, en acheter). Hors connexion : le dernier état connu, daté.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../l10n/gen/app_localizations.dart';
import '../remote/ai_client.dart';
import 'ai_code.dart';
import 'common.dart';
import 'shop_screen.dart';

/// Un code « expire bientôt » à partir de ce nombre de jours.
const soonDays = 7;

class MyCodesView {
  const MyCodesView(this.quota, {this.at, this.offline = false});

  final AiQuota? quota;

  /// Moment de l'état affiché (hors connexion : celui du dernier état enregistré).
  final DateTime? at;
  final bool offline;
}

/// Codes du téléphone : en ligne, sinon le dernier état enregistré.
final myCodesProvider = FutureProvider.autoDispose<MyCodesView>((ref) async {
  final db = ref.read(databaseProvider);
  try {
    final quota = await (await ref.watch(aiClientProvider.future)).quota();
    final now = DateTime.now();
    await db.setSetting('codes_cache', jsonEncode({'at': now.toIso8601String(), 'quota': quota.raw}));
    return MyCodesView(quota, at: now);
  } catch (_) {
    try {
      final cached = jsonDecode(await db.setting('codes_cache') ?? '') as Map<String, dynamic>;
      return MyCodesView(
        AiQuota.fromJson(cached['quota'] as Map<String, dynamic>),
        at: DateTime.tryParse('${cached['at']}'),
        offline: true,
      );
    } catch (_) {
      return const MyCodesView(null, offline: true);
    }
  }
});

/// « aujourd'hui », « demain », « dans 5 jours », « le 12 janv. 2027 ».
String whenLabel(BuildContext context, DateTime date, int days) {
  final l = context.l10n;
  if (days <= 0) return l.whenToday;
  if (days == 1) return l.whenTomorrow;
  if (days <= 30) return l.whenInDays(days);
  return l.whenOnDate(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date));
}

/// Le code qui expire le plus tôt parmi ceux encore utilisables, s'il expire bientôt.
AiCode? expiringSoon(Iterable<AiCode> codes, DateTime now) {
  AiCode? best;
  for (final c in codes) {
    final days = c.daysLeft(now);
    if (!c.isLive(now) || days == null || days > soonDays) continue;
    if (best == null || days < best.daysLeft(now)!) best = c;
  }
  return best;
}

class MyCodesScreen extends ConsumerWidget {
  const MyCodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final view = ref.watch(myCodesProvider);
    Future<void> refresh() async {
      ref.invalidate(myCodesProvider);
      ref.invalidate(quotaProvider);
      await ref.read(myCodesProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myCodes),
        actions: [IconButton(tooltip: l.retry, icon: const Icon(Icons.refresh), onPressed: refresh)],
      ),
      body: switch (view) {
        AsyncData(:final value) => RefreshIndicator(onRefresh: refresh, child: _Body(value)),
        AsyncError() => Center(child: Text(l.myCodesOfflineNone)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('codes-enter'),
                icon: const Icon(Icons.add_card_outlined),
                label: Text(l.aiCodeEnter, overflow: TextOverflow.ellipsis),
                onPressed: () async {
                  if (await enterAiCode(context, ref) != null) {
                    ref.invalidate(myCodesProvider);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(l.myCodesBuy, overflow: TextOverflow.ellipsis),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ShopScreen()));
                  ref.invalidate(myCodesProvider);
                  ref.invalidate(quotaProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.view);

  final MyCodesView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final quota = view.quota;
    final now = DateTime.now();
    final codes = quota?.allCodes ?? const <AiCode>[];
    final live = [
      for (final c in codes)
        if (c.isLive(now)) c,
    ];
    final ended = [
      for (final c in codes)
        if (!c.isLive(now)) c,
    ];
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      padding: scrollPadding(context),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (view.offline)
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.cloud_off),
              title: Text(
                quota == null || view.at == null
                    ? l.myCodesOfflineNone
                    : l.myCodesOffline(DateFormat.yMMMd(locale).add_Hm().format(view.at!)),
              ),
            ),
          ),
        if (quota != null) _TodayCard(quota: quota, live: live, now: now),
        if (quota != null && codes.isEmpty) ...[
          const SizedBox(height: 24),
          Icon(Icons.key_off_outlined, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(l.myCodesNone, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.myCodesEmptyBody, textAlign: TextAlign.center),
        ],
        if (live.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(l.myCodesIntro, style: theme.textTheme.bodySmall),
          ),
          for (final c in live) AiCodeCard(c, readOnly: view.offline),
        ],
        if (ended.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(l.myCodesEnded, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          for (final c in ended) AiCodeCard(c, readOnly: view.offline),
        ],
      ],
    );
  }
}

/// Aujourd'hui : quiz IA possibles (gratuits + codes) et l'avertissement « expire bientôt ».
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.quota, required this.live, required this.now});

  final AiQuota quota;
  final List<AiCode> live;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final soon = expiringSoon(live, now);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.myCodesToday, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Text(l.aiRemaining(quota.remaining), style: theme.textTheme.titleLarge),
            if (quota.codeRemaining > 0 || live.isNotEmpty)
              Text(l.aiRemainingDetail(quota.freeRemaining, quota.codeRemaining), style: theme.textTheme.bodyMedium),
            if (soon != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.hourglass_bottom, size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.myCodesExpireSoon(soon.remaining, whenLabel(context, soon.expires!, soon.daysLeft(now)!)),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un code : reste (barre), date limite, plafond du jour, partage ; menu copier / retirer.
class AiCodeCard extends ConsumerStatefulWidget {
  const AiCodeCard(this.code, {super.key, this.readOnly = false});

  final AiCode code;
  final bool readOnly;

  @override
  ConsumerState<AiCodeCard> createState() => _AiCodeCardState();
}

class _AiCodeCardState extends ConsumerState<AiCodeCard> {
  bool _busy = false;

  String? _stateLabel(AppLocalizations l, String state) => switch (state) {
    'exhausted' => l.codeStateExhausted,
    'expired' => l.codeStateExpired,
    'disabled' => l.codeStateDisabled,
    _ => null,
  };

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code.code));
    if (mounted) showSnack(context, context.l10n.codeCopied);
  }

  Future<void> _remove() async {
    final l = context.l10n;
    final c = widget.code;
    final now = DateTime.now();
    final ok = await confirm(
      context,
      title: l.codeRemoveTitle,
      body: l.codeRemoveBody(c.isLive(now) ? c.remaining : 0),
      action: l.codeRemove,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final client = await ref.read(aiClientProvider.future);
      await client.release(c.code);
      ref.invalidate(myCodesProvider);
      ref.invalidate(quotaProvider);
      if (mounted) showSnack(context, l.codeRemoved);
    } catch (_) {
      if (mounted) showSnack(context, l.codeRemoveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = widget.code;
    final now = DateTime.now();
    final live = c.isLive(now);
    final state = c.stateAt(now);
    final used = c.used ?? (c.credits - c.remaining);
    final days = c.daysLeft(now);
    final soon = live && days != null && days <= soonDays;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final muted = live ? null : scheme.onSurfaceVariant;
    final ended = _stateLabel(l, state);

    final lines = <Widget>[
      Row(
        children: [
          Icon(soon ? Icons.hourglass_bottom : Icons.event_outlined, size: 16, color: soon ? scheme.error : muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              c.expires == null ? l.codeNoExpiry : l.codeExpiresWhen(whenLabel(context, c.expires!, days!)),
              style: TextStyle(color: soon ? scheme.error : muted),
            ),
          ),
        ],
      ),
      if (c.dailyLimit > 0 && live)
        Text([l.codeDailyLimit(c.dailyLimit), if (c.dailyLeft != null) l.codeDailyLeft(c.dailyLeft!)].join(' · ')),
      if (c.isShared) Text(l.codeShared(c.maxDevices, c.usedByMe ?? 0)),
      if (c.lastUsed != null)
        Text(l.codeLastUsed(DateFormat.yMMMd(locale).format(c.lastUsed!)), style: theme.textTheme.bodySmall),
    ];

    return Card(
      key: ValueKey('code-${c.code}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: live ? scheme.primary : muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                      color: muted,
                    ),
                  ),
                ),
                if (ended != null)
                  Chip(label: Text(ended), visualDensity: VisualDensity.compact)
                else
                  Text(c.isBought ? l.codeBought : l.codeGift, style: theme.textTheme.labelMedium),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  PopupMenuButton<String>(
                    key: ValueKey('code-menu-${c.code}'),
                    onSelected: (v) => v == 'copy' ? _copy() : _remove(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'copy',
                        child: ListTile(leading: const Icon(Icons.copy), title: Text(l.codeCopy)),
                      ),
                      if (!widget.readOnly)
                        PopupMenuItem(
                          value: 'remove',
                          child: ListTile(leading: const Icon(Icons.remove_circle_outline), title: Text(l.codeRemove)),
                        ),
                    ],
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(l.aiCodeLeft(live ? c.remaining : 0), style: theme.textTheme.titleSmall?.copyWith(color: muted)),
                  const SizedBox(height: 6),
                  Semantics(
                    label: l.codeUsedOf(used, c.credits),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.credits > 0 ? (used / c.credits).clamp(0, 1).toDouble() : 1,
                        minHeight: 8,
                        color: live ? scheme.primary : scheme.outline,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l.codeUsedOf(used, c.credits), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  ...lines,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
