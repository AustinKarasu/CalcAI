import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/calculation_result.dart';
import '../models/calculator_mode.dart';

class OpenRouterService {
  static const _defaultEndpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  Future<OpenRouterResponse?> solve({
    required String query,
    required String apiKey,
    required String model,
    required CalculatorMode currentMode,
  }) async {
    final key = apiKey.trim().isNotEmpty
        ? apiKey.trim()
        : const String.fromEnvironment('OPENROUTER_API_KEY');
    final selectedModel = model.trim().isNotEmpty
        ? model.trim()
        : const String.fromEnvironment(
            'OPENROUTER_MODEL',
            defaultValue: 'openai/gpt-4o-mini',
          );
    if (key.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_defaultEndpoint),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
              'X-Title': 'CalcAI',
            },
            body: jsonEncode({
              'model': selectedModel,
              'temperature': 0.2,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a calculator assistant inside a mobile app. Reply with strict JSON only using keys expression, result, steps, suggestedMode, note. suggestedMode must be one of focus, scientific, programmer, financial, visual. Keep steps short. If the user asks a non-math question, answer briefly in result and explain in note.'
                },
                {
                  'role': 'user',
                  'content':
                      'Current mode: ${currentMode.name}. Query: $query. Return JSON only.'
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OpenRouterResponse.error(
          'AI request failed with status ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? const [];
      if (choices.isEmpty) {
        return OpenRouterResponse.error('AI returned no choices.');
      }

      final message = (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>? ??
          const {};
      final content = message['content']?.toString() ?? '';
      final jsonText = _extractJson(content);
      if (jsonText == null) {
        return OpenRouterResponse.error('AI response was not valid JSON.');
      }

      final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
      final modeName = parsed['suggestedMode']?.toString();
      return OpenRouterResponse(
        calculation: CalculationResult(
          input: query,
          expression: parsed['expression']?.toString() ?? query,
          result: parsed['result']?.toString() ?? 'No result',
          steps: ((parsed['steps'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList(),
          note: parsed['note']?.toString(),
        ),
        suggestedMode: CalculatorMode.values.firstWhere(
          (mode) => mode.name == modeName,
          orElse: () => currentMode,
        ),
      );
    } on FormatException {
      return OpenRouterResponse.error('AI response could not be parsed.');
    } on http.ClientException {
      return OpenRouterResponse.error('Network error while contacting AI.');
    } on TimeoutException {
      return OpenRouterResponse.error('AI request timed out.');
    } catch (_) {
      return OpenRouterResponse.error('Unexpected AI failure.');
    }
  }

  String? _extractJson(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(trimmed);
    return match?.group(0);
  }
}

class OpenRouterResponse {
  const OpenRouterResponse({
    required this.calculation,
    required this.suggestedMode,
    this.errorMessage,
  });

  factory OpenRouterResponse.error(String message) {
    return OpenRouterResponse(
      calculation: CalculationResult(
        input: 'ai',
        expression: 'ai',
        result: 'AI unavailable',
        steps: [message],
        note: message,
      ),
      suggestedMode: CalculatorMode.focus,
      errorMessage: message,
    );
  }

  final CalculationResult calculation;
  final CalculatorMode suggestedMode;
  final String? errorMessage;
}
