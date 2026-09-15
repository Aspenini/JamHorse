import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/shell/desktop_shell.dart';
import 'package:jamhorse/ui/shell/library_sidebar.dart';
import 'package:jamhorse/ui/shell/right_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('resolvePanelSizes', () {
    test('uses the saved widths when the window has room', () {
      final sizes = resolvePanelSizes(
        windowWidth: 1600,
        layout: const PanelLayout(libraryWidth: 400, rightPanelWidth: 420),
        rightPanelOpen: true,
      );
      expect(sizes, (
        library: 400.0,
        libraryCollapsed: false,
        rightPanel: 420.0,
      ));
    });

    test('shrinks the library first to keep the main view usable', () {
      final sizes = resolvePanelSizes(
        windowWidth: 1200,
        layout: const PanelLayout(libraryWidth: 700, rightPanelWidth: 400),
        rightPanelOpen: true,
      );
      // 1200 - 24 gutters - 408 panel - 360 content.
      expect(sizes.library, 408);
      expect(sizes.rightPanel, 400);
    });

    test('collapses the library to its rail in a narrow window', () {
      final sizes = resolvePanelSizes(
        windowWidth: 940,
        layout: const PanelLayout(),
        rightPanelOpen: true,
      );
      expect(sizes.libraryCollapsed, isTrue);
      expect(sizes.library, PanelLayout.collapsedLibraryWidth);
    });

    test('the closed right panel frees its space for the library', () {
      final sizes = resolvePanelSizes(
        windowWidth: 940,
        layout: const PanelLayout(),
        rightPanelOpen: false,
      );
      expect(sizes.libraryCollapsed, isFalse);
      expect(sizes.library, PanelLayout.defaultLibraryWidth);
    });
  });

  group('DesktopShell resize handles', () {
    Future<ProviderContainer> pumpShell(WidgetTester tester) async {
      await pumpWithFakes(
        tester,
        const DesktopShell(
          path: '/home',
          customDecorations: false,
          child: SizedBox.expand(),
        ),
        size: const Size(1600, 900),
      );
      return ProviderScope.containerOf(
        tester.element(find.byType(DesktopShell)),
      );
    }

    double widthOf(WidgetTester tester, Type type) =>
        tester.getSize(find.byType(type)).width;

    testWidgets('dragging the library edge resizes, collapses, and saves', (
      tester,
    ) async {
      final container = await pumpShell(tester);
      final handle = find.byKey(const ValueKey('library-resize-handle'));
      expect(widthOf(tester, LibrarySidebar), PanelLayout.defaultLibraryWidth);

      await tester.drag(handle, const Offset(120, 0));
      await tester.pumpAndSettle();
      expect(widthOf(tester, LibrarySidebar), closeTo(460, 1));

      await tester.drag(handle, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(
        widthOf(tester, LibrarySidebar),
        PanelLayout.collapsedLibraryWidth,
      );
      expect(find.byTooltip('Expand Your Library'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('libraryCollapsed'), isTrue);

      await tester.tap(find.byTooltip('Expand Your Library'));
      await tester.pumpAndSettle();
      expect(container.read(panelLayoutProvider).libraryCollapsed, isFalse);
      expect(widthOf(tester, LibrarySidebar), closeTo(460, 1));
    });

    testWidgets('dragging the right panel edge left widens it', (tester) async {
      await pumpShell(tester);
      final handle = find.byKey(const ValueKey('right-panel-resize-handle'));
      expect(widthOf(tester, RightPanel), PanelLayout.defaultRightPanelWidth);

      await tester.drag(handle, const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(widthOf(tester, RightPanel), closeTo(460, 1));

      await tester.drag(handle, const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(widthOf(tester, RightPanel), PanelLayout.minRightPanelWidth);
    });
  });
}
