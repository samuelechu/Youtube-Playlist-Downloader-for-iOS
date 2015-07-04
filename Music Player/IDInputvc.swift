//
//  IDInputvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class IDInputvc: UIViewController {

    @IBOutlet var vidID: UITextField!
    var numDownloads = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
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
    
    

    @IBAction func startDownloadTask() {
        var ID = vidID.text
        
        
        
        
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(ID, completionHandler: {(video, error) -> Void in
            
            var streamURLs : NSDictionary = video.valueForKey("streamURLs") as! NSDictionary
            var desiredURL : NSURL = (streamURLs[18] != nil ? streamURLs[18] : streamURLs[22]) as! NSURL //140 audio only
            println(desiredURL)
            
            var dlObject = dataDownloadObject(coder: NSCoder())
            
            dlObject.cellNum = self.numDownloads
            self.numDownloads++
            
            dlObject.setvidInfo(video)
            dlObject.startNewTask(desiredURL)
            
            
            NSNotificationCenter.defaultCenter().postNotificationName("addNewCell", object: nil)
            
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
