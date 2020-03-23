//
//  MKDecoder.swift
//  MusicKit
//
//  Created by Nate Thompson on 3/23/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Foundation

class MKDecoder {
    /// The strategy used to decode a JavaScript response.
    enum Strategy {
        /// Works with top-level objects of NSArray or NSDictionary.
        case jsonSerialization
        /// Decodes a JSON string. For use with JSON.stringify() in the JavaScript code.
        case jsonString
        /// Works on JS primitive types (e.g. string, boolean, number).
        case typeCasting
        /// For enums with associated RawValue types of Int or String.
        case enumType
    }
    
    
    enum DecodingError: Error {
        case invalidJSONObject
        case unexpectedType(expected: String)
        case typeCastingFailed(type: String)
        
        var localizedDescription: String {
            switch self {
            case .invalidJSONObject:
                return "Failed to decode invalid JSON object"
            case .unexpectedType(let expected):
                return "Unexpected Type, was expecting \(expected)"
            case .typeCastingFailed(let type):
                return "Failed to decode JSON by type casting to \(type)"
            }
        }
    }
    
    
    /// Decodes the response to the given type using the given strategy
    /// - Parameters:
    ///   - response: The result from JavaScript
    ///   - type: The type to try to decode the result to
    ///   - strategy: The strategy used to decode the response. Different types need to be decoded in different ways, and this function attempts to decode
    ///   the response using the strategy given. For more information, see MKDecoder.Strategy.
    func decodeJSResponse<T: Decodable>(_ response: Any, to type: T.Type, withStrategy strategy: Strategy) throws -> T {
        switch strategy {
        case .jsonSerialization:
            if JSONSerialization.isValidJSONObject(response) {
                // Top level object is NSArray or NSDictionary
                let responseData = try JSONSerialization.data(withJSONObject: response, options: [])
                return try JSONDecoder().decode(type.self, from: responseData)
            } else {
                throw DecodingError.invalidJSONObject
            }
            
        case .jsonString:
            // For use with JSON.stringify() in the JS code
            guard let jsonString = response as? String else {
                throw DecodingError.unexpectedType(expected: "String")
            }
            let responseData = jsonString.data(using: .utf8)!
            return try JSONDecoder().decode(type.self, from: responseData)
            
        case .typeCasting:
            // Works on raw JSON types (e.g. string, boolean, number)
            // JSONDecoder doesn't work with fragments https://bugs.swift.org/browse/SR-6163
            if let castResponse = response as? T {
                return castResponse
            } else {
                throw DecodingError.typeCastingFailed(type: String(describing: type))
            }
            
        case .enumType:
            // Synthesizes an integer or string into a case of the specified Swift enum
            if let _ = response as? Int {
                // RawValue type should be Int
                let fragmentArray = "[\(response)]".data(using: .utf8)!
                let decodedFragment = try JSONDecoder().decode([T].self, from: fragmentArray)
                return decodedFragment[0]
                
            } else if let _ = response as? String {
                // RawValue type should be String
                let fragmentArray = "[\"\(response)\"]".data(using: .utf8)!
                let decodedFragment = try JSONDecoder().decode([T].self, from: fragmentArray)
                return decodedFragment[0]
                
            } else {
                throw DecodingError.unexpectedType(expected: "Int or String")
            }
        }
    }
}
