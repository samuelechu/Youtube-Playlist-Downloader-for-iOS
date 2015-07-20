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


extension NSURLSessionTask{
    func start() {
        self.resume()
    }
}

class dataDownloadObject: NSObject, NSURLSessionDelegate, NSURLSessionDataDelegate {
    
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    var videoData : [XCDYouTubeVideo] = []
    var session : NSURLSession!
    var taskIDs : [Int] = []
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("bgSession")
        
        self.appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        self.context = appDel!.managedObjectContext
        
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    
    
    func addVidInfo(vid : XCDYouTubeVideo){
        videoData += [vid]
        
    }
    
    func startNewTask(targetUrl : NSURL) {
        
        let task = session.downloadTaskWithURL(targetUrl)
        taskIDs += [task.taskIdentifier]
        task.start()
        
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
                
               if ( num % 10 ) < 0.6 {
                    dispatch_async(dispatch_get_main_queue(),{
                        
                        
                        
                        
                        var dict = ["ndx" : cellNum!, "value" : taskProgress ]
                        
                        NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil, userInfo: dict as [NSObject : AnyObject])
                        
                        NSNotificationCenter.defaultCenter().postNotificationName("reloadCellAtNdxID", object: nil, userInfo : dict as [NSObject : AnyObject])
                        
                    })
                }
                
            }
    }
    
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL){
            
            var ndx = find(self.taskIDs, downloadTask.taskIdentifier)
            if ndx != nil{
                var identifier = videoData[ndx!].identifier
                
                
                var fileData : NSData = NSData(contentsOfURL: location)!
                var filePath = grabFilePath("\(identifier).mp4")
                //fileData.writeToURL(fileURL, atomically: true)
                fileData.writeToFile(filePath, atomically: true)
                
                
                
                var newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: context) as! NSManagedObject
                
                
                
                newSong.setValue("\(identifier)", forKey: "identifier")
                //newSong.setValue(filePath, forKey: "location")
                newSong.setValue("\(videoData[ndx!].title)", forKey: "title")
                println(newSong)
                
                
                
                context.save(nil)
                
            }
            
            var dict = ["ndx" : ndx!, "value" : "1.0" ]
            
            NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil, userInfo: dict as [NSObject : AnyObject])
            
            NSNotificationCenter.defaultCenter().postNotificationName("reloadCellAtNdxID", object: nil, userInfo : dict as [NSObject : AnyObject])

            
            
            
    }
    
    func grabFilePath(fileName : String) -> String {
        
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let writePath = documents.stringByAppendingPathComponent("\(fileName)")
        
        return writePath
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
