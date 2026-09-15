import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef NavigationAvailability = ({bool canGoBack, bool canGoForward});

/// Browser-style back/forward history for the desktop top bar. go_router
/// only models a pop stack, which has no notion of "forward".
class NavigationHistoryController extends Notifier<NavigationAvailability> {
  static const _limit = 50;

  final _back = <String>[];
  final _forward = <String>[];
  String? _current;

  /// Set while a back/forward navigation is in flight so the resulting
  /// location change is not recorded as a fresh visit.
  String? _expected;

  @override
  NavigationAvailability build() => (canGoBack: false, canGoForward: false);

  void record(String location) {
    if (location == _expected) {
      _expected = null;
      return;
    }
    _expected = null;
    if (location == _current) return;
    if (_current case final current?) {
      _back.add(current);
      if (_back.length > _limit) _back.removeAt(0);
    }
    _forward.clear();
    _current = location;
    _emit();
  }

  /// Returns the location to navigate to, or null when there is none.
  String? goBack() => _move(from: _back, to: _forward);

  String? goForward() => _move(from: _forward, to: _back);

  void reset() {
    _back.clear();
    _forward.clear();
    _current = null;
    _expected = null;
    _emit();
  }

  String? _move({required List<String> from, required List<String> to}) {
    if (from.isEmpty) return null;
    if (_current case final current?) to.add(current);
    final target = from.removeLast();
    _current = target;
    _expected = target;
    _emit();
    return target;
  }

  void _emit() {
    state = (canGoBack: _back.isNotEmpty, canGoForward: _forward.isNotEmpty);
  }
}

final navigationHistoryProvider =
    NotifierProvider<NavigationHistoryController, NavigationAvailability>(
      NavigationHistoryController.new,
    );
