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
    public func getIsEmpty(completionHandler: @escaping (Bool?) -> Void) {
        mkWebController.evaluateJavaScript(
            "MusicKit.getInstance().player.queue.isEmpty",
            type: Bool.self,
            decodingStrategy: .typeCasting,
            completionHandler: completionHandler)
    }
    
    /// An array of all the media items in the queue.
    public func getItems(completionHandler: @escaping ([MediaItem]?) -> Void) {
        mkWebController.evaluateJavaScript(
            "JSON.stringify(MusicKit.getInstance().player.queue.items)",
            type: [MediaItem].self,
            decodingStrategy: .jsonString,
            completionHandler: completionHandler)
    }
    
    /// The number of items in the queue.
    public func getLength(completionHandler: @escaping (Int?) -> Void) {
        mkWebController.evaluateJavaScript(
            "MusicKit.getInstance().player.queue.length",
            type: Int.self,
            decodingStrategy: .typeCasting,
            completionHandler: completionHandler)
    }
    
//    /// The next playable media item in the queue.
//    public func getNextPlayableItem(completionHandler: @escaping (MediaItem?) -> Void) {
//
//    }
//
//    /// The previous playable media item in the queue.
//    public func getPreviousPlayableItem(completionHandler: @escaping (Bool?) -> Void) {
//        
//    }
    
    /// The current queue position.
    public func getPosition(completionHandler: @escaping (Int?) -> Void) {
        mkWebController.evaluateJavaScript(
            "MusicKit.getInstance().player.queue.position",
            type: Int.self,
            decodingStrategy: .typeCasting,
            completionHandler: completionHandler)
    }
    
    // MARK: Methods
    
    /// Inserts the song defined by the given ID into the current queue immediately after the currently playing media item.
    public func prepend(song: MediaID, completionHandler: (() -> Void )? = nil) {
        mkWebController.evaluateJavaScript("""
            MusicKit.getInstance().api.song('\(song)', null).then(function(song) {
            MusicKit.getInstance().player.queue.prepend(song);
            });
            """, completionHandler: completionHandler)
    }
    
    /// Inserts the songs defined by the given IDs into the current queue immediately after the currently playing media item.
    public func prepend(songs: [MediaID], completionHandler: (() -> Void )? = nil) {
        mkWebController.evaluateJavaScript("""
            MusicKit.getInstance().api.songs(\(songs.description), null).then(function(songs) {
            MusicKit.getInstance().player.queue.prepend(songs);
            });
            """, completionHandler: completionHandler)
    }
    
    /// Inserts the song defined by the given ID after the last media item in the current queue.
    public func append(song: MediaID, completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            MusicKit.getInstance().api.song('\(song)', null).then(function(song) {
            MusicKit.getInstance().player.queue.append(song);
            });
            """, completionHandler: completionHandler)
    }
    
    /// Inserts the songs defined by the given IDs after the last media item in the current queue.
    public func append(songs: [MediaID], completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            MusicKit.getInstance().api.songs(\(songs.description), null).then(function(songs) {
            MusicKit.getInstance().player.queue.append(songs);
            });
            """, completionHandler: completionHandler)
    }
    
    public func remove(index: Int, completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript(
            "MusicKit.getInstance().player.queue.remove(\(index))",
            completionHandler: completionHandler)
    }
    
    public func remove(indexes: IndexSet, completionHandler: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript("""
            \(Array(indexes).description).reverse().forEach(function(element) {
            MusicKit.getInstance().player.queue.remove(element);
            });
            """, completionHandler: completionHandler)
    }
    
//    /// Returns the index in the playback queue for a media item descriptor.
//    public func indexForItem(descriptor: Descriptor) -> Int{
//        return 0
//    }
}