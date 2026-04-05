import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/core/services/voice_service.dart';

void main() {
  final service = VoiceService();

  test('normalizes spoken operators into symbols', () {
    final expression = service.normalizeSpokenMath('forty five plus six');
    expect(expression, '45 + 6');
  });

  test('normalizes divide phrases', () {
    final expression = service.normalizeSpokenMath('one hundred divided by four');
    expect(expression, '100 / 4');
  });
}
