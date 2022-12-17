//
//  URL+WebRequestOpenCombieTests.swift
//  
//
//  Created by Tyler Anger on 2022-12-14.
//

import Foundation

internal extension URL {
    func appendingQueryItem(_ name: String, withValue value: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        if components.queryItems == nil { components.queryItems = [] }
        if let idx = components.queryItems?.firstIndex(where: { return $0.name == name }) {
            components.queryItems?.remove(at: idx)
            components.queryItems?.insert(URLQueryItem(name: name, value: value), at: idx)
        } else {
            components.queryItems?.append(URLQueryItem(name: name, value: value))
        }
        return components.url!
    }
    func appendingQueryItem(_ item: String) -> URL {
        guard !item.contains("=") else {
            let strComponents = item.split(separator: "=").map(String.init)
            return self.appendingQueryItem(strComponents[0], withValue: strComponents[1])
        }
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        if components.queryItems == nil { components.queryItems = [] }
        if let idx = components.queryItems?.firstIndex(where: { return $0.name == item }) {
            components.queryItems?.remove(at: idx)
            components.queryItems?.insert(URLQueryItem(name: item, value: nil), at: idx)
        } else {
            components.queryItems?.append(URLQueryItem(name: item, value: nil))
        }
        return components.url!
    }
}
