//
//  MiscFuncs.swift
//  Music Player
//
//  Created by Sem on 9/13/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import Foundation
public class MiscFuncs{
    
    
    public class func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    
    public class func hrsAndMinutes(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02dh %02dm", hours, minutes)
    }
    
    
    
}

