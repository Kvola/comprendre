import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_update.dart';
import '../data/database.dart';
import '../remote/ai_client.dart';
import 'quiz_service.dart';
import 'settings.dart';

/// Fourni dans `main()` via `overrideWithValue`.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

/// Vérification des nouvelles versions : null = aucune (tests, iOS, ordinateur).
/// Activée dans `main()` sur Android ; sans réseau, l'application n'en voit rien.
final appUpdateCheckerProvider = Provider<AppUpdateChecker?>((ref) => null);

/// Web : page de téléchargement de l'application Android à proposer (null = rien).
final webInstallUrlProvider = Provider<Uri?>((ref) => null);

/// Adresse du serveur IA (remplaçable dans les tests).
final serverUrlProvider = Provider<String>((ref) => defaultServer);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(databaseProvider).watchSettings().map(AppSettings.fromMap),
);

/// Identifiant d'appareil aléatoire, créé au premier besoin et gardé dans la base.
final deviceIdProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(databaseProvider);
  final existing = await db.setting('device_id');
  if (existing != null && existing.length >= 16) return existing;
  final id = newDeviceId();
  await db.setSetting('device_id', id);
  return id;
});

final aiClientProvider = FutureProvider<AiClient>((ref) async {
  return AiClient(deviceId: await ref.watch(deviceIdProvider.future), baseUrl: ref.watch(serverUrlProvider));
});

/// Quota IA du jour ; null hors connexion.
final quotaProvider = FutureProvider.autoDispose<AiQuota?>((ref) async {
  try {
    return await (await ref.watch(aiClientProvider.future)).quota();
  } catch (_) {
    return null;
  }
});

final quizServiceProvider = FutureProvider<QuizService>((ref) async {
  return QuizService(ref.watch(databaseProvider), await ref.watch(aiClientProvider.future));
});

final libraryProvider = StreamProvider<List<DocumentSummary>>((ref) => ref.watch(databaseProvider).watchLibrary());

final documentProvider = StreamProvider.family<Document?, int>((ref, id) => ref.watch(databaseProvider).watchDocument(id));

final quizzesProvider = StreamProvider.family<List<QuizSummary>, int>(
  (ref, id) => ref.watch(databaseProvider).watchQuizzes(id),
);
