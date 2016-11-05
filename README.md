# Flake UUID

Flake UUID is a Dart library that provides 64- and 128-bit, k-ordered
identifiers, which preserve their order of creation (somewhat) if sorted
lexically.

It generates conflict-free and unique identifiers without further
coordination between the nodes on your cluster (assuming time goes
forward and machine IDs are unique).

## 64-bit Flake ID

The 64-bit Flake ID is created with:
- 42-bit timestamp (millis since epoch, good til the end of this century)
- 10-bit machine ID
- 11-bit sequence (incremented within the same millisecond)

A simple usage example, works only with Dart VM, because it uses the
environment to generate a somewhat-random machine ID:

    import 'package:flake_uuid/flake_uuid.dart';

    main() {
      var x = flake64.nextInt();
      var y = flake64.nextHex(); // '2b06cca4f5542000'
    }

A more detailed version if you use the class directly. You must supply
a pre-coordinated machine ID:

    import 'package:flake_uuid/flake_base.dart';

    main() {
      var flake = new Flake64(machineId: 123);
      var x = flake.nextInt();
      var y = flake.nextHex();
    }

## 128-bit Flake ID

The 128-bit Flake ID is created with:
- 64-bit timestamps (macroseconds(!) since epoch, won't run out in your lifetime)
- 48-bit machine ID
- 16-bit sequence (incremented within the same macrosecond)

A simple usage example, works only with Dart VM, because it uses the
environment to generate a somewhat-random machine ID:

    import 'package:flake_uuid/flake_uuid.dart';

    main() {
      var y = flake128.nextHex(); // '2b06cca4f5542000'
    }

A more detailed version if you use the class directly. You must supply
a pre-coordinated machine ID:

    import 'package:flake_uuid/flake_base.dart';

    main() {
      var flake = new Flake128(machineId: 123);
      var x = flake.nextInt(); // not recommended
      var y = flake.nextHex(); // '000540947b2305c4a25c0001c73a0000'
    }
