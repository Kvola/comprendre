import 'package:flutter/material.dart';

import '../app/quiz_service.dart';
import '../core/theme.dart';
import '../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Boîte de confirmation ; [destructive] colore l'action en rouge.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? body,
  required String action,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: c.palette.wrong) : null,
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

String skillLabel(AppLocalizations l, String skill) => switch (skill) {
  'main_idea' => l.skillMainIdea,
  'vocabulary' => l.skillVocabulary,
  'inference' => l.skillInference,
  'structure' => l.skillStructure,
  'cause' || 'cause_effect' => l.skillCause,
  _ => l.skillDetail,
};

String fallbackReason(AppLocalizations l, Fallback f, int? param) => switch (f) {
  Fallback.network => l.whyNetwork,
  Fallback.quota => l.whyQuota,
  Fallback.failures => l.whyFailures,
  Fallback.language => l.whyLanguage,
  Fallback.tooLong => l.whyTooLong(param ?? 30000),
  Fallback.busy => l.whyBusy,
  Fallback.unavailable => l.whyUnavailable,
  Fallback.rateLimited => l.whyRateLimited(param ?? 10),
  Fallback.disabled => l.whyDisabled,
  Fallback.unverified => l.whyUnverified,
  Fallback.refusedContent => l.whyRefusedContent,
  Fallback.cancelled => l.whyCancelled,
  Fallback.other => l.whyOther,
};

/// Nom d'une langue de texte ([textLanguages]).
String langLabel(AppLocalizations l, String code) => switch (code) {
  'en' => l.langEn,
  'es' => l.langEs,
  'pt' => l.langPt,
  'de' => l.langDe,
  'it' => l.langIt,
  _ => l.langFr,
};

IconData sourceIcon(String source) => switch (source) {
  'scan' => Icons.document_scanner_outlined,
  'photo' => Icons.image_outlined,
  'file' => Icons.description_outlined,
  _ => Icons.edit_note,
};

/// Contenu défilant qui respecte les zones système (encoche, barre de gestes)
/// et laisse de la place sous le dernier élément pour un bouton flottant.
EdgeInsets scrollPadding(BuildContext context, {double extraBottom = 0}) {
  final pad = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(16 + pad.left, 16, 16 + pad.right, 24 + pad.bottom + extraBottom);
}

/// Barre d'actions collée en bas de l'écran, au-dessus de la barre de gestes.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child),
    );
  }
}
