/// Codes IA : saisie d'un code (Réglages → Quiz IA) et affichage des codes activés.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../l10n/gen/app_localizations.dart';
import '../remote/ai_client.dart';
import 'common.dart';

/// Message d'un refus d'activation, dans la langue de l'application.
String aiCodeError(AppLocalizations l, Object error) {
  if (error is! AiException) return l.aiCodeErrOther;
  if (error.isNetwork) return l.aiCodeErrNetwork;
  if (error.code == 'AUTH_010') return l.aiCodeErrRate(error.minutes ?? 10);
  return switch (error.reason) {
    'code_unknown' => l.aiCodeErrUnknown,
    'code_disabled' => l.aiCodeErrDisabled,
    'code_expired' => l.aiCodeErrExpired,
    'code_exhausted' => l.aiCodeErrExhausted,
    'code_taken' => l.aiCodeErrTaken,
    _ => l.aiCodeErrOther,
  };
}

/// Demande un code IA et l'active. Un code activé allume l'IA (c'est pour elle qu'on le saisit).
Future<void> enterAiCode(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final redeemed = await showDialog<AiCode>(context: context, builder: (_) => const _AiCodeDialog());
  if (redeemed == null) return;
  final db = ref.read(databaseProvider);
  final wasOn = (await db.setting('ai')) == 'on';
  if (!wasOn) await db.setSetting('ai', 'on');
  ref.invalidate(quotaProvider);
  messenger.showSnackBar(
    SnackBar(
      content: Text([l.aiCodeActivated(redeemed.remaining), if (!wasOn) l.aiCodeActivatedAiOn].join(' ')),
      duration: const Duration(seconds: 6),
    ),
  );
}

/// La fenêtre de saisie : garde son champ (libéré seulement quand elle disparaît,
/// après l'animation de fermeture) et affiche l'erreur sous le champ, pour corriger.
class _AiCodeDialog extends ConsumerStatefulWidget {
  const _AiCodeDialog();

  @override
  ConsumerState<_AiCodeDialog> createState() => _AiCodeDialogState();
}

class _AiCodeDialogState extends ConsumerState<_AiCodeDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _controller.text.trim().isEmpty) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(aiClientProvider.future);
      final (code, _) = await client.redeem(_controller.text);
      if (mounted) Navigator.pop(context, code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = aiCodeError(l, e);
        });
        // Le champ, désactivé pendant la vérification, reprend le curseur, texte sélectionné : prêt à corriger.
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      icon: const Icon(Icons.key),
      title: Text(l.aiCodeDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.aiCodeDialogBody),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('ai-code-field'),
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              style: const TextStyle(fontFamily: 'monospace', letterSpacing: 2),
              decoration: InputDecoration(labelText: l.aiCodeField, errorText: _error, errorMaxLines: 4),
              onSubmitted: (_) => _submit(),
            ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(l.aiCodeActivate)),
      ],
    );
  }
}

/// Une ligne par code activé : code, quiz restants, date limite.
class AiCodeTile extends StatelessWidget {
  const AiCodeTile(this.code, {super.key});

  final AiCode code;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final expired = code.isExpired(now);
    final parts = [
      l.aiCodeLeft(expired ? 0 : code.remaining),
      if (expired)
        l.aiCodeExpired
      else if (code.expires != null)
        l.aiCodeUntil(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(code.expires!)),
      if (!expired && code.remaining > 0 && code.dailyLeft == 0) l.aiCodeDailyDone,
    ];
    final usable = !expired && code.remaining > 0;
    return ListTile(
      leading: Icon(Icons.key, color: usable ? Theme.of(context).colorScheme.primary : null),
      title: Text(l.aiCodeTitle(code.code)),
      subtitle: Text(parts.join(' · ')),
      enabled: usable,
    );
  }
}
