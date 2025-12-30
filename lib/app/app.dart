import 'package:flutter/material.dart';
import '../app/router.dart';
import '../theme/app_theme.dart';

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
