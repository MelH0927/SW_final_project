import 'package:flutter_test/flutter_test.dart';
import 'package:fretwise/main.dart';
import 'package:fretwise/models/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => AiMaterialService()),
        ],
        child: const FretwiseApp(),
      ),
    );
    await tester.pumpAndSettle();
  });
}
