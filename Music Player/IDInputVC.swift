//
//  IDInputvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
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
    
    func setDLButton(value : Bool)
    func dlButtonHidden() -> Bool
}

class IDInputvc: UIViewController {
    
    @IBOutlet var vidID: UITextField!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var initializingLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    
    var tableDelegate : inputVCTableDelegate? = nil
    var dlObject : dataDownloadObject!
    
    var downloadTasks : [String] = []//array of video identifiers
    var uncachedVideos : [String] = []//array of video identifiers for uncached videos
    var numDownloads = 0
    var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
        
        appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        //set initial quality to 360P if uninitialized
        var request = NSFetchRequest(entityName: "Settings")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        if results.count == 0 {
            var settings = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: context) as! NSManagedObject
            
            settings.setValue(0, forKey: "quality")
            settings.setValue(0, forKey: "cache")
            
            context.save(nil)
            results = context.executeFetchRequest(request, error: nil)!
        }
        
        //get identifiers lost from popping off view
        uncachedVideos = (tableDelegate?.getUncachedVids())!
        downloadTasks = (tableDelegate?.getDLTasks())!
        dlObject = tableDelegate?.getDLObject()
        
        //If a background URLSession does not exist, create and save through table delegate for future reuse
        if dlObject == nil{
            dlObject = dataDownloadObject(coder: NSCoder())
            dlObject.setDownloadObjectDelegate((tableDelegate as? downloadObjectTableDelegate)!)
            tableDelegate?.setDLObject(dlObject!)
        }
        
        //hide download button if downloads are being queued
        manageButtons((tableDelegate?.dlButtonHidden())!)
        
    }
    
    //hide download button and show download intializing buttons
    func manageButtons(dlButtonHidden : Bool){
        downloadButton.hidden = dlButtonHidden
        initializingLabel.hidden = !dlButtonHidden
        if dlButtonHidden {
            indicator.startAnimating()
        }
        else{
            indicator.stopAnimating()
        }
    }
    
    func DismissKeyboard(){
        view.endEditing(true)
    }
    @IBAction func finishedEditing() {
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //check if video in stored memory or currently downloading videos
    func vidStored (identifier : String) -> Bool {
        var request = NSFetchRequest(entityName: "Songs")
        request.predicate = NSPredicate(format: "identifier = %@", identifier.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        if(results.count > 0){
            return true
        }
            
        else if((find(downloadTasks, identifier)) != nil){
            return true
        }
            
        else if((find(uncachedVideos, identifier)) != nil){
            return true
        }
        
        return false
    }
    
    
    func startDownloadTaskHelper(ID : String, qual : Int){
        if(find(downloadTasks, ID) == nil){
            XCDYouTubeClient.defaultClient().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
                if error == nil {
                    
                    var streamURLs : NSDictionary = video!.valueForKey("streamURLs") as! NSDictionary
                    var desiredURL : NSURL!
                    
                    if (qual == 0){ //360P
                        desiredURL = (streamURLs[18] != nil ? streamURLs[18] : (streamURLs[22] != nil ? streamURLs[22] : streamURLs[36])) as! NSURL
                    }
                        
                    else { //720P
                        desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                    }
                    
                    var duration = MiscFuncs.stringFromTimeInterval(video!.duration)
                    
                    //get thumbnail
                    var thumbnailURL = (video!.mediumThumbnailURL != nil ? video!.mediumThumbnailURL : video!.smallThumbnailURL)
                    let data = NSData(contentsOfURL: thumbnailURL!)
                    var image = UIImage(data: data!)
                    
                    var dict = ["name" : video!.title, "duration" : duration, "thumbnail" : image!]
                    
                    self.tableDelegate!.addCell(dict)
                    self.tableDelegate!.reloadCells()
                    
                    self.dlObject.addVidInfo(video!)
                    self.dlObject.startNewTask(desiredURL)
                }
            })
        }
    }
    
    @IBAction func startDownloadTask() {
        var ID  = vidID.text
        if let index = find(ID, "=") {
            ID = ID.substringFromIndex(advance(index, 1))
        }
        
        //get vid quality
        var request = NSFetchRequest(entityName: "Settings")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        var settings = results[0] as! NSManagedObject
        var qual = settings.valueForKey("quality") as! Int
        
        
        
        if count(ID) == 11{
            var isStored =  vidStored(ID)
            
            if (!isStored){
                
                startDownloadTaskHelper(ID, qual: qual)
                downloadTasks += [ID]
                tableDelegate?.addDLTask([ID])
            }
        }
            
            
        else {
            tableDelegate?.setDLButton(true)
            downloadVideosForPlayist(ID, pageToken: "", qual: qual)
        }
        
        
        navigationController?.popViewControllerAnimated(true)
    }
    
     
    
    func performGetRequest(targetURL: NSURL!, completion: (data: NSData?, HTTPStatusCode: Int, error: NSError?) -> Void) {
        let request = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod = "GET"
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfiguration)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data: data, HTTPStatusCode: (response as! NSHTTPURLResponse).statusCode, error: error)
            })
        })
        
        task.resume()
    }
    
    func downloadVideosForPlayist(playlistID : String, pageToken : String?, qual : Int) {
        
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
                    let resultsDict = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                    // Get all playlist items ("items" array).
                    var nextPageToken = resultsDict["nextPageToken"] as! String?
                    let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                    let pageInfo : Dictionary<NSObject, AnyObject> = resultsDict["pageInfo"] as! Dictionary<NSObject, AnyObject>
                    var totalResults : Int = (pageInfo["totalResults"])!.integerValue!
                    var videoIDs : [String] = []
                    
                    for item : Dictionary<NSObject, AnyObject> in items {
                        let playlistContentDict = item["contentDetails"] as! Dictionary<NSObject, AnyObject>
                        var vidID : String = playlistContentDict["videoId"] as! String
                        videoIDs += [vidID]
                    }
                    
                    
                    var request = NSFetchRequest(entityName: "Settings")
                    var results : NSArray = self.context.executeFetchRequest(request, error: nil)!
                    
                    var settings = results[0] as! NSManagedObject
                    
                    var downloadVid = settings.valueForKey("cache") as! Int
                    
                    //download videos if cache option selected, otherwise save song object to persistent memory
                    if downloadVid != 2 {
                        for identifier : String in videoIDs {
                            
                            var isStored = self.vidStored(identifier)
                            
                            if (!isStored){
                                self.startDownloadTaskHelper(identifier, qual: qual)
                                self.downloadTasks += [identifier]
                                self.tableDelegate?.addDLTask([identifier])
                            }
                        }
                    }
                        
                    else {
                        for identifier : String in videoIDs {
                            
                            var isStored = self.vidStored(identifier)
                            
                            if (!isStored){
                                
                                self.uncachedVideos += [identifier]
                                self.tableDelegate?.addUncachedVid([identifier])
                                self.saveVideoInfo(identifier)
                                
                            }
                        }
                        if nextPageToken == nil {
                            self.manageButtons(false)
                        }
                        
                    }
                    
                    self.downloadVideosForPlayist(playlistID, pageToken: nextPageToken, qual: qual)
                }
                    
                else {
                    println("HTTP Status Code = \(HTTPStatusCode)")
                    println("Error while loading channel videos: \(error)")
                    self.tableDelegate?.setDLButton(false)
                    
                }
            })
        }
            
        else{
            tableDelegate?.setDLButton(false)
        }
        
    }
    
    func saveVideoInfo(identifier : String) {
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
            if error == nil {
                var newSong = NSEntityDescription.insertNewObjectForEntityForName("Songs", inManagedObjectContext: self.context) as! NSManagedObject
                newSong.setValue(identifier, forKey: "identifier")
                newSong.setValue(video!.title, forKey: "title")
                newSong.setValue(video!.expirationDate, forKey: "expireDate")
                newSong.setValue(false, forKey: "isDownloaded")
                
                var streamURLs = video!.streamURLs
                var desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                newSong.setValue("\(desiredURL)", forKey: "streamURL")
                
                var large = video!.largeThumbnailURL
                var medium = video!.mediumThumbnailURL
                var small = video!.smallThumbnailURL
                var imgData = NSData(contentsOfURL: (large != nil ? large : (medium != nil ? medium : small))!)
                
                newSong.setValue(imgData, forKey: "thumbnail")
                
                self.context.save(nil)
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPlaylistID", object: nil)
            }
        })
    }
    
}
