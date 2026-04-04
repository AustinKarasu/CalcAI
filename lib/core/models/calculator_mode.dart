enum CalculatorMode {
  focus('Focus Mode'),
  scientific('Scientific'),
  programmer('Programmer'),
  financial('Financial'),
  visual('Visual Math');

  const CalculatorMode(this.label);

  final String label;
}

enum AppThemeMode {
  dark('Dark'),
  neon('Neon'),
  glass('Glass');

  const AppThemeMode(this.label);

  final String label;
}
