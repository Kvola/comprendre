/// Réglages de l'application (table `settings` de la base).
class AppSettings {
  const AppSettings({
    this.localeCode,
    this.themeMode = 'system',
    this.aiMode = 'ask',
    this.questionCount = 10,
    this.deviceId,
  });

  factory AppSettings.fromMap(Map<String, String> m) => AppSettings(
    localeCode: switch (m['locale']) { 'fr' => 'fr', 'en' => 'en', _ => null },
    themeMode: m['theme'] ?? 'system',
    aiMode: switch (m['ai']) { 'on' => 'on', 'off' => 'off', _ => 'ask' },
    questionCount: switch (int.tryParse(m['questions'] ?? '')) { 5 => 5, 15 => 15, _ => 10 },
    deviceId: m['device_id'],
  );

  /// null = langue du téléphone.
  final String? localeCode;

  /// `system` | `light` | `dark`
  final String themeMode;

  /// `ask` (pas encore choisi) | `on` | `off`
  final String aiMode;
  final int questionCount;
  final String? deviceId;
}
