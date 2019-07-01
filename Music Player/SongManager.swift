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
    
    static var context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
    static var documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    //gets song associated with (identifier : String)
    open class func getSong(_ identifier : String) -> NSManagedObject {
        //relevant song : selectedSong
        let songRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        let fetchedSongs : NSArray = try! context.fetch(songRequest) as NSArray
        return fetchedSongs[0] as! NSManagedObject
    }
    
    //gets playlist associated with (playlistName : String)
    open class func getPlaylist(_ playlistName : String) -> NSManagedObject {
        let playlistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        playlistRequest.predicate = NSPredicate(format: "playlistName = %@", playlistName)
        let fetchedPlaylists : NSArray = try! context.fetch(playlistRequest) as NSArray
        return fetchedPlaylists[0] as! NSManagedObject
    }
    
    open class func isPlaylist(_ playlistName: String) -> Bool {
        let playlistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        playlistRequest.predicate = NSPredicate(format: "playlistName = %@", playlistName)
        let fetchedPlaylists : NSArray = try! context.fetch(playlistRequest) as NSArray
        if(fetchedPlaylists.count > 0) {
            return true
        }
        return false
    }
    
    open class func addToRelationships(_ identifier : String, playlistName : String){
        
        let selectedPlaylist = getPlaylist(playlistName)
        let selectedSong = getSong(identifier)
        
        //add song reference to songs relationship (in playlist entity)
        let playlist = selectedPlaylist.mutableSetValue(forKey: "songs")
        playlist.add(selectedSong)
        
        //add playlist reference to playlists relationship (in song entity)
        let inPlaylists = selectedSong.mutableSetValue(forKey: "playlists")
        inPlaylists.add(selectedPlaylist)
        
        save()
    }
    
    
    open class func removeFromRelationships(_ identifier : String, playlistName : String){
        let selectedPlaylist = getPlaylist(playlistName)
        let selectedSong = getSong(identifier)
        
        //delete song reference in songs relationship (in playlist entity)
        let playlist = selectedPlaylist.mutableSetValue(forKey: "songs")
        playlist.remove(selectedSong)
        
        //remove from playlist reference in playlists relationship (in song entity)
        let inPlaylists = selectedSong.mutableSetValue(forKey: "playlists")
        inPlaylists.remove(selectedPlaylist)
        
        save()
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
            let thumbnailUrl = video.thumbnailURL
            let imgData = try Data(contentsOf: thumbnailUrl!)
            newSong.setValue(imgData, forKey: "thumbnail")
        } catch _ {
        }
        
        
        newSong.setValue(qual, forKey: "quality")
        
        addToRelationships(video.identifier, playlistName: playlistName)
        save()
    }
    
    //deletes song only if not in other playlists
    open class func deleteSong(_ identifier : String, playlistName : String){
        
        removeFromRelationships(identifier, playlistName: playlistName)
        
        let selectedSong = getSong(identifier)
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
            context.delete(selectedSong)
        }
        save()
    }
    
    fileprivate class func save() {
        do {
            try context.save()
        } catch _ {
        }
    }
}




