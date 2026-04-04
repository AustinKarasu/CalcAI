import '../models/history_entry.dart';
import '../models/smart_suggestion.dart';

class HistoryIntelligenceService {
  List<SmartSuggestion> buildSuggestions(List<HistoryEntry> history) {
    if (history.isEmpty) {
      return const [
        SmartSuggestion(
          title: 'Try Smart Split',
          subtitle: 'Natural language for tips and bills',
          prefill: 'split \$120 among 3 people with 10% tip',
        ),
        SmartSuggestion(
          title: 'Visual Math',
          subtitle: 'Graph equations live',
          prefill: 'y=x^2',
        ),
      ];
    }

    final splitCount =
        history.where((entry) => entry.query.toLowerCase().contains('split')).length;
    final conversionCount =
        history.where((entry) => entry.query.toLowerCase().contains(' to ')).length;

    return [
      if (splitCount > 0)
        const SmartSuggestion(
          title: 'Frequent Group Spend',
          subtitle: 'Reuse your shared-expense shortcut',
          prefill: 'split \$250 among 5 people with 12% tip',
        ),
      if (conversionCount > 0)
        const SmartSuggestion(
          title: 'Quick Conversion',
          subtitle: 'You often convert units on the fly',
          prefill: '5 km to miles',
        ),
      SmartSuggestion(
        title: 'Repeat Last Pattern',
        subtitle:
            'History intelligence noticed you like quick finance checks',
        prefill: history.first.query,
      ),
    ];
  }
}
