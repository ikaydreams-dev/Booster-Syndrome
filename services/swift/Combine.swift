import Combine
import Foundation

class PublisherUtilities {
    private var cancellables = Set<AnyCancellable>()
    
    func debounce<T>(_ publisher: AnyPublisher<T, Never>, for interval: TimeInterval) -> AnyPublisher<T, Never> {
        return publisher
            .debounce(for: .seconds(interval), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func throttle<T>(_ publisher: AnyPublisher<T, Never>, for interval: TimeInterval) -> AnyPublisher<T, Never> {
        return publisher
            .throttle(for: .seconds(interval), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }
    
    func retryWithDelay<T, E: Error>(_ publisher: AnyPublisher<T, E>, maxAttempts: Int, delay: TimeInterval) -> AnyPublisher<T, E> {
        return publisher
            .catch { error -> AnyPublisher<T, E> in
                return Just(())
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                    .flatMap { _ in publisher }
                    .eraseToAnyPublisher()
            }
            .retry(maxAttempts)
            .eraseToAnyPublisher()
    }
    
    func merge<T>(_ publishers: [AnyPublisher<T, Never>]) -> AnyPublisher<T, Never> {
        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }
    
    func combineLatest<A, B>(_ pub1: AnyPublisher<A, Never>, _ pub2: AnyPublisher<B, Never>) -> AnyPublisher<(A, B), Never> {
        return pub1
            .combineLatest(pub2)
            .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
class Subject<T> {
    private let subject = PassthroughSubject<T, Never>()
    
    var publisher: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func send(_ value: T) {
        subject.send(value)
    }
}
