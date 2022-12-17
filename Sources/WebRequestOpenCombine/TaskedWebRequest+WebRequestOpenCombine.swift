//
//  TaskedWebRequest+WebRequestOpenCombine.swift
//  
//
//  Created by Tyler Anger on 2022-12-14.
//

import Foundation
import OpenCombine
import WebRequest
#if swift(>=4.1)
    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif
#endif


public extension WebRequest.TaskedWebRequest {
    /// The tasked publisher used for general tasked requests
    struct TaskedPublisher: Publisher {
        
        public typealias Output = (value: Results.ResultsType, response: URLResponse)
        public typealias Failure = URLError
        
        private class TaskedSubscription<S: Subscriber>: Subscription where S.Input == Output, S.Failure == Failure {
            /// The web request for this subscription
            private var request: TaskedWebRequest?
            /// The subscriber attached to this subscription
            private var subscriber: S?
            /// Lock used to synchronize sending the finish event
            private let hasFinishedLocked = NSLock()
            /// Indicator if the finished event has been sent
            private var hasFinished = false
            
            public init(request: TaskedWebRequest, subscriber: S) {
                self.request = request
                self.subscriber = subscriber
                
                // if the request has not completed then we will setup
                // a callback to handle when its done
                if request.state == .suspended || request.state == .running {
                    request.registerCompletionHandler { _, results in
                        self.publishResults(results)
                    }
                }
                
            }
            
            func executeFinishedBlock(_ block: () -> Void) {
                self.hasFinishedLocked.lock()
                guard !self.hasFinished else {
                    self.hasFinishedLocked.unlock()
                    return
                }
                defer { self.hasFinishedLocked.unlock() }
                self.hasFinished = true
                block()
            }
            
            /// Method used to publish web request results to the subscriber
            func publishResults(_ results: Results,
                                file: StaticString = #file,
                                line: Int = #line) {
                guard let s = self.subscriber else { return }
                
                if let e = results.error {
                    let err = WebRequest.errorToURLError(e, for: results.currentURL)
                    self.executeFinishedBlock {
                        s.receive(completion: .failure(err))
                    }
                } else if let r = results.results {
                    _ = s.receive((value: r,
                                  response: results.response!))
                    self.executeFinishedBlock {
                        s.receive(completion: .finished)
                    }
                } else {
                    self.executeFinishedBlock {
                        let err = TaskedWebRequest.createURLUnknown(for: results.currentURL,
                                                                    description: "No results or error set")
                        s.receive(completion: .failure(err))
                    }
                }
                
                
                self.request = nil
                self.subscriber = nil
            }
            
            func request(_ demand: Subscribers.Demand) {
                if let r = self.request?.results,
                   (r.response != nil || r.error != nil || r.results != nil) {
                    // if we already have results
                    // then lets just publish them
                    self.publishResults(r)
                } else if !(self.request?.hasStarted ?? false) && self.request?.state == .suspended {
                    self.request?.resume()
                }
            }
            
            func cancel() {
                if let r = self.request,
                   r.state != .completed && r.state != .canceling {
                    r.cancel()
                    self.executeFinishedBlock {
                        let cancelError = TaskedWebRequest.createURLCancel(for: r.currentRequest?.url)
                        self.subscriber?.receive(completion: .failure(cancelError))
                    }
                }
                self.subscriber = nil
                self.request = nil
            }
        }
        /// the web request this publisher is working on
        public let request: TaskedWebRequest
        
        fileprivate init(request: TaskedWebRequest) {
            self.request = request
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = TaskedSubscription(request: self.request,
                                                  subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }
    
    /// Create a Task Publisher
    func publisher() -> TaskedPublisher {
        return TaskedPublisher(request: self)
    }
}
