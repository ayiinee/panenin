import 'package:flutter/material.dart';
import 'package:panenin/app/app.dart' as app;
import 'package:panenin/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:panenin/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.ensureConfigured();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  runApp(
    app.PaneninApp(authEvents: Supabase.instance.client.auth.onAuthStateChange),
  );
}
