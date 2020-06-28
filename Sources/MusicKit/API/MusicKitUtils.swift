//
//  MusicKitUtils.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/10/20.
//  Copyright © 2020 Nate Thompson. All rights reserved.
//

import Cocoa

public enum MKEvent: String {
    case authorizationStatusDidChange
    case authorizationStatusWillChange
    case eligibleForSubscribeView
    case loaded
    case mediaCanPlay
    case mediaItemDidChange
    case mediaItemWillChange
    case mediaPlaybackError
    case metadataDidChange
    case musicKitDidLoad
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
public enum PlaybackBitrate: Int, Codable {
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

/// The repeat mode for the music player.
public enum PlayerRepeatMode: Int, Codable {
    /// No repeat mode specified.
    case none = 0
    /// The current media item will be repeated.
    case one = 1
    /// The current queue will be repeated.
    case all = 2

}

/// The shuffle mode for the music player.
public enum PlayerShuffleMode: Int, Codable {
    /// This value indicates that shuffle mode is off.
    case off = 0
    /// This value indicates that songs are being shuffled in the current queue.
    case shuffle = 1 // JS docs call this "songs" for some reason
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
    public let artwork: MediaItemArtwork?
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

/// An object that represents play parameters for resources.
///
/// [https://developer.apple.com/documentation/applemusicapi/playparameters](https://developer.apple.com/documentation/applemusicapi/playparameters)
public struct PlayParams: Codable {
    /// The ID of the content to use for playback.
    public let id: String
    public let catalogId: String?
    public let purchasedId: String?
    public let isLibrary: Bool?
    /// The kind of the content to use for playback.
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
        purchasedId = try? container.decode(String.self, forKey: .purchasedId)
    }
    
    public enum PlayParamsKeys: String, CodingKey {
        case id
        case catalogId
        case isLibrary
        case kind
        case reporting
        case purchasedId
    }
}

public enum ContentRating: String, Codable {
    case clean
    case explicit
}


/// A Song identifier
public typealias MediaID = String

/// A Resource object that represents a song.
///
/// [https://developer.apple.com/documentation/applemusicapi/song](https://developer.apple.com/documentation/applemusicapi/song)
public struct Song: Codable {
    /// The attributes for the song.
    public let attributes: Attributes
    /// A URL subpath that fetches the resource as the primary object. This member is only present in responses.
    public let href: String
    /// Persistent identifier of the resource.
    public let id: MediaID
    /// The type of resource. This value will always be songs. Value: `songs`
    public let type: String

    /// The attributes for a song object.
    ///
    /// [https://developer.apple.com/documentation/applemusicapi/song/attributes](https://developer.apple.com/documentation/applemusicapi/song/attributes)
    public struct Attributes: Codable {
        /// The localized name of the song.
        public let name: String
        /// The name of the album the song appears on.
        public let albumName: String?
        /// The artist’s name.
        public let artistName: String?
        /// The number of the song in the album’s track list.
        public let trackNumber: Int?
        /// The duration of the song in milliseconds.
        public let durationInMillis: Int
        /// The release date of the song in `YYYY-MM-DD` format.
        public let releaseDate: String?
        /// The parameters to use to playback the song.
        public let playParams: PlayParams?
        /// The album artwork.
        public let artwork: Artwork?
        /// The genre names the song is associated with.
        public let genreNames: [String]
        
        /// The song’s composer.
        // composerName
        /// The Recording Industry Association of America (RIAA) rating of the content. The possible values for this rating are clean and explicit. No value means no rating.
        // contentRating
        /// The disc number the song appears on.
        // discNumber
        /// The notes about the song that appear in the iTunes Store.
        // editorialNotes
        /// The International Standard Recording Code (ISRC) for the song.
        // isrc
        /// The URL for sharing a song in the iTunes Store.
        // url
        
        public var trackTime: String {
            return String(milliseconds: durationInMillis)
        }
    }
}


public struct Album: Codable {
    public let attributes: Attributes
    public let href: String
    public let id: MediaID
    public let type: String
    
    public struct Attributes: Codable {
        public let artistName: String
        public let artwork: Artwork
        public let dateAdded: String?
        public let name: String
        public let playParams: PlayParams?
        public let releaseDate: String
        public let trackCount: Int
    }
}


public struct Playlist: Codable {
    public let attributes: Attributes
    public let href: String
    public let id: MediaID
    public let type: String
    
    public struct Attributes: Codable {
        public let canEdit: Bool?
        public let dateAdded: String?
        public let hasCatalog: Bool?
        public let name: String
        public let playParams: PlayParams?
    }
}


public struct Station: Codable {
    public let href: String
    public let id: MediaID
    public let type: String
    public let attributes: Attributes
    
    public struct Attributes: Codable {
        public let artwork: Artwork
        public let isLive: Bool
        public let name: String
        public let playParams: PlayParams
        public let url: String
    }
}


public enum MediaCollection: Decodable {
    case album(album: Album)
    case playlist(playlist: Playlist)
    case station(station: Station)
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try values.decode(String.self, forKey: .type)
        
        guard let type = CollectionType(rawValue: typeString) else {
            throw MKError.decodingFailed(
                underlyingError: DecodingError.unexpectedType(expected: typeString))
        }
        
        switch type {
        case .albums:
            self = .album(album: try Album(from: decoder))
        case .playlists:
            self = .playlist(playlist: try Playlist(from: decoder))
        case .stations:
            self  = .station(station: try Station(from: decoder))
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public enum CollectionType: String {
        case albums
        case playlists
        case stations
    }
}

public struct Recommendation: Codable {
    public let attributes: Attributes
    public let href: String
    public let id: String
    public let relationships: Relationships
    public let type: String
    
    public struct Attributes: Codable {
        public let isGroupRecommendation: Bool
        public let kind: String
        public let nextUpdateDate: String
        public let resourceTypes: [String]
        public let title: Title
        
        public struct Title: Codable {
            public let stringForDisplay: String
        }
    }
    
    public struct Relationships: Codable {
        public let contents: Contents
        public let href: String?
        
        public struct Contents: Codable {
            public let data: [Playlist]
        }
    }
}

/// An object that represents artwork.
///
/// [https://developer.apple.com/documentation/applemusicapi/artwork](https://developer.apple.com/documentation/applemusicapi/artwork)
public struct Artwork: Codable {
    /// The maximum height available for the image.
    public let height: Int?
    /// The maximum width available for the image.
    public let width: Int?
    /// The URL to request the image asset. The image filename must be preceded by {w}x{h}, as placeholders for the width and height values as described above (for example, {w}x{h}bb.jpeg).
    public let url: String?
}



public enum MKError: Error, CustomStringConvertible {
    case javaScriptError(underlyingError: Error)
    case promiseRejected(context: [String: String])
    case decodingFailed(underlyingError: Error)
    case navigationFailed(withError: Error)
    case loadingFailed(message: String)
    case timeoutError(timeout: Int)
    
    public var description: String {
        switch self {
        case .javaScriptError(let error):
            return "Error evaluating JavaScript \(String(describing: error))"
        case .promiseRejected(let context):
            return "MusicKit rejected promise: \(context)"
        case .decodingFailed(let error):
            return "Error decoding JavaScript result: \(String(describing: error))"
        case .navigationFailed(let error):
            return "MusicKit webpage navigation failed \(String(describing: error))"
        case .loadingFailed(let message):
            return message
        case .timeoutError(let timeout):
            return "MusicKit was not loaded after a timeout of \(timeout) seconds"
        }
    }
    
    public var underlyingError: Error? {
        switch self {
        case .javaScriptError(let error):
            return error
        case .decodingFailed(let error):
            return error
        case .navigationFailed(let error):
            return error
        case .promiseRejected, .loadingFailed, .timeoutError:
            return nil
        }
    }
}
