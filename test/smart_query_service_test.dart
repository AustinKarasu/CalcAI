import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/core/models/calculator_mode.dart';
import 'package:calculator/core/services/calculation_engine.dart';
import 'package:calculator/core/services/conversion_service.dart';
import 'package:calculator/core/services/smart_query_service.dart';

void main() {
  final service = SmartQueryService(CalculationEngine(), ConversionService());

  test('parses split bill queries', () {
    final intent = service.parse(
      'split \$120 among 3 people with 10% tip',
      CalculatorMode.focus,
    );
    expect(intent.result.result, '44.00');
  });

  test('parses percent queries', () {
    final intent = service.parse('what is 25% of 400', CalculatorMode.focus);
    expect(intent.result.result, '100.00');
  });

  test('parses conversion queries', () {
    final intent = service.parse('5 km to miles', CalculatorMode.focus);
    expect(intent.result.result, '3.1069');
  });

  test('parses square root queries', () {
    final intent = service.parse('square root of 144', CalculatorMode.focus);
    expect(intent.result.result, '12');
  });

  test('parses multiply phrasing', () {
    final intent = service.parse('multiply 45 by 2', CalculatorMode.focus);
    expect(intent.result.result, '90');
  });
}
