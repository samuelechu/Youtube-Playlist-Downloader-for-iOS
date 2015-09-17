//
//  VidQualityvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData

class Settings: UITableViewController {
    var appDel : AppDelegate?
    var context : NSManagedObjectContext!
    var settings : NSManagedObject!
    
    func selectRow(path : NSIndexPath){
        tableView.selectRowAtIndexPath(path, animated: false, scrollPosition: UITableViewScrollPosition.None)
        tableView.cellForRowAtIndexPath(path)?.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    
    func deselectRow(path : NSIndexPath){
        tableView.deselectRowAtIndexPath(path, animated: false)
        tableView.cellForRowAtIndexPath(path)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 44
        
        appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        //set initial quality to 360P if uninitialized
        var request = NSFetchRequest(entityName: "Settings")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        //default settings : quality = 360P, cache videos within app
        if results.count == 0 {
            var settings = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: context) as! NSManagedObject
            
            settings.setValue(0, forKey: "quality")
            settings.setValue(0, forKey: "cache")
            
            context.save(nil)
            results = context.executeFetchRequest(request, error: nil)!
        }
        
        //retrieve settings if Settings Entity exists
        settings = results[0] as! NSManagedObject
        
        var qualRow = NSIndexPath(forRow: settings.valueForKey("quality") as! Int, inSection: 0)
        deselectRow(qualRow)
        selectRow(qualRow)
        
        var cacheRow = NSIndexPath(forRow: settings.valueForKey("cache") as! Int, inSection: 1)
        deselectRow(cacheRow)
        selectRow(cacheRow)
        
        //set background
        tableView.backgroundColor = UIColor.clearColor()
        var imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //deselect previously selected rows that are in same section
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if var selectedRows = tableView.indexPathsForSelectedRows() as? [NSIndexPath]{
            for selectedIndexPath : NSIndexPath in selectedRows{
                if selectedIndexPath.section == indexPath.section{
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
        switch indexPath.section {
        case 0: //Video Quality
            settings.setValue(indexPath.row, forKey: "quality")
        case 1://Video Caching
            settings.setValue(indexPath.row, forKey: "cache")
        default:
            break
        }
        
        context.save(nil)
    }
    
   //user cannot deselect cells manually
   override func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
}
