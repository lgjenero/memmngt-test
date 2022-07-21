import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'future.dart';

final Random _random = Random.secure();

/// Creates a random Operation ID
String randomOperationId([int length = 12]) {
  final string = base64Url.encode(List<int>.generate(length, (i) => _random.nextInt(256)));
  return string.substring(0, string.length - 1);
}

/// Operation context
/// Used when we need to run chained and/or parallel async operations
/// that share some data/resources
class OperationContext {
  final String operationId;
  const OperationContext(this.operationId);
}

/// Runs a new operatin context
Future<void> runInContext<T extends OperationContext>(T context, FutureOr<void> Function() operation) {
  final completer = Completer();

  runZoned(
    () {
      operation.call().then((_) => completer.complete());
    },
    zoneValues: {
      #_context: context,
    },
  );

  return completer.future;
}

/// Gets the current operaiton context
/// Will throw if called running outside the operation contex
T getContext<T extends OperationContext>() => Zone.current[#_context] as T;

/// Tries to get the current operaiton context
/// Will return `null` if called running outside the operation contex
T? tryGetContext<T extends OperationContext>() {
  final context = Zone.current[#_context];
  if (context is T) {
    return context;
  }
  return null;
}

/// Runs a new operatin context
Future<void> runOutOfContext<T extends OperationContext>(T context, FutureOr<void> Function() operation) {
  final completer = Completer();
  Zone.root.run(() => operation.then((_) => completer.complete()));
  return completer.future;
}
