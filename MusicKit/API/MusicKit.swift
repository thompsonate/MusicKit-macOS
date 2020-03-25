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
                          onSuccess: @escaping () -> Void,
                          onError: @escaping (Error) -> Void)
    {
        mkWebController.musicKitDidLoad = {
            RemoteCommandController.setup()
            NowPlayingInfoManager.setup()
            QueueManager.setup()
            
            onSuccess()
        }
        
        mkWebController.loadWebView(withDeveloperToken: developerToken,
                                    appName: appName,
                                    appBuild: appBuild,
                                    onError: onError)
    }
    
    /// Returns a promise containing a music user token when a user has authenticated and authorized the app.
    public func authorize(onSuccess: ((String) -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.authorize()",
            type: String.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    /// Unauthorizes the app for the current user.
    public func unauthorize(onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.unauthorize()",
            onSuccess: onSuccess)
    }
    
    public func getIsAuthorized(onSuccess: @escaping (Bool) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.isAuthorized",
            type: Bool.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// Sets a music player's playback queue using a URL.
    public func setQueue(url: String, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ url: '\(url)' })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    /// Sets a music player's playback queue to a single Song.
    public func setQueue(song: Song, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ song: '\(song.id)' })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func setQueue(items: [MediaID], onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ songs: \(items.description) })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    
    public func addEventListener(event: MusicKitEvent, callback: @escaping () -> Void) {
        mkWebController.addEventListener(named: event.rawValue, callback: callback)
    }
}

