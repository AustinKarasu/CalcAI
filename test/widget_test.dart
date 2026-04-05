import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/app/karasu_app.dart';

void main() {
  testWidgets('renders CalcAI shell', (WidgetTester tester) async {
    await tester.pumpWidget(const KarasuApp());
    await tester.pumpAndSettle();

    expect(find.text('CALCAI'), findsOneWidget);
    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
  });
}
