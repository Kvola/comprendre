/// Client du service de quiz IA (module Odoo `comprendre_backend`).
///
/// - La clé de l'API Claude reste sur le serveur ; l'application n'envoie que le
///   texte et un identifiant d'appareil aléatoire (aucun compte, aucune donnée
///   personnelle). Le serveur ne conserve pas le texte.
/// - Toute erreur est une [AiException] avec un code ; l'appelant retombe alors
///   sur le moteur hors ligne.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../engine/quiz_model.dart';

/// Serveur de production ; `--dart-define=COMPRENDRE_SERVER=http://10.0.2.2:8096` en développement.
const defaultServer = String.fromEnvironment('COMPRENDRE_SERVER', defaultValue: 'https://iyf.ebng.world');

class AiException implements Exception {
  AiException(this.code, {this.reason = '', this.message = '', this.minutes, this.transfersLeft});

  /// `NETWORK` | `TIMEOUT` | `SERVER` | `REFUSED` | `AI_FAILED` | `AUTH_010` | `BAD_REQUEST`
  final String code;

  /// Raison précise donnée par le serveur (`quota`, `too_long`, `busy`…), pour un message traduit.
  final String reason;

  /// Message du serveur (en français), en dernier recours.
  final String message;
  final int? minutes;

  /// Motif `code_transferable` : transferts encore permis.
  final int? transfersLeft;

  bool get isNetwork => code == 'NETWORK' || code == 'TIMEOUT';

  @override
  String toString() => 'AiException($code/$reason): $message';
}

/// Un code IA activé sur ce téléphone (serveur 19.0.1.3.0 et plus ; détails en 19.0.1.5.0).
class AiCode {
  const AiCode({
    required this.code,
    required this.remaining,
    required this.credits,
    this.expires,
    this.dailyLeft,
    this.usableToday = true,
    this.serverState,
    this.used,
    this.usedByMe,
    this.dailyLimit = 0,
    this.maxDevices = 1,
    this.devices = 1,
    this.activated,
    this.lastUsed,
    this.source = 'gift',
    this.transfersLeft = 0,
  });

  factory AiCode.fromJson(Map<dynamic, dynamic> j) {
    int? optInt(Object? v) => v is num ? v.toInt() : null;
    DateTime? optDate(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    DateTime? optUtc(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse('${v}Z')?.toLocal() : null;
    return AiCode(
      code: '${j['code'] ?? ''}',
      remaining: optInt(j['remaining']) ?? 0,
      credits: optInt(j['credits']) ?? 0,
      expires: optDate(j['expires']),
      dailyLeft: optInt(j['daily_left']),
      usableToday: j['usable_today'] != false,
      serverState: j['state'] is String ? j['state'] as String : null,
      used: optInt(j['used']),
      usedByMe: optInt(j['used_by_me']),
      dailyLimit: optInt(j['daily_limit']) ?? 0,
      maxDevices: optInt(j['max_devices']) ?? 1,
      devices: optInt(j['devices']) ?? 1,
      activated: optUtc(j['activated']),
      lastUsed: optUtc(j['last_used']),
      source: j['source'] == 'purchase' ? 'purchase' : 'gift',
      transfersLeft: optInt(j['transfers_left']) ?? 0,
    );
  }

  final String code;

  /// Quiz IA encore disponibles sur ce code (partagés s'il sert à plusieurs téléphones).
  final int remaining;
  final int credits;

  /// Dernier jour de validité (null : sans limite).
  final DateTime? expires;

  /// Quiz encore possibles aujourd'hui sur ce code (null : pas de plafond par jour).
  final int? dailyLeft;
  final bool usableToday;

  /// État donné par le serveur (19.0.1.5.0) ; null avec un serveur plus ancien.
  final String? serverState;

  /// Quiz comptés sur le code (tous téléphones), et par ce téléphone ; null avec un serveur ancien.
  final int? used;
  final int? usedByMe;
  final int dailyLimit;
  final int maxDevices;
  final int devices;
  final DateTime? activated;
  final DateTime? lastUsed;

  /// `purchase` (acheté avec Wave) ou `gift` (reçu).
  final String source;

  /// Transferts encore permis vers un autre téléphone (codes à un seul téléphone).
  final int transfersLeft;

  bool isExpired(DateTime now) => expires != null && DateTime(now.year, now.month, now.day).isAfter(expires!);

  /// `active` | `exhausted` | `expired` | `disabled` (déduit des chiffres avec un serveur ancien).
  String stateAt(DateTime now) => serverState ?? (isExpired(now) ? 'expired' : (remaining <= 0 ? 'exhausted' : 'active'));

  bool isLive(DateTime now) => stateAt(now) == 'active' && !isExpired(now) && remaining > 0;

  bool get isShared => maxDevices > 1;
  bool get isBought => source == 'purchase';

  /// Jours avant la fin (0 : dernier jour aujourd'hui) ; null sans date limite.
  int? daysLeft(DateTime now) => expires == null
      ? null
      : DateTime.utc(expires!.year, expires!.month, expires!.day).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
}

/// Résultat d'une activation : le code, le quota à jour, et s'il était déjà sur ce téléphone.
class AiRedeemed {
  const AiRedeemed(this.code, this.quota, {this.already = false, this.transferred = false});

  final AiCode code;
  final AiQuota quota;
  final bool already;
  final bool transferred;
}

/// Une offre de quiz IA en vente (serveur 19.0.1.4.0 et plus).
class AiPack {
  const AiPack({required this.id, required this.name, required this.credits, required this.price, required this.currency,
      this.description = '', this.validityDays = 0, this.dailyLimit = 0});

  factory AiPack.fromJson(Map<dynamic, dynamic> j) => AiPack(
    id: (j['id'] as num).toInt(),
    name: '${j['name'] ?? ''}',
    description: '${j['description'] ?? ''}',
    credits: (j['credits'] as num?)?.toInt() ?? 0,
    price: (j['price'] as num?) ?? 0,
    currency: '${j['currency'] ?? ''}',
    validityDays: (j['validity_days'] as num?)?.toInt() ?? 0,
    dailyLimit: (j['daily_limit'] as num?)?.toInt() ?? 0,
  );

  final int id;
  final String name;
  final String description;
  final int credits;
  final num price;
  final String currency;

  /// Validité du code délivré, en jours (0 : sans limite).
  final int validityDays;
  final int dailyLimit;
}

/// Un achat de l'appareil.
class AiOrder {
  const AiOrder({required this.ref, this.packId, required this.pack, required this.credits, required this.amount, required this.currency,
      required this.state, this.mode, this.awaitingValidation = false, this.waveRef, this.created, this.code});

  factory AiOrder.fromJson(Map<dynamic, dynamic> j) => AiOrder(
    ref: '${j['ref'] ?? ''}',
    packId: (j['pack_id'] is num) ? (j['pack_id'] as num).toInt() : null,
    pack: '${j['pack'] ?? ''}',
    credits: (j['credits'] as num?)?.toInt() ?? 0,
    amount: (j['amount'] as num?) ?? 0,
    currency: '${j['currency'] ?? ''}',
    state: '${j['state'] ?? 'draft'}',
    mode: j['mode'] is String ? j['mode'] as String : null,
    awaitingValidation: j['awaiting_validation'] == true,
    waveRef: j['wave_ref'] is String ? j['wave_ref'] as String : null,
    created: j['created'] is String ? DateTime.tryParse('${j['created']}Z')?.toLocal() : null,
    code: j['code'] is String ? j['code'] as String : null,
  );

  final String ref;
  final int? packId;
  final String pack;
  final int credits;
  final num amount;
  final String currency;

  /// `draft` (à payer) | `done` (payé, code activé) | `cancelled`
  final String state;

  /// `checkout` (Wave confirme tout seul) | `merchant` (un agent valide) ; null avant le paiement.
  final String? mode;
  final bool awaitingValidation;
  final String? waveRef;
  final DateTime? created;

  /// Code IA délivré (achat payé).
  final String? code;

  bool get isPending => state == 'draft';
  bool get isDone => state == 'done';
}

class AiShop {
  const AiShop({required this.packs, required this.paymentAvailable, required this.autoConfirm, required this.orders});

  factory AiShop.fromJson(Map<String, dynamic> r) => AiShop(
    packs: [for (final p in (r['packs'] is List ? r['packs'] as List : const [])) if (p is Map) AiPack.fromJson(p)],
    paymentAvailable: r['payment_available'] == true,
    autoConfirm: r['auto_confirm'] == true,
    orders: [for (final o in (r['orders'] is List ? r['orders'] as List : const [])) if (o is Map) AiOrder.fromJson(o)],
  );

  final List<AiPack> packs;
  final bool paymentAvailable;

  /// API Wave : la confirmation arrive toute seule (sinon un agent valide).
  final bool autoConfirm;
  final List<AiOrder> orders;
}

/// Achat préparé : l'URL Wave à ouvrir pour payer (vide si l'achat est déjà payé).
class AiPurchase {
  const AiPurchase(this.order, this.mode, this.url);

  final AiOrder order;
  final String? mode;
  final String? url;
}

class AiQuota {
  const AiQuota({
    required this.remaining,
    required this.daily,
    required this.maxChars,
    required this.enabled,
    this.limited = '',
    this.languages = const {'fr', 'en'},
    int? freeRemaining,
    this.codeRemaining = 0,
    this.codes = const [],
    List<AiCode>? allCodes,
    this.raw = const {},
  }) : freeRemaining = freeRemaining ?? remaining,
       allCodes = allCodes ?? codes;

  factory AiQuota.fromJson(Map<String, dynamic> r) => AiQuota(
    remaining: (r['remaining'] as num?)?.toInt() ?? 0,
    daily: (r['daily'] as num?)?.toInt() ?? 0,
    maxChars: (r['max_chars'] as num?)?.toInt() ?? 30000,
    enabled: r['enabled'] != false,
    limited: r['limited'] is String ? r['limited'] as String : '',
    languages: r['languages'] is List ? {for (final l in r['languages'] as List) '$l'} : const {'fr', 'en'},
    freeRemaining: (r['free_remaining'] as num?)?.toInt(),
    codeRemaining: (r['code_remaining'] as num?)?.toInt() ?? 0,
    codes: [for (final c in (r['codes'] is List ? r['codes'] as List : const [])) if (c is Map) AiCode.fromJson(c)],
    allCodes: r['all_codes'] is List ? [for (final c in r['all_codes'] as List) if (c is Map) AiCode.fromJson(c)] : null,
    raw: r,
  );

  /// Quiz IA possibles aujourd'hui : gratuits + codes IA.
  final int remaining;

  /// Dont gratuits (quota du jour), et payés par les codes IA.
  final int freeRemaining;
  final int codeRemaining;
  final List<AiCode> codes;

  /// Tous les codes du téléphone, terminés compris (serveur 19.0.1.5.0 ; sinon [codes]).
  final List<AiCode> allCodes;

  /// Réponse brute du serveur (gardée pour l'affichage hors connexion).
  final Map<String, dynamic> raw;
  final int daily;
  final int maxChars;
  final bool enabled;

  /// Pourquoi l'IA est fermée aujourd'hui malgré le quota : `failures` (trop
  /// d'échecs), `blocked` ; vide sinon. (Serveur 19.0.1.2.0 et plus.)
  final String limited;

  /// Langues que le serveur sait traiter (un serveur plus ancien : français et anglais).
  final Set<String> languages;
}

class AiResult {
  const AiResult(this.quiz, this.remaining);

  final Quiz quiz;
  final int remaining;
}

/// Identifiant d'appareil : 32 caractères aléatoires (le serveur n'en garde que l'empreinte).
String newDeviceId([Random? rnd]) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
  final r = rnd ?? Random.secure();
  return List.generate(32, (_) => alphabet[r.nextInt(alphabet.length)]).join();
}

class AiClient {
  AiClient({required this.deviceId, this.baseUrl = defaultServer, http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final String deviceId;
  final String baseUrl;
  final http.Client _http;
  int _id = 0;

  static const apiPath = '/comprendre/api/v1';

  Future<AiQuota> quota() async {
    return AiQuota.fromJson(await _call('/quota', {'device_id': deviceId}, const Duration(seconds: 12)));
  }

  /// Active un code IA sur ce téléphone. [transfer] : l'utilisateur a confirmé le transfert
  /// depuis son ancien téléphone. [AiException] (motif `code_unknown`, `code_transferable`…) sinon.
  Future<AiRedeemed> redeem(String code, {bool transfer = false}) async {
    final r = await _call('/redeem', {
      'device_id': deviceId,
      'code': code.trim(),
      'can_transfer': true,
      if (transfer) 'transfer': true,
    }, const Duration(seconds: 15));
    final redeemed = r['redeemed'];
    if (redeemed is! Map) throw AiException('SERVER');
    return AiRedeemed(AiCode.fromJson(redeemed), AiQuota.fromJson(r), already: r['already'] == true, transferred: transfer);
  }

  /// Retire un code de ce téléphone (pour le donner) ; renvoie le quota à jour.
  Future<AiQuota> release(String code) async =>
      AiQuota.fromJson(await _call('/code/release', {'device_id': deviceId, 'code': code}, const Duration(seconds: 15)));

  /// Délai d'attente d'un quiz IA. Le serveur borne lui-même ses appels à Claude
  /// (2 essais de 100 s) pour toujours répondre avant.
  static const quizTimeout = Duration(seconds: 240);

  /// Le serveur appelle Claude (jusqu'à ~2 min pour un long texte) puis vérifie chaque citation.
  Future<AiResult> generate(String text, {required String lang, int count = 10}) async {
    final r = await _call('/quiz', {'device_id': deviceId, 'text': text, 'lang': lang, 'count': count}, quizTimeout);
    final quiz = Quiz.fromJson({
      'engine': 'ai',
      'title': r['title'],
      'summary': r['summary'],
      'lang': lang,
      'questions': r['questions'],
    });
    if (quiz.questions.length < 3) throw AiException('AI_FAILED', reason: 'unverified');
    return AiResult(quiz, (r['remaining'] as num?)?.toInt() ?? 0);
  }

  /// Offres en vente et achats récents de ce téléphone.
  Future<AiShop> shop() async => AiShop.fromJson(await _call('/shop', {'device_id': deviceId}, const Duration(seconds: 15)));

  /// Achète [packId]. [clientRef] (tiré une fois par achat et gardé) rend l'appel rejouable sans double achat.
  Future<AiPurchase> buy(int packId, String clientRef) async {
    final r = await _call('/buy', {'device_id': deviceId, 'pack_id': packId, 'client_ref': clientRef}, const Duration(seconds: 30));
    final order = r['order'];
    if (order is! Map) throw AiException('SERVER');
    return AiPurchase(AiOrder.fromJson(order), r['mode'] is String ? r['mode'] as String : null,
        r['url'] is String && (r['url'] as String).isNotEmpty ? r['url'] as String : null);
  }

  /// Achats de ce téléphone et quota à jour.
  Future<(List<AiOrder>, AiQuota)> orders() async {
    final r = await _call('/orders', {'device_id': deviceId}, const Duration(seconds: 15));
    final quota = r['quota'];
    return (
      [for (final o in (r['orders'] is List ? r['orders'] as List : const [])) if (o is Map) AiOrder.fromJson(o)],
      AiQuota.fromJson(quota is Map<String, dynamic> ? quota : const {}),
    );
  }

  /// Identifiant de la transaction Wave (paiement par lien marchand), pour aider l'agent à la retrouver.
  Future<AiOrder> declareWaveRef(String ref, String waveRef) async {
    final r = await _call('/order/wave-ref', {'device_id': deviceId, 'ref': ref, 'wave_ref': waveRef.trim()},
        const Duration(seconds: 15));
    final order = r['order'];
    if (order is! Map) throw AiException('SERVER');
    return AiOrder.fromJson(order);
  }

  Future<Map<String, dynamic>> _call(String path, Map<String, dynamic> params, Duration timeout) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$apiPath$path');
    final body = jsonEncode({'jsonrpc': '2.0', 'method': 'call', 'id': ++_id, 'params': params});
    http.Response response;
    try {
      response = await _http
          .post(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: body)
          .timeout(timeout);
    } on TimeoutException {
      throw AiException('TIMEOUT');
    } on http.ClientException {
      throw AiException('NETWORK');
    } catch (_) {
      throw AiException('NETWORK'); // SocketException, HandshakeException… selon la plateforme
    }
    if (response.statusCode != 200) throw AiException('SERVER', message: 'HTTP ${response.statusCode}');
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw AiException('SERVER');
    }
    if (decoded is! Map || decoded['error'] != null) throw AiException('SERVER');
    final result = decoded['result'];
    if (result is! Map<String, dynamic>) throw AiException('SERVER');
    if (result['success'] != true) {
      final error = (result['error'] as Map?) ?? const {};
      final details = (error['details'] as Map?) ?? const {};
      throw AiException(
        '${error['code'] ?? 'REFUSED'}',
        reason: '${details['reason'] ?? ''}',
        message: '${error['message'] ?? ''}',
        minutes: (details['minutes'] as num?)?.toInt(),
        transfersLeft: (details['transfers_left'] as num?)?.toInt(),
      );
    }
    return result;
  }
}
