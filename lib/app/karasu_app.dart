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
  late final Future<CalculatorController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = CalculatorController.create();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CalculatorController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF090B11),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'CalcAI could not start cleanly. Restart the app to try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }

        final controller = snapshot.data;
        if (controller == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF090B11),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading CalcAI...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'CalcAI',
              theme: AppTheme.build(controller.activeTheme),
              themeAnimationDuration: const Duration(milliseconds: 220),
              home: CalculatorScreen(controller: controller),
            );
          },
        );
      },
    );
  }
}
