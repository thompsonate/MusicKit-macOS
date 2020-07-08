//
//  URLRequestManager.swift
//  MusicKit
//
//  Created by Nate Thompson on 7/8/20.
//

import Foundation

class URLRequestManager {
    static var shared = URLRequestManager()
    
    private var developerToken: String!
    private var userToken: String?
    
    func configure(
        onSuccess: (() -> Void)?,
        onError: @escaping (Error) -> Void)
    {
        MusicKit.shared.getDeveloperToken(onSuccess: { token in
            self.developerToken = token
            
            MusicKit.shared.getUserToken(onSuccess: { token in
                self.userToken = token
                onSuccess?()
                
            }, onError: onError)
        }, onError: onError)
    }

    
    func request<T: Decodable>(
        _ endpoint: String,
        requiresUserToken: Bool,
        type: T.Type,
        decodingStrategy: MKDecoder.Strategy,
        onSuccess: @escaping (T) -> Void,
        onError: @escaping (Error) -> Void)
    {
        guard let endpointURL = URL(string: endpoint) else {
            onError(URLRequestError.invalidURL)
            return
        }
        
        var request = URLRequest(url: endpointURL)
        request.setValue("Bearer \(developerToken!)", forHTTPHeaderField: "Authorization")
        
        if requiresUserToken {
            guard let userToken = userToken else {
                onError(MKError.requestFailed(underlyingError: URLRequestError.requiresUserToken))
                return
            }
            request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                onError(MKError.requestFailed(underlyingError: error))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(Response<T>.self, from: data!)
                if let decodedData = decodedResponse.data {
                    onSuccess(decodedData)
                } else if let errors = decodedResponse.errors {
                    onError(MKError.requestFailed(underlyingError: errors))
                } else {
                    onError(MKError.decodingFailed(underlyingError:
                        DecodingError.unexpectedType(expected: "values for keys named \"data\" or \"errors\"")))
                }
            } catch {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 400 {
                    onError(MKError.requestFailed(underlyingError: URLRequestError.failed(withStatusCode: statusCode)))
                } else {
                    onError(MKError.decodingFailed(underlyingError: error))
                }
            }
        }
        task.resume()
    }
    
    
    struct Response<T: Decodable>: Decodable {
        let data: T?
        let meta: Meta?
        let errors: [[String: String]]?
        
        struct Meta: Decodable {
            let total: Int
        }
    }
    
    
    enum URLRequestError: Error, CustomStringConvertible {
        case failed(withStatusCode: Int)
        case requiresUserToken
        case invalidURL
        
        var description: String {
            switch self {
            case .failed(let statusCode):
                return "URL request failed with status code \(statusCode)"
            case .requiresUserToken:
                return "This endpoint requires that a user is signed in"
            case .invalidURL:
                return "The URL supplied for the endpoint is invalid"
            }
        }
    }
}