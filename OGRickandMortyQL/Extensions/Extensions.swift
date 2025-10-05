//
//  Extensions.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 30/09/25.
//

import Foundation
import ApolloAPI
import RMServerAPI
import Apollo
import Combine


// MARK: - Combine
extension ApolloClient {
    /// Cancellation-aware Combine publisher for Apollo fetch.
    func fetchPublisher<Query: GraphQLQuery>(query: Query, cachePolicy: CachePolicy = .returnCacheDataElseFetch) -> AnyPublisher<GraphQLResult<Query.Data>, Error> {
        Deferred { () -> AnyPublisher<GraphQLResult<Query.Data>, Error> in
            // `cancellableRef` is captured by the Future and handleEvents closures,
            // so it's per-subscription and safe for concurrent subscriptions.
            var cancellableRef: Apollo.Cancellable?

            let publisher = Future<GraphQLResult<Query.Data>, Error> { promise in
                cancellableRef = self.fetch(query: query, cachePolicy: cachePolicy, context: nil, queue: .main) { result in
                    switch result {
                    case .success(let graphQLResult):
                        promise(.success(graphQLResult))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
            // When the Combine subscriber cancels the subscription, cancel Apollo's request:
            .handleEvents(receiveCancel: {
                cancellableRef?.cancel()
            })
            .eraseToAnyPublisher()

            return publisher
        }
        .eraseToAnyPublisher()
    }
}
// MARK: - Concurrency

import Foundation
import Apollo

// MARK: - CancellableToken
/// Thread-safe holder for Apollo's Cancellable so we can cancel the network request
final class CancellableToken {
    private let lock = NSLock()
    private var _cancellable: Apollo.Cancellable?

    func store(_ cancellable: Apollo.Cancellable) {
        lock.lock()
        _cancellable = cancellable
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let c = _cancellable
        _cancellable = nil
        lock.unlock()
        c?.cancel()
    }
}

// MARK: - ContinuationBox
/// Thread-safe wrapper that stores a continuation and ensures it's resumed exactly once.
final class ContinuationBox<Value> {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?
    private var resumed = false

    func store(_ continuation: CheckedContinuation<Value, Error>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func resume(returning value: Value) {
        lock.lock()
        guard !resumed, let cont = continuation else {
            lock.unlock()
            return
        }
        resumed = true
        continuation = nil
        lock.unlock()
        cont.resume(returning: value)
    }

    func resume(throwing error: Error) {
        lock.lock()
        guard !resumed, let cont = continuation else {
            lock.unlock()
            return
        }
        resumed = true
        continuation = nil
        lock.unlock()
        cont.resume(throwing: error)
    }
}

// MARK: - ApolloClient async bridge (cancellation-safe)
extension ApolloClient {
    /// Cancellation-aware bridge from Apollo callback fetch to async/await.
    /// Guarantees the continuation is resumed exactly once, and cancels the Apollo request if the Swift Task is cancelled.
    func fetchAsync<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .returnCacheDataElseFetch
    ) async throws -> GraphQLResult<Query.Data> {
        let token = CancellableToken()
        let box = ContinuationBox<GraphQLResult<Query.Data>>()
        
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GraphQLResult<Query.Data>, Error>) in
                // store the continuation so onCancel can resume it if needed
                box.store(continuation)
                
                // Start the Apollo fetch; deliver completion on the main queue by default.
                // (Adjust queue if you prefer background delivery.)
                let cancellable = self.fetch(query: query, cachePolicy: cachePolicy, context: nil, queue: .main) { result in
                    switch result {
                    case .success(let graphQLResult):
                        box.resume(returning: graphQLResult)
                    case .failure(let error):
                        // If the Swift Task was cancelled, prefer to surface CancellationError
                        if Task.isCancelled {
                            box.resume(throwing: CancellationError())
                        } else {
                            box.resume(throwing: error)
                        }
                    }
                }
                
                // store the Apollo cancellable so the onCancel handler can cancel the network
                token.store(cancellable)
            }
        }, onCancel: {
            // Cancel the underlying Apollo request *and* make sure the continuation finishes
            token.cancel()
            box.resume(throwing: CancellationError())
        })
    }
}

