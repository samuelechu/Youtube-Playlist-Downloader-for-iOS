//
//  dataDownloadObject.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
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
    var curVid : XCDYouTubeVideo!
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
        curVid = vid
        videoData += [vid]
        
    }
    
    func startNewTask(targetUrl : NSURL) {
        
        let task = session.downloadTaskWithURL(targetUrl)
        taskIDs += [task.taskIdentifier]
        task.start()
        
    }
    
    //get duration of video
    func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64){
            
            var taskProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            
            var num = taskProgress * 100
            
            if ( num % 10 ) < 0.6 {
                dispatch_async(dispatch_get_main_queue(),{
                    
                    
                    var cellNum = find(self.taskIDs, downloadTask.taskIdentifier)
                    var dict = ["ndx" : cellNum!, "value" : taskProgress ]
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil, userInfo: dict as [NSObject : AnyObject])
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("reloadCellAtNdxID", object: nil, userInfo : dict as [NSObject : AnyObject])
                    
                })
            }
            
            
    }
    
    /*func URLSession(session: NSURLSession,downloadTask: NSURLSessionDownloadTask,
    didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64){
    
    }*/
    
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL){
            
            var ndx = find(self.taskIDs, downloadTask.taskIdentifier)
            var identifier = videoData[ndx!].identifier
            
            
            var fileData : NSData = NSData(contentsOfURL: location)!
            var fileURL : NSURL = grabFileURL("\(identifier).mp4")
            fileData.writeToURL(fileURL, atomically: true)
            UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, nil, nil, nil)
            
            
            
            
            var newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: context) as! NSManagedObject
            
            
            
            newSong.setValue("\(identifier)", forKey: "identifier")
            newSong.setValue("\(fileURL)", forKey: "location")
            newSong.setValue("\(videoData[ndx!].title)", forKey: "title")
            println(newSong)
            
            
            
            context.save(nil)
            
            
            
            
            
    }
    
    func grabFileURL(fileName : String) -> NSURL {
        var url : NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        
        url = url.URLByAppendingPathComponent(fileName)
        
        return url
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
