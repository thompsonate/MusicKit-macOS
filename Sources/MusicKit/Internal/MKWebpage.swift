//
//  MKWebpage.swift
//  MusicKit
//
//  Created by Nate Thompson on 3/28/20.
//

import Foundation

enum MKWebpage {
    static func html(
        withDeveloperToken developerToken: String,
        appName: String,
        appBuild: String,
        appIconURL: URL?) -> String
    {
        var iconLinkHTML = ""
        if let appIconURL = appIconURL {
            iconLinkHTML = "<link rel=\"apple-music-app-icon\" href=\"\(appIconURL.absoluteString)\" />"
        }
        
        return """
        <!DOCTYPE html>
        <html lang="en"><head>
          <meta charset="utf-8">
          <title>MusicKit</title>
          \(iconLinkHTML)

          <script>
          var music
          
          document.addEventListener('musickitloaded', function() {
            // MusicKit global is now defined
            try {
                music = MusicKit.configure({
                developerToken: '\(developerToken)',
                app: {
                    name: '\(appName)',
                    build: '\(appBuild)'
                    }
                });
                
                musicKitLoaded();
            } catch(err) {
                throwLoadingError(err);
            }
          });
          
          function musicKitLoaded() {
            try {
              webkit.messageHandlers.musicKitLoaded.postMessage("");
            } catch(err) {
              log(err);
            }
          }
          
          function log(message) {
              try {
                webkit.messageHandlers.log.postMessage(message);
              } catch(err) {
                console.log(err);
              }
          }
            
          function throwLoadingError(err) {
              try {
                  webkit.messageHandlers.throwLoadingError.postMessage(err.toString());
              } catch(err) {
                  log(err);
              }
          }
          </script>
          
          <script type="text/javascript"
              src="https://js-cdn.music.apple.com/musickit/v1/musickit.js"
              onerror="throwLoadingError('Error loading MusicKit JS')"></script>



        </html>
        """
    }
    
}
