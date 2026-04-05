import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/core/models/calculator_mode.dart';
import 'package:calculator/core/services/calculation_engine.dart';

void main() {
  final engine = CalculationEngine();

  test('evaluates arithmetic expressions', () {
    final result = engine.evaluate('12 + 8 / 2', CalculatorMode.focus);
    expect(result.result, '16');
  });

  test('supports modulo expressions', () {
    final result = engine.evaluate('17 % 5', CalculatorMode.focus);
    expect(result.result, '2');
  });

  test('evaluates scientific expressions', () {
    final result = engine.evaluate('sqrt(81)', CalculatorMode.scientific);
    expect(result.result, '9');
  });

  test('evaluates financial emi expressions', () {
    final result = engine.evaluate('emi(250000,8.5,240)', CalculatorMode.financial);
    expect(result.result, isNot('Error'));
  });

  test('handles programmer bitwise expressions', () {
    final result = engine.evaluate('0b1010 & 0b1100', CalculatorMode.programmer);
    expect(result.result, '8');
  });

  test('handles plain hex programmer values', () {
    final result = engine.evaluate('ff', CalculatorMode.programmer);
    expect(result.result, '255');
  });
}
