import '../models/calculation_result.dart';

class ConversionService {
  static const Map<String, double> _lengthToMeters = {
    'm': 1,
    'meter': 1,
    'meters': 1,
    'km': 1000,
    'kilometer': 1000,
    'kilometers': 1000,
    'mile': 1609.34,
    'miles': 1609.34,
    'ft': 0.3048,
    'feet': 0.3048,
  };

  static const Map<String, double> _currencyToUsd = {
    'usd': 1,
    r'$': 1,
    'eur': 1.08,
    'inr': 0.012,
  };

  CalculationResult? tryConvert(String input) {
    final query = input.toLowerCase().trim();
    final match = RegExp(r'([\d.]+)\s*([a-z$]+)\s+to\s+([a-z$]+)$')
        .firstMatch(query);
    if (match == null) {
      return null;
    }

    final value = double.parse(match.group(1)!);
    final from = match.group(2)!;
    final to = match.group(3)!;

    if (_lengthToMeters.containsKey(from) && _lengthToMeters.containsKey(to)) {
      final meters = value * _lengthToMeters[from]!;
      final converted = meters / _lengthToMeters[to]!;
      return CalculationResult(
        input: input,
        expression: '$value $from -> $to',
        result: converted
            .toStringAsFixed(4)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), ''),
        steps: [
          'Normalize to meters = ${meters.toStringAsFixed(4)}',
          'Convert meters to $to',
        ],
      );
    }

    if (_currencyToUsd.containsKey(from) && _currencyToUsd.containsKey(to)) {
      final usd = value * _currencyToUsd[from]!;
      final converted = usd / _currencyToUsd[to]!;
      return CalculationResult(
        input: input,
        expression: '$value $from -> $to',
        result: converted.toStringAsFixed(2),
        steps: [
          'Convert source to USD anchor = ${usd.toStringAsFixed(2)}',
          'Convert USD anchor to $to',
        ],
        note: 'Offline currency rates use bundled demo values.',
      );
    }

    return null;
  }
}
