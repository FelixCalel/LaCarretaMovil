import 'package:flutter_test/flutter_test.dart';
import 'package:lacarretamovil/features/main.dart';

void main() {
  testWidgets('App boots smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Verify the app starts successfully without crashing.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
