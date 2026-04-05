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

  Map<String, Object?> toJson() {
    return {
      'query': query,
      'expression': expression,
      'result': result,
      'mode': mode.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      query: json['query'] as String? ?? '',
      expression: json['expression'] as String? ?? '',
      result: json['result'] as String? ?? '',
      mode: CalculatorMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => CalculatorMode.focus,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
    );
  }
}
