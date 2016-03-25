//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadTableViewController: UITableViewController, DownloadListView, downloadTableViewControllerDelegate {
    
    
    var downloadCells: [DownloadCellInfo] = []
     
    var dlObject : dataDownloadObject!
    var downloadTasks : [String] = []
    var uncachedVideos : [String] = []
    var dlButtonHidden = false
    
    override func viewWillAppear(animated: Bool) {
        reloadCells()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        if let appDel = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDel.downloadListView = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(downloadTableViewController.hideTabBar))
        view.addGestureRecognizer(tap)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(downloadTableViewController.resetDownloadTasks(_:)), name: "resetDownloadTasksID", object: nil)
        
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
        if cellNum < downloadCells.count{
            let indexPath = NSIndexPath(forRow: cellNum, inSection: 0)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    //update taskProgress of specific cell
    func setProgressValue(dict : NSDictionary){
        let cellNum : Int = dict.valueForKey("ndx")!.integerValue
        
        if cellNum < downloadCells.count {
            let taskProgress : Double = dict.valueForKey("value")!
            downloadCells[cellNum].setProgress(taskProgress)
        }
    }
    
    func addCell(dict : NSDictionary){
        let newCell = dict.valueForKey("cellInfo") as! DownloadCellInfo
        downloadCells += [newCell]
        reloadCells()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadCells.count
    }
    
    //populate cells with data from downloadCells : [DownloadCellInfo]
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> downloadCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("downloadCell", forIndexPath: indexPath) as! downloadCell
        
        let cellInfo = downloadCells[cellNum]
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        if cellInfo.downloadFinished() { cell.accessoryType = UITableViewCellAccessoryType.Checkmark }
        
        cell.progressBar.progress = cellInfo.progress
        cell.imageLabel.image = cellInfo.image
        cell.durationLabel.text = cellInfo.duration
        cell.nameLabel.text = cellInfo.name
        
        cell.contentView.backgroundColor = UIColor.clearColor()
        cell.backgroundColor = UIColor.clearColor()

        return cell
    }
}