import Foundation

class NetworkClient {
    let baseURL: URL
    var defaultHeaders: [String: String] = [:]

    init(baseURL: String) {
        self.baseURL = URL(string: baseURL)!
    }

    func get(_ path: String, parameters: [String: Any]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        request(method: "GET", path: path, parameters: parameters, completion: completion)
    }

    func post(_ path: String, body: [String: Any]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        request(method: "POST", path: path, body: body, completion: completion)
    }

    func put(_ path: String, body: [String: Any]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        request(method: "PUT", path: path, body: body, completion: completion)
    }

    func delete(_ path: String, completion: @escaping (Result<Data, Error>) -> Void) {
        request(method: "DELETE", path: path, completion: completion)
    }

    private func request(method: String, path: String, parameters: [String: Any]? = nil, body: [String: Any]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!

        if let params = parameters {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method

        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let bodyData = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: bodyData)
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                completion(.success(data))
            }
        }.resume()
    }
}

class Cache<Key: Hashable, Value> {
    private var storage: [Key: CacheEntry<Value>] = [:]
    private let lock = NSLock()
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 300) {
        self.ttl = ttl
    }

    func set(_ key: Key, value: Value) {
        lock.lock()
        defer { lock.unlock() }

        let expiresAt = Date().addingTimeInterval(ttl)
        storage[key] = CacheEntry(value: value, expiresAt: expiresAt)
    }

    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = storage[key] else {
            return nil
        }

        if Date() > entry.expiresAt {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }

        storage.removeValue(forKey: key)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }

        storage.removeAll()
    }
}

struct CacheEntry<Value> {
    let value: Value
    let expiresAt: Date
}

class Observable<T> {
    typealias Observer = (T) -> Void

    private var observers: [Observer] = []

    var value: T {
        didSet {
            notifyObservers()
        }
    }

    init(_ value: T) {
        self.value = value
    }

    func subscribe(_ observer: @escaping Observer) {
        observers.append(observer)
        observer(value)
    }

    private func notifyObservers() {
        observers.forEach { $0(value) }
    }
}

class Debouncer {
    private var timer: Timer?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }

    func call(_ action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
}

class RateLimiter {
    private var tokens: Int
    private let maxTokens: Int
    private let refillRate: TimeInterval
    private var lastRefill: Date

    init(maxTokens: Int, refillRate: TimeInterval) {
        self.maxTokens = maxTokens
        self.tokens = maxTokens
        self.refillRate = refillRate
        self.lastRefill = Date()
    }

    func allow() -> Bool {
        refill()

        if tokens > 0 {
            tokens -= 1
            return true
        }

        return false
    }

    private func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let tokensToAdd = Int(elapsed / refillRate)

        if tokensToAdd > 0 {
            tokens = min(tokens + tokensToAdd, maxTokens)
            lastRefill = now
        }
    }
}

class AsyncQueue {
    private var tasks: [() async -> Void] = []
    private var isProcessing = false

    func enqueue(_ task: @escaping () async -> Void) {
        tasks.append(task)
        process()
    }

    private func process() {
        guard !isProcessing, !tasks.isEmpty else { return }

        isProcessing = true

        Task {
            while !tasks.isEmpty {
                let task = tasks.removeFirst()
                await task()
            }

            isProcessing = false
        }
    }
}

struct Validator {
    static func isEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: email)
    }

    static func isURL(_ url: String) -> Bool {
        guard let url = URL(string: url) else { return false }
        return url.scheme != nil && url.host != nil
    }

    static func hasMinLength(_ string: String, length: Int) -> Bool {
        return string.count >= length
    }

    static func hasMaxLength(_ string: String, length: Int) -> Bool {
        return string.count <= length
    }
}
