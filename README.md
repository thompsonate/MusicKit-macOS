# MusicKit-macOS
A Swift framework that brings Apple Music to the Mac.

This framework is essentially a Swift wrapper around Apple's [MusicKit JS](https://developer.apple.com/documentation/musickitjs) API, with a structure very similar to that of MusicKit JS.

Internally, the JS framework runs in a web view and is interfaced with by sending it JavaScript strings and interpreting the response. Because of this, MusicKit for Mac is highly asynchronous, though a lot of care has been put into making the API as easy to use as possible.

## Configuration
MusicKit needs to be authenticated with a developer token. You can follow [Apple's documentation](https://developer.apple.com/documentation/applemusicapi/getting_keys_and_creating_tokens) on creating and signing a token. Keep in mind that these tokens expire after a maximum of 6 months.

After your app launches, configure MusicKit with your developer token. When `onSuccess` is called, MusicKit is set up and the rest of the API can be used.
```swift
MusicKit.shared.configure(
    withDeveloperToken: "...",
    appName: "My App",
    appBuild:"1.0",
    onSuccess: {
        // MusicKit is ready to use!
    }, onError: { error in
        // Error configuring or loading
    })
```

## Usage
After configuration, users can sign in to Apple Music. The authorization UI is completely handled by MusicKit for Mac and can be invoked with this simple function call:
```swift
MusicKit.shared.authorize(onSuccess: { _ in
    // Signed in!
}, onError: { error in
    // Error signing in
})
```

Now we're ready to play some music. Use a playlist URL to set the playlist to the queue and play it:
```swift
let rushPlaylistURL = "https://itunes.apple.com/us/playlist/rush-deep-cuts/pl.20e85b7fb46347479317bd6b0fb5f0d0"
MusicKit.shared.setQueue(url: rushPlaylistURL, onSuccess: {
        MusicKit.shared.player.play()
}, onError: { error in
    // Error setting queue to URL
})
```

To control playback, use the player object:
```swift
MusicKit.shared.player.pause()

MusicKit.shared.player.skipToNextItem()

MusicKit.shared.player.seek(to: 30.0)

MusicKit.shared.player.getCurrentPlaybackProgress { progress in
    print(progress)
}
```

MusicKit also has a bunch of event listeners. Here's an example that prints the name the currently playing media item when it changes:
```swift
MusicKit.shared.addEventListener(event: .mediaItemDidChange) {
    MusicKit.shared.player.getNowPlayingItem { nowPlayingItem in
        if let item = nowPlayingItem {
            print(item.attributes.name)
        }
    }
}
```
