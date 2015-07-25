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
    var songs : NSArray!
    let songSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
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
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return songs.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell", forIndexPath: indexPath) as! UITableViewCell
        
        
        
        var row = x[indexPath.row]
        cell.textLabel?.text = songs[row].valueForKey("title") as? String
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
        x = []
        if songs.count > 0 {
            for var index = 0; index < songs.count; ++index {
                x += [index]
            }
        }
        shuffle(&x)
        println(x)
        self.tableView.reloadData()
        
        
    }
    
    @IBAction func deleteAll() {
        
        
        var fileManager = NSFileManager.defaultManager()
        var request = NSFetchRequest(entityName: "Songs")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        
        
        for entity in results {
            
            
            var file = (entity as! NSManagedObject).valueForKey("identifier") as! String
            file = file.stringByAppendingString(".mp4")
            var filePath = documentsDir.stringByAppendingPathComponent(file)
            
            if fileManager.fileExistsAtPath(filePath) {
                println("File exists")
            } else {
                println("File not found")
            }
            fileManager.removeItemAtPath(filePath, error: nil)
            
            
            
            context.deleteObject(entity as! NSManagedObject)
        }
        
        context.save(nil)
        
        songs = context.executeFetchRequest(request, error: nil)
        
        self.tableView.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil)
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
        
        // var player = AVPlayer(playerItem: playerItem)
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
        var curItem = playerQueue.currentItem
        
        videoTracks = curItem.tracks as! [AVPlayerItemTrack]
        for track : AVPlayerItemTrack in videoTracks{
            track.enabled = true; // enable the track
        }
        
        curItem.seekToTime(kCMTimeZero)
        playerQueue.advanceToNextItem()
        playerQueue.insertItem(curItem, afterItem: nil)
        
        /*if playerQueue.items().count == 0{
        fillPlaylistQueue()
        }*/
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
        
        var lastItemNdx = playerQueue.items().count - 1
        var lastItem = playerQueue.items()[lastItemNdx] as! AVPlayerItem
        playerQueue.removeItem(lastItem)
        
        var curItem = playerQueue.currentItem
        curItem.seekToTime(kCMTimeZero)
        playerQueue.insertItem(lastItem, afterItem: curItem)
        playerQueue.advanceToNextItem()
        playerQueue.insertItem(curItem, afterItem: lastItem)
        
        
        
        
        //var playerItem = getSongAtIndex(index)
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
    
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell
    
    // Configure the cell...
    
    return cell
    }
    */
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
