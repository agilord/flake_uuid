// Copyright (c) 2016, Agilord. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library flake_uuid.base;

final int _maxClockSkewMillis = const Duration(seconds: 2).inMilliseconds;

/// Provides the current timestamp.
typedef int TimestampSource();

int _currentMillis() => new DateTime.now().millisecondsSinceEpoch;
int _currentMicros() => new DateTime.now().microsecondsSinceEpoch;

/// Generates 64-bit, mostly-unique, k-ordered values.
class Flake64 {
  /// Number of bits to store machine information
  final int machineBits;

  /// Number of bits to store the sequence information
  final int sequenceBits;

  /// The machine ID
  final int machineId;

  int _epochOffset = 0;
  int _timeShiftBits = 0;
  final _Tracker _tracker;

  /// Create a Flake64 instance. The default configuration uses
  /// a 42-bit timestamp, 10-bit machine id, and 11-bit sequence.
  Flake64({
    required this.machineId,
    this.machineBits = 10,
    this.sequenceBits = 11,
    TimestampSource time = _currentMillis,
    int? epochYear,
    bool continuousSequence = false,
  }) : _tracker = new _Tracker(time, sequenceBits, continuousSequence) {
    if (machineBits < 1)
      throw new StateError('Machine bits must be at least 1.');
    if (sequenceBits < 1)
      throw new StateError('Sequence bits must be at least 1.');
    _timeShiftBits = machineBits + sequenceBits;
    if (_timeShiftBits > 21)
      throw new StateError('Too many machine+sequence bits.');
    if (this.machineId < 0 || this.machineId > (1 << machineBits) - 1)
      throw new StateError('Machine ID out of bounds.');
    if (epochYear != null) {
      _epochOffset = new DateTime(epochYear).millisecondsSinceEpoch;
    }
  }

  /// Gets the next value as an integer.
  int nextInt() {
    _tracker.increment();
    return ((_tracker.timestamp - _epochOffset) << _timeShiftBits) +
        (machineId << sequenceBits) +
        _tracker.sequence;
  }

  /// Gets the next value as a hex String.
  String nextHex() {
    return nextInt().toRadixString(16).padLeft(16, '0');
  }
}

/// Generates 128-bit, mostly-unique, k-ordered values.
class Flake128 {
  /// The machine ID
  final int machineId;
  final String _machineIdHex;

  final _Tracker _tracker;

  /// Create a Flake128 instance.
  Flake128({
    required this.machineId,
    TimestampSource time = _currentMicros,
    bool continuousSequence = false,
  })  : _tracker = new _Tracker(time, 16, continuousSequence),
        _machineIdHex = machineId.toRadixString(16).padLeft(12, '0') {
    if (this.machineId < 0 || this.machineId > (1 << 48) - 1)
      throw new StateError('Machine ID out of bounds.');
  }

  /// Gets the next value as an integer.
  int nextInt() {
    _tracker.increment();
    return (_tracker.timestamp << 64) + (machineId << 48) + _tracker.sequence;
  }

  /// Gets the next value as a hex String.
  String nextHex() {
    _tracker.increment();
    return _tracker.timestamp.toRadixString(16).padLeft(16, '0') +
        _machineIdHex +
        _tracker.sequence.toRadixString(16).padLeft(4, '0');
  }

  /// Gets the next value as a UUID-formatted String.
  String nextUuid() {
    final hex = nextHex();
    return hex.substring(0, 8) +
        '-' +
        hex.substring(8, 12) +
        '-' +
        hex.substring(12, 16) +
        '-' +
        hex.substring(16, 20) +
        '-' +
        hex.substring(20);
  }
}

class _Tracker {
  final TimestampSource time;
  final bool continuousSequence;
  final int _maxSequence;

  int _timestamp = 0;
  int _sequence = 0;

  _Tracker(this.time, int sequenceBits, this.continuousSequence)
      : _maxSequence = (1 << sequenceBits) - 1 {
    _sequence = _maxSequence;
  }

  int get timestamp => _timestamp;
  int get sequence => _sequence;

  void increment() {
    int ts = 0;
    final bool isMax = _sequence >= _maxSequence;
    do {
      ts = time();
      if (ts < _timestamp && (_timestamp - ts) > _maxClockSkewMillis)
        throw new StateError('Max clock skew reached.');
    } while ((ts < _timestamp) || (ts == _timestamp && isMax));

    if (_timestamp != ts && (isMax || !continuousSequence)) {
      _sequence = 0;
    } else {
      _sequence++;
    }
    _timestamp = ts;
  }
}
