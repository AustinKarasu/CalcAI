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
      final each = (amount + tipValue) / people;
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

    final squareRootMatch =
        RegExp(r'(square root|sqrt) of (\d+(\.\d+)?)').firstMatch(normalized);
    if (squareRootMatch != null) {
      final value = squareRootMatch.group(2)!;
      return CalculationIntent(
        result: _engine.evaluate('sqrt($value)', CalculatorMode.scientific),
        suggestedMode: CalculatorMode.scientific,
      );
    }

    final powerMatch = RegExp(
      r'(\d+(\.\d+)?) (to the power of|power) (\d+(\.\d+)?)',
    ).firstMatch(normalized);
    if (powerMatch != null) {
      return CalculationIntent(
        result: _engine.evaluate(
          '${powerMatch.group(1)} ** ${powerMatch.group(4)}',
          CalculatorMode.scientific,
        ),
        suggestedMode: CalculatorMode.scientific,
      );
    }

    final multiplyMatch =
        RegExp(r'multiply (\d+(\.\d+)?) by (\d+(\.\d+)?)').firstMatch(normalized);
    if (multiplyMatch != null) {
      return CalculationIntent(
        result: _engine.evaluate(
          '${multiplyMatch.group(1)} * ${multiplyMatch.group(3)}',
          CalculatorMode.focus,
        ),
        suggestedMode: CalculatorMode.focus,
      );
    }

    final divideMatch =
        RegExp(r'divide (\d+(\.\d+)?) by (\d+(\.\d+)?)').firstMatch(normalized);
    if (divideMatch != null) {
      return CalculationIntent(
        result: _engine.evaluate(
          '${divideMatch.group(1)} / ${divideMatch.group(3)}',
          CalculatorMode.focus,
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
        .replaceAll('multiply by', '*')
        .replaceAll('divided by', '/')
        .replaceAll('times', '*')
        .replaceAll('plus', '+')
        .replaceAll('minus', '-');

    final suggestedMode =
        normalized.contains('sin') ||
                normalized.contains('cos') ||
                normalized.contains('tan') ||
                normalized.contains('log') ||
                normalized.contains('sqrt') ||
                normalized.contains('power')
            ? CalculatorMode.scientific
            : currentMode;

    final result = _engine.evaluate(arithmetic, suggestedMode);
    if (result.result == 'Error') {
      return CalculationIntent(
        result: CalculationResult(
          input: query,
          expression: query,
          result: 'Need math',
          steps: const [
            'Try requests like:',
            'split \$120 among 3 people with 10% tip',
            'what is 25% of 400',
            'square root of 144',
            '5 km to miles',
          ],
        ),
        suggestedMode: currentMode,
      );
    }

    return CalculationIntent(
      result: result,
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
