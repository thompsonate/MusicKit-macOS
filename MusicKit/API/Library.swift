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
    
    public func getSongs(ids: [MediaID],
                         completionHandler: @escaping ([Song]?) -> Void) {
        let jsString = "MusicKit.getInstance().api.library.songs(\(ids.count > 0 ? ids.description : "null"), null)"
        mkWebController.evaluateJavaScriptWithPromise(jsString,
                                                      type: [Song].self,
                                                      completionHandler: completionHandler)
    }
    
    
    public func getSongs(limit: Int,
                         offset: Int = 0,
                         completionHandler: @escaping ([Song]?) -> Void) {
        let jsString = "MusicKit.getInstance().api.library.songs(null, { limit: \(limit), offset: \(offset) })"
        mkWebController.evaluateJavaScriptWithPromise(jsString,
                                                      type: [Song].self,
                                                      completionHandler: completionHandler)
    }
}
