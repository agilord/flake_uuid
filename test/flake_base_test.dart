// Copyright (c) 2016, Agilord. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flake_uuid/flake_base.dart';

import 'package:test/test.dart';

void main() {
  group('Flake64', () {
    test('Invalid config.', () {
      expect(() => new Flake64(), throwsStateError);
      expect(() => new Flake64(machineId: -1), throwsStateError);
      expect(
          () => new Flake64(machineId: 100, machineBits: 2), throwsStateError);
      expect(
          () => new Flake64(machineId: 0, machineBits: 20), throwsStateError);
      expect(
          () => new Flake64(machineId: 0, sequenceBits: 20), throwsStateError);
    });

    test('Simple sequence.', () {
      var flake = new Flake64(machineId: 0, time: () => 10);
      expect(flake.nextHex(), '0000000001400000');
      expect(flake.nextHex(), '0000000001400001');
      expect(flake.nextHex(), '0000000001400002');

      flake = new Flake64(
          machineId: 0, sequenceBits: 8, machineBits: 8, time: () => 10);
      expect(flake.nextHex(), '00000000000a0000');
      expect(flake.nextHex(), '00000000000a0001');
      expect(flake.nextHex(), '00000000000a0002');
    });

    test('Unique values.', () {
      final List<Flake64> flakes = new List.generate(100,
          (i) => new Flake64(machineId: i, machineBits: 8, sequenceBits: 8));
      final Set<int> set = new Set();
      for (int i = 0; i < 1000; i++) {
        flakes.forEach((flake) {
          final int x = flake.nextInt();
          expect(set.contains(x), false);
          set.add(x);
        });
      }
    });

    test('Detect clock skew.', () {
      int timestamp = 1000000;
      final Flake64 flake = new Flake64(machineId: 0, time: () => timestamp--);
      flake.nextInt();
      expect(() {
        flake.nextInt();
      }, throwsStateError);
      expect(timestamp, lessThan(998000)); // throws after 2 seconds
    });

    test('Catch up with clock.', () {
      int timestamp = 10000;
      final Flake64 flake = new Flake64(machineId: 0, time: () => timestamp++);
      final int a = flake.nextInt();
      timestamp -= 1000; // rewind clock by 1 second
      final int b = flake.nextInt();
      expect(a, lessThan(b));
    });

    test('Reset sequence.', () {
      int time = 10;
      final flake = new Flake64(machineId: 0, time: () => time);
      expect(flake.nextHex(), '0000000001400000');
      expect(flake.nextHex(), '0000000001400001');
      expect(flake.nextHex(), '0000000001400002');
      time = 11;
      expect(flake.nextHex(), '0000000001600000');
      expect(flake.nextHex(), '0000000001600001');
      expect(flake.nextHex(), '0000000001600002');
    });

    test('Continuous sequence.', () {
      int time = 10;
      final flake = new Flake64(
        machineId: 0,
        time: () => time,
        continuousSequence: true,
      );
      expect(flake.nextHex(), '0000000001400000');
      expect(flake.nextHex(), '0000000001400001');
      expect(flake.nextHex(), '0000000001400002');
      time = 11;
      expect(flake.nextHex(), '0000000001600003');
      expect(flake.nextHex(), '0000000001600004');
      expect(flake.nextHex(), '0000000001600005');
    });
  });

  group('Flake128', () {
    test('Reset sequence.', () {
      int time = 10;
      final flake = new Flake128(machineId: 1, time: () => time);
      expect(flake.nextHex(), '000000000000000a0000000000010000');
      expect(flake.nextHex(), '000000000000000a0000000000010001');
      expect(flake.nextHex(), '000000000000000a0000000000010002');
      expect(flake.nextUuid(), '00000000-0000-000a-0000-000000010003');
      time = 11;
      expect(flake.nextHex(), '000000000000000b0000000000010000');
    });

    test('Continuous sequence.', () {
      int time = 10;
      final flake = new Flake128(
        machineId: 1,
        time: () => time,
        continuousSequence: true,
      );
      expect(flake.nextHex(), '000000000000000a0000000000010000');
      expect(flake.nextHex(), '000000000000000a0000000000010001');
      expect(flake.nextHex(), '000000000000000a0000000000010002');
      expect(flake.nextUuid(), '00000000-0000-000a-0000-000000010003');
      time = 11;
      expect(flake.nextHex(), '000000000000000b0000000000010004');
    });
  });
}
