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
        var randomString = randomStringWithLength(30)
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("\(randomString)")
        config.timeoutIntervalForRequest = 600
        appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
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
    
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64){
            
            var cellNum = find(taskIDs, downloadTask.taskIdentifier)
            
            if cellNum != nil{
                var taskProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                var num = taskProgress * 100
                
                if ( num % 10 ) < 0.8 && taskProgress != 1.0 {
                    dispatch_async(dispatch_get_main_queue(),{
                        var dict = ["ndx" : cellNum!, "value" : taskProgress ]
                        
                        self.tableDelegate.setProgressValue(dict)
                        self.tableDelegate.reloadCellAtNdx(cellNum!)
                    })
                }
            }
    }
    
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL){
            var loc = location
            var cellNum  = find(taskIDs, downloadTask.taskIdentifier)
            if cellNum != nil{
                
                var request = NSFetchRequest(entityName: "Settings")
                var results : NSArray = self.context.executeFetchRequest(request, error: nil)!
                
                var settings = results[0] as! NSManagedObject
                
                var downloadLocation = settings.valueForKey("cache") as! Int
                
                //move file from temporary folder to documents folder
                var fileData : NSData? = NSData(contentsOfURL: loc)
                var identifier = videoData[cellNum!].identifier
                var filePath = grabFilePath("\(identifier).mp4")
                NSFileManager.defaultManager().moveItemAtPath(location.path!, toPath: filePath, error: nil)
                
                if (downloadLocation == 1) {
                    UISaveVideoAtPathToSavedPhotosAlbum(filePath, nil, nil, nil)
                }
               
                //save to CoreData
                var newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: context) as! NSManagedObject
                newSong.setValue(identifier, forKey: "identifier")
                newSong.setValue(videoData[cellNum!].title, forKey: "title")
                
                var expireDate = videoData[cellNum!].expirationDate
                expireDate = expireDate.dateByAddingTimeInterval(-60*60) //decrease expire time by 1 hour
                newSong.setValue(expireDate, forKey: "expireDate")
                newSong.setValue(true, forKey: "isDownloaded")
                
                var duration = videoData[cellNum!].duration
                var durationStr = MiscFuncs.stringFromTimeInterval(duration)
                newSong.setValue(duration, forKey: "duration")
                newSong.setValue(durationStr, forKey: "durationStr")
                
                var streamURLs = videoData[cellNum!].streamURLs
                var desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                newSong.setValue("\(desiredURL)", forKey: "streamURL")
                
                var large = videoData[cellNum!].largeThumbnailURL
                var medium = videoData[cellNum!].mediumThumbnailURL
                var small = videoData[cellNum!].smallThumbnailURL
                var imgData = NSData(contentsOfURL: (large != nil ? large : (medium != nil ? medium : small)))
                newSong.setValue(imgData, forKey: "thumbnail")
                
                context.save(nil)
                
                
                //display checkmark for completion
                var dict = ["ndx" : cellNum!, "value" : "1.0" ]
                
                tableDelegate.setProgressValue(dict)
                tableDelegate.reloadCellAtNdx(cellNum!)
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
    }
    
    func grabFilePath(fileName : String) -> String {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let writePath = documents.stringByAppendingPathComponent("\(fileName)")
        
        return writePath
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
