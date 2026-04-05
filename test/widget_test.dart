import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:calculator/app/karasu_app.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('renders CalcAI shell', (WidgetTester tester) async {
    await tester.pumpWidget(const KarasuApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Calculator'), findsWidgets);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Speech'), findsOneWidget);
  });
}
