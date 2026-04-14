import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cicd/app.dart';

void main() {
  testWidgets('app renders root title', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter CI/CD Demo'), findsOneWidget);
  });
}
