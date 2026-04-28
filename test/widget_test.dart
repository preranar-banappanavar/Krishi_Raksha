import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('KrishiRaksha app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KrishiRakshaApp());
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
