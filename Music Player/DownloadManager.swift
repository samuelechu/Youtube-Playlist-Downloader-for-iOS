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
import SwiftyJSON


class DownloadManager {
    
    let downloadTable : downloadTableViewControllerDelegate
    let playlistName: String
    
    fileprivate var playlist : NSManagedObject!
    fileprivate var songs : NSMutableSet!
    
    fileprivate var context : NSManagedObjectContext!
    fileprivate var dataDownloader : DataDownloader!
    
    fileprivate var downloadTasks : [String] = []//array of video identifiers
    fileprivate var downloadedIDs : [String] = [] //array of downloaded video identifiers
    fileprivate var uncachedVideos : [String] = []//array of video identifiers for uncached videos
    
    fileprivate var numDownloads = 0
    fileprivate var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"
    
    
    init(downloadTable : downloadTableViewControllerDelegate, playlistName: String) {
        self.downloadTable = downloadTable
        self.playlistName = playlistName
        
        let appDel = UIApplication.shared.delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        //set initial quality to 360P if uninitialized
        _ = MiscFuncs.getSettings()
        
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
        let qual = settings.value(forKey: "quality") as! Int
        
        if let videoId = videoId {
            updateStoredSongs()
            
            let isStored =  isVideoStored(videoId, qual: qual)
            
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
    
    
    fileprivate func updateStoredSongs(){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
        request.predicate = NSPredicate(format: "isDownloaded = %@", true as CVarArg)
        
        let songs = try? context.fetch(request)
        downloadedIDs = []
        for song in songs!{
            let identifier = (song as AnyObject).value(forKey: "identifier") as! String
            downloadedIDs += [identifier]
        }
        
    }
    
    //check if video in stored memory or currently downloading videos
    fileprivate func isVideoStored (_ videoId : String, qual : Int) -> Bool {
        
        let isDownloaded = downloadedIDs.index(of: videoId) != nil || uncachedVideos.index(of: videoId) != nil
        
        if(isDownloaded){
            let song = SongManager.getSong(videoId)
            let quality = song.value(forKey: "quality") as! Int
            if(quality == qual){
                return true
            }
            else{
                SongManager.deleteSong(videoId, playlistName: playlistName)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadPlaylistID"), object: nil)
                downloadTasks = (downloadTable.getDLTasks())
            }
        }
            
        else if((downloadTasks.index(of: videoId)) != nil){
            return true
        }
        
        return false
    }
    
    func addStoredSong(_ videoId : String){
        SongManager.addToRelationships(videoId, playlistName: playlistName)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadPlaylistID"), object: nil)
    }
    
    fileprivate func startDownloadVideo(_ ID : String, qual : Int){
        if(downloadTasks.index(of: ID) == nil){
            XCDYouTubeClient.default().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
                if error == nil {
                    if let video = video {
                        let streamURLs : NSDictionary = video.value(forKey: "streamURLs") as! NSDictionary
                        var desiredURL : NSURL!
                        var vidQual : Int
                        
                        if (qual == 0  || qual == 2){ //360P or audio only
                            desiredURL = (streamURLs[18] != nil ? streamURLs[18] : (streamURLs[22] != nil ? streamURLs[22] : streamURLs[36])) as! NSURL
                            vidQual = (streamURLs[18] != nil ? 0 : (streamURLs[22] != nil ? 1 : 0))
                        }
                            
                        else { //720P
                            desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                            vidQual = (streamURLs[22] != nil ? 1 : (streamURLs[18] != nil ? 0 : 0))
                        }
                        
                        let vidInfo = VideoDownloadInfo(video: video, playlistName: self.playlistName)
                        self.dataDownloader.startNewTask(desiredURL as URL, vidInfo: vidInfo, vidQual: vidQual)
                    }
                }
            })
        }
    }
    
    fileprivate func performGetRequest(_ targetURL: URL!, completion: @escaping (_ data: Data?, _ HTTPStatusCode: Int, _ error: NSError?) -> Void) {
        
        
        
        
        
        
        let request = URLRequest(url: targetURL)
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfiguration)
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                completion(data, (response as! HTTPURLResponse).statusCode, error)
            })
            } as! (Data?, URLResponse?, Error?) -> Void)
        
        task.resume()
    }
    
    fileprivate var videoIDs : [String] = []
    fileprivate func downloadVideosForPlayist(_ playlistID : String, pageToken : String?, qual : Int) {
        
        if pageToken != nil{
            
            var urlString = ""
            if pageToken == "" {
                urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&playlistId=\(playlistID)&key=\(APIKey)"
            }
            else{
                urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&pageToken=\(pageToken!)&playlistId=\(playlistID)&key=\(APIKey)"
            }
            
            let targetURL = URL(string: urlString)
            
            let task = URLSession.shared.dataTask(with: targetURL!, completionHandler: {(data, HTTPStatusCode, error) -> Void in
                let statusCode = (HTTPStatusCode as! HTTPURLResponse).statusCode
                if statusCode == 200 && error == nil {
                    
                    
                    let json = try! JSONSerialization.jsonObject(with: data!, options: [])
                    print(json)
                    let playlistItems = try! JSON(data: data!)
                    
                    var nextPageToken : String?
                    nextPageToken = playlistItems ["nextPageToken"].stringValue
                    if nextPageToken == "" { nextPageToken = nil }
                    
                    //var totalResults = playlistItems ["pageInfo"]["totalResults"].intValue
                    
                    for item in playlistItems["items"].arrayValue {
                        
                        let vidID = item["contentDetails"]["videoId"].stringValue
                        self.videoIDs += [vidID]
                        
                        
                    }
                    
                    self.downloadVideosForPlayist(playlistID, pageToken: nextPageToken, qual: qual)
                }
                    
                else {
                    print("HTTP Status Code = \(String(describing: HTTPStatusCode))")
                    print("Error while loading channel videos: \(String(describing: error))")
                }
                
            })
            
            task.resume()
        }
            // Fetch the playlist Info from Google.
       /*     performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
                if HTTPStatusCode == 200 && error == nil {
                    
                    
                    let playlistItems = JSON(data!);
                    let nextPageToken = playlistItems ["nextPageToken"].stringValue
                    //var totalResults = playlistItems ["pageInfo"]["totalResults"].intValue
                    
                    for item in playlistItems["items"].arrayValue {
                        
                        let vidID = item["contentDetails"]["videoID"].stringValue
                        self.videoIDs += [vidID]
                        
                        
                    }
                    
                    self.downloadVideosForPlayist(playlistID, pageToken: nextPageToken, qual: qual)
                }
                    
                else {
                    print("HTTP Status Code = \(HTTPStatusCode)")
                    print("Error while loading channel videos: \(error)")
                }
                
            })
        }*/
            
        else{
            if(!videoIDs.isEmpty){
                
                updateStoredSongs()
                let settings = MiscFuncs.getSettings()
                let downloadVid = settings.value(forKey: "cache") as! Int
                
                //download videos if cache option selected, otherwise save song object to persistent memory
                if downloadVid != 1 {
                    for identifier : String in self.videoIDs {
                        
                        let isStored = self.isVideoStored(identifier, qual: qual)
                        
                        
                        
                        if (!isStored){
                            self.startDownloadVideo(identifier, qual: qual)
                            self.downloadTasks += [identifier]
                            self.downloadTable.addDLTask([identifier])
                        }
                            
                        else if (downloadTasks.index(of: identifier) == nil){
                            let settings = MiscFuncs.getSettings()
                            let qual = settings.value(forKey: "quality") as! Int
                            let filePath0 = MiscFuncs.grabFilePath("\(identifier).mp4")
                            let filePath1 = MiscFuncs.grabFilePath("\(identifier).m4a")
                            
                            //video option selected but no video file detected
                            let shouldDownloadVid = (qual == 0 || qual == 1) && !FileManager.default.fileExists(atPath: filePath0)
                            
                            //audio option selected but no audio file detected
                            let shouldDownloadAudio = qual == 2 && !FileManager.default.fileExists(atPath: filePath1)
                            
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
                            
                            if( FileManager.default.fileExists(atPath: filePath0) || FileManager.default.fileExists(atPath: filePath1)){
                                addStoredSong(identifier)
                            }
                            
                            
                        }
                    }
                }
                    
                else {
                    for identifier : String in self.videoIDs {
                        
                        let isStored = self.isVideoStored(identifier, qual: qual)
                        
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
    
    fileprivate func saveVideoInfo(_ identifier : String) {
        XCDYouTubeClient.default().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
            if error == nil {
                let newSong = NSEntityDescription.insertNewObject(forEntityName: "Song", into: self.context)
                newSong.setValue(identifier, forKey: "identifier")
                newSong.setValue(video!.title, forKey: "title")
                newSong.setValue(video!.expirationDate, forKey: "expireDate")
                newSong.setValue(false, forKey: "isDownloaded")
                
                /*var streamURLs = video!.streamURLs
                let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36]))! as NSURL
                newSong.setValue("\(desiredURL)", forKey: "streamURL")*/
                
                let large = video!.largeThumbnailURL
                let medium = video!.mediumThumbnailURL
                let small = video!.smallThumbnailURL
                let imgData = NSData(contentsOf: (large != nil ? large : (medium != nil ? medium : small))!)
                
                newSong.setValue(imgData, forKey: "thumbnail")
                
                
                
                do{
                    try self.context.save()
                }catch _ as NSError{}
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadPlaylistID"), object: nil)
            }
        })
    }
}
