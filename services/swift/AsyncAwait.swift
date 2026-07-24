import Foundation

class AsyncWorker {
    func fetchData(from url: String) async throws -> Data {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    func processInParallel<T>(_ tasks: [() async throws -> T]) async throws -> [T] {
        return try await withThrowingTaskGroup(of: T.self) { group in
            for task in tasks {
                group.addTask {
                    try await task()
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    func retry<T>(maxAttempts: Int, delay: TimeInterval, task: @escaping () async throws -> T) async throws -> T {
        for attempt in 1...maxAttempts {
            do {
                return try await task()
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        fatalError("Should never reach here")
    }
    
    func timeout<T>(seconds: TimeInterval, task: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await task()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            if let result = try await group.next() {
                group.cancelAll()
                return result
            }
            
            throw TimeoutError()
        }
    }
}

struct TimeoutError: Error {}
