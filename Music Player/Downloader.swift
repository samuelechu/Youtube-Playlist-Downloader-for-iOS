//
//  Downloader.swift
//  Music Player
//
//  Created by 岡本拓也 on 2015/12/31.
//  Copyright © 2015年 Sem. All rights reserved.
//

import Foundation
import XCDYouTubeKit
import CoreData



protocol inputVCTableDelegate{
    func addCell(dict : NSDictionary)
    func reloadCells()
    
    //necessary because IDInputvc view is reset when it is popped
    func setDLObject(session : dataDownloadObject)
    func getDLObject() -> dataDownloadObject?
    func addDLTask(tasks : [String])
    func getDLTasks() -> [String]
    
    func addUncachedVid(tasks : [String])
    func getUncachedVids() -> [String]
    
    func setDLButtonHidden(value : Bool)
    func dlButtonIsHidden() -> Bool
}




protocol DownloaderDelegate: class {
    func hideDownloadButton()
}




class Downloader {
    
    weak var delegate: DownloaderDelegate?
    let tableDelegate : inputVCTableDelegate
    
    private var context : NSManagedObjectContext!
    private var appDel : AppDelegate?
    private var dlObject : dataDownloadObject!

    private var downloadTasks : [String] = []//array of video identifiers
    private var downloadedIDs : [String] = [] //array of downloaded video identifiers
    private var uncachedVideos : [String] = []//array of video identifiers for uncached videos

    private var numDownloads = 0
    private var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"

    
    init(tableDelegate : inputVCTableDelegate) {
        self.tableDelegate = tableDelegate
        
        appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        //set initial quality to 360P if uninitialized
        let request = NSFetchRequest(entityName: "Settings")
        var results : NSArray = try! context.executeFetchRequest(request)
        
        if results.count == 0 {
            let settings = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: context)
            
            settings.setValue(0, forKey: "quality")
            settings.setValue(0, forKey: "cache")
            
            do {
                try context.save()
            } catch _ {
            }
            results = try! context.executeFetchRequest(request)
        }
        
        //get identifiers lost from popping off view
        uncachedVideos = (tableDelegate.getUncachedVids())
        downloadTasks = (tableDelegate.getDLTasks())
        dlObject = tableDelegate.getDLObject()
        
        //If a background URLSession does not exist, create and save through table delegate for future reuse
        if dlObject == nil{
            dlObject = dataDownloadObject(coder: NSCoder())
            dlObject.setDownloadObjectDelegate((tableDelegate as? downloadObjectTableDelegate)!)
            tableDelegate.setDLObject(dlObject!)
        }
    }
    
    
    
    func startDownloadVideoOrPlaylist(url playlistOrVideoUrl: String) {

        let (videoId, playlistId) = MiscFuncs.parseIDs(url: playlistOrVideoUrl)

        //get video quality setting
        let request = NSFetchRequest(entityName: "Settings")
        let results : NSArray = try! context.executeFetchRequest(request)
        let settings = results[0] as! NSManagedObject
        let qual = settings.valueForKey("quality") as! Int
        
        if let videoId = videoId {
            updateStoredSongs()
            
            let isStored =  isVideoStored(videoId)
            
            if (!isStored){
                startDownloadVideo(videoId, qual: qual)
                downloadTasks += [videoId]
                tableDelegate.addDLTask([videoId])
            }
        }
        else if let playlistId = playlistId {
            tableDelegate.setDLButtonHidden(true)
            downloadVideosForPlayist(playlistId, pageToken: "", qual: qual)
        }
    }
    
    
    private func updateStoredSongs(){
        let request = NSFetchRequest(entityName: "Songs")
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
        
        if(downloadedIDs.indexOf(videoId) != nil){
            return true
        }
            
        else if((downloadTasks.indexOf(videoId)) != nil){
            return true
        }
            
        else if((uncachedVideos.indexOf(videoId)) != nil){
            return true
        }
        
        return false
    }
    
    
    private func startDownloadVideo(ID : String, qual : Int){
        if(downloadTasks.indexOf(ID) == nil){
            XCDYouTubeClient.defaultClient().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
                if error == nil {
                    
                    let streamURLs : NSDictionary = video!.valueForKey("streamURLs") as! NSDictionary
                    var desiredURL : NSURL!
                    
                    if (qual == 0){ //360P
                        desiredURL = (streamURLs[18] != nil ? streamURLs[18] : (streamURLs[22] != nil ? streamURLs[22] : streamURLs[36])) as! NSURL
                    }
                        
                    else { //720P
                        desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                    }
                    
                    let duration = MiscFuncs.stringFromTimeInterval(video!.duration)
                    
                    //get thumbnail
                    let thumbnailURL = (video!.mediumThumbnailURL != nil ? video!.mediumThumbnailURL : video!.smallThumbnailURL)
                    let data = NSData(contentsOfURL: thumbnailURL!)
                    let image = UIImage(data: data!)
                    
                    let dict = ["name" : video!.title, "duration" : duration, "thumbnail" : image!]
                    
                    self.tableDelegate.addCell(dict)
                    self.tableDelegate.reloadCells()
                    
                    self.dlObject.addVidInfo(video!)
                    self.dlObject.startNewTask(desiredURL)
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
                    self.tableDelegate.setDLButtonHidden(false)
                    
                }
            })
        }
            
        else{
            tableDelegate.setDLButtonHidden(false)
            if(!videoIDs.isEmpty){
                
                updateStoredSongs()
                let request = NSFetchRequest(entityName: "Settings")
                let results : NSArray = try! self.context.executeFetchRequest(request)
                
                let settings = results[0] as! NSManagedObject
                let downloadVid = settings.valueForKey("cache") as! Int
                
                //download videos if cache option selected, otherwise save song object to persistent memory
                if downloadVid != 2 {
                    for identifier : String in self.videoIDs {
                        
                        let isStored = self.isVideoStored(identifier)
                        
                        if (!isStored){
                            self.startDownloadVideo(identifier, qual: qual)
                            self.downloadTasks += [identifier]
                            self.tableDelegate.addDLTask([identifier])
                        }
                    }
                }
                    
                else {
                    for identifier : String in self.videoIDs {
                        
                        let isStored = self.isVideoStored(identifier)
                        
                        if (!isStored){
                            
                            self.uncachedVideos += [identifier]
                            self.tableDelegate.addUncachedVid([identifier])
                            self.saveVideoInfo(identifier)
                            
                        }
                    }
                    
                    delegate?.hideDownloadButton()
                    
                }
            }
            videoIDs = []
        }
        
    }
    
    private func saveVideoInfo(identifier : String) {
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
            if error == nil {
                let newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: self.context)
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