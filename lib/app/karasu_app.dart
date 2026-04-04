import 'package:flutter/material.dart';

import '../core/state/calculator_controller.dart';
import '../ui/screens/calculator_screen.dart';
import '../ui/theme/app_theme.dart';

class KarasuApp extends StatefulWidget {
  const KarasuApp({super.key});

  @override
  State<KarasuApp> createState() => _KarasuAppState();
}

class _KarasuAppState extends State<KarasuApp> {
  late final CalculatorController controller;

  @override
  void initState() {
    super.initState();
    controller = CalculatorController()..seedDemoHistory();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Karasu Calculator',
          theme: AppTheme.build(controller.activeTheme),
          home: CalculatorScreen(controller: controller),
        );
      },
    );
  }
}
