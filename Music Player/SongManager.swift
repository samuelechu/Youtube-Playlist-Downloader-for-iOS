//
//  SongManager.swift
//  Music Player
//
//  Created by Samuel Chu on 2/19/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import Foundation
import CoreData

public class SongManager{
    static var appDel = UIApplication.sharedApplication().delegate as! AppDelegate
    static var context = appDel.managedObjectContext!
    static var documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    
    
    
    //gets song associated with (identifier : String)
    public class func getSong(identifier : String) -> NSManagedObject {
        //relevant song : selectedSong
        let songRequest = NSFetchRequest(entityName: "Song")
        songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        let fetchedSongs : NSArray = try! context.executeFetchRequest(songRequest)
        return fetchedSongs[0] as! NSManagedObject
    }
    
    //gets playlist associated with (playlistName : String)
    public class func getPlaylist(playlistName : String) -> NSManagedObject {
        let playlistRequest = NSFetchRequest(entityName: "Playlist")
        playlistRequest.predicate = NSPredicate(format: "playlistName = %@", playlistName)
        let fetchedPlaylists : NSArray = try! context.executeFetchRequest(playlistRequest)
        return fetchedPlaylists[0] as! NSManagedObject
    }
    
    public class func addToRelationships(identifier : String, playlistName : String){
        
        let selectedPlaylist = getPlaylist(playlistName)
        let selectedSong = getSong(identifier)
        
        //add song reference to songs relationship (in playlist entity)
        let playlist = selectedPlaylist.mutableSetValueForKey("songs")
        playlist.addObject(selectedSong)
        
        //add playlist reference to playlists relationship (in song entity)
        let inPlaylists = selectedSong.mutableSetValueForKey("playlists")
        inPlaylists.addObject(selectedPlaylist)
        
        save()
    }
    
    
    public class func removeFromRelationships(identifier : String, playlistName : String){
        let selectedPlaylist = getPlaylist(playlistName)
        let selectedSong = getSong(identifier)
        
        //delete song reference in songs relationship (in playlist entity)
        let playlist = selectedPlaylist.mutableSetValueForKey("songs")
        playlist.removeObject(selectedSong)
        
        //remove from playlist reference in playlists relationship (in song entity)
        let inPlaylists = selectedSong.mutableSetValueForKey("playlists")
        inPlaylists.removeObject(selectedPlaylist)
        
        save()
    }
    
    //deletes song only if not in other playlists
    public class func deleteSong(identifier : String, playlistName : String){
        
        removeFromRelationships(identifier, playlistName: playlistName)
        
        let selectedSong = getSong(identifier)
        let inPlaylists = selectedSong.mutableSetValueForKey("playlists")
        
        if (inPlaylists.count < 1){
            
            //allows for redownload of deleted song
            let dict = ["identifier" : identifier]
            NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
            
            let fileManager = NSFileManager.defaultManager()
            
            let isDownloaded = selectedSong.valueForKey("isDownloaded") as! Bool
            
            //remove item in both documents directory and persistentData
            if isDownloaded {
                let filePath0 = MiscFuncs.grabFilePath("\(identifier).mp4")
                let filePath1 = MiscFuncs.grabFilePath("\(identifier).m4a")

                do {
                    try fileManager.removeItemAtPath(filePath0)
                } catch _ {
                }
                
                do {
                    try fileManager.removeItemAtPath(filePath1)
                } catch _ {
                }
            }
            context.deleteObject(selectedSong)
        }
        save()
    }
    
    private class func save() {
        do {
            try context.save()
        } catch _ {
        }
    }
}




