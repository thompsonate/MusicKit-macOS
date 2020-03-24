//
//  Queue.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/11/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Foundation


/// The current playback queue of the music player.
open class Queue {
    private var mkWebController: MKWebController
    
    init(webController: MKWebController) {
        mkWebController = webController
    }
    
    // MARK: Properties
    
    /// A Boolean value indicating whether the queue has no items.
    public func getIsEmpty(onSuccess: @escaping (Bool) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.queue.isEmpty",
            type: Bool.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// An array of all the media items in the queue.
    public func getItems(onSuccess: @escaping ([MediaItem]) -> Void) {
        mkWebController.evaluateJavaScript(
            "JSON.stringify(music.player.queue.items)",
            type: [MediaItem].self,
            decodingStrategy: .jsonString,
            onSuccess: onSuccess)
    }
    
    /// The number of items in the queue.
    public func getLength(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.queue.length",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
//    /// The next playable media item in the queue.
//    public func getNextPlayableItem(onSuccess: @escaping (MediaItem?) -> Void) {
//
//    }
//
//    /// The previous playable media item in the queue.
//    public func getPreviousPlayableItem(onSuccess: @escaping (Bool?) -> Void) {
//
//    }
    
    /// The current queue position.
    public func getPosition(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.queue.position",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    // MARK: Methods
    
    /// Inserts the song defined by the given ID into the current queue immediately after the currently playing media item.
    public func prepend(song: MediaID, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            music.api.song('\(song)', null).then(function(song) {
                music.player.queue.prepend(song);
            })
            """,
            onSuccess: onSuccess)
    }
    
    /// Inserts the songs defined by the given IDs into the current queue immediately after the currently playing media item.
    public func prepend(songs: [MediaID], onSuccess: (() -> Void )? = nil) {
        mkWebController.evaluateJavaScript("""
            music.api.songs(\(songs.description), null).then(function(songs) {
                music.player.queue.prepend(songs);
            })
            """,
            onSuccess: onSuccess)
    }
    
    /// Inserts the song defined by the given ID after the last media item in the current queue.
    public func append(song: MediaID, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            music.api.song('\(song)', null).then(function(song) {
                music.player.queue.append(song);
            })
            """,
            onSuccess: onSuccess)
    }
    
    /// Inserts the songs defined by the given IDs after the last media item in the current queue.
    public func append(songs: [MediaID], onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            music.api.songs(\(songs.description), null).then(function(songs) {
                music.player.queue.append(songs);
            })
            """,
            onSuccess: onSuccess)
    }
    
    public func remove(index: Int, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript(
            "music.player.queue.remove(\(index))",
            onSuccess: onSuccess)
    }
    
    public func remove(indexes: IndexSet, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            \(Array(indexes).description).reverse().forEach(function(element) {
                music.player.queue.remove(element);
            })
            """,
            onSuccess: onSuccess)
    }
    
//    /// Returns the index in the playback queue for a media item descriptor.
//    public func indexForItem(descriptor: Descriptor) -> Int{
//        return 0
//    }
}
