import 'package:flutter/material.dart';

import 'game/game_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AetherApp());
}

class AetherApp extends StatelessWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aether Drift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const GamePage(),
    );
  }
}
