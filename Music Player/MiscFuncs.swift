//
//  MiscFuncs.swift
//  Music Player
//
//  Created by Sem on 9/13/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import Foundation
import CoreData

open class MiscFuncs{
    
    //convert double to format : hh:mm:ss
    open class func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    //convert double to format : xh xm
    open class func hrsAndMinutes(_ interval: TimeInterval) -> String {
        let interval = Int(interval)
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02dh %02dm", hours, minutes)
    }
    
    //shuffle int array
    open class func shuffle<C: MutableCollection>(_ list: inout C) where C.Index == Int {
        let c = list.count
        for i in 0..<max(0, c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i))) + i
            if (i != j){
                list.swapAt(i, j)
            }
        }
        
    }
    
    //delay execution, taken from : http://stackoverflow.com/questions/24034544/dispatch-after-gcd-in-swift
    open class func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    open class func randomStringWithLength (_ len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0 ..< len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString
    }
    
    
    open class func parseIDs(url: String) -> (videoId: String?, playlistId: String?) {
        
        var videoId: String? = nil
        var playlistId: String? = nil
        
        if let url: URL = URL(string: url) {
            if let comp = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                if let queryItems = comp.queryItems {
                    queryItems.forEach { item in
                        switch item.name {
                        case "list": playlistId = item.value
                        case "v"   : videoId    = item.value
                        default    : break
                        }
                    }
                }
            }
        }
        
        return (videoId: videoId, playlistId: playlistId)
    }
    
    //return path of video, input : video identifier
    open class func grabFilePath(_ fileName : String) -> String {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = (documents as NSString).appendingPathComponent("\(fileName)")
        
        return writePath
    }
    
    //delete files in this directory
    open class func deleteFiles(_ dir : String) {
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: dir){
            let dirContents  = (try! fileMgr.contentsOfDirectory(atPath: dir))
            
            for file : String in dirContents {
                do {
                    try fileMgr.removeItem(atPath: (dir as NSString).appendingPathComponent(file))
                } catch _ {
                }
            }
        }
    }
    
    class func addSkipBackupAttribute(toFilepath filepath: String) {
        var url = URL(fileURLWithPath: filepath)
        var attributes = URLResourceValues()
        attributes.isExcludedFromBackup = true
        try? url.setResourceValues(attributes)
    }
    
}

extension Data {
    func asImage() -> UIImage? {
        return UIImage(data: self)
    }
}
