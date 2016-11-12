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
  _Tracker _tracker;

  /// Create a Flake64 instance. The default configuration uses
  /// a 42-bit timestamp, 10-bit machine id, and 11-bit sequence.
  Flake64(
      {this.machineId,
      this.machineBits: 10,
      this.sequenceBits: 11,
      TimestampSource time: _currentMillis,
      int epochYear}) {
    if (machineBits < 1) throw 'Machine bits must be at least 1.';
    if (sequenceBits < 1) throw 'Sequence bits must be at least 1.';
    _timeShiftBits = machineBits + sequenceBits;
    if (_timeShiftBits > 21) throw 'Too many machine+sequence bits.';
    if (this.machineId == null) 'Machine ID must be set.';
    if (this.machineId < 0 || this.machineId > (1 << machineBits) - 1)
      throw 'Machine ID out of bounds.';
    _tracker = new _Tracker(time, sequenceBits);
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
  String _machineIdHex;

  _Tracker _tracker;

  /// Create a Flake128 instance.
  Flake128({this.machineId, TimestampSource time: _currentMicros}) {
    if (this.machineId == null) 'Machine ID must be set.';
    if (this.machineId < 0 || this.machineId > (1 << 48) - 1)
      throw 'Machine ID out of bounds.';
    _tracker = new _Tracker(time, 16);
    _machineIdHex = machineId.toRadixString(16).padLeft(12, '0');
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
}

class _Tracker {
  final TimestampSource time;
  int _maxSequence;

  int _timestamp = 0;
  int _sequence = 0;

  _Tracker(this.time, int sequenceBits) {
    _maxSequence = (1 << sequenceBits) - 1;
  }

  int get timestamp => _timestamp;
  int get sequence => _sequence;

  void increment() {
    int ts = 0;
    do {
      ts = time();
      if (ts < _timestamp && (_timestamp - ts) > _maxClockSkewMillis)
        throw 'Max clock skew reached.';
    } while (
        (ts < _timestamp) || (ts == _timestamp && _sequence == _maxSequence));

    if (_timestamp == ts) {
      _sequence++;
    } else {
      _timestamp = ts;
      _sequence = 0;
    }
  }
}
