//
//  dataDownloadObject.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import Foundation

extension NSURLSessionTask{
    func start() {
        self.resume()
    }
}

class dataDownloadObject: NSObject, NSURLSessionDelegate, NSURLSessionDataDelegate {
    
    var videoData : [XCDYouTubeVideo] = []
    var curVid : XCDYouTubeVideo!
    var session : NSURLSession!
    var taskIDs : [Int] = []
    
    var mutableData: NSMutableData = NSMutableData()
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("bgSession")
        
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    
    
    func addVidInfo(vid : XCDYouTubeVideo){
        curVid = vid
        videoData += [vid]
        var streamURLs : NSDictionary = curVid.valueForKey("streamURLs") as! NSDictionary
        
    }
    
    func startNewTask(targetUrl : NSURL) {
        
        let task = session.downloadTaskWithURL(targetUrl)
        
        taskIDs += [task.taskIdentifier]
        //let task = session.dataTaskWithURL(targetUrl, completionHandler: nil)
        
        
        /*var duration = stringFromTimeInterval(curVid.duration)
        
        var cellNum = find(taskIDs, task.taskIdentifier)
        
        
        var dict = ["ndx" : cellNum!, "name" : curVid.title, "duration" : duration]
    
        NSNotificationCenter.defaultCenter().postNotificationName("setDownloadInfoID", object: nil, userInfo: dict as [NSObject : AnyObject])
        
         NSNotificationCenter.defaultCenter().postNotificationName("reloadCellAtNdxID", object: nil, userInfo : dict as [NSObject : AnyObject])*/
        
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
            
            
            
            dispatch_async(dispatch_get_main_queue(),{
                
                
                var cellNum = find(self.taskIDs, downloadTask.taskIdentifier)
                var dict = ["ndx" : cellNum!, "value" : taskProgress ]
                
                // NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil, userInfo: dict as [NSObject : AnyObject])
                
                NSNotificationCenter.defaultCenter().postNotificationName("reloadCellAtNdxID", object: nil, userInfo : dict as [NSObject : AnyObject])
                
            })
            
            
            
    }
    
    /*func URLSession(session: NSURLSession,downloadTask: NSURLSessionDownloadTask,
        didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64){
            
    }*/
    
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL){
            
            var cellNum = find(self.taskIDs, downloadTask.taskIdentifier)
            var dict = ["ndx" : cellNum!, "value" : 1.0 ]
            
            NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil, userInfo: dict as [NSObject : AnyObject])

            var fileData : NSData = NSData(contentsOfURL: location)!
            var fileURL : NSURL = grabFileURL("narsha.mp4")
            fileData.writeToURL(fileURL, atomically: true)
            UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, nil, nil, nil)
            
         
    }
    
    func grabFileURL(fileName : String) -> NSURL {
        var url : NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        
        url = url.URLByAppendingPathComponent(fileName)
        
        return url
        
    }
    

    

    
    
    
    
    
    
    
    
    
}
