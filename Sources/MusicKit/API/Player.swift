//
//  Player.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/11/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Foundation

open class Player {
    public var queue: Queue
    private var mkWebController: MKWebController
    
    init(webController: MKWebController) {
        mkWebController = webController
        queue = Queue(webController: mkWebController)
    }
    
    // MARK: Properties
    /// The current playback duration.
    public func getCurrentPlaybackDuration(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.currentPlaybackDuration",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// The current playback progress.
    public func getCurrentPlaybackProgress(onSuccess: @escaping (Double) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.currentPlaybackProgress",
            type: Double.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// The current position of the playhead.
    public func getCurrentPlaybackTime(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.currentPlaybackTime",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    public func getCurrentPlaybackTimeRemaining(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.currentPlaybackTimeRemaining",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }

    
    /// A Boolean value indicating whether the player is currently playing.
    public func getIsPlaying(onSuccess: @escaping (Bool) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.isPlaying",
            type: Bool.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// The currently-playing media item, or the media item, within an queue, that you have designated to begin playback.
    public func getNowPlayingItem(onSuccess: @escaping (MediaItem?) -> Void) {
        mkWebController.evaluateJavaScript(
            "JSON.stringify(music.player.nowPlayingItem)",
            type: MediaItem?.self,
            decodingStrategy: .jsonString,
            onSuccess: onSuccess)
    }
    
    /// The index of the now playing item in the current playback queue. If there is no now playing item, the index is -1.
    public func getNowPlayingItemIndex(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.nowPlayingItemIndex",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    //    /// The current playback rate for the player.
    //    public func getPlaybackRate(onSuccess: @escaping (Int?) -> Void) {
    //
    //    }
    
    /// The current playback state of the music player.
    public func getPlaybackState(onSuccess: @escaping (PlaybackStates) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.playbackState",
            type: PlaybackStates.self,
            decodingStrategy: .enumType,
            onSuccess: onSuccess)
    }
    
//    /// A Boolean value that indicates whether a playback target is available.
//    public func getPlaybackTargetAvailable(onSuccess: @escaping (Bool?) -> Void) {
//
//    }
//
    /// The current repeat mode of the music player.
    public func getRepeatMode(onSuccess: @escaping (PlayerRepeatMode) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.repeatMode",
            type: PlayerRepeatMode.self,
            decodingStrategy: .enumType,
            onSuccess: onSuccess)
    }

    /// The current shuffle mode of the music player.
    public func getShuffleMode(onSuccess: @escaping (PlayerShuffleMode) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.shuffleMode",
            type: PlayerShuffleMode.self,
            decodingStrategy: .enumType,
            onSuccess: onSuccess)
    }

    /// A number indicating the current volume of the music player.
    public func getVolume(onSuccess: @escaping (Int) -> Void) {
        mkWebController.evaluateJavaScript(
            "music.player.volume",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    // MARK: Methods
    
    /// Begins playing the media item at the specified index in the queue immediately.
    public func changeToMediaAtIndex(_ index: Int, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.player.changeToMediaAtIndex(\(index))",
            onSuccess: onSuccess)
    }
    
//    /// Begins playing the media item in the queue immediately.
//    public func changeToMediaItem(id: MediaID, onSuccess: (() -> Void)? = nil) {
//
//    }
    
    /// Sets the volume to 0.
    public func mute() {
        mkWebController.evaluateJavaScript("music.player.mute()")
    }
    
    /// Pauses playback of the current item.
    public func pause() {
        mkWebController.evaluateJavaScript("music.player.pause()")
    }
    
    /// Initiates playback of the current item.
    public func play() {
        mkWebController.evaluateJavaScript("music.player.play()")
    }
    
    public func togglePlayPause() {
        getPlaybackState { playbackState in
            switch playbackState {
            case .playing:
                MusicKit.shared.player.pause()
            case .paused, .stopped, .ended:
                MusicKit.shared.player.play()
            default:
                break
            }
        }
    }
    
//    /// Prepares a music player for playback.
//    public func prepareToPlay(mediaItem: MediaItem, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void) {
//        mkWebController.evaluateJavaScriptWithPromise(
//            "music.player.prepareToPlay()",
//            onSuccess: onSuccess,
//            onError: onError)
//    }
    
    /// Sets the playback point to a specified time.
    public func seek(to time: Double, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.player.seekToTime(\(time))",
            onSuccess: onSuccess)
    }
    
//    /// Displays the playback target picker if a playback target is available.
//    public func showPlaybackTargetPicker() {
//        mkWebController.evaluateJavaScript("music.player.showPlaybackTargetPicker()")
//    }
    
    /// Starts playback of the next media item in the playback queue.
    /// Returns the current media item position.
    public func skipToNextItem(onSuccess: ((Int) -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.player.skipToNextItem()",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// Starts playback of the previous media item in the playback queue.
    /// Returns the current media position.
    public func skipToPreviousItem(onSuccess: ((Int) -> Void)? = nil) {
        mkWebController.evaluateJavaScriptWithPromise(
            "music.player.skipToPreviousItem()",
            type: Int.self,
            decodingStrategy: .typeCasting,
            onSuccess: onSuccess)
    }
    
    /// Stops the currently playing media item.
    public func stop() {
        mkWebController.evaluateJavaScript("music.player.stop()")
    }
    
    /// Sets the repeat mode of the player.
    /// - Parameters:
    ///   - mode: The repeat mode.
    ///   - onSuccess: Called when the action is completed successfully.
    public func setRepeatMode(_ mode: PlayerRepeatMode, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript(
            "music.player.repeatMode = \(mode.rawValue)",
            onSuccess: onSuccess)
    }
    
    /// Sets the shuffle mode of the player.
    /// - Parameters:
    ///   - mode: The shuffle mode: shuffle or off.
    ///   - onSuccess: Called when the action is completed successfully.
    public func setShuffleMode(_ mode: PlayerShuffleMode, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript(
            "music.player.shuffleMode = \(mode.rawValue)",
            onSuccess: onSuccess)
    }
    
    /// Sets the volume of the player
    /// - Parameters:
    ///   - volume: The volume level. Must be between 0 and 1.
    ///   - onSuccess: Called when the action is completed successfully.
    public func setVolume(_ volume: Double, onSuccess: (() -> Void)? = nil) {
        mkWebController.evaluateJavaScript(
            "music.player.volume = \(volume)",
            onSuccess: onSuccess)
    }
}
