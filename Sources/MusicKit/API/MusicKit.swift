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
    /// - Parameters:
    ///   - developerToken: Your MusicKit developer token
    ///   - appName: The name of your app
    ///   - appBuild: Your app's build version
    ///   - appURL: A URL that represents your app. This is surfaced in the Access Request dialog
    ///   in the sign-in flow and in the name of the web process shown in Activity Monitor.
    ///   - appIconURL: A URL that points to your app icon, surfaced in the Access Request dialog
    ///   in the sign-in flow. The preferred size is 120x120.
    ///   - onSuccess: Called when MusicKit is ready to use.
    ///   - onError: Called if there is an error loading or configuring MusicKit.
    public func configure(withDeveloperToken developerToken: String,
                          appName: String,
                          appBuild: String,
                          appURL: URL,
                          appIconURL: URL?,
                          onSuccess: (() -> Void)? = nil,
                          onError: @escaping (Error) -> Void)
    {
        mkWebController.addEventListener(for: .musicKitDidLoad) {
            URLRequestManager.shared.configure(
                onSuccess: onSuccess,
                onError: onError)
        }
        
        mkWebController.loadWebView(withDeveloperToken: developerToken,
                                    appName: appName,
                                    appBuild: appBuild,
                                    baseURL: appURL,
                                    appIconURL: appIconURL,
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
    
    internal func getDeveloperToken(
        onSuccess: ((String) -> Void)?,
        onError: @escaping (Error) -> Void)
    {
        mkWebController.evaluateJavaScript(
            "music.developerToken",
            type: String.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    
    internal func getUserToken(
        onSuccess: ((String?) -> Void)?,
        onError: @escaping (Error) -> Void)
    {
        // Value for musicUserToken is undefined if no user is logged in.
        // We need JS to return null instead of undefined so we can decode it.
        mkWebController.evaluateJavaScript(
            "JSON.stringify(music.musicUserToken !== undefined ? music.musicUserToken : null)",
            type: String?.self,
            decodingStrategy: .jsonString,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    /// Sets a music player's playback queue using a URL.
    public func setQueue(url: String, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ url: '\(url)' })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    /// Sets a music player's playback queue to a single Song.
    public func setQueue(song id: MediaID, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ song: '\(id)' })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func setQueue(songs ids: [MediaID], onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ songs: \(ids.description) })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    /// Sets a music player's playback queue to a single Playlist.
    public func setQueue(playlist id: MediaID, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ playlist: '\(id)' })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    /// Sets a music player's playback queue to a single Album.
    public func setQueue(album id: MediaID, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.setQueue({ album: '\(id)' })",
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func addEventListener(for event: MKEvent, callback: @escaping () -> Void) {
        mkWebController.addEventListener(for: event, callback: callback)
    }
    
    /// Set to true to enable logging errors with additional information useful for debugging the API.
    public var enhancedErrorLogging = false
}

