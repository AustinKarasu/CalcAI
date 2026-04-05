import 'dart:async';

import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/calculator_mode.dart';
import '../models/history_entry.dart';
import '../models/smart_suggestion.dart';
import '../services/app_storage.dart';
import '../services/calculation_engine.dart';
import '../services/conversion_service.dart';
import '../services/history_intelligence_service.dart';
import '../services/smart_query_service.dart';
import '../services/voice_service.dart';

class CalculatorController extends ChangeNotifier {
  CalculatorController._({
    required AppStorage storage,
    required CalculationEngine engine,
    required HistoryIntelligenceService historyService,
    required VoiceService voiceService,
  })  : _storage = storage,
        _engine = engine,
        _historyService = historyService,
        _voiceService = voiceService {
    _smartQueryService = SmartQueryService(_engine, ConversionService());
  }

  static Future<CalculatorController> create() async {
    final controller = CalculatorController._(
      storage: AppStorage(),
      engine: CalculationEngine(),
      historyService: HistoryIntelligenceService(),
      voiceService: VoiceService(),
    );
    await controller._initialize();
    return controller;
  }

  final TextEditingController _queryController = TextEditingController();
  final AppStorage _storage;
  final CalculationEngine _engine;
  final HistoryIntelligenceService _historyService;
  final VoiceService _voiceService;
  late final SmartQueryService _smartQueryService;

  CalculatorMode mode = CalculatorMode.focus;
  AppThemeMode activeTheme = AppThemeMode.neon;
  int bottomTab = 0;
  String expression = '150 / 4';
  String result = '37.5';
  String smartPrompt = 'split \$150 among 4 people with 10% tip';
  String insight = 'History intelligence learns repeated patterns locally.';
  String voiceStatus = 'Voice input is prepared for offline plugins.';
  List<String> steps = const ['Tap = to evaluate.'];
  List<HistoryEntry> history = const [];
  List<SmartSuggestion> suggestions = const [];
  List<OffsetPoint> graphPoints = const [];

  TextEditingController get queryController => _queryController;

  Future<void> _initialize() async {
    final persisted = await _storage.load();
    if (persisted != null) {
      expression = persisted.expression;
      result = persisted.result;
      smartPrompt = persisted.smartPrompt;
      insight = persisted.insight.isEmpty
          ? 'History intelligence learns repeated patterns locally.'
          : persisted.insight;
      steps = persisted.steps.isEmpty ? const ['Tap = to evaluate.'] : persisted.steps;
      mode = persisted.mode;
      activeTheme = persisted.theme;
      history = persisted.history;
    } else {
      _seedDemoHistory();
    }

    _queryController.text = smartPrompt;
    suggestions = _historyService.buildSuggestions(history);
    if (mode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(expression);
    }
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
        'Try y=sin(x), y=x^3-2*x, or graph x*x+3.',
      ];
    } else if (expression == 'y=x^2') {
      expression = '0';
      result = '0';
      steps = const ['Ready for the next calculation.'];
    } else {
      _evaluateCurrent();
    }
    _persistAndNotify();
  }

  void setTheme(AppThemeMode next) {
    activeTheme = next;
    _persistAndNotify();
  }

  void appendToken(String token) {
    final shouldReplace = expression == '0' || expression == 'Error';
    if (shouldReplace && !_isBinaryOperator(token)) {
      expression = token;
    } else if (token == '.' && _currentNumberSegment().contains('.')) {
      return;
    } else if (_isBinaryOperator(token)) {
      expression = _appendOperator(token);
    } else {
      expression += token;
    }
    _evaluateCurrent();
    _persistAndNotify();
  }

  void backspace() {
    if (expression.isEmpty || expression == '0') {
      return;
    }
    expression = expression.substring(0, expression.length - 1).trimRight();
    if (expression.isEmpty) {
      expression = '0';
    }
    _evaluateCurrent();
    _persistAndNotify();
  }

  void clear() {
    expression = '0';
    result = '0';
    steps = const ['Ready for the next calculation.'];
    _persistAndNotify();
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
    final query = (override ?? _queryController.text).trim();
    if (query.isEmpty) {
      return;
    }
    final intent = _smartQueryService.parse(query, mode);
    mode = intent.suggestedMode;
    smartPrompt = query;
    _queryController.text = query;
    _applyCalculation(
      intent.result,
      originalQuery: query,
      selectedMode: mode,
    );
  }

  void useSuggestion(SmartSuggestion suggestion) {
    runSmartQuery(suggestion.prefill);
  }

  void toggleSign() {
    if (expression == '0') {
      expression = '-';
    } else if (expression.startsWith('-')) {
      expression = expression.substring(1);
    } else {
      expression = '-$expression';
    }
    _evaluateCurrent();
    _persistAndNotify();
  }

  void longPressFunction(String token) {
    final alternate = switch (token) {
      '%' => 'sqrt(',
      '/' => 'log(',
      '*' => 'sin(',
      '-' => 'cos(',
      '+' => 'tan(',
      _ => token,
    };
    appendToken(alternate);
  }

  String modeSubtitle() {
    return switch (mode) {
      CalculatorMode.focus =>
        'Fast arithmetic with a distraction-free layout.',
      CalculatorMode.scientific =>
        'Trig, logs, powers, and engineering-style calculations.',
      CalculatorMode.programmer =>
        'Base conversions and bitwise operations for binary workflows.',
      CalculatorMode.financial =>
        'EMI, interest, tax, and money calculations.',
      CalculatorMode.visual =>
        'Graph equations and inspect step-by-step math behavior.',
    };
  }

  String smartBannerTitle() {
    return switch (mode) {
      CalculatorMode.programmer => 'Programmer assistant',
      CalculatorMode.financial => 'Finance assistant',
      CalculatorMode.visual => 'Visual math assistant',
      _ => 'Smart AI assistant',
    };
  }

  String accessibilitySummary() {
    return '${_voiceService.inputHint()} ${_voiceService.speakHint(result)}';
  }

  String formattedExpression() {
    return expression.replaceAll('*', 'x').replaceAll('/', '/');
  }

  void _evaluateCurrent() {
    if (mode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(expression);
      result =
          graphPoints.isEmpty ? 'No graph' : '${graphPoints.length} plot points';
      steps = const ['Graph refreshed.'];
      return;
    }

    final calculation = _engine.evaluate(expression, mode);
    result = calculation.result;
    steps = calculation.steps;
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
        'Suggestion: use Smart AI for natural-language calculations.';
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
    ].take(20).toList();
    suggestions = _historyService.buildSuggestions(history);
    _persistAndNotify();
  }

  bool _isBinaryOperator(String token) {
    return token == '+' || token == '-' || token == '*' || token == '/';
  }

  String _appendOperator(String token) {
    final trimmed = expression.trimRight();
    if (trimmed.isEmpty || trimmed == '0') {
      return token == '-' ? '-' : '0 $token ';
    }

    final lastChar = trimmed.substring(trimmed.length - 1);
    if (_isBinaryOperator(lastChar)) {
      return '${trimmed.substring(0, trimmed.length - 1)}$token ';
    }
    return '$trimmed $token ';
  }

  String _currentNumberSegment() {
    final segments = expression.split(RegExp(r'[+\-*/()]'));
    return segments.isEmpty ? '' : segments.last.trim();
  }

  void _seedDemoHistory() {
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
        expression: 'emi(250000,8.5,240)',
        result: '2169.42',
        mode: CalculatorMode.financial,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    suggestions = _historyService.buildSuggestions(history);
  }

  void _persistAndNotify() {
    unawaited(
      _storage.save(
        PersistedAppState(
          expression: expression,
          result: result,
          smartPrompt: smartPrompt,
          insight: insight,
          steps: steps,
          mode: mode,
          theme: activeTheme,
          history: history,
        ),
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}
