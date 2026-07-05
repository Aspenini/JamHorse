import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/platform/window_decorations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('custom window decorations are the desktop default', () async {
    SharedPreferences.setMockInitialValues({});

    expect(
      await loadWindowDecorationMode(),
      supportsWindowDecorations
          ? WindowDecorationMode.custom
          : WindowDecorationMode.native,
    );
  });

  test('saved native window decoration preference is restored', () async {
    SharedPreferences.setMockInitialValues({
      'windowDecorationMode': WindowDecorationMode.native.name,
    });

    expect(await loadWindowDecorationMode(), WindowDecorationMode.native);
  });
}
