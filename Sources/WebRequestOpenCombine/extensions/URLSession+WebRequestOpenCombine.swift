//
//  URLSession+WebRequestOpenCombine.swift
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

// MARK: - Data Web Request
public extension URLSession {
    /// Create a WebRequest Data Task Publisher
    func webRequestDataTaskPublisher(for request: URLRequest) -> WebRequest.DataRequest.TaskedPublisher {
        let request = WebRequest.DataRequest(request, usingSession: self)
        return request.publisher()
    }
    /// Create a WebRequest Data Task Publisher
    func webRequestDataTaskPublisher(for url: URL) -> WebRequest.DataRequest.TaskedPublisher {
        return self.webRequestDataTaskPublisher(for: URLRequest(url: url))
    }
    
    /// Create a WebRequest Data Event Task Publisher
    ///
    /// Note: This differes from the Data Task Publisher as this
    /// sends received data from the stream to the publisher
    func webRequestDataEventTaskPublisher(for request: URLRequest) -> WebRequest.DataRequest.DataEventPublisher {
        let request = WebRequest.DataRequest(request, usingSession: self)
        return request.dataEventPublisher()
    }
    /// Create a WebRequest Data Event Task Publisher
    ///
    /// Note: This differes from the Data Task Publisher as this
    /// sends received data from the stream to the publisher
    func webRequestDataEventTaskPublisher(for url: URL) -> WebRequest.DataRequest.DataEventPublisher {
        return self.webRequestDataEventTaskPublisher(for: URLRequest(url: url))
    }
}

// MARK: - Download Web Request
public extension URLSession {
    /// Create a WebRequest Download Task Publisher
    func webRequestDownloadTaskPublisher(for request: URLRequest) -> WebRequest.DownloadRequest.TaskedPublisher {
        let request = WebRequest.DownloadRequest(request, usingSession: self)
        return request.publisher()
    }
    /// Create a WebRequest Download Task Publisher
    func webRequestDownloadTaskPublisher(for url: URL) -> WebRequest.DownloadRequest.TaskedPublisher {
        return self.webRequestDownloadTaskPublisher(for: URLRequest(url: url))
    }
}

// MARK: - Upload Web Request
public extension URLSession {
    /// Create a WebRequest Upload Task Publisher
    /// - Parameters:
    ///   - bodyData: The data to upload
    func webRequestUploadTaskPublisher(for request: URLRequest,
                                       from bodyData: Data) -> WebRequest.UploadRequest.TaskedPublisher {
        let request = WebRequest.UploadRequest(request,
                                               from: bodyData,
                                               usingSession: self)
        return request.publisher()
    }
    
    /// Create a WebRequest Upload Task Publisher
    /// - Parameters:
    ///   - bodyData: The data to upload
    func webRequestUploadTaskPublisher(for url: URL,
                                       from bodyData: Data) -> WebRequest.UploadRequest.TaskedPublisher {
        return self.webRequestUploadTaskPublisher(for: URLRequest(url: url),
                                                     from: bodyData)
    }
    
    /// Create a WebRequest Upload Task Publisher
    /// - Parameters:
    ///   - fileURL: The file to upload
    func webRequestUploadTaskPublisher(for request: URLRequest,
                                       fromFile fileURL: URL) -> WebRequest.UploadRequest.TaskedPublisher {
        let request = WebRequest.UploadRequest(request,
                                               fromFile: fileURL,
                                               usingSession: self)
        return request.publisher()
    }
    
    /// Create a WebRequest Upload Task Publisher
    /// - Parameters:
    ///   - fileURL: The file to upload
    func webRequestUploadTaskPublisher(for url: URL,
                                       fromFile fileURL: URL) -> WebRequest.UploadRequest.TaskedPublisher {
        return self.webRequestUploadTaskPublisher(for: URLRequest(url: url),
                                                     fromFile: fileURL)
    }
    
    /// Create a WebRequest Upload Task Publisher
    /// - Parameters:
    ///   - request: The request with the stream attached to upload
    func webRequestUploadTaskPublisher(withStreamedRequest request: URLRequest) -> WebRequest.UploadRequest.TaskedPublisher {
        let request = WebRequest.UploadRequest(withStreamedRequest: request,
                                               usingSession: self)
        return request.publisher()
    }
}
