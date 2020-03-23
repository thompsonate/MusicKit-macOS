//
//  MusicKitUtils.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/10/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Cocoa

public enum MusicKitEvent: String {
    case authorizationStatusDidChange
    case authorizationStatusWillChange
    case eligibleForSubscribeView
    case loaded
    case mediaCanPlay
    case mediaItemDidChange
    case mediaItemWillChange
    case mediaPlaybackError
    case metadataDidChange
    case playbackBitrateDidChange
    case playbackDurationDidChange
    case playbackProgressDidChange
    case playbackStateDidChange
    case playbackStateWillChange
    case playbackTargetAvailableDidChange
    case playbackTimeDidChange
    case playbackVolumeDidChange
    case primaryPlayerDidChange
    case queueItemsDidChange
    case queuePositionDidChange
    case storefrontCountryCodeDidChange
    case storefrontIdentifierDidChange
    case userTokenDidChange
}


/// The playback bit rate of the music player
public enum PlaybackBitrate: Int {
    /// The bit rate is 256 kbps.
    case high = 256
    /// The bit rate is 64 kbps.
    case standard = 64
}

/// The playback states of the music player
public enum PlaybackStates: Int, Codable {
    /// The player has not attempted to start playback.
    case none = 0
    /// Loading of the media item has begun.
    case loading = 1
    /// The player is currently playing media.
    case playing = 2
    /// Playback has been paused.
    case paused = 3
    /// Plaback has been stopped.
    case stopped = 4
    /// Playback of the media item has ended.
    case ended = 5
    /// The player has started a seek operation.
    case seeking = 6
    /// Playback is delayed pending the completion of another operation.
    case waiting = 8
    /// The player is trying to fetch media data but cannot retrieve the data.
    case stalled = 9
    /// Playback of all media items in the queue has ended.
    case completed = 10
}

/// A single audio or video item
public struct MediaItem: Codable {
    public let assetURL: String?
    public let attributes: MediaItemAttributes
    public let flavor: String?
    public let id: String
    public let type: String
}

public struct MediaItemAttributes: Codable {
    public let albumName: String
    public let artistName: String
    public let artwork: MediaItemArtwork
    public let composerName: String?
    public let contentRating: ContentRating?
    public let discNumber: Int?
    public let durationInMillis: Int
    public let genreNames: [String]?
    public let isrc: String?
    public let name: String
    public let playParams: PlayParams
    public let releaseDate: String?
    public let trackNumber: Int
    public let url: String?
    
    public var durationInSecs: Int {
        return durationInMillis / 1000
    }
}

public struct MediaItemArtwork: Codable {
    public let url: String
    
    // An 80x80 image
    public var imageSmall: NSImage? {
        var urlString = url
        urlString = urlString.replacingOccurrences(of: "{w}", with: "80")
            .replacingOccurrences(of: "{h}", with: "80")
        guard let imageURL = URL(string: urlString) else { return nil }
        return NSImage(contentsOf: imageURL)
    }
}

public struct PlayParams: Codable {
    public let id: String
    public let catalogId: String?
    public let isLibrary: Bool?
    public let kind: String
    public let reporting: Bool?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PlayParamsKeys.self)
        // For some reason, id is sometimes a string and sometimes a number, try decoding both
        var idNumber: Int? = nil
        var idString: String? = nil
        do {
            idNumber = try container.decode(Int.self, forKey: .id)
        } catch {
            idString = try container.decode(String.self, forKey: .id)
        }
        id = idString ?? String(idNumber ?? -1)
        catalogId = try? container.decode(String.self, forKey: .catalogId)
        isLibrary = try? container.decode(Bool.self, forKey: .isLibrary)
        kind = try container.decode(String.self, forKey: .kind)
        reporting = try? container.decode(Bool.self, forKey: .reporting)
    }
    
    public enum PlayParamsKeys: String, CodingKey {
        case id
        case catalogId
        case isLibrary
        case kind
        case reporting
    }
}

public enum ContentRating: String, Codable {
    case clean
    case explicit
}


/// A Song identifier
public typealias MediaID = String

public struct Song: Codable {
    public let attributes: SongAttributes
    public let href: String
    public let id: MediaID
    public let type: String
}



public struct SongAttributes: Codable {
    public let albumName: String
    public let artistName: String
    public let artwork: Artwork?
    public let durationInMillis: Int
    public let name: String
    // nil if song is not playable (i.e. removed from Apple Music Catalog)
    public let playParams: PlayParams?
    public let trackNumber: Int
    
    public var trackTime: String {
        return String(milliseconds: durationInMillis)
    }
}


public struct Artwork: Codable {
    public let height: Int?
    public let width: Int?
    public let url: String
}
