//
//  DownloadDataStructures.swift
//  Music Player
//
//  Created by Samuel Chu on 3/24/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import Foundation

class DownloadingVideoInfo {
    let video: XCDYouTubeVideo
    let playlistName: String
    init(video: XCDYouTubeVideo, playlistName: String)  {
        self.video = video
        self.playlistName = playlistName
    }
}

class DownloadCellInfo {
    let image : UIImage
    let duration : String
    let name : String
    var progress : Double
    
    init(image : UIImage, duration : String, name : String) {
        self.image = image
        self.duration = duration
        self.name = name
        self.progress = 0.0
    }
    
    private func setProgress(progress : Double) {
        self.progress = progress
    }
    
    func downloadFinished() -> Bool {
        return progress >= 1.0
    }
}