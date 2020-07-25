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
    
    public func getSong(
        id: MediaID,
        onSuccess: @escaping (Song) -> Void,
        onError: @escaping (Error) -> Void)
    {
        URLRequestManager.shared.request(
            "https://api.music.apple.com/v1/me/library/songs/\(id.description)",
            requiresUserToken: false,
            type: [Song].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: { songs in
                if !songs.isEmpty {
                    onSuccess(songs[0])
                } else {
                    onError(MKError.emptyResponse)
                }
        },
            onError: onError)
    }
    
    
    public func getSongs(
        ids: [MediaID],
        onSuccess: @escaping ([Song]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        var idsFormatted = ""
        for id in ids {
            idsFormatted.append(id)
            idsFormatted.append(",")
        }
        URLRequestManager.shared.request(
            "https://api.music.apple.com/v1/me/library/songs?ids=\(idsFormatted)",
            requiresUserToken: true,
            type: [Song].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    
    public func getSongs(
        limit: Int = 25,
        offset: Int = 0,
        onSuccess: @escaping ([Song], Metadata?) -> Void,
        onError: @escaping (Error) -> Void)
    {
        URLRequestManager.shared.request(
            "https://api.music.apple.com/v1/me/library/songs?limit=\(limit.description)&offset=\(offset.description)",
            requiresUserToken: true,
            type: [Song].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    
    public func getAlbums(
        ids: [MediaID],
        onSuccess: @escaping ([Album]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        let jsString = "music.api.library.albums(\(ids.count > 0 ? ids.description : "null"), null)"
        mkWebController.evaluateJavaScriptWithPromise(
            jsString,
            type: [Album].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func getAlbums(
        limit: Int,
        offset: Int = 0,
        onSuccess: @escaping ([Album]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        let jsString = "music.api.library.albums(null, { limit: \(limit), offset: \(offset) })"
        mkWebController.evaluateJavaScriptWithPromise(
            jsString,
            type: [Album].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func getPlaylists(
        ids: [MediaID],
        onSuccess: @escaping ([LibraryPlaylist]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        let jsString = "music.api.library.playlists(\(ids.count > 0 ? ids.description : "null"), null)"
        mkWebController.evaluateJavaScriptWithPromise(
            jsString,
            type: [LibraryPlaylist].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func getPlaylists(
        limit: Int,
        offset: Int = 0,
        onSuccess: @escaping ([LibraryPlaylist]) -> Void,
        onError: @escaping (Error) -> Void)
    {
        let jsString = "music.api.library.playlists(null, { limit: \(limit), offset: \(offset) })"
        mkWebController.evaluateJavaScriptWithPromise(
            jsString,
            type: [LibraryPlaylist].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func getSongs(
        inPlaylist id: MediaID,
        limit: Int = 10,
        offset: Int = 0,
        onSuccess: @escaping ([Song], Metadata?) -> Void,
        onError: @escaping (Error) -> Void)
    {
        URLRequestManager.shared.request(
            "https://api.music.apple.com/v1/me/library/playlists/\(id)/tracks?limit=\(limit)&offset=\(offset)",
            requiresUserToken: true,
            type: [Song].self,
            decodingStrategy: .jsonSerialization,
            onSuccess: onSuccess,
            onError: onError)
    }
}
