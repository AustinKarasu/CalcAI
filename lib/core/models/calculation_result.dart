class CalculationResult {
  const CalculationResult({
    required this.input,
    required this.expression,
    required this.result,
    this.steps = const <String>[],
    this.note,
  });

  final String input;
  final String expression;
  final String result;
  final List<String> steps;
  final String? note;
}
