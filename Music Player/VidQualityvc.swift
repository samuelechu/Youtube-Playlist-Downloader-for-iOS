//
//  VidQualityvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData

class VidQualityvc: UITableViewController {
    
    
    var selectedRow : NSIndexPath!
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    var vidQual : NSManagedObject!
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.selectRowAtIndexPath(selectedRow, animated: true, scrollPosition: UITableViewScrollPosition.None)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        self.context = appDel!.managedObjectContext
        
        var request = NSFetchRequest(entityName: "VidQualitySelection")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        vidQual = results[0] as! NSManagedObject
        selectedRow = NSIndexPath(forRow: vidQual.valueForKey("quality") as! Int, inSection: 0)
        
        self.tableView.selectRowAtIndexPath(selectedRow, animated: true, scrollPosition: UITableViewScrollPosition.None)
        self.tableView.cellForRowAtIndexPath(selectedRow)?.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        vidQual.setValue(indexPath.row, forKey: "quality")
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
}
