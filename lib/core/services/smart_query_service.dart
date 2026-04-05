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
      r'split \$?([\d.]+) among (\d+) people with (\d+(\.\d+)?)% tip',
    ).firstMatch(normalized);
    if (splitMatch != null) {
      final amount = double.parse(splitMatch.group(1)!);
      final people = int.parse(splitMatch.group(2)!);
      final tip = double.parse(splitMatch.group(3)!);
      final tipValue = amount * tip / 100;
      final total = amount + tipValue;
      final each = total / people;
      return CalculationIntent(
        result: CalculationResult(
          input: query,
          expression: '($amount + $tipValue) / $people',
          result: each.toStringAsFixed(2),
          steps: [
            'Base amount = ${amount.toStringAsFixed(2)}',
            'Tip = ${tipValue.toStringAsFixed(2)}',
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
      return CalculationIntent(
        result: _engine.evaluate(
          'emi(${emiMatch.group(1)},${emiMatch.group(2)},${emiMatch.group(4)})',
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

    final percentMatch =
        RegExp(r'what is (\d+(\.\d+)?)% of (\d+(\.\d+)?)').firstMatch(normalized);
    if (percentMatch != null) {
      final percent = double.parse(percentMatch.group(1)!);
      final amount = double.parse(percentMatch.group(3)!);
      final value = amount * percent / 100;
      return CalculationIntent(
        result: CalculationResult(
          input: query,
          expression: '($percent / 100) * $amount',
          result: value.toStringAsFixed(2),
          steps: [
            'Convert percent to decimal = ${(percent / 100).toStringAsFixed(4)}',
            'Multiply by base amount = ${value.toStringAsFixed(2)}',
          ],
        ),
        suggestedMode: CalculatorMode.focus,
      );
    }

    final visualMatch = RegExp(r'^(y\s*=.+|graph\s+.+)$').firstMatch(normalized);
    if (visualMatch != null) {
      final expression = normalized.startsWith('graph ')
          ? 'y=${normalized.substring(6).trim()}'
          : normalized;
      return CalculationIntent(
        result: _engine.evaluate(expression, CalculatorMode.visual),
        suggestedMode: CalculatorMode.visual,
      );
    }

    final arithmetic = normalized
        .replaceAll('what is ', '')
        .replaceAll('calculate ', '')
        .replaceAll('multiplied by', '*')
        .replaceAll('divided by', '/')
        .replaceAll('times', '*')
        .replaceAll('plus', '+')
        .replaceAll('minus', '-');

    final suggestedMode =
        normalized.contains('sin') ||
                normalized.contains('cos') ||
                normalized.contains('tan') ||
                normalized.contains('log') ||
                normalized.contains('sqrt')
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
