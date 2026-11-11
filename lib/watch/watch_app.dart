import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'screens/watch_home_screen.dart';

/// Ponto de entrada da aplicação para Smartwatch (Wear OS / watchOS)
class WatchApp extends StatelessWidget {
  final bool isCircular;

  const WatchApp({
    super.key,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Titan Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: AppColors.primaryOrange,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryOrange,
          surface: AppColors.cardBackground,
        ),
      ),
      home: WatchHomeScreen(isCircular: isCircular),
    );
  }
}
