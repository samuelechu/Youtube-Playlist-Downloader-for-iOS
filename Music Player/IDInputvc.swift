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
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
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
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    func DismissKeyboard(){
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    
    
    @IBAction func finishedEditing() {
        view.endEditing(true)
    }
    
    @IBAction func settingsPressed() {
        self.navigationController?.navigationBarHidden = false
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
        
        var isStored =  vidStored("ID")
        
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
