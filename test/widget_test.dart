import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:casdoor_flutter_example/main.dart';

void main() {
  testWidgets('shows the login button when not signed in', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  test('signs in with PKCE at the demo server', () {
    expect(casdoorConfig.serverUrl, 'https://door.casdoor.com');
    expect(casdoorConfig.callbackUrlScheme, 'casdoor');
  });
}
