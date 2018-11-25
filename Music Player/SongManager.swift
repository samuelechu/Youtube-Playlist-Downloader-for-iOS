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
    static let context = Database.shared.managedObjectContext
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
    
    open class func addNewSong(_ vidInfo : VideoDownloadInfo, qual : Int) {
        
        let video = vidInfo.video
        let playlistName = vidInfo.playlistName
        
        //save to CoreData
        let newSong = NSEntityDescription.insertNewObject(forEntityName: "Song", into: context)
        
        newSong.setValue(video.identifier, forKey: "identifier")
        newSong.setValue(video.title, forKey: "title")
        
        var expireDate = video.expirationDate
        expireDate = expireDate!.addingTimeInterval(-60*60) //decrease expire time by 1 hour
        newSong.setValue(expireDate, forKey: "expireDate")
        newSong.setValue(true, forKey: "isDownloaded")
        
        let duration = video.duration
        let durationStr = MiscFuncs.stringFromTimeInterval(duration)
        newSong.setValue(duration, forKey: "duration")
        newSong.setValue(durationStr, forKey: "durationStr")
        
       /* var streamURLs = video.streamURLs
        let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36]))! as NSURL
        newSong.setValue("\(desiredURL)", forKey: "streamURL")*/
        
        do {
            let large = video.largeThumbnailURL
            let medium = video.mediumThumbnailURL
            let small = video.smallThumbnailURL
            let imgData = try Data(contentsOf: (large != nil ? large : (medium != nil ? medium : small))!)
            newSong.setValue(imgData, forKey: "thumbnail")
        } catch _ {
        }
        
        
        newSong.setValue(qual, forKey: "quality")
        
        addToRelationships(video.identifier, playlistName: playlistName)
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
                let filePath0 = MiscFuncs.grabFilePath("\(identifier).mp4")
                let filePath1 = MiscFuncs.grabFilePath("\(identifier).m4a")

                do {
                    try fileManager.removeItem(atPath: filePath0)
                } catch _ {
                }
                
                do {
                    try fileManager.removeItem(atPath: filePath1)
                } catch _ {
                }
            }
            database.delete(selectedSong)
        }
        database.save()
    }
    
}




