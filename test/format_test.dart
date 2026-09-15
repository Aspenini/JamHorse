import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/core/format.dart';

void main() {
  test('durations format as m:ss, growing hours when needed', () {
    expect(formatDuration(Duration.zero), '0:00');
    expect(formatDuration(const Duration(seconds: 65)), '1:05');
    expect(formatDuration(const Duration(minutes: 12, seconds: 3)), '12:03');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 5)),
      '1:02:05',
    );
    expect(formatDuration(const Duration(seconds: -4)), '0:00');
  });

  test('collection totals read like Spotify summaries', () {
    expect(formatTotalDuration(const Duration(minutes: 38)), '38 min');
    expect(formatTotalDuration(const Duration(minutes: 72)), '1 hr 12 min');
  });
}
