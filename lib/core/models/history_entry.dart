import 'calculator_mode.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.query,
    required this.expression,
    required this.result,
    required this.mode,
    required this.timestamp,
    this.note,
  });

  final String query;
  final String expression;
  final String result;
  final CalculatorMode mode;
  final DateTime timestamp;
  final String? note;
}
