import 'dart:async';

class StreamTransformers {
  static StreamTransformer<T, R> map<T, R>(R Function(T) mapper) {
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(mapper(data));
      },
    );
  }

  static StreamTransformer<T, T> filter<T>(bool Function(T) predicate) {
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (predicate(data)) {
          sink.add(data);
        }
      },
    );
  }

  static StreamTransformer<T, T> take<T>(int count) {
    int taken = 0;
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (taken < count) {
          sink.add(data);
          taken++;
        }
        if (taken >= count) {
          sink.close();
        }
      },
    );
  }

  static StreamTransformer<T, List<T>> buffer<T>(int size) {
    List<T> buffer = [];
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        buffer.add(data);
        if (buffer.length >= size) {
          sink.add(List.from(buffer));
          buffer.clear();
        }
      },
      handleDone: (sink) {
        if (buffer.isNotEmpty) {
          sink.add(List.from(buffer));
        }
        sink.close();
      },
    );
  }

  static StreamTransformer<T, T> distinct<T>() {
    Set<T> seen = {};
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (!seen.contains(data)) {
          seen.add(data);
          sink.add(data);
        }
      },
    );
  }
}

class StreamController<T> extends StreamController<T> {
  void addAll(Iterable<T> items) {
    for (var item in items) {
      add(item);
    }
  }
}
