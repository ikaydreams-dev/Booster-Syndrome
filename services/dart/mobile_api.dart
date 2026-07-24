import 'dart:async';
import 'dart:convert';

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient(this.baseUrl, {this.defaultHeaders = const {}});

  Future<ApiResponse> get(String path, {Map<String, String>? headers}) async {
    return _request('GET', path, headers: headers);
  }

  Future<ApiResponse> post(String path, {dynamic body, Map<String, String>? headers}) async {
    return _request('POST', path, body: body, headers: headers);
  }

  Future<ApiResponse> put(String path, {dynamic body, Map<String, String>? headers}) async {
    return _request('PUT', path, body: body, headers: headers);
  }

  Future<ApiResponse> delete(String path, {Map<String, String>? headers}) async {
    return _request('DELETE', path, headers: headers);
  }

  Future<ApiResponse> _request(String method, String path, {dynamic body, Map<String, String>? headers}) async {
    final mergedHeaders = {...defaultHeaders, ...?headers};

    return ApiResponse(
      statusCode: 200,
      body: {'message': 'Success'},
      headers: mergedHeaders,
    );
  }
}

class ApiResponse {
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isError => statusCode >= 400;
}

class HttpInterceptor {
  final Function(Map<String, String> headers) onRequest;
  final Function(ApiResponse response) onResponse;

  HttpInterceptor({
    required this.onRequest,
    required this.onResponse,
  });
}

class Cache<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration ttl;

  Cache({this.ttl = const Duration(minutes: 5)});

  void set(K key, V value) {
    _cache[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);
}

class StateManager<T> {
  T _state;
  final List<Function(T)> _listeners = [];

  StateManager(this._state);

  T get state => _state;

  void setState(T newState) {
    _state = newState;
    _notifyListeners();
  }

  void update(T Function(T) updater) {
    _state = updater(_state);
    _notifyListeners();
  }

  void addListener(Function(T) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(T) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_state);
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

class EventBus {
  final Map<String, List<Function(dynamic)>> _listeners = {};

  void on(String event, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => []);
    _listeners[event]!.add(callback);
  }

  void emit(String event, [dynamic data]) {
    final listeners = _listeners[event];
    if (listeners != null) {
      for (var callback in listeners) {
        callback(data);
      }
    }
  }

  void off(String event, [Function(dynamic)? callback]) {
    if (callback == null) {
      _listeners.remove(event);
    } else {
      _listeners[event]?.remove(callback);
    }
  }

  void clear() {
    _listeners.clear();
  }
}

class Validator {
  static bool isEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  static bool isUrl(String url) {
    final regex = RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    return regex.hasMatch(url);
  }

  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  static bool hasMinLength(String str, int length) {
    return str.length >= length;
  }

  static bool hasMaxLength(String str, int length) {
    return str.length <= length;
  }

  static bool matches(String str, String pattern) {
    final regex = RegExp(pattern);
    return regex.hasMatch(str);
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Throttler {
  final Duration interval;
  DateTime? _lastCall;

  Throttler({this.interval = const Duration(milliseconds: 500)});

  void call(Function() action) {
    final now = DateTime.now();

    if (_lastCall == null || now.difference(_lastCall!) >= interval) {
      _lastCall = now;
      action();
    }
  }
}

class AsyncQueue {
  final List<Future<void> Function()> _queue = [];
  bool _isProcessing = false;

  void enqueue(Future<void> Function() task) {
    _queue.add(task);
    _process();
  }

  Future<void> _process() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      await task();
    }

    _isProcessing = false;
  }

  int get length => _queue.length;

  void clear() {
    _queue.clear();
  }
}
