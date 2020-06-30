//
//  QueueManager.swift
//  MusicKit
//
//  Created by Nate Thompson on 3/11/19.
//  Copyright © 2019 Nate Thompson. All rights reserved.
//

import Foundation

public enum QueueManager {
    public static var queue: [MediaItem] = []
    
    private static var currentQueuePosition = -1
    private static var previousQueuePosition = -1
    
    private static var currentlyUpdatingQueue = false
    private static var didUpdateQueue = false
    
    /// Specifies how queue should be reordered on next queue update.
    private static var queueMoveInstruction: (from: IndexSet, to: Int)? = nil
    
    private static var queueDidUpdateListeners: [(QueueDidUpdateEvent) -> Void] = []
    
    static func setup() {
        loadQueue(with: .setupQueue)
        
        MusicKit.shared.addEventListener(for: .queueItemsDidChange) {
            // Keep table view from reloading all data if queue was just uploaded
            // as the result of a user action
            if didUpdateQueue && !currentlyUpdatingQueue {
                self.loadQueue(with: .userModified)
                didUpdateQueue = false
            } else {
                self.loadQueue(with: .queueItemsDidChange)
            }
        }
        
        MusicKit.shared.addEventListener(for: .queuePositionDidChange) {
            self.loadQueue(with: .queuePositionDidChange)
        }
    }
    
    public static func addEventListener(_ listener: @escaping (QueueDidUpdateEvent) -> Void) {
        queueDidUpdateListeners.append(listener)
    }
    
    enum LoadQueueEvent: Equatable {
        case setupQueue
        case queueItemsDidChange
        case queuePositionDidChange
        case userModified
    }
    
    public enum QueueDidUpdateEvent: Equatable {
        case setupQueue
        case queueItemsDidChange
        case queuePositionDidChange(by: Int)
        case userModified
        case error
        
        init(_ event: LoadQueueEvent, positionChange: Int = 0) {
            if positionChange != 0 && event != .queuePositionDidChange && event != .queueItemsDidChange {
                // Queue position shouldn't have changed if the event isn't queuePositionDidChange
                assertionFailure("Queue Position change is nonzero and LoadQueueEvent is \(event)")
            }
            
            switch event {
            case .setupQueue:
                self = .setupQueue
            case .queueItemsDidChange:
                self = .queueItemsDidChange
            case .queuePositionDidChange:
                self = .queuePositionDidChange(by: positionChange)
            case .userModified:
                self = .userModified
            }
        }
    }
    
    private static func queueDidUpdate(with event: QueueDidUpdateEvent) {
        for listener in queueDidUpdateListeners {
            listener(event)
        }
    }
    
    private static func loadQueue(with event: LoadQueueEvent) {
        guard !currentlyUpdatingQueue else { return }
        
        MusicKit.shared.player.queue.getPosition { position in
            MusicKit.shared.player.queue.getItems { items in
                let queueSizeChange = items.count - self.queue.count
                
                self.queue = items
                self.previousQueuePosition = self.currentQueuePosition
                self.currentQueuePosition = position
                
                // Reorder queue if needed after append (i.e. inserted in middle of queue)
                if let move = self.queueMoveInstruction {
                    // Ensure that append was was successful.
                    // Append can fail if too many items are added at once.
                    if move.from.count == queueSizeChange {
                        self.queue.move(with: move.from, to: move.to)
                        self.updateQueue()
                    } else {
                        NSLog("Error reordering queue - move instruction: \(move)")
                        self.queueMoveInstruction = nil
                        queueDidUpdate(with: .error)
                        return
                    }
                    self.queueMoveInstruction = nil
                }
                
                let change = self.currentQueuePosition - self.previousQueuePosition
                queueDidUpdate(with: QueueDidUpdateEvent(event, positionChange: change))
            }
        }
    }
    
    /// Updates MusicKit JS queue with contents of local queue
    private static func updateQueue() {
        currentlyUpdatingQueue = true
        
        MusicKit.shared.player.queue.getLength { queueLength in
            MusicKit.shared.player.queue.getPosition { currentPosition in
                let afterNowPlaying = (currentPosition + 1)..<queueLength
                let ids = self.queue[afterNowPlaying].map{ $0.id }
                
                for i in afterNowPlaying.reversed() {
                    MusicKit.shared.player.queue.remove(index: i)
                }
                MusicKit.shared.player.queue.append(songs: ids, onSuccess: {
                    self.currentlyUpdatingQueue = false
                    self.didUpdateQueue = true
                })
            }
        }
    }
    
    /// Inserts media item into queue at specified index
    public static func insert(songs ids: [MediaID], at index: Int) {
        // queueItemsDidChange event listener doesn't get called if items are
        // appended to empty queue
        if queue.count == 0 {
            MusicKit.shared.setQueue(songs: ids, onSuccess: {
                self.loadQueue(with: .userModified)
            }, onError: { error in
                print(error)
                fatalError("Could not insert item into queue")
            })
        } else {
            MusicKit.shared.player.queue.append(songs: ids)
            
            // append() doesn't return a promise, but also doesn't update queue synchronously.
            // Set queueMoveInstruction to reorder queue when next queueItemsDidChange
            // event listener is triggered.
            let fromIndexes = IndexSet(queue.count...queue.count + ids.count - 1)
            queueMoveInstruction = (from: fromIndexes, to: index + currentQueuePosition + 1)
        }
    }
    
    public static func prepend(songs ids: [MediaID]) {
        if queue.count == 0 {
            MusicKit.shared.setQueue(songs: ids, onSuccess: {
                self.loadQueue(with: .userModified)
            }, onError: { error in
                print(error)
                fatalError("Could not prepend item to queue")
            })
        } else {
            MusicKit.shared.player.queue.prepend(songs: ids)
        }
    }
    
    public static func append(songs ids: [MediaID]) {
        if queue.count == 0 {
            MusicKit.shared.setQueue(songs: ids, onSuccess: {
                self.loadQueue(with: .userModified)
            }, onError: { error in
                print(error)
                fatalError("Could not append item to queue")
            })
        } else {
            MusicKit.shared.player.queue.append(songs: ids)
        }
    }
    
    public static func delete(index: Int) {
        let queueIndex = convertToQueueIndex(upNextIndex: index)
        MusicKit.shared.player.queue.remove(index: queueIndex)
    }
    
    public static func delete(indexes: IndexSet) {
        let queueIndexes = convertToQueueIndexes(upNextIndexes: indexes)
        MusicKit.shared.player.queue.remove(indexes: queueIndexes)
    }
    
    public static func changeToMediaItem(at index: Int, onSuccess: (() -> Void)? = nil) {
        let queueIndex = convertToQueueIndex(upNextIndex: index)
        MusicKit.shared.player.changeToMediaAtIndex(queueIndex,
                                                    onSuccess: onSuccess)
    }
    
    /// Calculates indexe of queue array from indexe of array slice starting after now playing item
    public static func convertToQueueIndex(upNextIndex index: Int) -> Int {
        return index + currentQueuePosition + 1
    }
    
    /// Calculates indexes of queue array from indexes of array slice starting after now playing item
    static func convertToQueueIndexes(upNextIndexes indexes: IndexSet) -> IndexSet {
        return IndexSet(indexes.map{ $0 + currentQueuePosition + 1 })
    }
    
    /// The number of songs after the now playing item
    public static var upNextCount: Int {
        return queue.count - currentQueuePosition - 1
    }
    
    /// Moves array element from one index to another.
    /// Arguments are based on indexes starting after now playing item.
    public static func move(from src: Int, to dest: Int) {
        let from = convertToQueueIndex(upNextIndex: src)
        let to = convertToQueueIndex(upNextIndex: dest)
        queue.move(from: from, to: to)
        updateQueue()
    }
    
    /// Moves array elements to a specified location in the array.
    /// Arguments are based on indexes starting after now playing item.
    public static func move(with src: IndexSet, to dest: Int) {
        let from = convertToQueueIndexes(upNextIndexes: src)
        let to = convertToQueueIndex(upNextIndex: dest)
        queue.move(with: from, to: to)
        updateQueue()
    }
}
