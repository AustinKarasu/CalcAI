import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/calculation_result.dart';
import '../models/calculator_mode.dart';
import '../models/history_entry.dart';
import '../models/smart_suggestion.dart';
import '../services/app_storage.dart';
import '../services/calculation_engine.dart';
import '../services/conversion_service.dart';
import '../services/history_intelligence_service.dart';
import '../services/openrouter_service.dart';
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
    _openRouterService = OpenRouterService();
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
  late final OpenRouterService _openRouterService;
  Timer? _persistDebounce;

  CalculatorMode mode = CalculatorMode.focus;
  AppThemeMode activeTheme = AppThemeMode.neon;
  int bottomTab = 0;
  String expression = '150 / 4';
  String result = '37.5';
  String smartPrompt = 'split \$150 among 4 people with 10% tip';
  String insight = 'History intelligence learns repeated patterns locally.';
  String voiceStatus = 'Voice input is ready.';
  String speechTranscript = '';
  String speechExpression = '';
  bool speechAvailable = false;
  bool isListening = false;
  bool livePreviewEnabled = true;
  bool saveHistoryEnabled = true;
  bool smartSuggestionsEnabled = true;
  bool speechAutoApplyEnabled = true;
  bool remoteAiEnabled = true;
  String openRouterApiKey = '';
  String openRouterModel = 'openai/gpt-4o-mini';
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
      livePreviewEnabled = persisted.livePreview;
      saveHistoryEnabled = persisted.saveHistory;
      smartSuggestionsEnabled = persisted.smartSuggestions;
      speechAutoApplyEnabled = persisted.speechAutoApply;
      openRouterApiKey = persisted.openRouterApiKey;
      openRouterModel = persisted.openRouterModel;
      remoteAiEnabled = persisted.remoteAiEnabled;
    } else {
      _seedDemoHistory();
    }

    _queryController.text = smartPrompt;
    _refreshSuggestions();
    if (mode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(expression);
    }
  }

  void setBottomTab(int index) {
    bottomTab = index;
    notifyListeners();
  }

  void openSettingsPage() {
    setBottomTab(4);
  }

  void clearHistory() {
    history = const [];
    insight = 'History cleared. New calculation patterns will appear here.';
    _refreshSuggestions();
    _persistAndNotify();
  }

  void setMode(CalculatorMode next) {
    mode = next;
    if (mode == CalculatorMode.visual) {
      if (!expression.contains('x')) {
        expression = 'y=x^2';
      }
      graphPoints = _engine.buildGraphPoints(expression);
      result = graphPoints.isEmpty ? 'No graph' : '${graphPoints.length} plot points';
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

  void updateVisualExpression(String value) {
    expression = value.trim().isEmpty ? 'y=x^2' : value.trim();
    if (mode == CalculatorMode.visual) {
      _evaluateCurrent();
    }
    _persistAndNotify();
  }

  void useVisualSample(String sample) {
    expression = sample;
    if (mode != CalculatorMode.visual) {
      mode = CalculatorMode.visual;
    }
    _evaluateCurrent();
    _persistAndNotify();
  }

  void setLivePreview(bool value) {
    livePreviewEnabled = value;
    if (livePreviewEnabled) {
      _evaluateCurrent();
    }
    _persistAndNotify();
  }

  void setSaveHistory(bool value) {
    saveHistoryEnabled = value;
    if (!value) {
      history = const [];
    }
    _refreshSuggestions();
    _persistAndNotify();
  }

  void setSmartSuggestions(bool value) {
    smartSuggestionsEnabled = value;
    _refreshSuggestions();
    _persistAndNotify();
  }

  void setSpeechAutoApply(bool value) {
    speechAutoApplyEnabled = value;
    _persistAndNotify();
  }

  void setRemoteAiEnabled(bool value) {
    remoteAiEnabled = value;
    _persistAndNotify();
  }

  void setOpenRouterApiKey(String value) {
    openRouterApiKey = value.trim();
    _persistAndNotify();
  }

  void setOpenRouterModel(String value) {
    openRouterModel = value.trim().isEmpty ? 'openai/gpt-4o-mini' : value.trim();
    _persistAndNotify();
  }

  Future<void> appendToken(String token) async {
    if (_shouldInsertAsFreshToken(token)) {
      expression = token;
    } else if (token == '.' && _currentNumberSegment().contains('.')) {
      return;
    } else if (_isBinaryOperator(token)) {
      expression = _appendOperator(token);
    } else {
      expression += token;
    }
    await _afterInputChanged();
  }

  Future<void> backspace() async {
    if (expression.isEmpty || expression == '0') {
      return;
    }
    expression = expression.substring(0, expression.length - 1).trimRight();
    if (expression.isEmpty) {
      expression = '0';
    }
    await _afterInputChanged();
  }

  void clear() {
    expression = '0';
    result = '0';
    steps = const ['Ready for the next calculation.'];
    _persistAndNotify();
  }

  void evaluateExpression() {
    final sanitized = _sanitizeForEvaluation(expression);
    final calculation = _engine.evaluate(sanitized, mode);
    _applyCalculation(
      calculation,
      originalQuery: expression,
      selectedMode: mode,
    );
  }

  Future<void> runSmartQuery([String? override]) async {
    final query = (override ?? _queryController.text).trim();
    if (query.isEmpty) {
      return;
    }
    try {
      final intent = _smartQueryService.parse(query, mode);
      if (remoteAiEnabled &&
          (intent.result.result == 'Need math' || intent.result.result == 'Error')) {
        final remote = await _openRouterService.solve(
          query: query,
          apiKey: openRouterApiKey,
          model: openRouterModel,
          currentMode: mode,
        );
        if (remote != null && remote.errorMessage == null) {
          mode = remote.suggestedMode;
          smartPrompt = query;
          _queryController.text = query;
          _applyCalculation(
            remote.calculation,
            originalQuery: query,
            selectedMode: mode,
          );
          return;
        }
        if (remote?.errorMessage != null) {
          insight = remote!.errorMessage!;
        }
      }
      mode = intent.suggestedMode;
      smartPrompt = query;
      _queryController.text = query;
      _applyCalculation(
        intent.result,
        originalQuery: query,
        selectedMode: mode,
      );
    } catch (_) {
      result = 'AI unavailable';
      steps = const [
        'The assistant could not process that request right now.',
        'Try a direct math phrase or review remote AI settings.',
      ];
      insight = 'Smart AI failed safely without interrupting the calculator.';
      _persistAndNotify();
    }
  }

  void useSuggestion(SmartSuggestion suggestion) {
    unawaited(runSmartQuery(suggestion.prefill));
  }

  Future<void> toggleSign() async {
    if (expression == '0') {
      expression = '-';
    } else if (expression.startsWith('-')) {
      expression = expression.substring(1);
    } else {
      expression = '-$expression';
    }
    await _afterInputChanged();
  }

  Future<void> longPressFunction(String token) async {
    final alternate = switch (token) {
      '%' => 'sqrt(',
      '/' => 'log(',
      '*' => 'sin(',
      '-' => 'cos(',
      '+' => 'tan(',
      _ => token,
    };
    if (expression == '0' || expression == 'Error') {
      expression = alternate;
    } else {
      expression += alternate;
    }
    await _afterInputChanged();
  }

  Future<void> insertFunction(String functionName) async {
    final token = '$functionName(';
    if (expression == '0' || expression == 'Error') {
      expression = token;
    } else {
      expression += token;
    }
    await _afterInputChanged();
  }

  Future<void> insertProgrammerToken(String token) async {
    if (_isProgrammerOperator(token)) {
      if (expression == '0') {
        return;
      }
      expression = '${expression.trim()} $token ';
    } else if (expression == '0' || expression == 'Error') {
      expression = token;
    } else {
      expression += token;
    }
    await _afterInputChanged();
  }

  Future<void> startVoiceCapture() async {
    speechAvailable = await _voiceService.initialize();
    if (!speechAvailable) {
      voiceStatus = 'Speech recognition is unavailable on this device.';
      notifyListeners();
      return;
    }

    isListening = true;
    voiceStatus = 'Listening... say numbers and operators like plus or divide.';
    notifyListeners();
    await _voiceService.startListening(
      onTranscript: (transcript, isFinal) {
        speechTranscript = transcript;
        speechExpression = _voiceService.normalizeSpokenMath(transcript);
        if (isFinal) {
          isListening = false;
          voiceStatus = 'Captured voice command.';
          if (speechAutoApplyEnabled && speechExpression.isNotEmpty) {
            expression = speechExpression;
            _evaluateCurrent();
            _persistAndNotify();
          } else {
            notifyListeners();
          }
        } else {
          notifyListeners();
        }
      },
    );
  }

  Future<void> stopVoiceCapture() async {
    await _voiceService.stopListening();
    isListening = false;
    voiceStatus = 'Voice capture stopped.';
    notifyListeners();
  }

  Future<void> applySpeechToCalculator() async {
    if (speechExpression.isEmpty) {
      return;
    }
    expression = speechExpression;
    setBottomTab(0);
    await _afterInputChanged();
  }

  void applySpeechToSmartAi() {
    if (speechTranscript.isEmpty) {
      return;
    }
    setBottomTab(1);
    _queryController.text = speechTranscript;
    unawaited(runSmartQuery(speechTranscript));
  }

  String modeSubtitle() {
    return switch (mode) {
      CalculatorMode.focus =>
        'Fast arithmetic with a distraction-free layout.',
      CalculatorMode.scientific =>
        'Trig, logs, powers, and engineering-style calculations.',
      CalculatorMode.programmer =>
        'Base conversions, bitwise operators, and hex/binary input.',
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
    return expression.replaceAll('*', 'x');
  }

  List<String> numbersUsedFor(HistoryEntry entry) {
    return RegExp(r'-?\d+(\.\d+)?')
        .allMatches(entry.expression)
        .map((match) => match.group(0)!)
        .toList();
  }

  List<String> quickScientificFunctions() {
    return const ['sin', 'cos', 'tan', 'log', 'sqrt', 'ln'];
  }

  List<String> programmerShortcutTokens() {
    return const ['A', 'B', 'C', 'D', 'E', 'F', '0b', '0x', '&', '|', '^', '<<', '>>'];
  }

  String smartStatusLabel() {
    if (!remoteAiEnabled) {
      return 'Local AI only';
    }
    if (openRouterApiKey.isEmpty) {
      return 'Remote AI needs key';
    }
    return 'Remote AI ready';
  }

  Future<void> _afterInputChanged() async {
    if (livePreviewEnabled) {
      _evaluateCurrent();
    }
    await HapticFeedback.selectionClick();
    _persistAndNotify();
  }

  void _evaluateCurrent() {
    if (mode == CalculatorMode.visual) {
      graphPoints = _engine.buildGraphPoints(expression);
      result =
          graphPoints.isEmpty ? 'No graph' : '${graphPoints.length} plot points';
      steps = const ['Graph refreshed.'];
      return;
    }

    final preview = _previewForExpression(expression);
    if (preview != null) {
      result = preview;
      steps = const ['Waiting for the rest of the expression.'];
      return;
    }

    final calculation = _engine.evaluate(expression, mode);
    result = calculation.result;
    steps = calculation.steps;
  }

  String? _previewForExpression(String current) {
    final trimmed = current.trim();
    if (trimmed.isEmpty) {
      return '0';
    }

    if (_isProgrammerOperatorSuffix(trimmed)) {
      final fallback = trimmed.replaceFirst(RegExp(r'(\s*(<<|>>|[&|^])\s*)$'), '');
      if (fallback.isNotEmpty) {
        final calculation = _engine.evaluate(fallback, mode);
        return calculation.result == 'Error' ? null : calculation.result;
      }
    }

    if (_isIncompleteExpression(trimmed)) {
      final fallback = _sanitizeForEvaluation(trimmed);
      if (fallback == trimmed && !_looksLikeStandaloneValue(trimmed)) {
        return result;
      }
      final calculation = _engine.evaluate(fallback, mode);
      return calculation.result == 'Error' ? result : calculation.result;
    }

    return null;
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
    if (saveHistoryEnabled) {
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
    }
    _refreshSuggestions();
    _persistAndNotify();
  }

  void _refreshSuggestions() {
    suggestions = smartSuggestionsEnabled
        ? _historyService.buildSuggestions(history)
        : const [];
  }

  bool _shouldInsertAsFreshToken(String token) {
    final shouldReplace = expression == '0' || expression == 'Error';
    return shouldReplace && !_isBinaryOperator(token) && !_isProgrammerOperator(token);
  }

  bool _isBinaryOperator(String token) {
    return token == '+' || token == '-' || token == '*' || token == '/' || token == '%';
  }

  bool _isProgrammerOperator(String token) {
    return token == '&' || token == '|' || token == '^' || token == '<<' || token == '>>';
  }

  bool _isProgrammerOperatorSuffix(String text) {
    return RegExp(r'(<<|>>|[&|^])$').hasMatch(text.trim());
  }

  String _appendOperator(String token) {
    final trimmed = expression.trimRight();
    if (trimmed.isEmpty || trimmed == '0') {
      return token == '-' ? '-' : '0 $token ';
    }

    final operatorMatch = RegExp(r'([+\-*/%])$').firstMatch(trimmed);
    if (operatorMatch != null) {
      return '${trimmed.substring(0, trimmed.length - 1)}$token ';
    }
    return '$trimmed $token ';
  }

  String _currentNumberSegment() {
    final segments = expression.split(RegExp(r'[+\-*/%()]'));
    return segments.isEmpty ? '' : segments.last.trim();
  }

  bool _isIncompleteExpression(String text) {
    if (RegExp(r'[+\-*/%]$').hasMatch(text)) {
      return true;
    }
    final openParens = '('.allMatches(text).length;
    final closeParens = ')'.allMatches(text).length;
    if (openParens > closeParens) {
      return true;
    }
    if (RegExp(r'(sin|cos|tan|log|sqrt|ln)\($').hasMatch(text)) {
      return true;
    }
    return false;
  }

  bool _looksLikeStandaloneValue(String text) {
    if (mode == CalculatorMode.programmer) {
      return RegExp(r'^(0b[01]+|0x[a-fA-F0-9]+|[A-Fa-f0-9]+)$').hasMatch(text);
    }
    return RegExp(r'^-?\d+(\.\d+)?$').hasMatch(text);
  }

  String _sanitizeForEvaluation(String text) {
    var sanitized = text.trim();
    sanitized = sanitized.replaceFirst(RegExp(r'[+\-*/%]+$'), '').trimRight();
    while ('('.allMatches(sanitized).length > ')'.allMatches(sanitized).length) {
      sanitized += ')';
    }
    return sanitized.isEmpty ? '0' : sanitized;
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
        query: 'what is 25% of 400',
        expression: '(25 / 100) * 400',
        result: '100.00',
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
    _refreshSuggestions();
  }

  void _persistAndNotify() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(
      const Duration(milliseconds: 180),
      () {
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
              livePreview: livePreviewEnabled,
              saveHistory: saveHistoryEnabled,
              smartSuggestions: smartSuggestionsEnabled,
              speechAutoApply: speechAutoApplyEnabled,
              openRouterApiKey: openRouterApiKey,
              openRouterModel: openRouterModel,
              remoteAiEnabled: remoteAiEnabled,
            ),
          ),
        );
      },
    );
    notifyListeners();
  }

  @override
  void dispose() {
    if (isListening) {
      unawaited(_voiceService.stopListening());
    }
    _persistDebounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }
}
