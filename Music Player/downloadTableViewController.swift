//
//  downloadTableViewController.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadTableViewController: UITableViewController {
    
    var count : Int = 0
    
    var progressValues : [Float] = []
    
    var downloadNames : [String] = []
    
    var vidDurations : [String] = []
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        self.tableView.reloadData()
    }
    
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
        
        var rowNumber : Int? = dict.valueForKey("ndx")?.integerValue
        var indexPath = NSIndexPath(forRow: rowNumber!, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }

    
    
    //update taskProgress of specific cell
    func setProgressValue(notification: NSNotification){
        var dict : NSDictionary = notification.userInfo!
        
        var cellNum : Int? = dict.valueForKey("ndx")?.integerValue
        var taskProgress : Float? = dict.valueForKey("value")?.floatValue
        progressValues[cellNum!] = taskProgress!
        
        
        
    }
    
    func setDownloadInfo(notification: NSNotification){
        var dict : NSDictionary = notification.userInfo!
        
        var cellNum : Int? = dict.valueForKey("ndx")?.integerValue
        var cellName : String? = dict.valueForKey("name") as? String
        var vidDur : String? = dict.valueForKey("duration") as? String
        downloadNames[cellNum!] = cellName!
        vidDurations[cellNum!] = vidDur!
        
        
        
        
    }
    
    func addCell(notification: NSNotification){
        
        
        var dict : NSDictionary = notification.userInfo!
        
        var cellNum : Int? = dict.valueForKey("ndx")?.integerValue
        var cellName : String? = dict.valueForKey("name") as? String
        var vidDur : String? = dict.valueForKey("duration") as? String
        count++
        progressValues += [0.0]
        downloadNames[cellNum!] += cellName!
        vidDurations[cellNum!] += vidDur!
        
        
        
        
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
        
        //see if video info has been obtained
        if vidDurations[indexPath.row] != "" && downloadNames[indexPath.row] != ""{
            cell.durationLabel.text = vidDurations[indexPath.row]
            cell.downloadLabel.text = downloadNames[indexPath.row]
            cell.progressBar.progress = progressValues[indexPath.row]
        }
        
        else {
            cell.durationLabel.text = "00:00:00"
            cell.downloadLabel.text = "Initializing download..."
        }
        
        
        if cell.progressBar.progress == 1.0 { cell.accessoryType = UITableViewCellAccessoryType.Checkmark}
        // Configure the cell...
        
        return cell
    }


 





}







