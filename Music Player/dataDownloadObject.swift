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
        self.appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        self.context = appDel!.managedObjectContext
        
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
            
            var cellNum = find(self.taskIDs, downloadTask.taskIdentifier)
            
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
            var cellNum  = find(self.taskIDs, downloadTask.taskIdentifier)
            if cellNum != nil{
                
                //move file from temporary folder to documents folder
                var fileData : NSData? = NSData(contentsOfURL: loc)
                var identifier = self.videoData[cellNum!].identifier
                var filePath = self.grabFilePath("\(identifier).mp4")
                NSFileManager.defaultManager().moveItemAtPath(location.path!, toPath: filePath, error: nil)
                
                //save to CoreData
                var newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: self.context) as! NSManagedObject
                newSong.setValue("\(identifier)", forKey: "identifier")
                newSong.setValue("\(self.videoData[cellNum!].title)", forKey: "title")
                self.context.save(nil)
                
                //display checkmark for completion
                var dict = ["ndx" : cellNum!, "value" : "1.0" ]
                
                self.tableDelegate.setProgressValue(dict)
                self.tableDelegate.reloadCellAtNdx(cellNum!)
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
    }
    
    func grabFilePath(fileName : String) -> String {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let writePath = documents.stringByAppendingPathComponent("\(fileName)")
        
        return writePath
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
