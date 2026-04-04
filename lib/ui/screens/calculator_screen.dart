import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/models/calculator_mode.dart';
import '../../core/models/smart_suggestion.dart';
import '../../core/state/calculator_controller.dart';
import '../widgets/graph_card.dart';
import '../widgets/keypad_button.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({
    super.key,
    required this.controller,
  });

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withValues(alpha: 0.96),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: controller.bottomTab,
                  children: [
                    _HomeTab(controller: controller),
                    _HistoryTab(controller: controller),
                    _SettingsTab(controller: controller),
                  ],
                ),
              ),
              NavigationBar(
                selectedIndex: controller.bottomTab,
                onDestinationSelected: controller.setBottomTab,
                backgroundColor: Colors.transparent,
                indicatorColor:
                    theme.colorScheme.primary.withValues(alpha: 0.18),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.calculate_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_rounded),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          const SizedBox(height: 24),
          _DisplayCard(controller: controller),
          const SizedBox(height: 16),
          _SmartPromptCard(controller: controller),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CalculatorMode.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mode = CalculatorMode.values[index];
                return ChoiceChip(
                  label: Text(mode.label),
                  selected: controller.mode == mode,
                  onSelected: (_) => controller.setMode(mode),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _InsightCards(controller: controller),
          const SizedBox(height: 16),
          if (controller.mode == CalculatorMode.visual)
            GraphCard(
              points: controller.graphPoints,
              expression: controller.expression,
            )
          else
            _Keypad(controller: controller),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.menu_rounded, color: theme.colorScheme.primary),
        const Spacer(),
        Text(
          'KARASU CALCULATOR',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.6,
          ),
        ),
        const Spacer(),
        Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
      ],
    );
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0) {
          controller.backspace();
        } else if (velocity > 0) {
          controller.clear();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.64),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              controller.expression,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              controller.result,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                controller.modeSubtitle(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartPromptCard extends StatelessWidget {
  const _SmartPromptCard({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    controller.smartBannerTitle(),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.queryController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Split \$120 among 3 people with 10% tip',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.14),
                  prefixIcon: const Icon(Icons.mic_none_rounded),
                  suffixIcon: IconButton(
                    onPressed: controller.runSmartQuery,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => controller.runSmartQuery(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final suggestion = controller.suggestions[index];
                    return _SuggestionChip(
                      suggestion: suggestion,
                      onTap: () => controller.useSuggestion(suggestion),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final SmartSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 178,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              suggestion.title,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCards extends StatelessWidget {
  const _InsightCards({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            title: 'History Intelligence',
            value: controller.insight,
            icon: Icons.psychology_alt_rounded,
            accent: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            title: 'Accessibility',
            value: controller.accessibilitySummary(),
            icon: Icons.record_voice_over_rounded,
            accent: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const rows = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '±', '='],
    ];
    return Column(
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: KeypadButton(
                      label: key,
                      isAccent: ['÷', '×', '-', '+', '='].contains(key),
                      onTap: () => _onKeyTap(key),
                      onLongPress: ['÷', '×', '-', '+', '%'].contains(key)
                          ? () => controller.longPressFunction(key)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          'Long press operators for scientific shortcuts. Swipe the display left to delete.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.56),
          ),
        ),
      ],
    );
  }

  void _onKeyTap(String key) {
    switch (key) {
      case 'C':
        controller.clear();
        return;
      case '⌫':
        controller.backspace();
        return;
      case '=':
        controller.evaluateExpression();
        return;
      case '±':
        controller.toggleSign();
        return;
      default:
        controller.appendToken(key);
        return;
    }
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recent History', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Stored locally and used to suggest recurring calculations.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in controller.history)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.query, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '${entry.expression} = ${entry.result}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.mode.label} • ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Personalization', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          'Adaptive layout, themes, and accessibility hooks designed for an intelligent mobile calculator.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final appTheme in AppThemeMode.values)
              ChoiceChip(
                label: Text(appTheme.label),
                selected: controller.activeTheme == appTheme,
                onSelected: (_) => controller.setTheme(appTheme),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Offline-first',
          value:
              'Core arithmetic, financial presets, smart parsing, history patterns, and graphing all run on-device.',
          icon: Icons.offline_bolt_rounded,
          accent: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Adaptive UI',
          value:
              'The home view prioritizes Focus Mode, while advanced modes expose extra intelligence without leaving the main workspace.',
          icon: Icons.tune_rounded,
          accent: theme.colorScheme.secondary,
        ),
      ],
    );
  }
}
