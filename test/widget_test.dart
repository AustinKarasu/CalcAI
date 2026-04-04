import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/app/karasu_app.dart';

void main() {
  testWidgets('renders Karasu calculator shell', (WidgetTester tester) async {
    await tester.pumpWidget(const KarasuApp());
    await tester.pumpAndSettle();

    expect(find.text('KARASU CALCULATOR'), findsOneWidget);
    expect(find.text('Focus Mode'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
