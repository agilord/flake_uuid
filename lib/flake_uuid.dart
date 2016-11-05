// Copyright (c) 2016, Agilord. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library flake_uuid;

import 'dart:io';

import 'flake_base.dart';

/// Generates a machine ID based on the process's environment and current
/// timestamp.
int _machineId(int bits) {
  List values = [
    Platform.operatingSystem,
    Platform.numberOfProcessors,
    Platform.localHostname,
    pid,
    Platform.resolvedExecutable,
    Platform.script,
    Platform.executableArguments?.join(', '),
    new DateTime.now().microsecondsSinceEpoch
  ];
  if (bits <= 30) {
    int hash = values.join('/@/').hashCode.abs();
    return hash % (1 << bits);
  } else if (bits <= 60) {
    int hash1 = values.join('/').hashCode.abs();
    int hash2 = values.join('@').hashCode.abs();
    int hash = (hash1 % (1 << 30)) * (1 << 30) + (hash2 % (1 << (bits - 30)));
    return hash % (1 << bits);
  } else {
    throw 'Cannot handle $bits bits.';
  }
}

/// The default Flake64 instance that initializes its machine ID from the
/// environment (somewhat randomly).
Flake64 flake64 = new Flake64(machineId: _machineId(10));

/// The default Flake128 instance that initializes its machine ID from the
/// environment (somewhat randomly).
Flake128 flake128 = new Flake128(machineId: _machineId(48));
