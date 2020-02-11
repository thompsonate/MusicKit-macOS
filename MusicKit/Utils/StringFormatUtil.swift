//
//  StringFormatUtil.swift
//  MusicKit
//
//  Created by Nate Thompson on 2/4/19.
//  Copyright © 2019 Nate Thompson. All rights reserved.
//

import Foundation

extension String {
    /// Formats seconds into "h:m:s"
    public init(seconds: Int) {
        let minutes = seconds / 60
        let hours = minutes / 60
        
        if hours == 0 {
            self = String(format: "%d:%02d", minutes, seconds % 60)
        } else {
            self = String(format: "%d:%02d:%02d", hours, minutes % 60, seconds % 60)
        }
    }
    
    /// Formats milliseconds into "h:m:s"
    public init(milliseconds: Int) {
        let remainder = milliseconds % 1000
        var seconds = milliseconds / 1000

        // Round up if it's closer to the next highest second
        if remainder >= 500 {
            seconds += 1
        }
        
        let minutes = seconds / 60
        let hours = minutes / 60
        
        if hours == 0 {
            self = String(format: "%d:%02d", minutes, seconds % 60)
        } else {
            self = String(format: "%d:%02d:%02d", hours, minutes % 60, seconds % 60)
        }
    }
}
