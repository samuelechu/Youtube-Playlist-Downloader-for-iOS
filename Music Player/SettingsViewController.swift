//
//  VidQualityvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData

class SettingsViewController: UITableViewController {
    
    let context = Database.shared.managedObjectContext
    var settings : NSManagedObject!
    
    func selectRow(_ path : IndexPath){
        tableView.selectRow(at: path, animated: false, scrollPosition: UITableViewScrollPosition.none)
        tableView.cellForRow(at: path)?.accessoryType = UITableViewCellAccessoryType.checkmark
    }
    
    func deselectRow(_ path : IndexPath){
        tableView.deselectRow(at: path, animated: false)
        tableView.cellForRow(at: path)?.accessoryType = UITableViewCellAccessoryType.none
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 44
        
        //retrieve settings, or initialize default settings if unset
        settings = MiscFuncs.getSettings()
        let qualRow = IndexPath(row: settings.value(forKey: "quality") as! Int, section: 0)
        deselectRow(qualRow)
        selectRow(qualRow)
        
        let cacheRow = IndexPath(row: settings.value(forKey: "cache") as! Int, section: 1)
        deselectRow(cacheRow)
        selectRow(cacheRow)
        
        //set background
        tableView.backgroundColor = UIColor.clear
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView //recast your view as a UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.clear
        header.backgroundView?.backgroundColor = UIColor.clear
    }
    
    //deselect previously selected rows that are in same section
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedRows = tableView.indexPathsForSelectedRows as [IndexPath]?{
            for selectedIndexPath : IndexPath in selectedRows{
                if selectedIndexPath.section == indexPath.section{
                    tableView.deselectRow(at: selectedIndexPath, animated: false)
                    tableView.cellForRow(at: selectedIndexPath)?.accessoryType = UITableViewCellAccessoryType.none
                }
            }
        }
        return indexPath
    }
    
    //0 is videoQual, 1 is cache Video
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.checkmark
        switch indexPath.section {
        case 0: //Video Quality
            settings.setValue(indexPath.row, forKey: "quality")
        case 1://Video Caching
            settings.setValue(indexPath.row, forKey: "cache")
        default:
            break
        }
        
        do {
            try context.save()
        } catch _ {
        }
    }
    
   //user cannot deselect cells manually
   override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}
