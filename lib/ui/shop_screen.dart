/// Achat de quiz IA : offres payées avec Wave ; le paiement confirmé ajoute un
/// code IA à ce téléphone (rien à saisir).
///
/// Robustesse :
/// - chaque achat a une clé tirée une fois et **gardée** (réglage `shop_pending`)
///   avant l'appel : un réessai (réseau coupé, double appui) retrouve le même achat ;
/// - l'écran revérifie l'état toutes les 10 s tant qu'un paiement attend, et au
///   retour dans l'application (après Wave).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/providers.dart';
import '../core/theme.dart';
import '../l10n/gen/app_localizations.dart';
import '../remote/ai_client.dart';
import 'common.dart';

/// Montant lisible : « 2 500 F CFA », « 12,50 USD ».
String formatPrice(BuildContext context, num amount, String currency) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final whole = currency == 'XOF' || currency == 'XAF' || amount == amount.roundToDouble();
  final n = (whole ? NumberFormat.decimalPattern(locale) : NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2))
      .format(amount);
  final label = switch (currency) { 'XOF' || 'XAF' => 'F CFA', _ => currency };
  return '$n $label';
}

String _newClientRef() {
  final r = Random.secure();
  return List.generate(24, (_) => r.nextInt(36).toRadixString(36)).join();
}

String shopError(AppLocalizations l, Object e) {
  if (e is! AiException) return l.aiCodeErrOther;
  if (e.isNetwork) return l.aiCodeErrNetwork;
  if (e.code == 'AUTH_010') return l.aiCodeErrRate(e.minutes ?? 10);
  return switch (e.reason) {
    'pack_unavailable' => l.shopErrUnavailable,
    'payment_unavailable' => l.shopErrPayment,
    'bad_wave_ref' => l.shopErrRefShort,
    'wave_ref_used' => l.shopErrRefUsed,
    _ => l.aiCodeErrOther,
  };
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with WidgetsBindingObserver {
  AiShop? _shop;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;
  DateTime? _pollUntil;

  /// Achats déjà vus payés : un passage « à payer → payé » est annoncé une fois.
  final _seenDone = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(first: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour de Wave : on regarde tout de suite si le paiement est confirmé.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<AiClient> get _client => ref.read(aiClientProvider.future);

  Future<Map<String, String>> _pendingRefs() async {
    try {
      final raw = await ref.read(databaseProvider).setting('shop_pending');
      return raw == null ? {} : Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _savePendingRefs(Map<String, String> refs) =>
      ref.read(databaseProvider).setSetting('shop_pending', jsonEncode(refs));

  Future<void> _refresh({bool first = false}) async {
    try {
      final shop = await (await _client).shop();
      if (!mounted) return;
      final l = context.l10n;
      final newlyDone = shop.orders.where((o) => o.isDone && !_seenDone.contains(o.ref)).toList();
      if (first) {
        _seenDone.addAll(shop.orders.where((o) => o.isDone).map((o) => o.ref));
      } else if (newlyDone.isNotEmpty) {
        _seenDone.addAll(newlyDone.map((o) => o.ref));
        await _onConfirmed(newlyDone);
        if (!mounted) return;
        showSnack(context, l.shopConfirmed(newlyDone.fold(0, (n, o) => n + o.credits)));
      }
      setState(() {
        _shop = shop;
        _error = null;
        _loading = false;
      });
      _schedulePoll(shop);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  /// Un paiement confirmé : l'IA est allumée (c'est pour elle qu'on a payé), le quota relu,
  /// et la clé de l'achat oubliée.
  Future<void> _onConfirmed(List<AiOrder> done) async {
    final db = ref.read(databaseProvider);
    if ((await db.setting('ai')) != 'on') await db.setSetting('ai', 'on');
    final refs = await _pendingRefs();
    refs.removeWhere((k, _) => done.any((o) => o.ref == k));
    await _savePendingRefs(refs);
    ref.invalidate(quotaProvider);
  }

  void _schedulePoll(AiShop shop) {
    final waiting = shop.orders.any((o) => o.isPending);
    if (!waiting) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _pollUntil ??= DateTime.now().add(const Duration(minutes: 15));
    if (_poll != null) return;
    _poll = Timer.periodic(const Duration(seconds: 10), (t) {
      if (!mounted || DateTime.now().isAfter(_pollUntil!)) {
        t.cancel();
        _poll = null;
        return;
      }
      _refresh();
    });
  }

  Future<void> _openWave(String url) async {
    final l = context.l10n;
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (opened || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.shopBuy),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(l.shopOpenFailed), const SizedBox(height: 8), SelectableText(url)],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(c);
              showSnack(context, l.shopLinkCopied);
            },
            child: Text(l.shopCopyLink),
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close)),
        ],
      ),
    );
  }

  Future<void> _buy(AiPack pack) async {
    final l = context.l10n;
    final ok = await confirm(
      context,
      title: l.shopConfirmTitle,
      body: l.shopConfirmBody(pack.name, l.shopCredits(pack.credits), formatPrice(context, pack.price, pack.currency)),
      action: l.shopBuy,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    // La clé est gardée AVANT l'appel : si la réponse se perd, le prochain essai retrouve l'achat.
    final refs = await _pendingRefs();
    final clientRef = refs['pack:${pack.id}'] ?? _newClientRef();
    refs['pack:${pack.id}'] = clientRef;
    await _savePendingRefs(refs);
    try {
      final purchase = await (await _client).buy(pack.id, clientRef);
      refs
        ..remove('pack:${pack.id}')
        ..[purchase.order.ref] = clientRef;
      await _savePendingRefs(refs);
      if (purchase.url != null) await _openWave(purchase.url!);
    } catch (e) {
      if (mounted) showSnack(context, shopError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _pollUntil = DateTime.now().add(const Duration(minutes: 15));
    await _refresh();
  }

  /// Rouvre Wave pour un achat en attente (même achat, même paiement).
  Future<void> _payAgain(AiOrder order) async {
    final l = context.l10n;
    final refs = await _pendingRefs();
    final clientRef = refs[order.ref];
    // Le serveur retrouve l'achat par sa clé, même si l'offre n'est plus en vente.
    if (clientRef == null || order.packId == null) {
      if (mounted) showSnack(context, l.shopErrPayment);
      return;
    }
    setState(() => _busy = true);
    try {
      final purchase = await (await _client).buy(order.packId!, clientRef);
      if (purchase.url != null) await _openWave(purchase.url!);
    } catch (e) {
      if (mounted) showSnack(context, shopError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final shop = _shop;
    final pending = shop?.orders.where((o) => o.isPending).toList() ?? const <AiOrder>[];
    final done = shop?.orders.where((o) => o.isDone).toList() ?? const <AiOrder>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.shopTitle),
        actions: [IconButton(tooltip: l.shopCheck, icon: const Icon(Icons.refresh), onPressed: _busy ? null : _refresh)],
        bottom: _busy || _loading
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: scrollPadding(context),
          children: [
            Text(l.shopIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (shop == null && _error != null)
              _Message(icon: Icons.cloud_off, text: shopError(l, _error!) == l.aiCodeErrNetwork ? l.shopOffline : shopError(l, _error!),
                  action: TextButton(onPressed: _refresh, child: Text(l.retry))),
            if (pending.isNotEmpty) ...[
              Text(l.shopMyOrders, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final o in pending)
                _PendingOrder(
                  key: ValueKey('order-${o.ref}'),
                  order: o,
                  autoConfirm: shop!.autoConfirm || o.mode == 'checkout',
                  busy: _busy,
                  onPayAgain: () => _payAgain(o),
                  onCheck: _refresh,
                  onWaveRef: (waveRef) async {
                    try {
                      await (await _client).declareWaveRef(o.ref, waveRef);
                      await _refresh();
                      return null;
                    } catch (e) {
                      return shopError(l, e);
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
            if (shop != null && (shop.packs.isEmpty || !shop.paymentAvailable))
              _Message(icon: Icons.storefront_outlined, text: l.shopNoOffer)
            else if (shop != null)
              for (final p in shop.packs)
                _PackCard(key: ValueKey('pack-${p.id}'), pack: p, onBuy: _busy ? null : () => _buy(p)),
            if (done.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final o in done)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: context.palette.success),
                  title: Text(l.shopOrderDone),
                  subtitle: Text([
                    l.shopOrderRef(o.ref),
                    l.shopCredits(o.credits),
                    if (o.code != null) l.aiCodeTitle(o.code!),
                  ].join(' · ')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          ?action,
        ],
      ),
    ),
  );
}

class _PackCard extends StatelessWidget {
  const _PackCard({super.key, required this.pack, required this.onBuy});

  final AiPack pack;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final details = [
      pack.validityDays > 0 ? l.shopValidity(pack.validityDays) : l.shopNoExpiry,
      if (pack.dailyLimit > 0) l.shopDailyLimit(pack.dailyLimit),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(pack.name, style: theme.textTheme.titleLarge)),
                Text(formatPrice(context, pack.price, pack.currency),
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.shopCredits(pack.credits), style: theme.textTheme.titleMedium),
            if (pack.description.isNotEmpty) Text(pack.description),
            Text(details.join(' · '), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(key: ValueKey('buy-${pack.id}'), onPressed: onBuy, icon: const Icon(Icons.account_balance_wallet_outlined), label: Text(l.shopBuy)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un achat qui attend son paiement (ou sa confirmation).
class _PendingOrder extends StatefulWidget {
  const _PendingOrder({
    super.key,
    required this.order,
    required this.autoConfirm,
    required this.busy,
    required this.onPayAgain,
    required this.onCheck,
    required this.onWaveRef,
  });

  final AiOrder order;
  final bool autoConfirm;
  final bool busy;
  final VoidCallback onPayAgain;
  final Future<void> Function() onCheck;

  /// Renvoie un message d'erreur, ou null si l'identifiant est enregistré.
  final Future<String?> Function(String waveRef) onWaveRef;

  @override
  State<_PendingOrder> createState() => _PendingOrderState();
}

class _PendingOrderState extends State<_PendingOrder> {
  final _ref = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_ref.text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onWaveRef(_ref.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final o = widget.order;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(child: Text(l.shopOrderPending, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text([l.shopOrderRef(o.ref), l.shopCredits(o.credits), formatPrice(context, o.amount, o.currency)].join(' · ')),
            const SizedBox(height: 8),
            Text(widget.autoConfirm ? l.shopWaitAuto : l.shopWaitAgent),
            if (!widget.autoConfirm) ...[
              const SizedBox(height: 12),
              if (o.waveRef != null)
                Text(l.shopWaveRefSent(o.waveRef!), style: const TextStyle(fontWeight: FontWeight.w600))
              else ...[
                TextField(
                  key: ValueKey('wave-ref-${o.ref}'),
                  controller: _ref,
                  enabled: !_sending,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: l.shopWaveRefLabel,
                    helperText: l.shopWaveRefHint,
                    helperMaxLines: 3,
                    errorText: _error,
                    suffixIcon: IconButton(tooltip: l.shopWaveRefSend, icon: const Icon(Icons.send), onPressed: _send),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.busy ? null : widget.onPayAgain,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.shopPayAgain),
                ),
                TextButton.icon(onPressed: widget.busy ? null : widget.onCheck, icon: const Icon(Icons.refresh), label: Text(l.shopCheck)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
