//
//  DownloadManager.swift
//  Music Player
//
//  Created by 岡本拓也 on 2015/12/31.
//  Copyright © 2015年 Sem. All rights reserved.
//

///Gets Youtube videos, starts downloads
import Foundation
import XCDYouTubeKit
import CoreData

class DownloadManager {
    
    let downloadTable : downloadTableViewControllerDelegate
    let playlistName: String
    
    private var playlist : NSManagedObject!
    private var songs : NSMutableSet!
    
    private var context : NSManagedObjectContext!
    private var dataDownloader : DataDownloader!
    
    private var downloadTasks : [String] = []//array of video identifiers
    private var downloadedIDs : [String] = [] //array of downloaded video identifiers
    private var uncachedVideos : [String] = []//array of video identifiers for uncached videos
    
    private var numDownloads = 0
    private var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"
    
    
    init(downloadTable : downloadTableViewControllerDelegate, playlistName: String) {
        self.downloadTable = downloadTable
        self.playlistName = playlistName
        
        let appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        //set initial quality to 360P if uninitialized
        MiscFuncs.getSettings()
        
        //get identifiers from downloadTableViewController
        uncachedVideos = (downloadTable.getUncachedVids())
        downloadTasks = (downloadTable.getDLTasks())
        dataDownloader = appDel?.dataDownloader
        
        //dataDownloader has not been initialized for app
        if dataDownloader == nil{
            appDel!.dataDownloader = DataDownloader(coder: NSCoder())
            appDel!.dataDownloader!.tableDelegate = downloadTable
            dataDownloader = appDel?.dataDownloader
        }
        
        updateStoredSongs()
    }
    
    func startDownloadVideoOrPlaylist(url playlistOrVideoUrl: String) {
        
        let (videoId, playlistId) = MiscFuncs.parseIDs(url: playlistOrVideoUrl)
        
        //get video quality setting
        let settings = MiscFuncs.getSettings()
        let qual = settings.valueForKey("quality") as! Int
        
        if let videoId = videoId {
            updateStoredSongs()
            
            let isStored =  isVideoStored(videoId)
            
            if (!isStored){
                startDownloadVideo(videoId, qual: qual)
                downloadTasks += [videoId]
                downloadTable.addDLTask([videoId])
            }
        }
        else if let playlistId = playlistId {
            downloadVideosForPlayist(playlistId, pageToken: "", qual: qual)
        }
    }
    
    
    private func updateStoredSongs(){
        let request = NSFetchRequest(entityName: "Song")
        request.predicate = NSPredicate(format: "isDownloaded = %@", true)
        
        let songs = try? context.executeFetchRequest(request)
        downloadedIDs = []
        for song in songs!{
            let identifier = song.valueForKey("identifier") as! String
            downloadedIDs += [identifier]
        }
        
    }
    
    //check if video in stored memory or currently downloading videos
    private func isVideoStored (videoId : String) -> Bool {
        
        let isDownloaded = downloadedIDs.indexOf(videoId) != nil || uncachedVideos.indexOf(videoId) != nil
        
        if(isDownloaded){
            return true
        }
            
        else if((downloadTasks.indexOf(videoId)) != nil){
            return true
        }
        
        return false
    }
    
    func addStoredSong(videoId : String){
        SongManager.addToRelationships(videoId, playlistName: playlistName)
        NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
    }
    
    private func startDownloadVideo(ID : String, qual : Int){
        if(downloadTasks.indexOf(ID) == nil){
            XCDYouTubeClient.defaultClient().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
                if error == nil {
                    if let video = video {
                        let streamURLs : NSDictionary = video.valueForKey("streamURLs") as! NSDictionary
                        var desiredURL : NSURL!
                        
                        if (qual == 0){ //360P
                            desiredURL = (streamURLs[18] != nil ? streamURLs[18] : (streamURLs[22] != nil ? streamURLs[22] : streamURLs[36])) as! NSURL
                        }
                            
                        else { //720P
                            desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                        }
                        
                        let vidInfo = VideoDownloadInfo(video: video, playlistName: self.playlistName)
                        self.dataDownloader.startNewTask(desiredURL, vidInfo: vidInfo)
                    }
                }
            })
        }
    }
    
    private func performGetRequest(targetURL: NSURL!, completion: (data: NSData?, HTTPStatusCode: Int, error: NSError?) -> Void) {
        let request = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod = "GET"
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfiguration)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data: data, HTTPStatusCode: (response as! NSHTTPURLResponse).statusCode, error: error)
            })
        })
        
        task.resume()
    }
    
    private var videoIDs : [String] = []
    private func downloadVideosForPlayist(playlistID : String, pageToken : String?, qual : Int) {
        
        if pageToken != nil{
            
            var urlString = ""
            if pageToken == "" {
                urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&playlistId=\(playlistID)&key=\(APIKey)"
            }
            else{
                urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&pageToken=\(pageToken!)&playlistId=\(playlistID)&key=\(APIKey)"
            }
            
            let targetURL = NSURL(string: urlString)
            // Fetch the playlist from Google.
            performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
                if HTTPStatusCode == 200 && error == nil {
                    
                    // Convert the JSON data into a dictionary.
                    let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! NSDictionary
                    // Get all playlist items ("items" array).
                    let nextPageToken = resultsDict["nextPageToken"] as! String?
                    let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                    //let pageInfo : Dictionary<NSObject, AnyObject> = resultsDict["pageInfo"] as! Dictionary<NSObject, AnyObject>
                    //var totalResults : Int = (pageInfo["totalResults"])!.integerValue!
                    
                    
                    for item : Dictionary<NSObject, AnyObject> in items {
                        let playlistContentDict = item["contentDetails"] as! Dictionary<NSObject, AnyObject>
                        let vidID : String = playlistContentDict["videoId"] as! String
                        self.videoIDs += [vidID]
                    }
                    
                    self.downloadVideosForPlayist(playlistID, pageToken: nextPageToken, qual: qual)
                }
                    
                else {
                    print("HTTP Status Code = \(HTTPStatusCode)")
                    print("Error while loading channel videos: \(error)")
                }
            })
        }
            
        else{
            if(!videoIDs.isEmpty){
                
                updateStoredSongs()
                let settings = MiscFuncs.getSettings()
                let downloadVid = settings.valueForKey("cache") as! Int
                
                //download videos if cache option selected, otherwise save song object to persistent memory
                if downloadVid != 1 {
                    for identifier : String in self.videoIDs {
                        
                        let isStored = self.isVideoStored(identifier)
                        
                        
                        
                        if (!isStored){
                            self.startDownloadVideo(identifier, qual: qual)
                            self.downloadTasks += [identifier]
                            self.downloadTable.addDLTask([identifier])
                        }
                            
                        else if (downloadTasks.indexOf(identifier) == nil){
                            let settings = MiscFuncs.getSettings()
                            let qual = settings.valueForKey("quality") as! Int
                            let filePath0 = MiscFuncs.grabFilePath("\(identifier).mp4")
                            let filePath1 = MiscFuncs.grabFilePath("\(identifier).m4a")
                            
                            //video option selected but no video file detected
                            let shouldDownloadVid = (qual == 0 || qual == 1) && !NSFileManager.defaultManager().fileExistsAtPath(filePath0)
                            
                            //audio option selected but no audio file detected
                            let shouldDownloadAudio = qual == 2 && !NSFileManager.defaultManager().fileExistsAtPath(filePath1)
                            
                            if(shouldDownloadVid || shouldDownloadAudio){
                                self.startDownloadVideo(identifier, qual: qual)
                                self.downloadTasks += [identifier]
                                self.downloadTable.addDLTask([identifier])
                            }
                            else{
                                addStoredSong(identifier)
                            }
                        }
                        
                        else {
                            
                            let filePath0 = MiscFuncs.grabFilePath("\(identifier).mp4")
                            let filePath1 = MiscFuncs.grabFilePath("\(identifier).m4a")
                            
                            if( NSFileManager.defaultManager().fileExistsAtPath(filePath0) || NSFileManager.defaultManager().fileExistsAtPath(filePath1)){
                                addStoredSong(identifier)
                            }
                            
                            
                        }
                    }
                }
                    
                else {
                    for identifier : String in self.videoIDs {
                        
                        let isStored = self.isVideoStored(identifier)
                        
                        if (!isStored){
                            
                            self.uncachedVideos += [identifier]
                            self.downloadTable.addUncachedVid([identifier])
                            self.saveVideoInfo(identifier)
                            
                        }
                        
                    }
                }
            }
            videoIDs = []
        }
        
    }
    
    private func saveVideoInfo(identifier : String) {
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
            if error == nil {
                let newSong = NSEntityDescription.insertNewObjectForEntityForName("Song", inManagedObjectContext: self.context)
                newSong.setValue(identifier, forKey: "identifier")
                newSong.setValue(video!.title, forKey: "title")
                newSong.setValue(video!.expirationDate, forKey: "expireDate")
                newSong.setValue(false, forKey: "isDownloaded")
                
                var streamURLs = video!.streamURLs
                let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36]))! as NSURL
                newSong.setValue("\(desiredURL)", forKey: "streamURL")
                
                let large = video!.largeThumbnailURL
                let medium = video!.mediumThumbnailURL
                let small = video!.smallThumbnailURL
                let imgData = NSData(contentsOfURL: (large != nil ? large : (medium != nil ? medium : small))!)
                
                newSong.setValue(imgData, forKey: "thumbnail")
                
                
                
                do{
                    try self.context.save()
                }catch _ as NSError{}
                
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
        })
    }
}