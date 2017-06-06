//
//  AppDelegate.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData

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
        
        self.saveContext()
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
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.Music_Player" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Music_Player", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Music_Player.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
}

