import 'dart:math' as math;

import '../models/calculation_result.dart';
import '../models/calculator_mode.dart';

class CalculationEngine {
  CalculationResult evaluate(String input, CalculatorMode mode) {
    final normalized = normalize(input);
    switch (mode) {
      case CalculatorMode.programmer:
        return _evaluateProgrammer(normalized);
      case CalculatorMode.financial:
        return _evaluateFinancial(normalized);
      case CalculatorMode.visual:
        return _evaluateVisual(normalized);
      case CalculatorMode.focus:
      case CalculatorMode.scientific:
        return _evaluateArithmetic(normalized);
    }
  }

  String normalize(String source) {
    return source
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', '${math.pi}')
        .replaceAll('pi', '${math.pi}')
        .replaceAll('^', '**');
  }

  List<OffsetPoint> buildGraphPoints(String expression) {
    final sanitized = normalize(
      expression.replaceAll('y=', '').replaceAll(' ', ''),
    );
    final points = <OffsetPoint>[];
    for (var x = -10.0; x <= 10.0; x += 0.25) {
      final replaced = sanitized.replaceAll('x', '($x)');
      final result = _safeEval(replaced);
      if (result != null && result.isFinite) {
        points.add(OffsetPoint(x, result));
      }
    }
    return points;
  }

  CalculationResult _evaluateArithmetic(String expression) {
    final value = _safeEval(expression);
    if (value == null) {
      return CalculationResult(
        input: expression,
        expression: expression,
        result: 'Error',
        steps: const ['Invalid expression.'],
      );
    }

    return CalculationResult(
      input: expression,
      expression: expression,
      result: _format(value),
      steps: [
        'Expression: $expression',
        'Computed locally on-device.',
        'Result = ${_format(value)}',
      ],
    );
  }

  CalculationResult _evaluateProgrammer(String expression) {
    final compact = expression.toLowerCase().replaceAll(' ', '');
    if (compact.isEmpty) {
      return const CalculationResult(
        input: '',
        expression: '',
        result: '0',
        steps: ['Enter binary, hex, or decimal values.'],
      );
    }

    final bitwiseMatch = RegExp(
      r'^(0b[01]+|0x[a-f0-9]+|[a-f0-9]+)(<<|>>|&|\||\^)(0b[01]+|0x[a-f0-9]+|[a-f0-9]+)$',
    ).firstMatch(compact);
    if (bitwiseMatch != null) {
      final left = _parseInt(bitwiseMatch.group(1)!);
      final operator = bitwiseMatch.group(2)!;
      final right = _parseInt(bitwiseMatch.group(3)!);
      final result = switch (operator) {
        '&' => left & right,
        '|' => left | right,
        '^' => left ^ right,
        '<<' => left << right,
        '>>' => left >> right,
        _ => 0,
      };

      return CalculationResult(
        input: expression,
        expression: '$left $operator $right',
        result: '$result',
        steps: [
          'Decimal: $result',
          'Binary: ${result.toRadixString(2)}',
          'Hex: ${result.toRadixString(16).toUpperCase()}',
        ],
      );
    }

    final value = _parseInt(compact);
    return CalculationResult(
      input: expression,
      expression: '$value',
      result: '$value',
      steps: [
        'Binary: ${value.toRadixString(2)}',
        'Octal: ${value.toRadixString(8)}',
        'Hex: ${value.toRadixString(16).toUpperCase()}',
      ],
    );
  }

  CalculationResult _evaluateFinancial(String expression) {
    final compact = expression.replaceAll(' ', '');

    final emiMatch =
        RegExp(r'emi\(([\d.]+),([\d.]+),([\d.]+)\)').firstMatch(compact);
    if (emiMatch != null) {
      final principal = double.parse(emiMatch.group(1)!);
      final annualRate = double.parse(emiMatch.group(2)!);
      final months = double.parse(emiMatch.group(3)!);
      final monthlyRate = annualRate / 12 / 100;
      final factor = math.pow(1 + monthlyRate, months).toDouble();
      final emi = principal * monthlyRate * factor / (factor - 1);
      return CalculationResult(
        input: expression,
        expression: 'emi($principal,$annualRate,$months)',
        result: _format(emi),
        steps: [
          'Monthly interest = ${_format(monthlyRate * 100)}%',
          'Monthly payment = ${_format(emi)}',
          'Total payout = ${_format(emi * months)}',
        ],
      );
    }

    final interestMatch =
        RegExp(r'interest\(([\d.]+),([\d.]+),([\d.]+)\)').firstMatch(compact);
    if (interestMatch != null) {
      final principal = double.parse(interestMatch.group(1)!);
      final rate = double.parse(interestMatch.group(2)!);
      final years = double.parse(interestMatch.group(3)!);
      final interest = principal * rate * years / 100;
      return CalculationResult(
        input: expression,
        expression: 'interest($principal,$rate,$years)',
        result: _format(interest),
        steps: [
          'Simple interest = principal x rate x time / 100',
          'Interest = ${_format(interest)}',
          'Total amount = ${_format(principal + interest)}',
        ],
      );
    }

    final taxMatch = RegExp(r'tax\(([\d.]+),([\d.]+)\)').firstMatch(compact);
    if (taxMatch != null) {
      final amount = double.parse(taxMatch.group(1)!);
      final rate = double.parse(taxMatch.group(2)!);
      final tax = amount * rate / 100;
      return CalculationResult(
        input: expression,
        expression: 'tax($amount,$rate)',
        result: _format(amount + tax),
        steps: [
          'Tax amount = ${_format(tax)}',
          'Total with tax = ${_format(amount + tax)}',
        ],
      );
    }

    return _evaluateArithmetic(expression);
  }

  CalculationResult _evaluateVisual(String expression) {
    final points = buildGraphPoints(expression);
    if (points.isEmpty) {
      return const CalculationResult(
        input: 'visual',
        expression: 'visual',
        result: 'No graph',
        steps: ['Use forms like y=x^2 or y=sin(x).'],
      );
    }

    final sample = points.firstWhere(
      (point) => point.x >= 0,
      orElse: () => points.first,
    );

    return CalculationResult(
      input: expression,
      expression: expression,
      result: '${points.length} plot points',
      steps: [
        'Graph generated in real time.',
        'Use x as the variable.',
        'At x=${_format(sample.x)}, y=${_format(sample.y)}',
      ],
    );
  }

  double? _safeEval(String expression) {
    try {
      return _ExpressionParser(expression).parse();
    } catch (_) {
      return null;
    }
  }

  int _parseInt(String value) {
    if (value.startsWith('0b')) {
      return int.parse(value.substring(2), radix: 2);
    }
    if (value.startsWith('0x')) {
      return int.parse(value.substring(2), radix: 16);
    }
    if (RegExp(r'^[a-f0-9]+$').hasMatch(value) &&
        RegExp(r'[a-f]').hasMatch(value)) {
      return int.parse(value, radix: 16);
    }
    return int.parse(value);
  }

  static String _format(num value) {
    if (value.isNaN || value.isInfinite) {
      return 'Undefined';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class OffsetPoint {
  const OffsetPoint(this.x, this.y);

  final double x;
  final double y;
}

class _ExpressionParser {
  _ExpressionParser(this.source);

  final String source;
  int _index = 0;

  double parse() {
    final value = _parseExpression();
    _skipWhitespace();
    if (_index != source.length) {
      throw const FormatException('Unexpected input');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parsePower();
    while (true) {
      _skipWhitespace();
      if (_peek('**')) {
        return value;
      }
      if (_match('*')) {
        value *= _parsePower();
      } else if (_match('/')) {
        value /= _parsePower();
      } else if (_match('%')) {
        value %= _parsePower();
      } else {
        return value;
      }
    }
  }

  double _parsePower() {
    var value = _parseUnary();
    while (true) {
      _skipWhitespace();
      if (_match('**')) {
        value = math.pow(value, _parseUnary()).toDouble();
      } else {
        return value;
      }
    }
  }

  double _parseUnary() {
    _skipWhitespace();
    if (_match('+')) {
      return _parseUnary();
    }
    if (_match('-')) {
      return -_parseUnary();
    }
    return _parsePrimary();
  }

  double _parsePrimary() {
    _skipWhitespace();
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Missing )');
      }
      return value;
    }

    final identifier = _parseIdentifier();
    if (identifier != null) {
      if (!_match('(')) {
        throw const FormatException('Missing (');
      }
      final inner = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Missing )');
      }
      return switch (identifier) {
        'sin' => math.sin(inner),
        'cos' => math.cos(inner),
        'tan' => math.tan(inner),
        'log' => math.log(inner) / math.ln10,
        'ln' => math.log(inner),
        'sqrt' => math.sqrt(inner),
        _ => throw const FormatException('Unknown function'),
      };
    }

    return _parseNumber();
  }

  String? _parseIdentifier() {
    _skipWhitespace();
    final start = _index;
    while (_index < source.length &&
        RegExp(r'[a-zA-Z]').hasMatch(source[_index])) {
      _index++;
    }
    if (start == _index) {
      return null;
    }
    return source.substring(start, _index);
  }

  double _parseNumber() {
    _skipWhitespace();
    final start = _index;
    var hasDot = false;
    while (_index < source.length) {
      final char = source[_index];
      if (RegExp(r'\d').hasMatch(char)) {
        _index++;
        continue;
      }
      if (char == '.' && !hasDot) {
        hasDot = true;
        _index++;
        continue;
      }
      break;
    }
    if (start == _index) {
      throw const FormatException('Expected number');
    }
    return double.parse(source.substring(start, _index));
  }

  void _skipWhitespace() {
    while (_index < source.length && source[_index].trim().isEmpty) {
      _index++;
    }
  }

  bool _match(String value) {
    if (source.startsWith(value, _index)) {
      _index += value.length;
      return true;
    }
    return false;
  }

  bool _peek(String value) {
    return source.startsWith(value, _index);
  }
}
