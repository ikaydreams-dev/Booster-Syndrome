import 'dart:async';

class AsyncUtils {
  static Future<List<T>> parallel<T>(List<Future<T>> futures) async {
    return await Future.wait(futures);
  }

  static Future<T> retry<T>({
    required Future<T> Function() task,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await task();
      } catch (e) {
        if (attempt == maxAttempts) {
          rethrow;
        }
        await Future.delayed(delay * attempt);
      }
    }
    throw Exception('Should never reach here');
  }

  static Future<T> timeout<T>({
    required Future<T> Function() task,
    required Duration duration,
  }) async {
    return await task().timeout(duration);
  }

  static Stream<T> debounce<T>(Stream<T> stream, Duration duration) {
    StreamController<T>? controller;
    Timer? timer;
    
    controller = StreamController<T>(
      onListen: () {
        stream.listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () {
              controller!.add(data);
            });
          },
          onDone: () => controller!.close(),
          onError: (error) => controller!.addError(error),
        );
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    
    return controller.stream;
  }

  static Stream<T> throttle<T>(Stream<T> stream, Duration duration) {
    StreamController<T>? controller;
    bool isThrottled = false;
    
    controller = StreamController<T>(
      onListen: () {
        stream.listen(
          (data) {
            if (!isThrottled) {
              controller!.add(data);
              isThrottled = true;
              Timer(duration, () => isThrottled = false);
            }
          },
          onDone: () => controller!.close(),
          onError: (error) => controller!.addError(error),
        );
      },
    );
    
    return controller.stream;
  }
}
