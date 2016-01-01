//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit



protocol DownloadListView{
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



class downloadTableViewController: UITableViewController, DownloadListView, downloadObjectTableDelegate {
    
    var progressValues : [Float] = []
    var downloadNames : [String] = []
    var vidDurations : [String] = []
    var images : [UIImage] = []
    var count = 0
     
    var dlObject : dataDownloadObject!
    var downloadTasks : [String] = []
    var uncachedVideos : [String] = []
    var dlButtonHidden = false
    
    override func viewWillAppear(animated: Bool) {
        reloadCells()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideTabBar")
        view.addGestureRecognizer(tap)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resetDownloadTasks:", name: "resetDownloadTasksID", object: nil)
        
        tableView.backgroundColor = UIColor.clearColor()
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
    }
     
    func hideTabBar(){
        setTabBarVisible(!(tabBarIsVisible()), animated: true)
        let visible = (navigationController?.navigationBarHidden)!
        navigationController?.setNavigationBarHidden(!visible, animated: true)
    }
    
    func setTabBarVisible(visible:Bool, animated:Bool) {
        if (tabBarIsVisible() == visible) { return }
        
        // get a frame calculation ready for tabBar
        let frame = self.tabBarController?.tabBar.frame
        let height = (frame?.size.height)!
        let offsetY = (visible ? -height : height)
        
        // zero duration means no animation
        let duration:NSTimeInterval = (animated ? 0.2 : 0.0)
        
        //  animate the tabBar
        if frame != nil {
            
            UIView.animateWithDuration(duration) {
                self.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY)
                return
            }
        }
    }
    
    func tabBarIsVisible() ->Bool {
        return self.tabBarController?.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame)
    }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    func setDLObject(session : dataDownloadObject){ dlObject = session }
    func getDLObject() -> dataDownloadObject? { return dlObject }
    func addDLTask(tasks : [String]){ downloadTasks += tasks }
    func getDLTasks() -> [String] { return downloadTasks }
    func addUncachedVid(identifier: [String]) { uncachedVideos += identifier}
    func getUncachedVids() -> [String] { return uncachedVideos }
    
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

            
            tableView.reloadData()
        }
    }*/
    func resetDownloadTasks(notification: NSNotification){
        let dict : NSDictionary? = notification.userInfo
        if dict == nil {
            downloadTasks = []
        }
        
        else {
            let identifier = dict!.valueForKey("identifier") as! String
            let x = downloadTasks.indexOf(identifier)
            if x != nil {
                downloadTasks.removeAtIndex(x!)
            }
            
        }
    }
    
    func setDLButtonHidden(value: Bool) {
        dlButtonHidden = value
    }
    
    func dlButtonIsHidden() -> Bool{
        return dlButtonHidden
    }
    
    func reloadCells(){ tableView.reloadData() }
    
    func reloadCellAtNdx(cellNum : Int){
        if cellNum < count{
            let indexPath = NSIndexPath(forRow: cellNum, inSection: 0)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    //update taskProgress of specific cell
    func setProgressValue(dict : NSDictionary){
        let cellNum : Int = dict.valueForKey("ndx")!.integerValue
        
        if cellNum < count {
            let taskProgress : Float = dict.valueForKey("value")!.floatValue
            progressValues[cellNum] = taskProgress
        }
    }
    
    func addCell(dict : NSDictionary){
        let cellName : String = dict.valueForKey("name") as! String
        let vidDur : String = dict.valueForKey("duration") as! String
        let thumbnail = dict.valueForKey("thumbnail") as! UIImage
        
        count++
        progressValues += [0.0]
        downloadNames += [cellName]
        vidDurations += [vidDur]
        images += [thumbnail]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> downloadCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("downloadCell", forIndexPath: indexPath) as! downloadCell
        
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
            downloader.setup(downloadListView: self)
        }
        if segue.identifier == "showSearchWebView" {
            let downloader = segue.destinationViewController as! SearchWebViewController
            downloader.setup(downloadListView: self)
        }
    }
}