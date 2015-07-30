//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadTableViewController: UITableViewController, inputVCTableDelegate, downloadObjectTableDelegate {
    
    var progressValues : [Float] = []
    var downloadNames : [String] = []
    var vidDurations : [String] = []
    var images : [UIImage] = []
    var count = 0
    
    var dlObject : dataDownloadObject!
    var downloadTasks : [String] = []
    var dlButton = false
    
    
    override func viewWillAppear(animated: Bool) {
        reloadCells()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resetDownloadTasks:", name: "resetDownloadTasksID", object: nil)
        
        self.tableView.backgroundColor = UIColor.clearColor()
        var imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = self.tableView.frame
        self.tableView.backgroundView = imgView
        navigationController?.hidesBarsOnSwipe = true
    }
    
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    func setDLObject(session : dataDownloadObject){ dlObject = session }
    func getDLObject() -> dataDownloadObject? { return dlObject }
    func addDLTask(tasks : [String]){ downloadTasks += tasks }
    func getDLTasks() -> [String] { return downloadTasks }
    
    
    /*override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            //var row = x[indexPath.row]
            //x.removeAtIndex(indexPath.row)
            
            
            
            var row = indexPath.row
            
            
            dlObject.taskIDs.removeAtIndex(row)
            dlObject.tasks[row].cancel()
            dlObject.tasks.removeAtIndex(row)
            
            count--
            progressValues.removeAtIndex(row)
            downloadNames.removeAtIndex(row)
            vidDurations.removeAtIndex(row)
            images.removeAtIndex(row)

            
            self.tableView.reloadData()
        }
    }*/
    func resetDownloadTasks(notification: NSNotification){
        var dict : NSDictionary? = notification.userInfo
        if dict == nil {
            downloadTasks = []
        }
        
        else {
            var identifier = dict!.valueForKey("identifier") as! String
            var x = find(downloadTasks, identifier)
            if x != nil {
                downloadTasks.removeAtIndex(x!)
            }
            
        }
    }
    
    
    func setDLButton(value : Bool){
        dlButton = value
    }
    
    func dlButtonHidden() -> Bool{
        return dlButton
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
        cell.contentView.backgroundColor = UIColor.clearColor()
        cell.backgroundColor = UIColor.clearColor()

        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDownloader" {
            let downloader : IDInputvc = segue.destinationViewController as! IDInputvc
            downloader.tableDelegate = self
        }
    }
}







