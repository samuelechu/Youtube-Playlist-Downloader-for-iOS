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
    
    var video : XCDYouTubeVideo!
    var URL : NSURL!
    var session : NSURLSession!
    var cellNum : Int!
    
    
    var mutableData: NSMutableData = NSMutableData()
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 180.0
        
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    
    
    func setvidInfo(vid : XCDYouTubeVideo){
        
        video = vid
        var streamURLs : NSDictionary = video.valueForKey("streamURLs") as! NSDictionary
        URL = (streamURLs[18] != nil ? streamURLs[18] : streamURLs[22]) as! NSURL //140 audio only
        
    }
    
    func startNewTask(targetUrl : NSURL) {
        
        
        let task = session.dataTaskWithURL(targetUrl, completionHandler: nil)
        task.start()
        
        
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        data.enumerateByteRangesUsingBlock{[weak self](pointer : UnsafePointer<()>,
            range: NSRange,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            let newData = NSData(bytes: pointer, length: range.length)
            self!.mutableData.appendData(newData)
            
            var taskProgress = Float(dataTask.countOfBytesReceived) / Float(dataTask.countOfBytesExpectedToReceive)
            
            dispatch_async(dispatch_get_main_queue(),{
                
                var dict = ["ndx" : self!.cellNum, "value" : taskProgress ]
                
                // NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("setProgressValueID", object: nil, userInfo: dict as [NSObject : AnyObject])
                
                NSNotificationCenter.defaultCenter().postNotificationName("reloadCellsID", object: nil)
                
            })
            
        }
        
    }
    
    func grabFileURL(fileName : String) -> NSURL {
        var url : NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        
        url = url.URLByAppendingPathComponent(fileName)
        
        return url
        
    }
    
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        
        
        session.finishTasksAndInvalidate()
        
        if error == nil {
            
            var fileURL : NSURL = grabFileURL("narsha.mp4")
            mutableData.writeToURL(fileURL, atomically: true)
            UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, nil, nil, nil)
            
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
