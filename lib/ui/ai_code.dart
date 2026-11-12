/// Codes IA : saisie d'un code (Réglages → Quiz IA, Mes codes IA), transfert depuis un
/// ancien téléphone, et motifs de refus traduits.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    'code_full' => l.aiCodeErrFull,
    _ => l.aiCodeErrOther,
  };
}

/// Demande un code IA et l'active ; renvoie le résultat (null si abandon).
/// Un code activé allume l'IA (c'est pour elle qu'on le saisit).
Future<AiRedeemed?> enterAiCode(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<AiRedeemed>(context: context, builder: (_) => const _AiCodeDialog());
  if (result == null) return null;
  final db = ref.read(databaseProvider);
  final wasOn = (await db.setting('ai')) == 'on';
  if (!wasOn) await db.setSetting('ai', 'on');
  ref.invalidate(quotaProvider);
  final first = result.already
      ? l.aiCodeAlready
      : [if (result.transferred) l.aiCodeTransferred, l.aiCodeActivated(result.code.remaining)].join(' ');
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text([first, if (!wasOn) l.aiCodeActivatedAiOn].join(' ')), duration: const Duration(seconds: 6)),
    );
  return result;
}

/// Un code IA dans un texte quelconque (« Votre code : AB12-CD34 ! ») ; null s'il n'y en a pas.
/// Un code a des groupes séparés par des tirets, avec un chiffre ou tout en majuscules ;
/// un texte court fait seulement de lettres et de chiffres est pris tel quel.
String? findAiCode(String? text) {
  if (text == null) return null;
  final t = text.trim();
  for (final m in RegExp(r'(?<![A-Za-z0-9-])[A-Za-z0-9]{2,6}(?:-[A-Za-z0-9]{2,6}){1,3}(?![A-Za-z0-9-])').allMatches(t)) {
    final raw = m.group(0)!;
    if (raw.replaceAll('-', '').length >= 6 && (RegExp(r'\d').hasMatch(raw) || raw == raw.toUpperCase())) {
      return raw.toUpperCase();
    }
  }
  if (t.length <= 24 && RegExp(r'^[A-Za-z0-9\s-]+$').hasMatch(t) && t.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').length >= 6) {
    return t.toUpperCase().replaceAll(RegExp(r'\s+'), '-');
  }
  return null;
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

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final code = findAiCode(data?.text);
    if (code == null) {
      setState(() => _error = context.l10n.aiCodePasteEmpty);
      return;
    }
    _controller.text = code;
    _controller.selection = TextSelection.collapsed(offset: code.length);
    setState(() => _error = null);
  }

  Future<void> _submit({bool transfer = false}) async {
    if (_busy || _controller.text.trim().isEmpty) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(aiClientProvider.future);
      final result = await client.redeem(_controller.text, transfer: transfer);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      // Le code est sur un autre téléphone : on propose le transfert (changement de téléphone).
      if (e is AiException && e.reason == 'code_transferable' && !transfer) {
        setState(() => _busy = false);
        final ok = await confirm(
          context,
          title: l.aiCodeTransferTitle,
          body: l.aiCodeTransferBody(e.transfersLeft ?? 1),
          action: l.aiCodeTransferAction,
        );
        if (ok && mounted) return _submit(transfer: true);
        if (mounted) _refocus();
        return;
      }
      setState(() {
        _busy = false;
        _error = aiCodeError(l, e);
      });
      _refocus();
    }
  }

  /// Le champ, désactivé pendant la vérification, reprend le curseur, texte sélectionné : prêt à corriger.
  void _refocus() {
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
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
              decoration: InputDecoration(
                labelText: l.aiCodeField,
                errorText: _error,
                errorMaxLines: 5,
                suffixIcon: IconButton(
                  key: const ValueKey('ai-code-paste'),
                  tooltip: l.aiCodePaste,
                  icon: const Icon(Icons.content_paste),
                  onPressed: _busy ? null : _paste,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _busy ? null : () => _submit(), child: Text(l.aiCodeActivate)),
      ],
    );
  }
}
