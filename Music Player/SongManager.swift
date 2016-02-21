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
    
    
    
    //deletes song only if not in other playlists
    public class func deleteSong(identifier : String){
        
        let songRequest = NSFetchRequest(entityName: "Song")
        songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        let fetchedSongs : NSArray = try! context.executeFetchRequest(songRequest)
        let selectedSong = fetchedSongs[0] as! NSManagedObject
        let inPlaylists = selectedSong.mutableSetValueForKey("playlists")
        
        
        if (inPlaylists.count == 1){
            
            
            //allows for redownload of deleted song
            let dict = ["identifier" : identifier]
            NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
            
            let fileManager = NSFileManager.defaultManager()
            
            //remove item in both documents directory and persistentData
            let isDownloaded = selectedSong.valueForKey("isDownloaded") as! Bool
            
            
            if isDownloaded {
                var file = selectedSong.valueForKey("identifier") as! String
                file = file.stringByAppendingString(".m4a")
                let filePath = (documentsDir as NSString).stringByAppendingPathComponent(file)
                do {
                    try fileManager.removeItemAtPath(filePath)
                } catch _ {
                }
            }
            context.deleteObject(selectedSong)
            
            
            do {
                try context.save()
            } catch _ {
            }
        }
        
        
        
    }

    
}




