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

extension CalculatorModeX on CalculatorMode {
  static CalculatorMode fromName(String? name) {
    return CalculatorMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => CalculatorMode.focus,
    );
  }
}

extension AppThemeModeX on AppThemeMode {
  static AppThemeMode fromName(String? name) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => AppThemeMode.neon,
    );
  }
}
