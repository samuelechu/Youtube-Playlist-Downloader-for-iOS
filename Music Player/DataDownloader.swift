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
class DataDownloader: NSObject, URLSessionDelegate{
    
    let context = Database.shared.managedObjectContext
    var session : Foundation.URLSession!
    
    //taskID index corresponds to videoData index, for assigning Song info after download is complete
    var taskIDs : [Int] = []
    var videoData : [VideoDownloadInfo] = []
    var qualData : [Int] = []
    
    //delegate set in DownloadManager
    var tableDelegate : downloadTableViewControllerDelegate!
    
    required init(coder aDecoder: NSCoder){
        super.init()
        
        let randomString = MiscFuncs.randomStringWithLength(30)
        let config = URLSessionConfiguration.background(withIdentifier: "\(randomString)")
        config.timeoutIntervalForRequest = 600
        session = Foundation.URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func addVideoToDownloadTable(_ vidInfo : VideoDownloadInfo) {
        let video = vidInfo.video
        let duration = MiscFuncs.stringFromTimeInterval(video.duration)
        
        //get thumbnail
        let thumbnailURL = (video.mediumThumbnailURL != nil ? video.mediumThumbnailURL : video.smallThumbnailURL)
        
        do {
            let data = try Data(contentsOf: thumbnailURL!)
            let image = UIImage(data: data)!
            let newCell = DownloadCellInfo(image: image, duration: duration, name: video.title)
            let dict = ["cellInfo" : newCell]
            self.tableDelegate.addCell(dict as NSDictionary)
        } catch _ {
        }
        
    }
    
    func startNewTask(_ targetUrl : URL, vidInfo : VideoDownloadInfo, vidQual : Int) {
        addVideoToDownloadTable(vidInfo)
        let task = session.downloadTask(with: targetUrl)
        taskIDs += [task.taskIdentifier]
        videoData += [vidInfo]
        qualData += [vidQual]
        task.resume()
    }
    
    //update progress when data is received
    @objc func URLSession(_ session: Foundation.URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64){
        
            //cell order in tableDelegate identical to order in taskIDs
            let cellNum = taskIDs.index(of: downloadTask.taskIdentifier)
            
            if cellNum != nil{
                let taskProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                let num = taskProgress * 100
                
                if ( num.truncatingRemainder(dividingBy: 10) ) < 0.8 && taskProgress != 1.0 {
                    DispatchQueue.main.async(execute: {
                        let dict = ["ndx" : cellNum!, "value" : taskProgress ] as [String : Any]
                        self.tableDelegate.setProgressValue(dict as NSDictionary)
                    })
                }
            }
        
    }
    
    ///save video when download completed
    @objc func URLSession(_ session: Foundation.URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingToURL location: URL){
            let cellNum  = taskIDs.index(of: downloadTask.taskIdentifier)
            if cellNum != nil{
                
                let vidInfo = videoData[cellNum!]
                let qual = qualData[cellNum!]
                
                storeVideo(vidInfo, quality: qual, tempLocation: location.path)
              
                //display checkmark for completion
                DispatchQueue.main.async(execute: {
                    let dict = ["ndx" : cellNum!, "value" : Float(1) ] as [String : Any]
                    self.tableDelegate.setProgressValue(dict as NSDictionary)
                })
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadPlaylistID"), object: nil)
            }
    }
    
    //stores the temporary file (downloaded video) to app data
    func storeVideo(_ vidInfo : VideoDownloadInfo, quality : Int, tempLocation : String){
        
        var qual = quality
        
        let fileManager = FileManager.default
        let identifier = vidInfo.video.identifier
        let filePath = MiscFuncs.grabFilePath("\(identifier).mp4")
        
        try? fileManager.moveItem(atPath: tempLocation, toPath: filePath)
        MiscFuncs.addSkipBackupAttribute(toFilepath: filePath)
        
        //if audio only selected in settings, rip audio from video
        let settings = MiscFuncs.getSettings()
        let isAudio = settings.value(forKey: "quality") as! Int == 2
        let audioPath = MiscFuncs.grabFilePath("\(identifier).m4a")
        if(isAudio && !fileManager.fileExists(atPath: audioPath)){
            let asset = AVURLAsset(url: URL(fileURLWithPath: filePath))
            asset.writeAudioTrackToURL(URL(fileURLWithPath: audioPath) as NSURL) {(success, error) -> () in
                if !success {
                    print(error!)
                }
            }
            
            try? fileManager.removeItem(atPath: filePath)
            qual = 2
        }
        
        SongManager.addNewSong(vidInfo, qual: qual)
    }
    
}
