import '../models/calculation_result.dart';
import '../models/calculator_mode.dart';
import 'calculation_engine.dart';
import 'conversion_service.dart';

class SmartQueryService {
  SmartQueryService(this._engine, this._conversionService);

  final CalculationEngine _engine;
  final ConversionService _conversionService;

  CalculationIntent parse(String query, CalculatorMode currentMode) {
    final normalized = query.trim().toLowerCase();

    final conversion = _conversionService.tryConvert(normalized);
    if (conversion != null) {
      return CalculationIntent(
        result: conversion,
        suggestedMode: CalculatorMode.focus,
      );
    }

    final splitMatch = RegExp(
      r'split \$?([\d.]+) among (\d+) people with (\d+)% tip',
    ).firstMatch(normalized);
    if (splitMatch != null) {
      final amount = double.parse(splitMatch.group(1)!);
      final people = int.parse(splitMatch.group(2)!);
      final tip = double.parse(splitMatch.group(3)!);
      final total = amount + (amount * tip / 100);
      final each = total / people;
      return CalculationIntent(
        result: CalculationResult(
          input: query,
          expression: '($amount + ${amount * tip / 100}) / $people',
          result: each.toStringAsFixed(2),
          steps: [
            'Tip = ${(amount * tip / 100).toStringAsFixed(2)}',
            'Total with tip = ${total.toStringAsFixed(2)}',
            'Per person = ${each.toStringAsFixed(2)}',
          ],
        ),
        suggestedMode: CalculatorMode.focus,
      );
    }

    final emiMatch = RegExp(
      r'emi for \$?([\d.]+) at (\d+(\.\d+)?)% for (\d+) months',
    ).firstMatch(normalized);
    if (emiMatch != null) {
      final principal = emiMatch.group(1)!;
      final rate = emiMatch.group(2)!;
      final months = emiMatch.group(4)!;
      return CalculationIntent(
        result: _engine.evaluate(
          'emi($principal,$rate,$months)',
          CalculatorMode.financial,
        ),
        suggestedMode: CalculatorMode.financial,
      );
    }

    final interestMatch = RegExp(
      r'interest on \$?([\d.]+) at (\d+(\.\d+)?)% for (\d+) years',
    ).firstMatch(normalized);
    if (interestMatch != null) {
      return CalculationIntent(
        result: _engine.evaluate(
          'interest(${interestMatch.group(1)},${interestMatch.group(2)},${interestMatch.group(4)})',
          CalculatorMode.financial,
        ),
        suggestedMode: CalculatorMode.financial,
      );
    }

    final taxMatch =
        RegExp(r'add (\d+(\.\d+)?)% tax to \$?([\d.]+)').firstMatch(normalized);
    if (taxMatch != null) {
      return CalculationIntent(
        result: _engine.evaluate(
          'tax(${taxMatch.group(3)},${taxMatch.group(1)})',
          CalculatorMode.financial,
        ),
        suggestedMode: CalculatorMode.financial,
      );
    }

    final arithmetic = normalized
        .replaceAll('plus', '+')
        .replaceAll('minus', '-')
        .replaceAll('times', '*')
        .replaceAll('multiplied by', '*')
        .replaceAll('divided by', '/');

    final suggestedMode =
        normalized.contains('sin') ||
                normalized.contains('cos') ||
                normalized.contains('tan') ||
                normalized.contains('log')
            ? CalculatorMode.scientific
            : currentMode;

    return CalculationIntent(
      result: _engine.evaluate(arithmetic, suggestedMode),
      suggestedMode: suggestedMode,
    );
  }
}

class CalculationIntent {
  const CalculationIntent({
    required this.result,
    required this.suggestedMode,
  });

  final CalculationResult result;
  final CalculatorMode suggestedMode;
}
