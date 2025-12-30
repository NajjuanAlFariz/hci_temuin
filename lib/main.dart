import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ================= FIREBASE INIT =================
  await Firebase.initializeApp();

  /// ================= SUPABASE INIT =================
  await Supabase.initialize(
    url: 'https://mgjyfjejqppcehwwezfp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nanlmamVqcXBwY2Vod3dlemZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY5NDg3NjcsImV4cCI6MjA4MjUyNDc2N30.nq_llR1tXX4I7vcx8I0GKC0pUqSsQGVDJB9ho7iViNQ',
  );

  runApp(const TemuinApp());
}

class TemuinApp extends StatelessWidget {
  const TemuinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Temuin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
