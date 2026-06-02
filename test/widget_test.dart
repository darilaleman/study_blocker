// This is a basic Flutter widget test.
//
// It boots the actual app shell and verifies that the login screen renders.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_blocker/injection_container.dart' as di;
import 'package:study_blocker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.init();
  });

  testWidgets('renders the login screen on startup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyBlockerApp());
    await tester.pumpAndSettle();

    expect(find.text('Dopamind'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
