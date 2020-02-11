//
//  API.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/11/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Foundation

/// Represents the Apple Music API
open class API {
    public var library: Library
    
    private var mkWebController: MKWebController
    
    init(webController: MKWebController) {
        mkWebController = webController
        library = Library(webController: webController)
    }
    
    
    public func addToLibrary(songs: [MediaID], completionHandler: (() -> Void)? = nil) {
        addToLibrary(songs: songs, albums: nil, playlists: nil, completionHandler: completionHandler)
    }
    
    public func addToLibrary(albums: [MediaID], completionHandler: (() -> Void)? = nil) {
        addToLibrary(songs: nil, albums: albums, playlists: nil, completionHandler: completionHandler)
    }
    
    public func addToLibrary(playlists: [MediaID], completionHandler: (() -> Void)? = nil) {
        addToLibrary(songs: nil, albums: nil, playlists: playlists, completionHandler: completionHandler)
    }
    
    public func addToLibrary(
        songs: [MediaID]?,
        albums: [MediaID]?,
        playlists: [MediaID]?,
        completionHandler: (() -> Void)? = nil)
    {
        var params = [String]()
        if let songs = songs {
            params.append("songs: \(songs.description)")
        }
        if let albums = albums {
            params.append("albums: \(albums.description)")
        }
        if let playlists = playlists {
            params.append("playlists: \(playlists.description)")
        }
        let paramsString = params.joined(separator: ", ")
        mkWebController.evaluateJavaScriptWithPromise(
            "MusicKit.getInstance().api.addToLibrary({ \(paramsString) })",
            completionHandler: completionHandler)
    }
}
