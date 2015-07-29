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
    var numDownloads = 0
    var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
        
        self.appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        self.context = appDel!.managedObjectContext
        
        //set initial quality to 360P if uninitialized
        var request = NSFetchRequest(entityName: "VidQualitySelection")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count == 0 {
            var vidQual = NSEntityDescription.insertNewObjectForEntityForName("VidQualitySelection", inManagedObjectContext: context) as! NSManagedObject
            
            vidQual.setValue(0, forKey: "quality")
            
        }
        
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
        self.downloadButton.hidden = dlButtonHidden
        self.initializingLabel.hidden = !dlButtonHidden
        if dlButtonHidden {
            self.indicator.startAnimating()
        }
        else{
            self.indicator.stopAnimating()
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
    
    //check if video in stored memory
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
        
        return false
    }
    
    
    func startDownloadTaskHelper(ID : String, qual : Int){
        if(find(downloadTasks, ID) == nil){
            XCDYouTubeClient.defaultClient().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
                if error == nil {
                    var streamURLs : NSDictionary = video.valueForKey("streamURLs") as! NSDictionary
                    var desiredURL : NSURL!
                    
                    if (qual == 0){ //360P
                        desiredURL = (streamURLs[18] != nil ? streamURLs[18] : (streamURLs[22] != nil ? streamURLs[22] : streamURLs[36])) as! NSURL
                    }
                        
                    else { //720P
                        desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                    }
                    
                    var duration = self.stringFromTimeInterval(video.duration)
                    
                    //get thumbnail
                    var thumbnailURL = (video.mediumThumbnailURL != nil ? video.mediumThumbnailURL : video.smallThumbnailURL)
                    let data = NSData(contentsOfURL: thumbnailURL!)
                    var image = UIImage(data: data!)
                    
                    var dict = ["name" : video.title, "duration" : duration, "thumbnail" : image!]
                    
                    self.tableDelegate!.addCell(dict)
                    self.tableDelegate!.reloadCells()
                    
                    self.dlObject.addVidInfo(video)
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
        var request = NSFetchRequest(entityName: "VidQualitySelection")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        var vidQual = results[0] as! NSManagedObject
        var qual = vidQual.valueForKey("quality") as! Int
        
        
        
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
        
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
                    let resultsDict = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary//Dictionary<NSObject, AnyObject>
                    
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
                    
                    for identifier : String in videoIDs {
                        
                        var isStored = self.vidStored(identifier)
                        
                        if (!isStored){
                            self.startDownloadTaskHelper(identifier, qual: qual)
                            self.downloadTasks += [identifier]
                            self.tableDelegate?.addDLTask([identifier])
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
            self.tableDelegate?.setDLButton(false)
        }
        
    }
    
    
    
}
