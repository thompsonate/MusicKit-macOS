//
//  MusicKit.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/10/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Foundation

open class MusicKit {
    
    static public var shared = MusicKit()
    private var mkWebController = MKWebController()
    
    public var player: Player
    public var api: API
    
    init() {
        player = Player(webController: mkWebController)
        api = API(webController: mkWebController)
    }
    
    /// Configures MusicKit. This must be called before MusicKit can be used.
    public func configure(withDeveloperToken developerToken: String,
                          appName: String,
                          appBuild: String,
                          completionHandler: @escaping () -> Void)
    {
        mkWebController.musicKitDidLoad = {
            RemoteCommandController.setup()
            NowPlayingInfoManager.setup()
            QueueManager.setup()
            
            completionHandler()
        }
        
//        mkWebController.loadWebView(withDeveloperToken: developerToken, appName: appName, appBuild: appBuild)
    }
    
    /// Returns a promise containing a music user token when a user has authenticated and authorized the app.
    public func authorize(completionHandler: ((String?) -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise("MusicKit.getInstance().authorize()",
                                                      type: String.self,
                                                      completionHandler: completionHandler)
    }
    
    /// Unauthorizes the app for the current user.
    public func unauthorize(completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise("MusicKit.getInstance().unauthorize()",
                                                      completionHandler: completionHandler)
    }
    
    public func getIsAuthorized(completionHandler: @escaping (Bool?) -> Void) {
        mkWebController.evaluateJavaScript("MusicKit.getInstance().isAuthorized",
                                           type: Bool.self,
                                           completionHandler: completionHandler)
    }
    
    /// Sets a music player's playback queue using a URL.
    public func setQueue(url: String, completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise("MusicKit.getInstance().setQueue({ url: '\(url)' })",
            completionHandler: completionHandler)
    }
    
    /// Sets a music player's playback queue to a single Song.
    public func setQueue(song: Song, completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise("MusicKit.getInstance().setQueue({ song: '\(song.id)' })") {
            completionHandler?()
        }
    }
    
    public func setQueue(items: [MediaID], completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise(
            "MusicKit.getInstance().setQueue({ songs: \(items.description) })",
            completionHandler: completionHandler)
    }
    
    
    public func addEventListener(event: MusicKitEvent, callback: @escaping () -> Void) {
        mkWebController.addEventListener(named: event.rawValue, callback: callback)
    }
}

