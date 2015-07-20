//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadTableViewController: UITableViewController {
    
    var count = 0
    
    var progressValues : [Float] = []
    
    var downloadNames : [String] = []
    
    var vidDurations : [String] = []
    
    var images : [UIImage] = []
    
    /*override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addCell:", name: "addNewCellID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setProgressValue:", name: "setProgressValueID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setDownloadInfo:", name: "setDownloadInfoID", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadCells:", name: "reloadCellsID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadCellAtNdx:", name: "reloadCellAtNdxID", object: nil)
        
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadCells(notification: NSNotification){
        self.tableView.reloadData()
    }
    
    
    func reloadCellAtNdx(notification: NSNotification){
        var dict : NSDictionary = notification.userInfo!
        
        var rowNumber : Int = dict.valueForKey("ndx")!.integerValue
        if rowNumber < count{
            var indexPath = NSIndexPath(forRow: rowNumber, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    
    
    //update taskProgress of specific cell
    func setProgressValue(notification: NSNotification){
        var dict : NSDictionary = notification.userInfo!
        
        var cellNum : Int = dict.valueForKey("ndx")!.integerValue
        
        if cellNum < count {
            var taskProgress : Float = dict.valueForKey("value")!.floatValue
            progressValues[cellNum] = taskProgress
        }
        
        
    }
    
    
    
    func addCell(notification: NSNotification){
        
        
        var dict : NSDictionary = notification.userInfo!
        
        var cellName : String = dict.valueForKey("name") as! String
        var vidDur : String = dict.valueForKey("duration") as! String
        
        var url = dict.valueForKey("thumbnail") as! NSURL
        let data = NSData(contentsOfURL: url)!
        var thumbnail = UIImage(data: data)!
        
        
        count++
        progressValues += [0.0]
        downloadNames += [cellName]
        vidDurations += [vidDur]
        images += [thumbnail]
    }
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> downloadCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("downloadCell", forIndexPath: indexPath) as! downloadCell
        var row = indexPath.row
        
        cell.accessoryType = UITableViewCellAccessoryType.None
        
        cell.progressBar.progress = progressValues[indexPath.row]
        
        
        if progressValues[indexPath.row] == 1.0 {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        
        
        
        
        
        cell.imageLabel.image = images[indexPath.row]
        cell.durationLabel.text = vidDurations[indexPath.row]
        cell.downloadLabel.text = downloadNames[indexPath.row]
        
        
        // Configure the cell...
        
        return cell
    }
    
    
    
    
    
    
    
    
}







