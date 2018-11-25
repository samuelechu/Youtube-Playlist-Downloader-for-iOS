//
//  SongManager.swift
//  Music Player
//
//  Created by Samuel Chu on 2/19/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import Foundation
import CoreData

open class SongManager{
    
    static let database = Database.shared
    static var documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    open class func addToRelationships(_ identifier : String, playlistName : String){
        guard let selectedPlaylist = database.findPlaylist(named: playlistName),
            let selectedSong = database.findSong(with: identifier) else { return }
        
        //add song reference to songs relationship (in playlist entity)
        let playlist = selectedPlaylist.mutableSetValue(forKey: "songs")
        playlist.add(selectedSong)
        
        //add playlist reference to playlists relationship (in song entity)
        let inPlaylists = selectedSong.mutableSetValue(forKey: "playlists")
        inPlaylists.add(selectedPlaylist)
        
        database.save()
    }
    
    
    open class func removeFromRelationships(_ identifier : String, playlistName : String){
        guard let selectedPlaylist = database.findPlaylist(named: playlistName),
            let selectedSong = database.findSong(with: identifier) else { return }
        
        //delete song reference in songs relationship (in playlist entity)
        let playlist = selectedPlaylist.mutableSetValue(forKey: "songs")
        playlist.remove(selectedSong)
        
        //remove from playlist reference in playlists relationship (in song entity)
        let inPlaylists = selectedSong.mutableSetValue(forKey: "playlists")
        inPlaylists.remove(selectedPlaylist)
        
        database.save()
    }
    
    open class func addSongObject(from video: XCDYouTubeVideo) -> Song {
        let newSong = database.createSong(titled: video.title, identifier: video.identifier)
        newSong.duration = NSNumber(value: video.duration)
        newSong.durationStr = MiscFuncs.stringFromTimeInterval(video.duration)
        newSong.expireDate = video.expirationDate as NSDate?
        
        if let url = video.largeThumbnailURL ?? video.mediumThumbnailURL ?? video.smallThumbnailURL,
            let imgData = try? Data(contentsOf: url) {
            newSong.thumbnail = imgData
        }
        
        return newSong
    }
    
    open class func addNewSong(_ vidInfo : VideoDownloadInfo, qual : Int) {
        let newSong = addSongObject(from: vidInfo.video)
        newSong.quality = NSNumber(value: qual)
        newSong.isDownloaded = true
        newSong.expireDate = newSong.expireDate?.addingTimeInterval(-60*60) //decrease expire time by 1 hour)
        addToRelationships(vidInfo.video.identifier, playlistName: vidInfo.playlistName)
        database.save()
    }
    
    //deletes song only if not in other playlists
    open class func deleteSong(_ identifier : String, playlistName : String){
        
        removeFromRelationships(identifier, playlistName: playlistName)
        
        guard let selectedSong = database.findSong(with: identifier) else { return }
        let inPlaylists = selectedSong.mutableSetValue(forKey: "playlists")
        
        if (inPlaylists.count < 1){
            
            //allows for redownload of deleted song
            let dict = ["identifier" : identifier]
            NotificationCenter.default.post(name: Notification.Name(rawValue: "resetDownloadTasksID"), object: nil, userInfo: dict as [AnyHashable: Any])
            
            let fileManager = FileManager.default
            
            let isDownloaded = selectedSong.value(forKey: "isDownloaded") as! Bool
            
            //remove item in both documents directory and persistentData
            if isDownloaded {
                try? fileManager.removeItem(atPath: MiscFuncs.grabFilePath(identifier + ".mp4"))
                try? fileManager.removeItem(atPath: MiscFuncs.grabFilePath(identifier + ".m4a"))
            }
            database.delete(selectedSong)
        }
        database.save()
    }
    
}




