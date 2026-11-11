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
  AiException(this.code, {this.reason = '', this.message = '', this.minutes});

  /// `NETWORK` | `TIMEOUT` | `SERVER` | `REFUSED` | `AI_FAILED` | `AUTH_010` | `BAD_REQUEST`
  final String code;

  /// Raison précise donnée par le serveur (`quota`, `too_long`, `busy`…), pour un message traduit.
  final String reason;

  /// Message du serveur (en français), en dernier recours.
  final String message;
  final int? minutes;

  bool get isNetwork => code == 'NETWORK' || code == 'TIMEOUT';

  @override
  String toString() => 'AiException($code/$reason): $message';
}

class AiQuota {
  const AiQuota({
    required this.remaining,
    required this.daily,
    required this.maxChars,
    required this.enabled,
    this.limited = '',
    this.languages = const {'fr', 'en'},
  });

  final int remaining;
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
    final r = await _call('/quota', {'device_id': deviceId}, const Duration(seconds: 12));
    return AiQuota(
      remaining: (r['remaining'] as num?)?.toInt() ?? 0,
      daily: (r['daily'] as num?)?.toInt() ?? 0,
      maxChars: (r['max_chars'] as num?)?.toInt() ?? 30000,
      enabled: r['enabled'] != false,
      limited: r['limited'] is String ? r['limited'] as String : '',
      languages: r['languages'] is List ? {for (final l in r['languages'] as List) '$l'} : const {'fr', 'en'},
    );
  }

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
      );
    }
    return result;
  }
}
