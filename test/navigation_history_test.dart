import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/state/navigation_history.dart';

void main() {
  late ProviderContainer container;
  late NavigationHistoryController history;

  setUp(() {
    container = ProviderContainer();
    history = container.read(navigationHistoryProvider.notifier);
  });

  tearDown(() => container.dispose());

  NavigationAvailability availability() =>
      container.read(navigationHistoryProvider);

  test('visits build a back stack', () {
    history.record('/home');
    expect(availability(), (canGoBack: false, canGoForward: false));

    history
      ..record('/search')
      ..record('/item/1');
    expect(availability(), (canGoBack: true, canGoForward: false));
  });

  test('back and forward walk the stack without re-recording', () {
    history
      ..record('/home')
      ..record('/search')
      ..record('/item/1');

    expect(history.goBack(), '/search');
    // The router reports the location it navigated to.
    history.record('/search');
    expect(availability(), (canGoBack: true, canGoForward: true));

    expect(history.goBack(), '/home');
    history.record('/home');
    expect(availability(), (canGoBack: false, canGoForward: true));
    expect(history.goBack(), isNull);

    expect(history.goForward(), '/search');
    history.record('/search');
    expect(history.goForward(), '/item/1');
    history.record('/item/1');
    expect(availability(), (canGoBack: true, canGoForward: false));
  });

  test('a new visit after going back discards the forward stack', () {
    history
      ..record('/home')
      ..record('/search');
    history.goBack();
    history
      ..record('/home')
      ..record('/liked');

    expect(availability(), (canGoBack: true, canGoForward: false));
    expect(history.goBack(), '/home');
  });

  test('repeat visits to the current page are ignored and reset clears', () {
    history
      ..record('/home')
      ..record('/home');
    expect(availability().canGoBack, isFalse);

    history
      ..record('/search')
      ..reset();
    expect(availability(), (canGoBack: false, canGoForward: false));
  });
}
