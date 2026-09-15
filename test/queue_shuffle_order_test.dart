import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/playback/queue_shuffle_order.dart';

void main() {
  QueueShuffleOrder shuffled(int count, {int seed = 1}) {
    return QueueShuffleOrder(random: Random(seed))
      ..insert(0, count)
      ..shuffle();
  }

  test('shuffle puts the initial index first', () {
    final order = QueueShuffleOrder(random: Random(3))..insert(0, 6);
    order.shuffle(initialIndex: 4);
    expect(order.indices.first, 4);
    expect(order.indices.toSet(), {0, 1, 2, 3, 4, 5});
  });

  test('an anchored insert lands at exactly that play position', () {
    final order = shuffled(5);
    final before = List.of(order.indices);

    order
      ..anchorNextInsert(1)
      ..insert(5, 2);

    expect(order.indices, [before.first, 5, 6, ...before.skip(1)]);
  });

  test('inserting ahead of existing sources renumbers them', () {
    final order = shuffled(3, seed: 7);
    final before = List.of(order.indices);

    order
      ..anchorNextInsert(0)
      ..insert(1, 1);

    expect(order.indices, [
      1,
      for (final index in before) index >= 1 ? index + 1 : index,
    ]);
  });

  test('an anchor applies to one insert only', () {
    final order = shuffled(4, seed: 2)..anchorNextInsert(0);
    order.insert(4, 1);
    expect(order.indices.first, 4);

    order.insert(5, 1);
    expect(order.indices.toSet(), {0, 1, 2, 3, 4, 5});
  });

  test('removing a range drops those sources and compacts the rest', () {
    final order = shuffled(6, seed: 5)..removeRange(1, 3);
    expect(order.indices, hasLength(4));
    expect(order.indices.toSet(), {0, 1, 2, 3});
  });

  test('clear empties the order and forgets any anchor', () {
    final order = shuffled(3)
      ..anchorNextInsert(2)
      ..clear();
    expect(order.indices, isEmpty);
    order.insert(0, 1);
    expect(order.indices, [0]);
  });
}
