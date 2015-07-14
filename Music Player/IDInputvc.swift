//
//  IDInputvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData

class IDInputvc: UIViewController {
    
    @IBOutlet var vidID: UITextField!
    var numDownloads = 0
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    var vidQual : NSManagedObject!
    var dlObject = dataDownloadObject(coder: NSCoder())
    
    
    var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"
    
    var desiredChannelsArray = ["Apple", "Google", "Microsoft"]
    
    var channelIndex = 0
    
    var channelsDataArray: Array<Dictionary<NSObject, AnyObject>> = []
    
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []
    
    var selectedVideoIndex: Int!
    
    var playlistID = "PL8mG-RkN2uTzFS_ljRvTdL9rF6aAWf_Dx"
    
    
    
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
            vidQual = NSEntityDescription.insertNewObjectForEntityForName("VidQualitySelection", inManagedObjectContext: context) as! NSManagedObject
            
            vidQual.setValue(0, forKey: "quality")
            
        }
        
        
        getVideosForChannelAtIndex()
        
        // Do any additional setup after loading the view.
    }
    
    func DismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    
    
    @IBAction func finishedEditing() {
        view.endEditing(true)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //check if video in stored memory
    func vidStored (identifier : String) -> Bool {
        var request = NSFetchRequest(entityName: "Songs")
        request.predicate = NSPredicate(format: "identifier = %@", identifier.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        if(results.count > 0){
            return true
        }
        
        return false
    }
    
    @IBAction func startDownloadTask() {
        var ID  = vidID.text
        if count(ID) != 11{
            return
        }
        
        var isStored =  vidStored(ID)
        
        if (!isStored){
            var request = NSFetchRequest(entityName: "VidQualitySelection")
            var results : NSArray = context.executeFetchRequest(request, error: nil)!
            vidQual = results[0] as! NSManagedObject
            var qual = vidQual.valueForKey("quality") as! Int
            
            
            
            
            XCDYouTubeClient.defaultClient().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
                
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
                var url = NSURL(string: "\(video.smallThumbnailURL)")
                let data = NSData(contentsOfURL: url!)
                var image = UIImage(data: data!)
                
                
                var dict = ["name" : video.title, "duration" : duration, "thumbnail" : video.smallThumbnailURL]
                
                NSNotificationCenter.defaultCenter().postNotificationName("addNewCellID", object: nil, userInfo: dict as [NSObject : AnyObject])
                
                NSNotificationCenter.defaultCenter().postNotificationName("reloadCellsID", object: nil, userInfo : dict as [NSObject : AnyObject])
                
                
                
                
                self.dlObject.addVidInfo(video)
                self.dlObject.startNewTask(desiredURL)
                
                
                
            })
        }
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
    
    
    
    func getChannelDetails(useChannelIDParam: Bool) {
        var urlString: String!
        if !useChannelIDParam {
           // urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&forUsername=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
            urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=PL8mG-RkN2uTzFS_ljRvTdL9rF6aAWf_Dx&key=\(APIKey)"
        }
        else {
            
        }
        
        let targetURL = NSURL(string: urlString)
    }
    
    
    func getVideosForChannelAtIndex() {
        // Get the selected channel's playlistID value from the channelsDataArray array and use it for fetching the proper video playlst.
        //let playlistID = channelsDataArray[index]["playlistID"] as! String
        
        // Form the request URL string.
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&key=\(APIKey)"
        
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: urlString)
        
        // Fetch the playlist from Google.
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                // Convert the JSON data into a dictionary.
                let resultsDict = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! Dictionary<NSObject, AnyObject>
                
                // Get all playlist items ("items" array).
                let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                
                // Use a loop to go through all video items.
                for var i=0; i<items.count; ++i {
                    let playlistSnippetDict = (items[i] as Dictionary<NSObject, AnyObject>)["snippet"] as! Dictionary<NSObject, AnyObject>
                    
                    // Initialize a new dictionary and store the data of interest.
                    var desiredPlaylistItemDataDict = Dictionary<NSObject, AnyObject>()
                    
                    desiredPlaylistItemDataDict["title"] = playlistSnippetDict["title"]
                    desiredPlaylistItemDataDict["thumbnail"] = ((playlistSnippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                    desiredPlaylistItemDataDict["videoID"] = (playlistSnippetDict["resourceId"] as! Dictionary<NSObject, AnyObject>)["videoId"]
                    
                    // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                    self.videosArray.append(desiredPlaylistItemDataDict)
                    println(self.videosArray)
                    // Reload the tableview.
                }
            }
            else {
                println("HTTP Status Code = \(HTTPStatusCode)")
                println("Error while loading channel videos: \(error)")
            }
            
        })
    }

    
    
    
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
