//
//  MiscFuncs.swift
//  Music Player
//
//  Created by Sem on 9/13/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import Foundation
public class MiscFuncs{
    
    //convert double to format : hh:mm:ss
    public class func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    //convert double to format : xh xm
    public class func hrsAndMinutes(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02dh %02dm", hours, minutes)
    }
    
    //shuffle int array
    public class func shuffle<C: MutableCollectionType where C.Index == Int>(inout list: C) {
            let c = count(list)
            for i in 0..<(c - 1) {
                let j = Int(arc4random_uniform(UInt32(c - i))) + i
                swap(&list[i], &list[j])
            }
        
    }
    
    public class func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
}

