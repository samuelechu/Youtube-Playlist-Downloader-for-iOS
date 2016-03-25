//
//  DownloadProtocols.swift
//  Music Player
//
//  Created by Samuel Chu on 3/21/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import Foundation


protocol downloadTableViewControllerDelegate{
    func setProgressValue(dict : NSDictionary)
    func reloadCellAtNdx(cellNum : Int)
    func addCell(dict : NSDictionary)
    func reloadCells()
}

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