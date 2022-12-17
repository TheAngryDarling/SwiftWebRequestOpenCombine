//
//  DataRequest+WebRequestOpenCombine.swift
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

public extension WebRequest.DataRequest {
    /// The data event publisher used to capture data packets
    /// being received from the request
    struct DataEventPublisher: Publisher {
        
        public typealias Output = (data: Data, response: URLResponse)
        public typealias Failure = URLError
        
        private class DataEventSubscription<S: Subscriber>: Subscription where S.Input == Output, S.Failure == Failure {
            /// The web request for this subscription
            private var request: DataRequest?
            /// The subscriber attached to this subscription
            private var subscriber: S?
            /// Lock used to synchronize sending the finish event
            private let hasFinishedLocked = NSLock()
            /// Indicator if the finished event has been sent
            private var hasFinished = false
            
            public init(request: DataRequest, subscriber: S) {
                self.request = request
                self.subscriber = subscriber
                
                // if the request has not completed then we will setup
                // a callback to handle when its done
                if request.state == .suspended || request.state == .running {
                    request.addDidReceiveDataHandler { session, request, data in
                        // when ever we receive data we send it along
                        _ = self.subscriber?.receive((data: data,
                                                      response: request.response!))
                    }
                    request.registerCompletionHandler { _, results in
                        // The request is finished
                        // lets synchronize sending the finish
                        // event
                        self.executeFinishedBlock {
                            // if there was an error and the state was NOT canceling
                            // lets send the error
                            if let e = results.error,
                               request.state != .canceling {
                                
                                let err = WebRequest.errorToURLError(e, for: results.currentURL)
                                self.subscriber?.receive(completion: .failure(err))
                                
                            } else {
                                // otherwise send the finished event
                                self.subscriber?.receive(completion: .finished)
                            }
                        }
                    }
                    
                }
                
            }
            /// Method used to synchronization of the finish block
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
            
            
            
            
            func request(_ demand: Subscribers.Demand) {
                // start the request if needed
                if !(self.request?.hasStarted ?? false) && self.request?.state == .suspended {
                    self.request?.resume()
                }
            }
            
            func cancel() {
                self.executeFinishedBlock {
                    if let r = self.request,
                       r.state != .completed && r.state != .canceling {
                       self.subscriber?.receive(completion: .finished)
                    }
                }
                self.subscriber = nil
                self.request?.cancel()
                self.request = nil
            }
        }
        /// The web request for this publisher
        public let request: DataRequest
        
        internal init(request: DataRequest) {
            self.request = request
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = DataEventSubscription(request: self.request,
                                                     subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }
    /// Create a WebRequest Data Event Task Publisher
    ///
    /// Note: This differes from the Data Task Publisher as this
    /// sends received data from the stream to the publisher
    func dataEventPublisher() -> DataEventPublisher {
        return DataEventPublisher(request: self)
    }
    
}
