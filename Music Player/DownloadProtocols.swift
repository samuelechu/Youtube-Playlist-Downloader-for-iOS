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
    func addCell(dict : NSDictionary)
    
    //necessary to avoid duplicate downloads
    func addDLTask(tasks : [String])
    func getDLTasks() -> [String]
    func addUncachedVid(tasks : [String])
    func getUncachedVids() -> [String]
}
