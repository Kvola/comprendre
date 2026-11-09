/// « Nouvelle version disponible » : demande au serveur (module Odoo
/// `mobile_app_release`) si un APK plus récent est publié, et l'annonce par un
/// bandeau en haut de l'application.
///
/// Fichier AUTONOME, identique dans chaque application (Quiz biblique,
/// Comprendre, Kavola Pro, Kavola) : rien n'y dépend de l'application, les
/// textes traduits arrivent par [AppUpdateStrings]. Le corriger ici, puis le
/// recopier tel quel dans les autres.
///
/// Règles :
/// - Android seulement ([appUpdateSupported]) : un APK ne veut rien dire
///   ailleurs.
/// - Au plus une requête toutes les 12 h ([AppUpdateChecker.interval]) ; entre
///   deux, la dernière réponse est relue du stockage.
/// - Toute erreur (hors ligne, délai dépassé, réponse inattendue) = pas de
///   bandeau, jamais de message d'erreur : ne pas savoir n'est pas une
///   information à donner.
/// - « Plus tard » masque le bandeau pour CE build ; une version plus récente
///   le fera réapparaître. Une mise à jour obligatoire ne se masque pas.
///
/// Contrat serveur : `POST {server}/apps/{slug}/latest` (Odoo `jsonrpc`),
/// paramètre `current_version` au format `1.4.0+5` — le serveur compare les
/// numéros de build (après le `+`).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Vrai là où un APK peut s'installer.
bool get appUpdateSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Version installée au format du serveur : `1.4.0+5`.
Future<String?> installedAppVersion() async {
  final p = await PackageInfo.fromPlatform();
  if (p.version.isEmpty) return null;
  return p.buildNumber.isEmpty ? p.version : '${p.version}+${p.buildNumber}';
}

/// Numéro de build d'une version (`1.4.0+5` → 5), ou null s'il n'y en a pas.
/// Même règle que `build_number()` côté serveur.
int? buildNumberOf(String? version) {
  final m = RegExp(r'\+(\d+)\s*$').firstMatch(version ?? '');
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// Une version plus récente à proposer.
@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    this.latestBuild,
    this.mandatory = false,
    this.releaseNotes = '',
    this.downloadUrl = '',
    this.pageUrl = '',
  });

  /// Relit [toJson] ; null si illisible.
  static AppUpdateInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final version = json['latest_version'];
    if (version is! String || version.trim().isEmpty) return null;
    final build = json['latest_build'];
    final info = AppUpdateInfo(
      latestVersion: version.trim(),
      latestBuild: build is int ? build : buildNumberOf(version),
      mandatory: json['mandatory'] == true,
      releaseNotes: _text(json['release_notes']),
      downloadUrl: _httpUrl(json['download_url']),
      pageUrl: _httpUrl(json['page_url']),
    );
    return info.links.isEmpty ? null : info;
  }

  /// `1.5.0+6`
  final String latestVersion;
  final int? latestBuild;

  /// La version installée n'est plus acceptée : le bandeau ne se masque pas.
  final bool mandatory;
  final String releaseNotes;
  final String downloadUrl;
  final String pageUrl;

  /// Version lisible, sans le build : `1.5.0`.
  String get displayVersion => latestVersion.split('+').first;

  /// Ce que « Plus tard » retient : le build, sinon la version.
  String get id => latestBuild?.toString() ?? latestVersion;

  /// Adresses à essayer dans l'ordre : l'APK, puis la page de téléchargement.
  List<Uri> get links => [
    for (final u in {downloadUrl, pageUrl})
      if (u.isNotEmpty) Uri.parse(u),
  ];

  /// Notes de version courtes (une ligne, au plus [max] caractères).
  String shortNotes([int max = 140]) {
    final flat = releaseNotes.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= max ? flat : '${flat.substring(0, max - 1).trimRight()}…';
  }

  Map<String, Object?> toJson() => {
    'latest_version': latestVersion,
    'latest_build': latestBuild,
    'mandatory': mandatory,
    'release_notes': releaseNotes,
    'download_url': downloadUrl,
    'page_url': pageUrl,
  };

  @override
  bool operator ==(Object other) => other is AppUpdateInfo && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => 'AppUpdateInfo($latestVersion, mandatory: $mandatory)';
}

String _text(Object? v) => v is String ? v.trim() : '';

/// Seules les adresses http(s) absolues sont gardées (Odoo renvoie `false`
/// pour un champ vide, et l'on ne veut pas ouvrir n'importe quoi).
String _httpUrl(Object? v) {
  if (v is! String) return '';
  final uri = Uri.tryParse(v.trim());
  if (uri == null || !uri.hasAuthority || (uri.scheme != 'https' && uri.scheme != 'http')) return '';
  return uri.toString();
}

/// Réponse du serveur (corps JSON décodé) → version à proposer, ou null.
///
/// Null pour tout ce qui n'est pas une réponse de succès annonçant une mise à
/// jour exploitable : erreur JSON-RPC, `status: error`, champs manquants ou
/// mal typés, aucune adresse http(s).
AppUpdateInfo? parseAppUpdateResponse(Object? body) {
  if (body is! Map) return null;
  final payload = body.containsKey('result') ? body['result'] : (body.containsKey('error') ? null : body);
  if (payload is! Map) return null;
  if (payload['status'] != 'success' || payload['update_available'] != true) return null;
  return AppUpdateInfo.fromJson(payload);
}

/// Petit stockage clé → texte (préférences, ou mémoire dans les tests).
abstract interface class AppUpdateStore {
  Future<String?> read(String key);

  /// null efface la clé.
  Future<void> write(String key, String? value);
}

/// Stockage par défaut : préférences de l'appareil (localStorage sur le web).
class PrefsAppUpdateStore implements AppUpdateStore {
  PrefsAppUpdateStore([SharedPreferencesAsync? prefs]) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String? value) => value == null ? _prefs.remove(key) : _prefs.setString(key, value);
}

class MemoryAppUpdateStore implements AppUpdateStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

/// Interroge le serveur (au plus toutes les [interval]) et décide quoi montrer.
class AppUpdateChecker {
  AppUpdateChecker({
    required String server,
    required this.slug,
    required this.store,
    Future<String?> Function()? currentVersion,
    this.client,
    DateTime Function()? now,
    this.interval = const Duration(hours: 12),
    this.timeout = const Duration(seconds: 8),
  }) : server = server.trim().replaceAll(RegExp(r'/+$'), ''),
       _currentVersion = currentVersion ?? installedAppVersion,
       _now = now ?? DateTime.now;

  final String server;
  final String slug;
  final AppUpdateStore store;
  final Duration interval;
  final Duration timeout;
  final Future<String?> Function() _currentVersion;

  /// Client HTTP injecté (tests) ; sinon un client par requête.
  final http.Client? client;
  final DateTime Function() _now;
  Future<AppUpdateInfo?>? _running;

  static const keyLastCheck = 'app_update.last_check';
  static const keyCache = 'app_update.latest';
  static const keyDismissed = 'app_update.dismissed';
  static const keyWebInstallDismissed = 'app_update.web_install_dismissed';

  Uri get endpoint => Uri.parse('$server/apps/${Uri.encodeComponent(slug)}/latest');

  /// Page publique de téléchargement.
  Uri get pageUri => Uri.parse('$server/apps/${Uri.encodeComponent(slug)}');

  /// Version à annoncer, ou null. Ne lève jamais.
  Future<AppUpdateInfo?> check() => _running ??= _guarded().whenComplete(() => _running = null);

  /// « Plus tard » : ne plus montrer CE build (sans effet si obligatoire).
  Future<void> dismiss(AppUpdateInfo info) async {
    if (info.mandatory) return;
    try {
      await store.write(keyDismissed, info.id);
    } catch (_) {}
  }

  Future<AppUpdateInfo?> _guarded() async {
    try {
      return await _check();
    } catch (_) {
      return null;
    }
  }

  Future<AppUpdateInfo?> _check() async {
    final current = await _currentVersion();
    if (current == null || current.trim().isEmpty) return null;
    final now = _now();
    final last = DateTime.tryParse(await store.read(keyLastCheck) ?? '');
    // Horloge revenue en arrière : on ne s'y fie pas, on redemande.
    final fresh = last != null && !now.isBefore(last) && now.difference(last) < interval;

    AppUpdateInfo? info;
    if (fresh) {
      final cached = await store.read(keyCache);
      info = cached == null ? null : AppUpdateInfo.fromJson(_tryDecode(cached));
    } else {
      info = await _fetch(current.trim());
      // Le serveur a répondu (même « rien de neuf ») : on attend le prochain
      // créneau. Hors ligne, _fetch lève et rien n'est noté : on réessaiera au
      // prochain retour dans l'application.
      await store.write(keyLastCheck, now.toUtc().toIso8601String());
      await store.write(keyCache, info == null ? null : jsonEncode(info.toJson()));
    }
    if (info == null) return null;

    // Réponse en cache, mais l'application a été mise à jour depuis.
    final currentBuild = buildNumberOf(current);
    if (currentBuild != null && info.latestBuild != null && info.latestBuild! <= currentBuild) return null;
    if (!info.mandatory && await store.read(keyDismissed) == info.id) return null;
    return info;
  }

  Future<AppUpdateInfo?> _fetch(String current) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {'current_version': current},
            }),
          )
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      return parseAppUpdateResponse(_tryDecode(utf8.decode(res.bodyBytes, allowMalformed: true)));
    } finally {
      if (client == null) c.close();
    }
  }
}

Object? _tryDecode(String s) {
  try {
    return jsonDecode(s);
  } on FormatException {
    return null;
  }
}

/// Textes du bandeau, fournis par l'application (ses fichiers ARB).
class AppUpdateStrings {
  const AppUpdateStrings({
    required this.available,
    required this.required,
    required this.requiredHint,
    required this.download,
    required this.later,
    this.webInstallTitle = '',
    this.webInstallBody = '',
    this.webInstallAction = '',
    this.webInstallDismiss = '',
  });

  /// « Version 1.5.0 disponible »
  final String Function(String version) available;

  /// « Mise à jour obligatoire : version 1.5.0 »
  final String Function(String version) required;
  final String requiredHint;
  final String download;
  final String later;
  final String webInstallTitle;
  final String webInstallBody;
  final String webInstallAction;
  final String webInstallDismiss;
}

/// Ouvre une adresse dans le navigateur ; faux si impossible.
Future<bool> openExternalUrl(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Bandeau en haut de l'application, à placer dans `MaterialApp.builder` :
///
/// ```dart
/// builder: (context, child) => AppUpdateHost(checker: …, strings: …, child: child!),
/// ```
///
/// Vérifie au démarrage et à chaque retour dans l'application. Sans [checker]
/// (tests, web, iOS) il n'interroge rien ; avec [webInstallUrl] il invite à
/// installer l'application Android (web).
class AppUpdateHost extends StatefulWidget {
  const AppUpdateHost({
    super.key,
    required this.child,
    required this.strings,
    this.checker,
    this.webInstallUrl,
    this.store,
    this.launch = openExternalUrl,
  });

  final Widget child;
  final AppUpdateStrings Function(BuildContext context) strings;
  final AppUpdateChecker? checker;
  final Uri? webInstallUrl;

  /// Où retenir la fermeture de l'invitation web (défaut : celui du [checker],
  /// sinon les préférences).
  final AppUpdateStore? store;
  final Future<bool> Function(Uri uri) launch;

  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost> with WidgetsBindingObserver {
  final _childKey = GlobalKey(debugLabel: 'app_update_child');
  AppUpdateInfo? _update;
  bool _webInstall = false;
  AppUpdateStore? _webStore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    if (widget.webInstallUrl != null) _loadWebInstall();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final checker = widget.checker;
    if (checker == null) return;
    final info = await checker.check();
    // Un échec passager n'efface pas un bandeau déjà affiché.
    if (!mounted || info == null || info == _update) return;
    setState(() => _update = info);
  }

  Future<void> _loadWebInstall() async {
    final store = _webStore = widget.store ?? widget.checker?.store ?? PrefsAppUpdateStore();
    String? dismissed;
    try {
      dismissed = await store.read(AppUpdateChecker.keyWebInstallDismissed);
    } catch (_) {
      dismissed = null;
    }
    if (!mounted || dismissed != null) return;
    setState(() => _webInstall = true);
  }

  Future<void> _later() async {
    final info = _update;
    if (info == null || info.mandatory) return;
    setState(() => _update = null);
    await widget.checker?.dismiss(info);
  }

  Future<void> _download() async {
    for (final uri in _update?.links ?? const <Uri>[]) {
      if (await widget.launch(uri)) return;
    }
  }

  Future<void> _dismissWebInstall() async {
    setState(() => _webInstall = false);
    try {
      await _webStore?.write(AppUpdateChecker.keyWebInstallDismissed, '1');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    final Widget? banner = update != null
        ? _Banner(
            key: const ValueKey('app_update_banner'),
            urgent: update.mandatory,
            icon: update.mandatory ? Icons.system_update : Icons.system_update_outlined,
            title: (s) => update.mandatory ? s.required(update.displayVersion) : s.available(update.displayVersion),
            body: (s) => [if (update.mandatory) s.requiredHint, update.shortNotes()].where((t) => t.isNotEmpty).join('\n'),
            action: (s) => s.download,
            onAction: _download,
            dismiss: update.mandatory ? null : (s) => s.later,
            onDismiss: _later,
            strings: widget.strings,
          )
        : _webInstall && widget.webInstallUrl != null
        ? _Banner(
            key: const ValueKey('web_install_banner'),
            urgent: false,
            icon: Icons.install_mobile,
            title: (s) => s.webInstallTitle,
            body: (s) => s.webInstallBody,
            action: (s) => s.webInstallAction,
            onAction: () => widget.launch(widget.webInstallUrl!),
            dismiss: (s) => s.webInstallDismiss,
            onDismiss: _dismissWebInstall,
            strings: widget.strings,
          )
        : null;
    // Même arbre avec ou sans bandeau : l'application (son Navigator) n'est
    // jamais reconstruite quand il paraît. Le bandeau prend la marge de la
    // barre d'état ; l'application en dessous n'en a donc plus.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?banner,
        Expanded(
          key: _childKey,
          child: MediaQuery.removePadding(context: context, removeTop: banner != null, child: widget.child),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.urgent,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    required this.dismiss,
    required this.onDismiss,
    required this.strings,
  });

  final bool urgent;
  final IconData icon;
  final String Function(AppUpdateStrings s) title;
  final String Function(AppUpdateStrings s) body;
  final String Function(AppUpdateStrings s) action;
  final VoidCallback onAction;
  final String Function(AppUpdateStrings s)? dismiss;
  final VoidCallback onDismiss;
  final AppUpdateStrings Function(BuildContext context) strings;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = urgent ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final text = body(s);
    return Material(
      color: urgent ? scheme.errorContainer : scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, color: fg)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title(s), style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                        if (text.isNotEmpty)
                          Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg)),
                      ],
                    ),
                  ),
                ],
              ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  if (dismiss != null)
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(foregroundColor: fg),
                      child: Text(dismiss!(s)),
                    ),
                  FilledButton(onPressed: onAction, child: Text(action(s))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
