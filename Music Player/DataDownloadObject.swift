//
//  dataDownloadObject.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//
//
import UIKit
import Foundation
import CoreData
import XCDYouTubeKit
import AssetsLibrary

protocol downloadObjectTableDelegate{
    func setProgressValue(dict : NSDictionary)
    func reloadCellAtNdx(cellNum : Int)
}

class DownloadingVideoInfo {
    let video: XCDYouTubeVideo
    let playlistName: String
    init(video: XCDYouTubeVideo, playlistName: String)  {
        self.video = video
        self.playlistName = playlistName
    }
}

class dataDownloadObject: NSObject, NSURLSessionDelegate{
    
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    
    var videoData : [DownloadingVideoInfo] = []
    
    var session : NSURLSession!
    var taskIDs : [Int] = []
    var tasks : [NSURLSessionDownloadTask] = []
    
    var playlist: NSManagedObject!
    
    var tableDelegate : downloadObjectTableDelegate!
    
    required init(coder aDecoder: NSCoder){
        super.init()
        let randomString = MiscFuncs.randomStringWithLength(30)
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("\(randomString)")
        config.timeoutIntervalForRequest = 600
        appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    func setDownloadObjectDelegate(del : downloadObjectTableDelegate){ tableDelegate = del }
    
    func addVidInfo(vid : DownloadingVideoInfo){
        videoData += [vid]
    }
    
    func startNewTask(targetUrl : NSURL) {
        
        let task = session.downloadTaskWithURL(targetUrl)
        taskIDs += [task.taskIdentifier]
        tasks += [task]
        task.resume()
        
    }
    
    //update progress when data is received
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64){
            
            let cellNum = taskIDs.indexOf(downloadTask.taskIdentifier)
            
            if cellNum != nil{
                let taskProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                let num = taskProgress * 100
                
                if ( num % 10 ) < 0.8 && taskProgress != 1.0 {
                    dispatch_async(dispatch_get_main_queue(),{
                        let dict = ["ndx" : cellNum!, "value" : taskProgress ]
                        
                        self.tableDelegate.setProgressValue(dict)
                        self.tableDelegate.reloadCellAtNdx(cellNum!)
                    })
                }
            }
    }
    
    ///save video when download completed
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL){
            let cellNum  = taskIDs.indexOf(downloadTask.taskIdentifier)
            if cellNum != nil{
                
                let video = videoData[cellNum!].video
                let playlistName = videoData[cellNum!].playlistName
                
                let identifier = video.identifier
                let filePath = MiscFuncs.grabFilePath("\(identifier).mp4")
                
                do{
                    try NSFileManager.defaultManager().moveItemAtPath(location.path!, toPath: filePath)
                }catch _ as NSError{}
                
                //save to CoreData
                let newSong = NSEntityDescription.insertNewObjectForEntityForName("Song", inManagedObjectContext: context)
                newSong.setValue(identifier, forKey: "identifier")
                newSong.setValue(video.title, forKey: "title")
                newSong.setValue(playlistName, forKey: "playlistName")
                
                var expireDate = video.expirationDate
                expireDate = expireDate!.dateByAddingTimeInterval(-60*60) //decrease expire time by 1 hour
                newSong.setValue(expireDate, forKey: "expireDate")
                newSong.setValue(true, forKey: "isDownloaded")
                
                let duration = video.duration
                let durationStr = MiscFuncs.stringFromTimeInterval(duration)
                newSong.setValue(duration, forKey: "duration")
                newSong.setValue(durationStr, forKey: "durationStr")
                
                var streamURLs = video.streamURLs
                let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36]))! as NSURL
                newSong.setValue("\(desiredURL)", forKey: "streamURL")
                
                let large = video.largeThumbnailURL
                let medium = video.mediumThumbnailURL
                let small = video.smallThumbnailURL
                let imgData = NSData(contentsOfURL: (large != nil ? large : (medium != nil ? medium : small))!)
                newSong.setValue(imgData, forKey: "thumbnail")
                
                
                let request = NSFetchRequest(entityName: "Playlist")
                request.predicate = NSPredicate(format: "playlistName = %@", playlistName)
                
                let playlists = try? context.executeFetchRequest(request) as NSArray
                playlist = playlists![0] as! NSManagedObject
                
                let songs = playlist.mutableSetValueForKey("songs")
                songs.addObject(newSong)

                
                
                do {
                    try context.save()
                } catch _ {
                }
                
                
                
                //display checkmark for completion
                let dict = ["ndx" : cellNum!, "value" : "1.0" ]
                
                tableDelegate.setProgressValue(dict)
                tableDelegate.reloadCellAtNdx(cellNum!)
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
    }
}