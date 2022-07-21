import 'dart:async';

extension FutureOrUtils<T> on FutureOr<T> {
  FutureOr<U> then<U>(FutureOr<U> Function(T) function) {
    final futureOr = this;
    if (futureOr is Future<T>) {
      return futureOr.then((value) => function(value));
    } else {
      return function(futureOr);
    }
  }

  static FutureOr<List<U>> wait<U>(Iterable<FutureOr<U>> futureOrs) {
    List<Future<U>> futures = [];
    List<U> values = [];

    for (final futureOr in futureOrs) {
      if (futureOr is Future<U>) {
        futures.add(futureOr);
      } else {
        futures.add(Future.value(futureOr));
        values.add(futureOr);
      }
    }

    if (values.length < futureOrs.length) {
      return Future.wait(futures);
    }

    return values;
  }
}

extension FutureOrNumUtils on FutureOr<num?> {
  FutureOr<num?> add(FutureOr<num?> other) {
    return FutureOrUtils.wait<num?>([this, other])
        .then((list) => list[0] != null && list[1] != null ? list[0]! + list[1]! : null);
  }

  FutureOr<num?> mul(FutureOr<num?> other) {
    return FutureOrUtils.wait<num?>([this, other])
        .then((list) => list[0] != null && list[1] != null ? list[0]! * list[1]! : null);
  }

  FutureOr<num?> div(FutureOr<num?> other) {
    return FutureOrUtils.wait<num?>([this, other])
        .then((list) => list[0] != null && list[1] != null ? list[0]! / list[1]! : null);
  }
}

extension FutureOrStringUtils on FutureOr<String?> {
  FutureOr<String?> join(List<FutureOr<num?>> futureOrs, {String separator = ''}) {
    return FutureOrUtils.wait(futureOrs).then((list) => list.join(separator));
  }

  FutureOr<String?> append(FutureOr<String?> other) {
    return FutureOrUtils.wait<String?>([this, other])
        .then((list) => list[0] != null && list[1] != null ? list[0]! + list[1]! : null);
  }

  FutureOr<String?> prepend(FutureOr<String?> other) {
    return FutureOrUtils.wait<String?>([this, other])
        .then((list) => list[0] != null && list[1] != null ? list[1]! + list[0]! : null);
  }
}
