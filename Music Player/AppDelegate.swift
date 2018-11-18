//
//  AppDelegate.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    //this will be used when opening Webview from playlist
    var downloadTable : downloadTableViewControllerDelegate?
    var dataDownloader : DataDownloader?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        addCustomMenuItems()
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil,
                                        {(_,observer, name, _,_) -> Void in
                                            if((name?.rawValue)! == "com.apple.springboard.lockcomplete" as CFString){
                                                UserDefaults.standard.set(true, forKey: "kDisplayStatusLocked")
                                                UserDefaults.standard.synchronize()
                                            }
        },
                                        "com.apple.springboard.lockcomplete" as CFString, nil, .deliverImmediately)
        
        self.markExistingFilesNoBackupIfNeeded()
        return true
    }
    
    fileprivate func displayStatusChanged(center : CFNotificationCenter!, observer : UnsafeRawPointer, name : CFString!, object : UnsafeRawPointer, suspensionBehavior: CFNotificationSuspensionBehavior){
        
        
    }
    
    fileprivate func addCustomMenuItems() {
        
        let menuController = UIMenuController.shared
        var menuItems = menuController.menuItems ?? [UIMenuItem]()
        
        let copyLinkItem = UIMenuItem(title: "Copy Link", action: MenuAction.copyLink.selector())
        //let saveVideoItem = UIMenuItem(title: "Save to Camera Roll", action: MenuAction.saveVideo.selector())
        //let redownloadItem = UIMenuItem(title: "Re-download Video", action: MenuAction.redownloadVideo.selector())
        
        menuItems.append(copyLinkItem)
        //menuItems.append(saveVideoItem)
        //menuItems.append(redownloadItem)
        menuController.menuItems = menuItems
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        let state = UIApplication.shared.applicationState
        
        if(state == UIApplicationState.background){
            if(!UserDefaults.standard.bool(forKey: "kDisplayStatusLocked")){
                //disable video tracks to allow background audio play only when home button pressed (not performed on lock button press)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "enteredBackgroundID"), object: nil)
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //renable video tracks
        NotificationCenter.default.post(name: Notification.Name(rawValue: "enteredForegroundID"), object: nil)
        
        UserDefaults.standard.set(false, forKey: "kDisplayStatusLocked")
        UserDefaults.standard.synchronize()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
        //remove excess documents and data
        let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        var dirsToClean : [String] = []
        
        dirsToClean += [(cacheFolder as NSString).appendingPathComponent("/com.Music-Player/fsCachedData/"),
                        (cacheFolder as NSString).appendingPathComponent("/com.apple.nsurlsessiond/"),
                        (cacheFolder as NSString).appending("/WebKit/"),
                        NSTemporaryDirectory()]
        
        for dir : String in dirsToClean{
            MiscFuncs.deleteFiles(dir)
        }
        
        Database.shared.save()
    }
    
    func markExistingFilesNoBackupIfNeeded() {
        let hasNoBackup = UserDefaults.standard.bool(forKey: "has no backup")
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard !hasNoBackup, let enumerator = FileManager.default.enumerator(atPath: documents) else {
            return
        }
        
        for case let filename as String in enumerator
            where filename.hasSuffix("mp4") || filename.hasSuffix("m4a") {
                MiscFuncs.addSkipBackupAttribute(toFilepath: MiscFuncs.grabFilePath(filename))
        }
        
        UserDefaults.standard.set(true, forKey: "has no backup")
    }

}

