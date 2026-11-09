import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'app/providers.dart';
import 'core/app_update.dart';
import 'data/database.dart';
import 'remote/ai_client.dart' show defaultServer;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(AppDatabase()),
        if (appUpdateSupported)
          appUpdateCheckerProvider.overrideWithValue(
            AppUpdateChecker(server: defaultServer, slug: 'comprendre', store: PrefsAppUpdateStore()),
          ),
      ],
      child: const ComprendreApp(),
    ),
  );
}
