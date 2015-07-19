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
    var qual : Int!
    
    var APIKey = "AIzaSyCUeYkR8QSs3ZRjVrTeZwPSv9QiHydFYuw"
    
    var videoIDs: Array<String> = []
    
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
        
        //   getVideosForChannelAtIndex()
        
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
    
    
    func startDownloadTaskHelper(ID : String, qual : Int){
        
        
        
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
            var url = NSURL(string: "\(video.smallThumbnailURL)")
            let data = NSData(contentsOfURL: url!)
            var image = UIImage(data: data!)
            
            
            var dict = ["name" : video.title, "duration" : duration, "thumbnail" : video.smallThumbnailURL]
            
            NSNotificationCenter.defaultCenter().postNotificationName("addNewCellID", object: nil, userInfo: dict as [NSObject : AnyObject])
            
            NSNotificationCenter.defaultCenter().postNotificationName("reloadCellsID", object: nil, userInfo : dict as [NSObject : AnyObject])
            
            
            
            
            self.dlObject.addVidInfo(video)
            self.dlObject.startNewTask(desiredURL)
            
            }
        })
        
        
    }
    
    
    @IBAction func startDownloadTask() {
        var ID  = vidID.text
        
        //get vid quality
        var request = NSFetchRequest(entityName: "VidQualitySelection")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        vidQual = results[0] as! NSManagedObject
        qual = vidQual.valueForKey("quality") as! Int
        
        
        
        if count(ID) == 11{
            var isStored =  vidStored(ID)
            
            if (!isStored){
                startDownloadTaskHelper(ID, qual: qual)
            }
        }
            
            
        else {
            downloadVideosForChannelAtIndex(ID)
            
            
            /*for identifier : String in self.videoIDs {
                
                var isStored = self.vidStored(identifier)
                
                if (!isStored){
                    
                    self.startDownloadTaskHelper(identifier, qual: qual)
                }
            }*/

            
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
    
    
    
    
    
    func downloadVideosForChannelAtIndex(playlistID : String) {
        
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&maxResults=50&playlistId=\(playlistID)&key=\(APIKey)"
        let targetURL = NSURL(string: urlString)
        
        // Fetch the playlist from Google.
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
           // if HTTPStatusCode == 200 && error == nil {
                
                // Convert the JSON data into a dictionary.
                let resultsDict = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! Dictionary<NSObject, AnyObject>
                
                // Get all playlist items ("items" array).
                let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                let pageInfo : Dictionary<NSObject, AnyObject> = resultsDict["pageInfo"] as! Dictionary<NSObject, AnyObject>
                var totalResults : Int = (pageInfo["totalResults"])!.integerValue!
                
                for item : Dictionary<NSObject, AnyObject> in items {
                    let playlistContentDict = item["contentDetails"] as! Dictionary<NSObject, AnyObject>
                    var vidID : String = playlistContentDict["videoId"] as! String
                    self.videoIDs += [vidID]
                }
                
            for identifier : String in self.videoIDs {
                
                var isStored = self.vidStored(identifier)
                
                if (!isStored){
                    
                    self.startDownloadTaskHelper(identifier, qual: self.qual)
                }
            }

            
               
          /* }
                
            else {
                println("HTTP Status Code = \(HTTPStatusCode)")
                println("Error while loading channel videos: \(error)")
            }
            */
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
