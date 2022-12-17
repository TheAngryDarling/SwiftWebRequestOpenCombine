//
//  WebRequest+WebRequestOpenCombine.swift
//  
//
//  Created by Tyler Anger on 2022-12-14.
//

import Foundation
#if swift(>=4.1)
    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif
#endif

internal extension WebRequest {
    /// Create a URLError
    /// - Parameters:
    ///   - url: The url the error is for
    ///   - error: The error code for the error
    ///   - description: The description of the error
    ///   - userInfo: Any additional user info for the error
    /// - Returns: Returns the newly created URL Error
    static func createURLError(for url: URL?,
                               error: URLError.Code,
                               description: String? = nil,
                               userInfo: [String: Any] = [:]) -> URLError {
        guard url != nil || description != nil || !userInfo.isEmpty else {
            return URLError(error)
        }
        var userInfo = userInfo
        if let url = url {
            userInfo[NSURLErrorFailingURLStringErrorKey] = "\(url)"
            userInfo[NSURLErrorFailingURLErrorKey] = url
        }
        if let d = description {
            userInfo[NSLocalizedDescriptionKey] = d
        }
        return URLError(error, userInfo: userInfo)
    }
    /// Create a new Cancelled URLError
    /// - Parameters:
    ///   - url: The url the error is for
    ///   - userInfo: Any additional user info for the error
    /// - Returns: Returns the newly created URL Error
    static func createURLCancel(for url: URL?,
                                userInfo: [String: Any] = [:]) -> URLError {
        return self.createURLError(for: url,
                                      error: .cancelled,
                                      description: "cancelled")
    }
    /// Create new Unknown Error URLError
    /// - Parameters:
    ///   - url: The url the error is for
    ///   - description: The description of the error
    ///   - userInfo: Any additional user info for the error
    /// - Returns: Returns the newly created URL Error
    static func createURLUnknown(for url: URL?,
                                 description: String? = nil,
                                 userInfo: [String: Any] = [:]) -> URLError {
        return self.createURLError(for: url,
                                   error: .unknown,
                                   description: description ?? "Unknown Error",
                                   userInfo: userInfo)
    }
    /// Create new Unknown Error URLError
    /// - Parameters:
    ///   - url: The url the error is for
    ///   - description: The description of the error
    ///   - error: The error attributed to the unknown error
    ///   - userInfo: Any additional user info for the error
    /// - Returns: Returns the newly created URL Error
    static func createURLUnknown<E: Error>(for url: URL?,
                                           description: String? = nil,
                                           error: E,
                                           userInfo: [String: Any] = [:]) -> URLError {
        var workingInfo = userInfo
        workingInfo["Error"] = error
        return self.createURLUnknown(for: url,
                                     description: description,
                                     userInfo: workingInfo)
    }
    
    /// Create a URLError from a different error type
    /// - Parameters:
    ///   - error: The error to convert into a URLError
    ///   - url: The URL this error is for if one exists
    /// - Returns: Returns the newly created URL Error
    static func errorToURLError(_ error: Error, for url: URL? = nil) -> URLError {
        #if _runtime(_ObjC) || swift(>=5.0)
        if let err = error as? URLError {
            return err
        } else {
            return URLError(_nsError: error as NSError)
        }
        #else
        if let err = error as? URLError {
            return err
        } else if let err = error as? NSError {
            return URLError(_nsError: err)
        } else {
            return createURLUnknown(for: url,
                                    error: error)
        }
        #endif
    }
}
