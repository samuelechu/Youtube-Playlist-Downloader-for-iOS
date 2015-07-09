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

class Playlist: UITableViewController {
    
    
    var appDel : AppDelegate!
    var context : NSManagedObjectContext!
    var songs : NSArray!
    let songSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    
    
    
    var playerItem : AVPlayerItem!
    var videoTracks : [AVPlayerItemTrack]!
    
    //sort + reload data
    override func viewWillAppear(animated: Bool) {
        var request = NSFetchRequest(entityName: "Songs")
        request.sortDescriptors = [songSortDescriptor]
        songs = context.executeFetchRequest(request, error: nil)
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        self.context = appDel!.managedObjectContext
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredBackground:", name: "enteredBackgroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredForeground:", name: "enteredForegroundID", object: nil)

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
        
        cell.textLabel?.text = songs[indexPath.row].valueForKey("title") as? String
        return cell
    }

    
    @IBAction func deleteAll() {
        var fileManager = NSFileManager.defaultManager()
        var request = NSFetchRequest(entityName: "Songs")
        var results : NSArray = context.executeFetchRequest(request, error: nil)!
        
        for entity in results {
            
            var URL : String? = (entity as! NSManagedObject).valueForKey("location") as? String
            var fileToRemove = NSURL(string: URL!)
            fileManager.removeItemAtURL(fileToRemove!, error: nil)
            
            context.deleteObject(entity as! NSManagedObject)
        }
        
        context.save(nil)
        self.tableView.reloadData()
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //set audio to play in bg
        var audio : AVAudioSession = AVAudioSession()
        audio.setCategory(AVAudioSessionCategoryPlayback , error: nil)
        audio.setActive(true, error: nil)
        
        //if download finished, initialize avplayer
        if(origFileURL != nil){
            let destination = segue.destinationViewController as! AVPlayerViewController
            let url = origFileURL
            
            playerItem = AVPlayerItem(URL: origFileURL)
            
            var player = AVPlayer(playerItem: playerItem)
            destination.player = player
        }
    }
    
    func enteredForeground(notification: NSNotification){
        
        if( origFileURL != nil){
            
            for track : AVPlayerItemTrack in videoTracks{
                
                track.enabled = true; // enable the track
            }
        }
    }
    
    //disable vidTracks
    func enteredBackground(notification: NSNotification){
        
        if( origFileURL != nil){
            
            videoTracks = playerItem.tracks as! [AVPlayerItemTrack]
            
            for track : AVPlayerItemTrack in videoTracks{
                
                if(!track.assetTrack.hasMediaCharacteristic("AVMediaCharacteristicAudible")){
                    println("disabled track")
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
