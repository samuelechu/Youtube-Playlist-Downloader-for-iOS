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

protocol downloadObjectTableDelegate{
    func setProgressValue(dict : NSDictionary)
    func reloadCellAtNdx(cellNum : Int)
}

class dataDownloadObject: NSObject, NSURLSessionDelegate{
    
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    
    var videoData : [XCDYouTubeVideo] = []
    
    var session : NSURLSession!
    var taskIDs : [Int] = []
    var tasks : [NSURLSessionDownloadTask] = []
    
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
    
    func addVidInfo(vid : XCDYouTubeVideo){
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
                
                let request = NSFetchRequest(entityName: "Settings")
                let results : NSArray = try! self.context.executeFetchRequest(request)
                
                let settings = results[0] as! NSManagedObject
                
                let downloadLocation = settings.valueForKey("cache") as! Int
                
                //if download to photos album selected, save to photos album and delete downloaded file
                if (downloadLocation == 1) {
                    UISaveVideoAtPathToSavedPhotosAlbum(location.path!, nil, nil, nil)
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(location.path!)
                    } catch _ {
                    }
                }
                    
                else{ //else move file from temporary folder to documents folder
                     
                    let identifier = videoData[cellNum!].identifier
                    let filePath = grabFilePath("\(identifier).mp4")
                    
                    do{
                        try NSFileManager.defaultManager().moveItemAtPath(location.path!, toPath: filePath)
                    }catch _ as NSError{}
                    
                    //save to CoreData
                    let newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: context)
                    newSong.setValue(identifier, forKey: "identifier")
                    newSong.setValue(videoData[cellNum!].title, forKey: "title")
                    
                    var expireDate = videoData[cellNum!].expirationDate
                    expireDate = expireDate!.dateByAddingTimeInterval(-60*60) //decrease expire time by 1 hour
                    newSong.setValue(expireDate, forKey: "expireDate")
                    newSong.setValue(true, forKey: "isDownloaded")
                    
                    let duration = videoData[cellNum!].duration
                    let durationStr = MiscFuncs.stringFromTimeInterval(duration)
                    newSong.setValue(duration, forKey: "duration")
                    newSong.setValue(durationStr, forKey: "durationStr")
                    
                    var streamURLs = videoData[cellNum!].streamURLs
                    let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36]))! as NSURL
                    newSong.setValue("\(desiredURL)", forKey: "streamURL")
                    
                    let large = videoData[cellNum!].largeThumbnailURL
                    let medium = videoData[cellNum!].mediumThumbnailURL
                    let small = videoData[cellNum!].smallThumbnailURL
                    let imgData = NSData(contentsOfURL: (large != nil ? large : (medium != nil ? medium : small))!)
                    newSong.setValue(imgData, forKey: "thumbnail")
                    
                    do {
                        try context.save()
                    } catch _ {
                    }
                    
                }
                
                //display checkmark for completion
                let dict = ["ndx" : cellNum!, "value" : "1.0" ]
                
                tableDelegate.setProgressValue(dict)
                tableDelegate.reloadCellAtNdx(cellNum!)
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
    }
    
    func grabFilePath(fileName : String) -> String {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let writePath = (documents as NSString).stringByAppendingPathComponent("\(fileName)")
        
        return writePath
    } 
}