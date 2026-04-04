import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/calculator_mode.dart';
import '../models/history_entry.dart';
import '../models/smart_suggestion.dart';
import '../services/calculation_engine.dart';
import '../services/conversion_service.dart';
import '../services/history_intelligence_service.dart';
import '../services/smart_query_service.dart';
import '../services/voice_service.dart';

class CalculatorController extends ChangeNotifier {
  CalculatorController()
      : _engine = CalculationEngine(),
        _historyService = HistoryIntelligenceService(),
        _voiceService = VoiceService() {
    _smartQueryService = SmartQueryService(_engine, ConversionService());
    _queryController.text = smartPrompt;
  }

  final TextEditingController _queryController = TextEditingController();
  final CalculationEngine _engine;
  final HistoryIntelligenceService _historyService;
  final VoiceService _voiceService;
  late final SmartQueryService _smartQueryService;

  CalculatorMode mode = CalculatorMode.focus;
  AppThemeMode activeTheme = AppThemeMode.neon;
  int bottomTab = 0;
  String expression = '150 ÷ 4';
  String result = '37.5';
  String smartPrompt = 'Split \$150 among 4 people...';
  String insight = 'History intelligence learns repeated patterns locally.';
  String voiceStatus = 'Voice input is prepared for offline plugins.';
  List<String> steps = const [
    'Swipe left on the display to delete the last character.',
  ];
  List<HistoryEntry> history = const [];
  List<SmartSuggestion> suggestions = const [];
  List<OffsetPoint> graphPoints = const [];

  TextEditingController get queryController => _queryController;

  void seedDemoHistory() {
    history = [
      HistoryEntry(
        query: 'split \$150 among 4 people with 10% tip',
        expression: '(150 + 15) / 4',
        result: '41.25',
        mode: CalculatorMode.focus,
        timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
      ),
      HistoryEntry(
        query: '5 km to miles',
        expression: '5 km -> miles',
        result: '3.1069',
        mode: CalculatorMode.focus,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      HistoryEntry(
        query: 'emi for \$250000 at 8.5% for 240 months',
        expression: 'EMI',
        result: '2169.42',
        mode: CalculatorMode.financial,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    suggestions = _historyService.buildSuggestions(history);
  }

  void setBottomTab(int index) {
    bottomTab = index;
    notifyListeners();
  }

  void setMode(CalculatorMode next) {
    mode = next;
    if (mode == CalculatorMode.visual) {
      expression = 'y=x^2';
      graphPoints = _engine.buildGraphPoints(expression);
      result = '${graphPoints.length} plot points';
      steps = const [
        'Visual Math Mode graphs the equation in real time.',
        'Try y=sin(x) or y=x^3-2*x.',
      ];
    }
    notifyListeners();
  }

  void setTheme(AppThemeMode next) {
    activeTheme = next;
    notifyListeners();
  }

  void appendToken(String token) {
    if (expression == '0' || expression == 'Error') {
      expression = token;
    } else {
      expression += token;
    }
    _evaluateCurrent();
  }

  void backspace() {
    if (expression.isEmpty) {
      return;
    }
    expression = expression.substring(0, expression.length - 1);
    if (expression.isEmpty) {
      expression = '0';
    }
    _evaluateCurrent();
  }

  void clear() {
    expression = '0';
    result = '0';
    steps = const ['Ready for the next calculation.'];
    notifyListeners();
  }

  void evaluateExpression() {
    final calculation = _engine.evaluate(expression, mode);
    _applyCalculation(
      calculation,
      originalQuery: expression,
      selectedMode: mode,
    );
  }

  void runSmartQuery([String? override]) {
    final query = override ?? _queryController.text;
    if (query.trim().isEmpty) {
      return;
    }
    final intent = _smartQueryService.parse(query, mode);
    mode = intent.suggestedMode;
    _queryController.text = query;
    smartPrompt = query;
    if (mode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(intent.result.expression);
    }
    _applyCalculation(
      intent.result,
      originalQuery: query,
      selectedMode: mode,
    );
  }

  void useSuggestion(SmartSuggestion suggestion) {
    _queryController.text = suggestion.prefill;
    runSmartQuery(suggestion.prefill);
  }

  void toggleSign() {
    if (expression.startsWith('-')) {
      expression = expression.substring(1);
    } else {
      expression = '-$expression';
    }
    _evaluateCurrent();
  }

  void longPressFunction(String token) {
    final alternate = switch (token) {
      '%' => 'sqrt(',
      '÷' => 'log(',
      '×' => 'sin(',
      '-' => 'cos(',
      '+' => 'tan(',
      _ => token,
    };
    appendToken(alternate);
  }

  String modeSubtitle() {
    return switch (mode) {
      CalculatorMode.focus =>
        'Minimal input, smart shortcuts, and quick arithmetic.',
      CalculatorMode.scientific =>
        'Trig, logs, powers, and engineering-style calculations.',
      CalculatorMode.programmer =>
        'Base conversions and bitwise operations for binary workflows.',
      CalculatorMode.financial =>
        'EMI, interest, tax, and everyday money intelligence.',
      CalculatorMode.visual =>
        'Graph equations and inspect step-by-step math behavior.',
    };
  }

  String smartBannerTitle() {
    return switch (mode) {
      CalculatorMode.programmer => 'Binary insight ready',
      CalculatorMode.financial => 'Finance intelligence ready',
      CalculatorMode.visual => 'Graph intelligence ready',
      _ => 'Smart calculation ready',
    };
  }

  String accessibilitySummary() {
    return '${_voiceService.inputHint()} ${_voiceService.speakHint(result)}';
  }

  void _evaluateCurrent() {
    if (mode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(expression);
      result = graphPoints.isEmpty ? 'No graph' : '${graphPoints.length} plot points';
      steps = const ['Graph refreshed.'];
      notifyListeners();
      return;
    }

    final calculation = _engine.evaluate(expression, mode);
    result = calculation.result;
    steps = calculation.steps;
    notifyListeners();
  }

  void _applyCalculation(
    CalculationResult calculation, {
    required String originalQuery,
    required CalculatorMode selectedMode,
  }) {
    expression = calculation.expression;
    result = calculation.result;
    steps = calculation.steps;
    insight = calculation.note ??
        'Shortcut suggestion: long-press operators for advanced functions.';
    voiceStatus = _voiceService.speakHint(result);
    if (selectedMode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(calculation.expression);
    }
    history = [
      HistoryEntry(
        query: originalQuery,
        expression: calculation.expression,
        result: calculation.result,
        mode: selectedMode,
        timestamp: DateTime.now(),
        note: calculation.note,
      ),
      ...history,
    ].take(10).toList();
    suggestions = _historyService.buildSuggestions(history);
    notifyListeners();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}
