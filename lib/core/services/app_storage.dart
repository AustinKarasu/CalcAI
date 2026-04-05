import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculator_mode.dart';
import '../models/history_entry.dart';

class AppStorage {
  static const _expressionKey = 'expression';
  static const _resultKey = 'result';
  static const _smartPromptKey = 'smart_prompt';
  static const _insightKey = 'insight';
  static const _stepsKey = 'steps';
  static const _modeKey = 'mode';
  static const _themeKey = 'theme';
  static const _historyKey = 'history';
  static const _livePreviewKey = 'live_preview';
  static const _saveHistoryKey = 'save_history';
  static const _smartSuggestionsKey = 'smart_suggestions';
  static const _speechAutoApplyKey = 'speech_auto_apply';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<PersistedAppState?> load() async {
    final expression = await _prefs.getString(_expressionKey);
    if (expression == null) {
      return null;
    }

    final result = await _prefs.getString(_resultKey) ?? '0';
    final smartPrompt = await _prefs.getString(_smartPromptKey) ?? '';
    final insight = await _prefs.getString(_insightKey) ?? '';
    final modeName = await _prefs.getString(_modeKey);
    final themeName = await _prefs.getString(_themeKey);
    final stepsJson = await _prefs.getStringList(_stepsKey) ?? const <String>[];
    final historyRaw = await _prefs.getStringList(_historyKey) ?? const <String>[];
    final livePreview = await _prefs.getBool(_livePreviewKey) ?? true;
    final saveHistory = await _prefs.getBool(_saveHistoryKey) ?? true;
    final smartSuggestions = await _prefs.getBool(_smartSuggestionsKey) ?? true;
    final speechAutoApply = await _prefs.getBool(_speechAutoApplyKey) ?? true;
    final history = historyRaw
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .map(HistoryEntry.fromJson)
        .toList();

    return PersistedAppState(
      expression: expression,
      result: result,
      smartPrompt: smartPrompt,
      insight: insight,
      steps: stepsJson,
      mode: CalculatorModeX.fromName(modeName),
      theme: AppThemeModeX.fromName(themeName),
      history: history,
      livePreview: livePreview,
      saveHistory: saveHistory,
      smartSuggestions: smartSuggestions,
      speechAutoApply: speechAutoApply,
    );
  }

  Future<void> save(PersistedAppState state) async {
    await _prefs.setString(_expressionKey, state.expression);
    await _prefs.setString(_resultKey, state.result);
    await _prefs.setString(_smartPromptKey, state.smartPrompt);
    await _prefs.setString(_insightKey, state.insight);
    await _prefs.setStringList(_stepsKey, state.steps);
    await _prefs.setString(_modeKey, state.mode.name);
    await _prefs.setString(_themeKey, state.theme.name);
    await _prefs.setBool(_livePreviewKey, state.livePreview);
    await _prefs.setBool(_saveHistoryKey, state.saveHistory);
    await _prefs.setBool(_smartSuggestionsKey, state.smartSuggestions);
    await _prefs.setBool(_speechAutoApplyKey, state.speechAutoApply);
    await _prefs.setStringList(
      _historyKey,
      state.history.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

class PersistedAppState {
  const PersistedAppState({
    required this.expression,
    required this.result,
    required this.smartPrompt,
    required this.insight,
    required this.steps,
    required this.mode,
    required this.theme,
    required this.history,
    required this.livePreview,
    required this.saveHistory,
    required this.smartSuggestions,
    required this.speechAutoApply,
  });

  final String expression;
  final String result;
  final String smartPrompt;
  final String insight;
  final List<String> steps;
  final CalculatorMode mode;
  final AppThemeMode theme;
  final List<HistoryEntry> history;
  final bool livePreview;
  final bool saveHistory;
  final bool smartSuggestions;
  final bool speechAutoApply;
}
