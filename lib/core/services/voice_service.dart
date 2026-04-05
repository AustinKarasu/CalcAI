import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  static const Map<String, int> _smallNumbers = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  Future<bool> initialize() {
    return _speech.initialize();
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onTranscript,
  }) async {
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        onTranscript(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stopListening() {
    return _speech.stop();
  }

  String inputHint() {
    return 'Voice input can convert spoken math into calculator expressions.';
  }

  String speakHint(String result) {
    return 'Current result ready for speech output: $result';
  }

  String normalizeSpokenMath(String source) {
    var value = source.toLowerCase().trim();
    value = value
        .replaceAll('multiplied by', ' * ')
        .replaceAll('multiply by', ' * ')
        .replaceAll('times', ' * ')
        .replaceAll('divide by', ' / ')
        .replaceAll('divided by', ' / ')
        .replaceAll('over', ' / ')
        .replaceAll('plus', ' + ')
        .replaceAll('add', ' + ')
        .replaceAll('minus', ' - ')
        .replaceAll('subtract', ' - ')
        .replaceAll('modulo', ' % ')
        .replaceAll('mod', ' % ')
        .replaceAll('open bracket', ' ( ')
        .replaceAll('close bracket', ' ) ')
        .replaceAll('open parenthesis', ' ( ')
        .replaceAll('close parenthesis', ' ) ')
        .replaceAll('point', ' . ')
        .replaceAll('dot', ' . ');

    final words = value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final buffer = <String>[];
    final currentNumberWords = <String>[];

    void flushNumberWords() {
      if (currentNumberWords.isEmpty) {
        return;
      }
      final parsed = _parseNumberWords(currentNumberWords);
      buffer.add(parsed);
      currentNumberWords.clear();
    }

    for (final word in words) {
      if (_smallNumbers.containsKey(word) ||
          word == 'hundred' ||
          word == 'thousand') {
        currentNumberWords.add(word);
      } else if (word == '.') {
        flushNumberWords();
        buffer.add('.');
      } else if (_isOperator(word) || word == '(' || word == ')') {
        flushNumberWords();
        buffer.add(word);
      } else if (RegExp(r'^\d+$').hasMatch(word)) {
        flushNumberWords();
        buffer.add(word);
      }
    }

    flushNumberWords();

    return buffer.join(' ').replaceAll(' . ', '.').trim();
  }

  bool _isOperator(String value) {
    return value == '+' || value == '-' || value == '*' || value == '/' || value == '%';
  }

  String _parseNumberWords(List<String> words) {
    var total = 0;
    var current = 0;

    for (final word in words) {
      if (_smallNumbers.containsKey(word)) {
        current += _smallNumbers[word]!;
      } else if (word == 'hundred') {
        current = current == 0 ? 100 : current * 100;
      } else if (word == 'thousand') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
      }
    }

    return (total + current).toString();
  }
}
