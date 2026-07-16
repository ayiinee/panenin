import 'package:flutter/material.dart';
import 'package:panenin/app/theme/app_theme.dart';
import 'package:panenin/features/home/presentation/screens/farmer_home_screen.dart';

class PaneninApp extends StatelessWidget {
  const PaneninApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panenin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const FarmerHomeScreen(),
    );
  }
}
