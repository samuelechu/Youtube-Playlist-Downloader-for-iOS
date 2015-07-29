//
//  Playlist.swift
//  Music Player
//
//  Created by Sem on 7/9/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

class Playlist: UITableViewController, PlaylistDelegate {
    
    var appDel : AppDelegate!
    var context : NSManagedObjectContext!
    var songSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    var songs : NSArray!
    
    var documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    var x : [Int] = []
    var playerQueue = AVQueuePlayer()
    var videoTracks : [AVPlayerItemTrack]!
    var selectedNdx : Int!
    
    //sort + reload data
    override func viewWillAppear(animated: Bool) {
        var request = NSFetchRequest(entityName: "Songs")
        request.sortDescriptors = [songSortDescriptor]
        songs = context.executeFetchRequest(request, error: nil)
        self.tableView.reloadData()
        println(songs.count)
        resetX()
    }
    
    func resetX(){
        x = []
        if songs.count > 0 {
            for var index = 0; index < songs.count; ++index {
                x += [index]
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        self.context = appDel!.managedObjectContext
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredBackground:", name: "enteredBackgroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredForeground:", name: "enteredForegroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerQueue.currentItem)
        
        //set audio to play in bg
        var audio : AVAudioSession = AVAudioSession()
        audio.setCategory(AVAudioSessionCategoryPlayback , error: nil)
        audio.setActive(true, error: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell", forIndexPath: indexPath) as! UITableViewCell
        
        var row = x[indexPath.row]
        cell.textLabel?.text = songs[row].valueForKey("title") as? String
        
        cell.contentView.backgroundColor = UIColor.clearColor()
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    func shuffle<C: MutableCollectionType where C.Index == Int>(inout list: C) {
        let c = count(list)
        for i in 0..<(c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i))) + i
            swap(&list[i], &list[j])
        }
    }
    
    @IBAction func shufflePlaylist() {
        if songs.count > 0 {
            shuffle(&x)
            self.tableView.reloadData()
        }
    }
    
    @IBAction func deleteAll() {
        var fileManager = NSFileManager.defaultManager()
        var request = NSFetchRequest(entityName: "Songs")
        var songsToDelete : NSArray = context.executeFetchRequest(request, error: nil)!
        
        for entity in songsToDelete {//remove item in downloadTasks
            var identifier = (entity as! NSManagedObject).valueForKey("identifier") as! String
            var dict = ["identifier" : identifier]
            NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
            }
        
        deleteSongs(songsToDelete)
        songs = context.executeFetchRequest(request, error: nil)
        resetX()
        self.tableView.reloadData()
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            var row = x[indexPath.row]
            x.removeAtIndex(indexPath.row)
            
            for var index = 0; index < x.count; ++index {
                if x[index] > row {
                    x[index]--
                }
            }
            
            var selectedSong = fetchSong(row)
            
            var dict = ["identifier" : selectedSong[0].valueForKey("identifier")!]
            NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
            
            deleteSongs(selectedSong)
            
            var request = NSFetchRequest(entityName: "Songs")
            request.sortDescriptors = [songSortDescriptor]
            songs = context.executeFetchRequest(request, error: nil)
            resetX()
            self.tableView.reloadData()
        }
    }
    
    func deleteSongs(songsToDelete : NSArray){
        var fileManager = NSFileManager.defaultManager()
        
        for entity in songsToDelete {//remove item in both documents directory and persistentData
            var file = (entity as! NSManagedObject).valueForKey("identifier") as! String
            file = file.stringByAppendingString(".mp4")
            var filePath = documentsDir.stringByAppendingPathComponent(file)
            fileManager.removeItemAtPath(filePath, error: nil)
            context.deleteObject(entity as! NSManagedObject)
        }
        
        context.save(nil)
        
    }
    
    
    
    func fetchSong (ndx : Int) -> NSArray{
        
        var identifier = songs[ndx].valueForKey("identifier") as! String
        var request = NSFetchRequest(entityName: "Songs")
        request.predicate = NSPredicate(format: "identifier = %@", identifier)
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        return results
    }
    
    
    
    
    func getSongAtIndex(index : Int) -> AVPlayerItem {
        var file = songs[index].valueForKey("identifier") as! String
        file = file.stringByAppendingString(".mp4")
        var filePath = documentsDir.stringByAppendingPathComponent(file)
        
        let url = NSURL(fileURLWithPath: filePath)
        var playerItem = AVPlayerItem(URL: url)
        
        return playerItem
    }
    
    func addSongToQueue(index : Int) {
        var ndx = x[index]
        var playerItem = getSongAtIndex(ndx)
        playerQueue.insertItem(playerItem, afterItem: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPlayer" {
            playerQueue.removeAllItems()
            
            selectedNdx = tableView.indexPathForSelectedRow()?.row
            fillPlaylistQueue()
            
            //if download finished, initialize avplayer\
            let player : Player = segue.destinationViewController as! Player
            player.playlistDelegate = self
            player.player = playerQueue
        }
    }
    
    func playerItemDidReachEnd(notification : NSNotification){
        videoTracks = playerQueue.currentItem.tracks as! [AVPlayerItemTrack]
        for track : AVPlayerItemTrack in videoTracks{
            track.enabled = true; // enable the track
        }
        advance()
    }
    
    func advance(){
        var curItem = playerQueue.currentItem
        curItem.seekToTime(kCMTimeZero)
        playerQueue.advanceToNextItem()
        playerQueue.insertItem(curItem, afterItem: nil)
    }
    
    func retreat(){
        if selectedNdx == 0 {
            selectedNdx = songs.count - 1
        }
        else {
            selectedNdx = selectedNdx - 1
        }
        
        if (songs.count == 1){
            advance()
        }
            
        else {//insert previous avplayeritem to beginnning of list
            var curItem = playerQueue.currentItem
            curItem.seekToTime(kCMTimeZero)
            var lastItemNdx = playerQueue.items().count - 1
            var lastItem = playerQueue.items()[lastItemNdx] as! AVPlayerItem
            playerQueue.removeItem(lastItem)
            playerQueue.insertItem(lastItem, afterItem: curItem)
            playerQueue.advanceToNextItem()
            playerQueue.insertItem(curItem, afterItem: lastItem)
        }
    }
    
    func fillPlaylistQueue(){
        for var index = selectedNdx!; index < songs.count; index++ {
            addSongToQueue(index)
        }
        
        for var index = 0; index < selectedNdx!; index++ {
            addSongToQueue(index)
        }
    }
    
    func enteredForeground(notification: NSNotification){
        if playerQueue.currentItem != nil{
            videoTracks = playerQueue.currentItem.tracks as! [AVPlayerItemTrack]
            
            for track : AVPlayerItemTrack in videoTracks{
                
                track.enabled = true; // enable the track
            }
        }
    }
    
    //disable vidTracks
    func enteredBackground(notification: NSNotification){
        
        if playerQueue.currentItem != nil {
            videoTracks = playerQueue.currentItem.tracks as! [AVPlayerItemTrack]
            
            for track : AVPlayerItemTrack in videoTracks{
                
                if(!track.assetTrack.hasMediaCharacteristic("AVMediaCharacteristicAudible")){
                    track.enabled = false; // disable the track
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        var row = indexPath.row
        var cell = self.tableView.cellForRowAtIndexPath(indexPath)
        println(cell!.textLabel?.text)
    }
}
