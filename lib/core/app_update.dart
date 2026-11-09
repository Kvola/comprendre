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
/// - Version web (PWA) : sur Android ou ordinateur, invitation à installer
///   l'APK ([AppUpdateHost.webInstallUrl]) ; dans Safari sur iPhone, où un APK
///   ne s'installe pas, conseil « Sur l'écran d'accueil » — une fois installée,
///   l'application garde ses données et s'ouvre en plein écran.
/// - Au DÉMARRAGE, on demande au serveur (au plus toutes les 5 min,
///   [AppUpdateChecker.startupInterval]) ; au RETOUR dans l'application, au
///   plus toutes les heures ([AppUpdateChecker.interval]). Entre deux, la
///   dernière réponse est relue du stockage. Une réponse fait ~600 octets.
///   Avant, une réponse « rien de neuf » valait 12 h : une version publiée
///   juste après restait invisible une demi-journée — « le bandeau ne
///   fonctionne pas ».
/// - Seule une VRAIE réponse du serveur (HTTP 200, JSON-RPC lisible) compte
///   comme vérification. Hors ligne, délai dépassé, 502 du proxy pendant un
///   redémarrage d'Odoo, page HTML… : rien n'est noté, on réessaiera, et une
///   mise à jour déjà connue reste annoncée.
/// - Toute erreur = jamais de message d'erreur : ne pas savoir n'est pas une
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
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'web_env.dart';

/// Vrai là où un APK peut s'installer.
bool get appUpdateSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Version installée au format du serveur : `1.4.0+5`.
Future<String?> installedAppVersion() async {
  final p = await PackageInfo.fromPlatform();
  return serverVersionOf(p.version, p.buildNumber);
}

/// `1.4.0` + `2005` → `1.4.0+5`.
///
/// LE NUMÉRO QU'ANDROID LIT N'EST PAS CELUI DU PUBSPEC
///
/// Nos APK sont construits un par processeur (`--split-per-abi`), et Flutter
/// ajoute alors 1000 × le type de processeur au numéro de build : `+5` devient
/// 1005 (armeabi-v7a), 2005 (arm64-v8a) ou 4005 (x86_64). C'est ce nombre que
/// rend `PackageInfo.buildNumber`. Le serveur, lui, compare au pubspec
/// (`1.5.0+6` → 6) : envoyé tel quel, 2005 paraîtrait toujours plus récent que
/// 6, et **le bandeau ne s'afficherait jamais**. On retire donc le décalage.
/// Un numéro de pubspec reste très en dessous de 1000.
String? serverVersionOf(String version, String buildNumber) {
  if (version.isEmpty) return null;
  final build = int.tryParse(buildNumber);
  if (build == null) return buildNumber.isEmpty ? version : '$version+$buildNumber';
  return '$version+${build % 1000}';
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
  final payload = _serverAnswer(body);
  if (payload == null || payload['status'] != 'success' || payload['update_available'] != true) return null;
  return AppUpdateInfo.fromJson(payload);
}

/// Le contenu d'une vraie réponse du module, ou null si ce n'en est pas une
/// (erreur JSON-RPC, page HTML d'un proxy, corps vide…). « Pas de mise à
/// jour » est une réponse ; « je n'ai rien compris » n'en est pas une.
Map<Object?, Object?>? _serverAnswer(Object? body) {
  if (body is! Map) return null;
  final payload = body.containsKey('result') ? body['result'] : (body.containsKey('error') ? null : body);
  if (payload is! Map || payload['status'] is! String) return null;
  return payload;
}

/// Le serveur n'a pas donné de réponse exploitable : on ne note rien.
class _NoAnswer implements Exception {
  const _NoAnswer(this.reason);
  final String reason;

  @override
  String toString() => 'Pas de réponse exploitable : $reason';
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
    this.interval = const Duration(hours: 1),
    this.startupInterval = const Duration(minutes: 5),
    this.timeout = const Duration(seconds: 8),
  }) : server = server.trim().replaceAll(RegExp(r'/+$'), ''),
       _currentVersion = currentVersion ?? installedAppVersion,
       _now = now ?? DateTime.now;

  final String server;
  final String slug;
  final AppUpdateStore store;

  /// Délai entre deux requêtes au retour dans l'application.
  final Duration interval;

  /// Délai entre deux requêtes au démarrage : court, pour qu'une version
  /// publiée se voie dès la prochaine ouverture ; non nul, pour qu'une
  /// application qui redémarre en boucle n'interroge pas le serveur en boucle.
  final Duration startupInterval;
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
  static const keyHomeScreenDismissed = 'app_update.home_screen_dismissed';

  Uri get endpoint => Uri.parse('$server/apps/${Uri.encodeComponent(slug)}/latest');

  /// Page publique de téléchargement.
  Uri get pageUri => Uri.parse('$server/apps/${Uri.encodeComponent(slug)}');

  /// Version à annoncer, ou null. Ne lève jamais.
  ///
  /// [startup] : ouverture de l'application, on se contente d'une réponse
  /// de moins de [startupInterval] ; sinon (retour dans l'application) de
  /// moins de [interval].
  Future<AppUpdateInfo?> check({bool startup = false}) =>
      _running ??= _guarded(startup ? startupInterval : interval).whenComplete(() => _running = null);

  /// « Plus tard » : ne plus montrer CE build (sans effet si obligatoire).
  Future<void> dismiss(AppUpdateInfo info) async {
    if (info.mandatory) return;
    try {
      await store.write(keyDismissed, info.id);
    } catch (_) {}
  }

  Future<AppUpdateInfo?> _guarded(Duration maxAge) async {
    try {
      return await _check(maxAge);
    } catch (_) {
      return null;
    }
  }

  Future<AppUpdateInfo?> _check(Duration maxAge) async {
    final current = await _currentVersion();
    if (current == null || current.trim().isEmpty) return null;
    final now = _now();
    final last = DateTime.tryParse(await store.read(keyLastCheck) ?? '');
    // Horloge revenue en arrière : on ne s'y fie pas, on redemande.
    final fresh = last != null && !now.isBefore(last) && now.difference(last) < maxAge;

    AppUpdateInfo? info;
    if (fresh) {
      info = await _cached();
    } else {
      try {
        info = await _fetch(current.trim());
      } catch (_) {
        // Pas de réponse (hors ligne, délai, 502, page HTML…) : rien n'est
        // noté, on réessaiera. Une mise à jour déjà connue reste annoncée —
        // elle n'a pas cessé d'exister parce que le réseau est tombé.
        info = await _cached();
        return _toShow(info, current);
      }
      // Le serveur a répondu (même « rien de neuf ») : on attend le prochain
      // créneau.
      await store.write(keyLastCheck, now.toUtc().toIso8601String());
      await store.write(keyCache, info == null ? null : jsonEncode(info.toJson()));
    }
    return _toShow(info, current);
  }

  Future<AppUpdateInfo?> _cached() async {
    final cached = await store.read(keyCache);
    return cached == null ? null : AppUpdateInfo.fromJson(_tryDecode(cached));
  }

  Future<AppUpdateInfo?> _toShow(AppUpdateInfo? info, String current) async {
    if (info == null) return null;
    // Réponse en cache, mais l'application a été mise à jour depuis.
    final currentBuild = buildNumberOf(current);
    if (currentBuild != null && info.latestBuild != null && info.latestBuild! <= currentBuild) return null;
    if (!info.mandatory && await store.read(keyDismissed) == info.id) return null;
    return info;
  }

  /// La réponse du serveur : une mise à jour, ou null s'il n'y en a pas.
  /// Lève [_NoAnswer] (ou une erreur réseau) si le serveur n'a pas vraiment
  /// répondu.
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
      if (res.statusCode != 200) throw _NoAnswer('HTTP ${res.statusCode}');
      final body = _tryDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
      if (_serverAnswer(body) == null) throw const _NoAnswer('corps illisible');
      return parseAppUpdateResponse(body);
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
    this.homeScreenTitle = '',
    this.homeScreenBody = '',
    this.homeScreenDismiss = '',
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

  /// Conseil Safari/iPhone : « Installez l'application » / « Touchez Partager,
  /// puis Sur l'écran d'accueil » / « Compris ». Titre vide = pas de conseil.
  final String homeScreenTitle;
  final String homeScreenBody;
  final String homeScreenDismiss;
}

/// Faut-il conseiller l'écran d'accueil ? Dans le navigateur d'un iPhone ou
/// d'un iPad, tant que l'application n'y est pas installée.
bool get homeScreenHintSupported =>
    kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && !runningStandalone();

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
/// installer l'application Android (web) ; avec [homeScreenHint] il explique
/// comment installer la version web sur l'écran d'accueil (iPhone).
class AppUpdateHost extends StatefulWidget {
  const AppUpdateHost({
    super.key,
    required this.child,
    required this.strings,
    this.checker,
    this.webInstallUrl,
    this.homeScreenHint,
    this.store,
    this.launch = openExternalUrl,
  });

  final Widget child;
  final AppUpdateStrings Function(BuildContext context) strings;
  final AppUpdateChecker? checker;
  final Uri? webInstallUrl;

  /// Null : décidé seul ([homeScreenHintSupported]).
  final bool? homeScreenHint;

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
  bool _homeScreen = false;
  AppUpdateStore? _webStore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check(startup: true);
    if (widget.webInstallUrl != null) _loadWebInstall();
    if (widget.homeScreenHint ?? homeScreenHintSupported) _loadHomeScreen();
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

  Future<void> _check({bool startup = false}) async {
    final checker = widget.checker;
    if (checker == null) return;
    final info = await checker.check(startup: startup);
    // Un échec passager n'efface pas un bandeau déjà affiché.
    if (!mounted || info == null || info == _update) return;
    setState(() => _update = info);
  }

  AppUpdateStore get _prefs => _webStore ??= widget.store ?? widget.checker?.store ?? PrefsAppUpdateStore();

  /// Déjà fermé ? Une lecture impossible vaut « pas encore » : le pire est de
  /// revoir une invitation, jamais de perdre l'application.
  Future<bool> _dismissed(String key) async {
    try {
      return await _prefs.read(key) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _remember(String key) async {
    try {
      await _prefs.write(key, '1');
    } catch (_) {}
  }

  Future<void> _loadWebInstall() async {
    if (await _dismissed(AppUpdateChecker.keyWebInstallDismissed) || !mounted) return;
    setState(() => _webInstall = true);
  }

  Future<void> _loadHomeScreen() async {
    if (await _dismissed(AppUpdateChecker.keyHomeScreenDismissed) || !mounted) return;
    setState(() => _homeScreen = true);
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
    await _remember(AppUpdateChecker.keyWebInstallDismissed);
  }

  Future<void> _dismissHomeScreen() async {
    setState(() => _homeScreen = false);
    await _remember(AppUpdateChecker.keyHomeScreenDismissed);
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
        : _homeScreen && widget.strings(context).homeScreenTitle.isNotEmpty
        ? _Banner(
            key: const ValueKey('home_screen_banner'),
            urgent: false,
            icon: Icons.add_to_home_screen,
            title: (s) => s.homeScreenTitle,
            body: (s) => s.homeScreenBody,
            dismiss: (s) => s.homeScreenDismiss,
            onDismiss: _dismissHomeScreen,
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
    this.action,
    this.onAction,
    required this.dismiss,
    required this.onDismiss,
    required this.strings,
  });

  final bool urgent;
  final IconData icon;
  final String Function(AppUpdateStrings s) title;
  final String Function(AppUpdateStrings s) body;
  /// Null : pas de bouton d'action (simple conseil, à fermer).
  final String Function(AppUpdateStrings s)? action;
  final VoidCallback? onAction;
  final String Function(AppUpdateStrings s)? dismiss;
  final VoidCallback onDismiss;
  final AppUpdateStrings Function(BuildContext context) strings;

  @override
  Widget build(BuildContext context) {
    final s = strings(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = urgent ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final bg = urgent ? scheme.errorContainer : scheme.primaryContainer;
    final text = body(s);
    // Le bandeau passe sous la barre d'état : ses icônes (heure, batterie)
    // doivent contraster avec LUI, pas avec la barre de titre d'en dessous —
    // sinon, icônes blanches sur fond clair, illisibles.
    final overlay = ThemeData.estimateBrightnessForColor(bg) == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Material(
        color: bg,
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
                    if (action != null) FilledButton(onPressed: onAction, child: Text(action!(s))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
