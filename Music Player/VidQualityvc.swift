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
    
    
    @IBOutlet var overlay: UIView!
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
        
        self.tableView.backgroundColor = UIColor.clearColor()
        var imgView = UIImageView(image: UIImage(named: "hillsTransition.png"))
        imgView.frame = self.tableView.frame
        self.tableView.backgroundView = imgView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /*
- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath {
for ( NSIndexPath* selectedIndexPath in tableView.indexPathsForSelectedRows ) {
if ( selectedIndexPath.section == indexPath.section )
[tableView deselectRowAtIndexPath:selectedIndexPath animated:NO] ;
}
return indexPath ;
}*/
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if var selectedRows = tableView.indexPathsForSelectedRows() as? [NSIndexPath]{
            for selectedIndexPath : NSIndexPath in selectedRows{
                if selectedIndexPath.section == indexPath.section{
                    println("hi")
                    tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
                    tableView.cellForRowAtIndexPath(selectedIndexPath)?.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        }
        return indexPath
    }
    
    //0 is videoQual, 1 is cache Video
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        if indexPath.section == 0{
            vidQual.setValue(indexPath.row, forKey: "quality")
        }
    }
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    
    override func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if indexPath.section == 1{
            return indexPath
        }
        return nil
    }
}
