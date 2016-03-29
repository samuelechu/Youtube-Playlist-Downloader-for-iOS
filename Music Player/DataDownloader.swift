//
//  DataDownloader.swift
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

//only one instance of DataDownloader declared in AppDelegate.swift
class DataDownloader: NSObject, NSURLSessionDelegate{
    
    var context : NSManagedObjectContext!
    var session : NSURLSession!
    
    //taskID index corresponds to videoData index, for assigning Song info after download is complete
    var taskIDs : [Int] = []
    var videoData : [VideoDownloadInfo] = []
    
    //delegate set in DownloadManager
    var tableDelegate : downloadTableViewControllerDelegate!
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        let randomString = MiscFuncs.randomStringWithLength(30)
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("\(randomString)")
        config.timeoutIntervalForRequest = 600
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        
        let appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
    }
    
    func addVideoToDownloadTable(vidInfo : VideoDownloadInfo) {
        let video = vidInfo.video
        let duration = MiscFuncs.stringFromTimeInterval(video.duration)
        
        //get thumbnail
        let thumbnailURL = (video.mediumThumbnailURL != nil ? video.mediumThumbnailURL : video.smallThumbnailURL)
        let data = NSData(contentsOfURL: thumbnailURL!)
        let image = UIImage(data: data!)
        
        let newCell = DownloadCellInfo(image: image!, duration: duration, name: video.title)
        let dict = ["cellInfo" : newCell]
        self.tableDelegate.addCell(dict)
        
    }
    
    func startNewTask(targetUrl : NSURL, vidInfo : VideoDownloadInfo) {
        addVideoToDownloadTable(vidInfo)
        let task = session.downloadTaskWithURL(targetUrl)
        taskIDs += [task.taskIdentifier]
        videoData += [vidInfo]
        task.resume()
    }
    
    //update progress when data is received
    func URLSession(session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64){
        
            //cell order in tableDelegate identical to order in taskIDs
            let cellNum = taskIDs.indexOf(downloadTask.taskIdentifier)
            
            if cellNum != nil{
                let taskProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                let num = taskProgress * 100
                
                if ( num % 10 ) < 0.8 && taskProgress != 1.0 {
                    dispatch_async(dispatch_get_main_queue(),{
                        let dict = ["ndx" : cellNum!, "value" : taskProgress ]
                        self.tableDelegate.setProgressValue(dict)
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
                
                let vidInfo = videoData[cellNum!]
                
                storeVideo(vidInfo, tempLocation: location.path!)
                SongManager.addNewSong(vidInfo)
              
                //display checkmark for completion
                let dict = ["ndx" : cellNum!, "value" : 1.0 ]
                
                tableDelegate.setProgressValue(dict)
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
    }
    
    //stores the temporary file (downloaded video) to app data
    func storeVideo(vidInfo : VideoDownloadInfo, tempLocation : String){
        
        let fileManager = NSFileManager.defaultManager()
        let identifier = vidInfo.video.identifier
        let filePath = MiscFuncs.grabFilePath("\(identifier).mp4")
        
        do{
            try NSFileManager.defaultManager().moveItemAtPath(tempLocation, toPath: filePath)
        }catch _ as NSError{}
        
        let settings = MiscFuncs.getSettings()
        let isAudio = settings.valueForKey("quality") as! Int == 2
        if(isAudio && !fileManager.fileExistsAtPath(MiscFuncs.grabFilePath("\(identifier).m4a"))){
            let asset = AVURLAsset(URL: NSURL(fileURLWithPath: filePath))
            asset.writeAudioTrackToURL(NSURL(fileURLWithPath: MiscFuncs.grabFilePath("\(identifier).m4a")
            )) {(success, error) -> () in
                if !success {
                    print(error)
                }
            }
            
            do {
                try fileManager.removeItemAtPath(filePath)
            } catch _ {
            }
        }
    }
    
}