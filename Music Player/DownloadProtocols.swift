//
//  DownloadProtocols.swift
//  Music Player
//
//  Created by Samuel Chu on 3/21/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import Foundation


protocol downloadTableViewControllerDelegate{
    func setProgressValue(cellIndex: Int, taskProgress: Float)
    func addCell(_: DownloadCellInfo)
    
    //necessary to avoid duplicate downloads
    func addDLTask(_ tasks : [String])
    func getDLTasks() -> [String]
    func addUncachedVid(_ tasks : [String])
    func getUncachedVids() -> [String]
}
