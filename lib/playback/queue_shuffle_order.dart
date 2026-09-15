import 'dart:math';

import 'package:just_audio/just_audio.dart';

/// just_audio's default shuffle order scatters inserted tracks randomly,
/// which breaks "Play next" and "Add to queue" while shuffled. This order
/// behaves the same except that an insertion can be anchored to an exact
/// position in the play order.
class QueueShuffleOrder extends ShuffleOrder {
  QueueShuffleOrder({Random? random}) : _random = random ?? Random();

  final Random _random;
  int? _anchor;

  @override
  final indices = <int>[];

  /// Places the next [insert]ed indices at [position] in [indices] instead
  /// of at random.
  void anchorNextInsert(int position) => _anchor = position;

  @override
  void shuffle({int? initialIndex}) {
    _anchor = null;
    if (indices.length <= 1) return;
    indices.shuffle(_random);
    if (initialIndex == null) return;
    final position = indices.indexOf(initialIndex);
    if (position <= 0) return;
    indices[position] = indices[0];
    indices[0] = initialIndex;
  }

  @override
  void insert(int index, int count) {
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= index) indices[i] += count;
    }
    final added = List<int>.generate(count, (offset) => index + offset);
    final anchor = _anchor;
    _anchor = null;
    if (anchor != null) {
      indices.insertAll(anchor.clamp(0, indices.length), added);
      return;
    }
    for (final value in added) {
      indices.insert(_random.nextInt(indices.length + 1), value);
    }
  }

  @override
  void removeRange(int start, int end) {
    final count = end - start;
    indices.removeWhere((value) => value >= start && value < end);
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= end) indices[i] -= count;
    }
  }

  @override
  void clear() {
    _anchor = null;
    indices.clear();
  }
}
