//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadTableViewController: UITableViewController, downloadTableDelegate, downloadObjectDelegate {
    
    @IBOutlet var overlay: UIView!
    var progressValues : [Float] = []
    var downloadNames : [String] = []
    var vidDurations : [String] = []
    var images : [UIImage] = []
    var count = 0
    
    var dlObject : dataDownloadObject!
    var downloadTasks : [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resetDownloadTasks:", name: "resetDownloadTasksID", object: nil)
        
        view.addSubview(overlay)
        view.sendSubviewToBack(overlay)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlay.frame = view.bounds
    }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    func setDLObject(session : dataDownloadObject){ dlObject = session }
    func getDLObject() -> dataDownloadObject? { return dlObject }
    func setDLTasks(tasks : [String]){ downloadTasks = tasks }
    func getDLTasks() -> [String] { return downloadTasks }
    func resetDownloadTasks(notification: NSNotification){
        downloadTasks = []
        
    }
    
    
    func reloadCells(){ self.tableView.reloadData() }
    
    func reloadCellAtNdx(cellNum : Int){
        if cellNum < count{
            var indexPath = NSIndexPath(forRow: cellNum, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    //update taskProgress of specific cell
    func setProgressValue(dict : NSDictionary){
        var cellNum : Int = dict.valueForKey("ndx")!.integerValue
        
        if cellNum < count {
            var taskProgress : Float = dict.valueForKey("value")!.floatValue
            progressValues[cellNum] = taskProgress
        }
    }
    
    func addCell(dict : NSDictionary){
        var cellName : String = dict.valueForKey("name") as! String
        var vidDur : String = dict.valueForKey("duration") as! String
        var thumbnail = dict.valueForKey("thumbnail") as! UIImage
        
        count++
        progressValues += [0.0]
        downloadNames += [cellName]
        vidDurations += [vidDur]
        images += [thumbnail]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> downloadCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("downloadCell", forIndexPath: indexPath) as! downloadCell
        var row = indexPath.row
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        if progressValues[indexPath.row] == 1.0 { cell.accessoryType = UITableViewCellAccessoryType.Checkmark }
        
        cell.progressBar.progress = progressValues[indexPath.row]
        cell.imageLabel.image = images[indexPath.row]
        cell.durationLabel.text = vidDurations[indexPath.row]
        cell.downloadLabel.text = downloadNames[indexPath.row]
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDownloader" {
            let downloader : IDInputvc = segue.destinationViewController as! IDInputvc
            downloader.tableDelegate = self
        }
    }
}







