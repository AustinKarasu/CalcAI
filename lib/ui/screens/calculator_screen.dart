import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/calculator_mode.dart';
import '../../core/models/history_entry.dart';
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
  static final Uri _releaseUri =
      Uri.parse('https://github.com/AustinKarasu/CalcAI/releases/latest');

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
                    _CalculatorPage(controller: controller),
                    _AiPage(controller: controller),
                    _SpeechPage(controller: controller),
                    _HistoryPage(controller: controller),
                    _SettingsPage(
                      controller: controller,
                      releaseUri: _releaseUri,
                    ),
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
                    label: 'Calculator',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_rounded),
                    label: 'AI',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_rounded),
                    label: 'Speech',
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

class _CalculatorPage extends StatelessWidget {
  const _CalculatorPage({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: 'Calculator',
            badge: 'CalcAI',
            onSettingsTap: controller.openSettingsPage,
          ),
          const SizedBox(height: 22),
          _DisplayCard(controller: controller),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
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
          if (controller.mode == CalculatorMode.scientific) ...[
            const SizedBox(height: 14),
            _FunctionStrip(controller: controller),
          ],
          if (controller.mode == CalculatorMode.programmer) ...[
            const SizedBox(height: 14),
            _ProgrammerStrip(controller: controller),
          ],
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

class _AiPage extends StatelessWidget {
  const _AiPage({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        _Header(
          title: 'Smart AI',
          badge: 'CalcAI',
          onSettingsTap: controller.openSettingsPage,
        ),
        const SizedBox(height: 22),
        _SmartPromptCard(controller: controller),
        const SizedBox(height: 16),
        _InsightCards(controller: controller),
        const SizedBox(height: 16),
        _StepsCard(controller: controller),
      ],
    );
  }
}

class _SpeechPage extends StatelessWidget {
  const _SpeechPage({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        _Header(
          title: 'Speech Input',
          badge: 'CalcAI',
          onSettingsTap: controller.openSettingsPage,
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Say math naturally', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Examples: "forty five plus six", "one hundred divided by four", "nine times eight".',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.isListening
                          ? null
                          : controller.startVoiceCapture,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Listening'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isListening
                          ? controller.stopVoiceCapture
                          : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SpeechDataCard(
                title: 'Transcript',
                value: controller.speechTranscript.isEmpty
                    ? 'Waiting for spoken input.'
                    : controller.speechTranscript,
              ),
              const SizedBox(height: 12),
              _SpeechDataCard(
                title: 'Expression',
                value: controller.speechExpression.isEmpty
                    ? 'Spoken operators become calculator symbols here.'
                    : controller.speechExpression,
              ),
              const SizedBox(height: 12),
              _SpeechDataCard(
                title: 'Status',
                value: controller.voiceStatus,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: controller.applySpeechToCalculator,
                      child: const Text('Use In Calculator'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.applySpeechToSmartAi,
                      child: const Text('Ask Smart AI'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent History', style: theme.textTheme.headlineSmall),
            ),
            TextButton.icon(
              onPressed: controller.history.isEmpty ? null : controller.clearHistory,
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Stored locally and used to suggest recurring calculations.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 16),
        if (controller.history.isEmpty)
          const _EmptyCard(
            message: 'No history yet. Completed calculations will appear here.',
          ),
        for (final entry in controller.history)
          _HistoryEntryCard(entry: entry, controller: controller),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.controller,
    required this.releaseUri,
  });

  final CalculatorController controller;
  final Uri releaseUri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          'Theme, accessibility, offline behavior, and release-readiness settings.',
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
        _SettingSwitchTile(
          title: 'Live Preview',
          subtitle: 'Show a safe preview while the expression is incomplete.',
          value: controller.livePreviewEnabled,
          onChanged: controller.setLivePreview,
        ),
        _SettingSwitchTile(
          title: 'Save History',
          subtitle: 'Store completed calculations locally for quick recall.',
          value: controller.saveHistoryEnabled,
          onChanged: controller.setSaveHistory,
        ),
        _SettingSwitchTile(
          title: 'Smart Suggestions',
          subtitle: 'Generate quick prompts from recent calculation patterns.',
          value: controller.smartSuggestionsEnabled,
          onChanged: controller.setSmartSuggestions,
        ),
        _SettingSwitchTile(
          title: 'Speech Auto Apply',
          subtitle: 'Send recognized speech straight into the calculator.',
          value: controller.speechAutoApplyEnabled,
          onChanged: controller.setSpeechAutoApply,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => launchUrl(releaseUri, mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.system_update_alt_rounded),
          label: const Text('Check For Updates'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.history.isEmpty ? null : controller.clearHistory,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Clear History'),
        ),
        const SizedBox(height: 20),
        _CreditsCard(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.badge,
    required this.onSettingsTap,
  });

  final String title;
  final String badge;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24),
              ),
              Text(
                badge,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSettingsTap,
          icon: Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
          tooltip: 'Settings',
        ),
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
              controller.formattedExpression(),
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

class _FunctionStrip extends StatelessWidget {
  const _FunctionStrip({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.quickScientificFunctions().length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final function = controller.quickScientificFunctions()[index];
          return ActionChip(
            label: Text(function),
            onPressed: () => controller.insertFunction(function),
          );
        },
      ),
    );
  }
}

class _ProgrammerStrip extends StatelessWidget {
  const _ProgrammerStrip({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.programmerShortcutTokens().length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final token = controller.programmerShortcutTokens()[index];
          return ActionChip(
            label: Text(token),
            onPressed: () => controller.insertProgrammerToken(token),
          );
        },
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
                  hintText: 'split \$120 among 3 people with 10% tip',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.14),
                  prefixIcon: const Icon(Icons.auto_fix_high_rounded),
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
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              maxLines: 2,
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
            title: 'History insight',
            value: controller.insight,
            icon: Icons.psychology_alt_rounded,
            accent: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            title: 'Current result',
            value: controller.result,
            icon: Icons.bolt_rounded,
            accent: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.controller});

  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Steps', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final step in controller.steps) ...[
            Text(
              step,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
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
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SpeechDataCard extends StatelessWidget {
  const _SpeechDataCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credits', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            'Built for AayanKarasu, 18yo developer, editor, designer, vibe coder, and ethical hacker.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Creative direction, release ambition, and product energy led by AayanKarasu.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CalcAI is shaped to feel fast, sharp, expressive, and practical for everyday use.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.controller,
  });

  final HistoryEntry entry;
  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numbers = controller.numbersUsedFor(entry);
    return Container(
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
            'Numbers used: ${numbers.isEmpty ? 'None' : numbers.join(', ')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.mode.label} - ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.7),
        ),
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
      ['C', 'DEL', '%', '/'],
      ['7', '8', '9', '*'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '+/-', '='],
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
                      label: key == '*' ? 'x' : key,
                      isAccent: ['/', '*', '-', '+', '='].contains(key),
                      onTap: () => _onKeyTap(key),
                      onLongPress: ['/', '*', '-', '+', '%'].contains(key)
                          ? () => controller.longPressFunction(key)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          controller.mode == CalculatorMode.scientific
              ? 'Long press operators or use the function strip for scientific shortcuts.'
              : controller.mode == CalculatorMode.programmer
                  ? 'Use the programmer strip for A-F, 0b, 0x, and bitwise operators.'
                  : 'Swipe left to delete. Incomplete expressions keep a safe preview.',
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
      case 'DEL':
        controller.backspace();
        return;
      case '=':
        controller.evaluateExpression();
        return;
      case '+/-':
        controller.toggleSign();
        return;
      default:
        controller.appendToken(key);
        return;
    }
  }
}
