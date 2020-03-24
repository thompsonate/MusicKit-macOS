//
//  Library.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/11/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Foundation

/// Represents the user's cloud library
open class Library {
    private var mkWebController: MKWebController
    
    init(webController: MKWebController) {
        mkWebController = webController
    }
    
    public func getSongs(
        ids: [MediaID],
        onSuccess: @escaping ([Song]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        let jsString = "music.api.library.songs(\(ids.count > 0 ? ids.description : "null"), null)"
        mkWebController.evaluateJavaScriptWithPromise(
            jsString,
            type: [Song].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    
    public func getSongs(
        limit: Int,
        offset: Int = 0,
        onSuccess: @escaping ([Song]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        let jsString = "music.api.library.songs(null, { limit: \(limit), offset: \(offset) })"
        mkWebController.evaluateJavaScriptWithPromise(
            jsString,
            type: [Song].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
}
