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
    
     
    @IBOutlet var overlay: UIView!
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
        
        var request = NSFetchRequest(entityName: "Settings")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        settings = results[0] as! NSManagedObject
        println(settings.valueForKey("quality") as! Int)
        println(settings.valueForKey("cache") as! Bool)

        var qualRow = NSIndexPath(forRow: settings.valueForKey("quality") as! Int, inSection: 0)
        
        deselectRow(qualRow)
        selectRow(qualRow)
        
        
        var cacheRow = NSIndexPath(forRow: 0, inSection: 1)
        deselectRow(cacheRow)
        
        if settings.valueForKey("cache") as! Bool {
            selectRow(cacheRow)
        }
        
        tableView.backgroundColor = UIColor.clearColor()
        var imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        navigationController?.setNavigationBarHidden(true, animated: false)
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
        case 1://cache Video
            settings.setValue(true, forKey: "cache")
        default:
            break
        }
        
        context.save(nil)
    }
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
        
        if indexPath.section == 1 {
            settings.setValue(false, forKey: "cache")
        }
        
        context.save(nil)
    }
    
    
    override func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if indexPath.section == 1{
            return indexPath
        }
        return nil
    }
}
