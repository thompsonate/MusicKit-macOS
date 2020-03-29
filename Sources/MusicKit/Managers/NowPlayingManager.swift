//
//  NowPlayingManager.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/16/19.
//  Copyright © 2019 Nate Thompson. All rights reserved.
//

import Cocoa
import MediaPlayer

enum RemoteCommandController {
    private static let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    static func setup() {
        remoteCommandCenter.playCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            MusicKit.shared.player.play()
            return .success
        }
        
        remoteCommandCenter.pauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            MusicKit.shared.player.pause()
            return .success
        }
        
        remoteCommandCenter.togglePlayPauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            MusicKit.shared.player.getIsPlaying { isPlaying in
                if isPlaying {
                    MusicKit.shared.player.pause()
                } else {
                    MusicKit.shared.player.play()
                }
            }
            return .success
        }
        
        remoteCommandCenter.previousTrackCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            MusicKit.shared.player.skipToPreviousItem()
            return .success
        }
        
        remoteCommandCenter.nextTrackCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            MusicKit.shared.player.skipToNextItem()
            return .success
        }
        
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
            let event = event as! MPChangePlaybackPositionCommandEvent
            MusicKit.shared.player.seek(to: event.positionTime)
            return .success
        }
    }
}


enum NowPlayingInfoManager {
    private static let infoCenter = MPNowPlayingInfoCenter.default()
    
    static func setup() {
        MusicKit.shared.addEventListener(for: .playbackStateDidChange) {
            MusicKit.shared.player.getPlaybackState(onSuccess: { state in
                switch state {
                case .playing:
                    updateInfo()
                    // Dirty hack: steal focus back as current now playing app from WKWebView process.
                    // WebKit gives info to MPNowPlayingInfoCenter, but its implementation is incomplete.
                    updateState(.paused)
                    updateState(.playing)
                case .paused:
                    updateState(.paused)
                case .stopped, .ended:
                    updateState(.stopped)
                case .loading:
                    updateInfo()
                default:
                    break
                }
                
            })
        }
    }
    
    private static func updateState(_ state: MPNowPlayingPlaybackState) {
        infoCenter.playbackState = state
    }
    
    private static func updateInfo() {
        var nowPlayingInfo = [String: Any]()
        
        MusicKit.shared.player.getNowPlayingItem { nowPlayingItem in
            MusicKit.shared.player.getCurrentPlaybackTime { playbackTime in
                
                nowPlayingInfo[MPMediaItemPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlayingItem?.attributes.name
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = nowPlayingItem?.attributes.albumName
                nowPlayingInfo[MPMediaItemPropertyArtist] = nowPlayingItem?.attributes.artistName
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = nowPlayingItem?.attributes.durationInSecs
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: playbackTime)
                
                let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 80, height: 80), requestHandler: { size -> NSImage in
                    if let artwork = nowPlayingItem?.attributes.artwork?.imageSmall {
                        return artwork
                    } else {
                        return NSImage(named: NSImage.applicationIconName)!
                    }
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                
                infoCenter.nowPlayingInfo = nowPlayingInfo
            }
        }
    }
}
