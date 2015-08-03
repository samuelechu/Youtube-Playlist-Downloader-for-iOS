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
    
    
    @IBOutlet var selectButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    
    var appDel : AppDelegate!
    var context : NSManagedObjectContext!
    var songSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    
    var songs : NSArray!
    var documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    var streamURLs = [String : NSURL]()
    
    var x : [Int] = []
    var playerQueue = AVQueuePlayer()
    var curNdx = 0
    var videoTracks : [AVPlayerItemTrack]!
    
    //sort + reload data
    override func viewWillAppear(animated: Bool) {
        refreshPlaylist()
        retrieveStreams()
        resetX()
    }
    func reloadPlaylist(notification: NSNotification){
        refreshPlaylist()
        retrieveStreams()
        resetX()
    }
    func refreshPlaylist(){
        var request = NSFetchRequest(entityName: "Songs")
        request.sortDescriptors = [songSortDescriptor]
        songs = context.executeFetchRequest(request, error: nil)
        
        
        
        tableView.reloadData()
    }
    
    
    
    
    
    
    func resetX(){
        x = []
        if songs.count > 0 {
            for var index = 0; index < songs.count; ++index {
                x += [index]
            }
        }
    }
    
    
    
    
    
    func retrieveStreams() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            for song in self.songs{
                
                var isDownloaded = song.valueForKey("isDownloaded") as! Bool
                if !isDownloaded {
                    var identifier = song.valueForKey("identifier") as! String
                    
                    if self.streamURLs[identifier] == nil {
                        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
                            if error == nil {
                                var streamURLs : NSDictionary = video.valueForKey("streamURLs") as! NSDictionary
                                
                                
                                
                                var url = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                                
                                self.streamURLs[video.identifier] = url
                                
                            }
                        })
                        
                    }
                }
                
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel!.managedObjectContext
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredBackground:", name: "enteredBackgroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredForeground:", name: "enteredForegroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadPlaylist:", name: "reloadPlaylistID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerQueue.currentItem)
        
        //set audio to play in bg
        var audio : AVAudioSession = AVAudioSession()
        audio.setCategory(AVAudioSessionCategoryPlayback , error: nil)
        audio.setActive(true, error: nil)
        
        tableView.backgroundColor = UIColor.clearColor()
        var imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        editButtonItem().title = "Select"
        navigationItem.leftBarButtonItem = editButtonItem()
        
        deleteButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.grayColor()], forState: UIControlState.Disabled)
    }
    
    
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: true)
        
        
        if editing {
            deleteButton.enabled = false
            selectButton.title = "Select All"
            editButtonItem().title = "Cancel"
            navigationController?.toolbarHidden = false
            navigationController?.hidesBarsOnSwipe = true
        }
            
        else {
            navigationController?.hidesBarsOnSwipe = false
            navigationController?.toolbarHidden = true
        }
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
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing{
            deleteButton.enabled = true
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        var selectedRows = tableView.indexPathsForSelectedRows()
        if selectedRows == nil {
            deleteButton.enabled = false
        }
    }
    
    @IBAction func selectPressed() {
        // var rows = tableView.indexpaths
        
        
        if selectButton.title == "Select All"{
            for var row = 0; row < tableView.numberOfRowsInSection(0); ++row {
                var indexPath = NSIndexPath(forRow: row, inSection: 0)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            }
            selectButton.title = "Select None"
            deleteButton.enabled = true
        }
            
            
            
        else{
            for var row = 0; row < tableView.numberOfRowsInSection(0); ++row {
                var indexPath = NSIndexPath(forRow: row, inSection: 0)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
            selectButton.title = "Select All"
            deleteButton.enabled = false
        }
        
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell", forIndexPath: indexPath) as! SongCell
        
        var row = x[indexPath.row]
        cell.songLabel?.text = songs[row].valueForKey("title") as? String
        
        cell.contentView.backgroundColor = UIColor.clearColor()
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    //shuffle functions
    @IBAction func shufflePlaylist() {
        if songs.count > 0 {
            shuffle(&x)
            tableView.reloadData()
        }
    }
    
    func shuffle<C: MutableCollectionType where C.Index == Int>(inout list: C) {
        let c = count(list)
        for i in 0..<(c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i))) + i
            swap(&list[i], &list[j])
        }
    }
    
    //delete functions
    @IBAction func deletePressed() {
        
        if var selectedIndexPaths = tableView.indexPathsForSelectedRows() as? [NSIndexPath] {
            
            
            
            var selectedRows : [Int] = []
            for indexPath : NSIndexPath in selectedIndexPaths {
                selectedRows += [indexPath.row]
                
                
                var row = x[indexPath.row]
                
                var identifier = songs[row].valueForKey("identifier") as! String
                
                deleteSong(identifier)
            }
            
            //horribly unreadable, but keeps shuffled songs in order after deletion
            var temp = x
            var selectedSongs : [Int] = []
            
            for num in selectedRows {
                selectedSongs += [x[num]]
            }
            
            for var index = 0; index < x.count; ++index {
                if var found = find(selectedSongs, x[index]) {
                    x.removeAtIndex(index)
                    index--
                }
            }
            
            var temp2 = x
            for num in temp {
                if find(x, num) == nil {
                for var index = 0; index < x.count; ++index {
                    if x[index] > num {
                        temp2[index]--
                    }
                }
                }
            }
            x = temp2
            
            refreshPlaylist()
            
        }
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
            
            //fetch song
            var identifier = songs[row].valueForKey("identifier") as! String
            var songRequest = NSFetchRequest(entityName: "Songs")
            songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
            var selectedSong : NSArray = context.executeFetchRequest(songRequest, error: nil)!
            
            var dict = ["identifier" : identifier]
            NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
            
            deleteSongs(selectedSong)
            
            var request = NSFetchRequest(entityName: "Songs")
            request.sortDescriptors = [songSortDescriptor]
            songs = context.executeFetchRequest(request, error: nil)
            tableView.reloadData()
        }
    }
    
    
    
    func deleteSong(identifier : String){
        var songRequest = NSFetchRequest(entityName: "Songs")
        songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        var fetchedSongs : NSArray = context.executeFetchRequest(songRequest, error: nil)!
        var selectedSong = fetchedSongs[0] as! NSManagedObject
        
        
        var dict = ["identifier" : identifier]
        NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
        
        var fileManager = NSFileManager.defaultManager()
        
        //remove item in both documents directory and persistentData
        var file = selectedSong.valueForKey("identifier") as! String
        file = file.stringByAppendingString(".mp4")
        var filePath = documentsDir.stringByAppendingPathComponent(file)
        fileManager.removeItemAtPath(filePath, error: nil)
        context.deleteObject(selectedSong)
        
        
        context.save(nil)
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
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if !tableView.editing {
            return true
        }
        
        return false
    }
    
    
    //avplayer related functions
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPlayer"{
            playerQueue.removeAllItems()
            
            curNdx = (tableView.indexPathForSelectedRow()?.row)!
            addSongToQueue(curNdx)
            
            //if download finished, initialize avplayer\
            let player : Player = segue.destinationViewController as! Player
            player.playlistDelegate = self
            player.player = playerQueue
        }
    }
    
    func addSongToQueue(index : Int) {
        if let curItem = playerQueue.currentItem{
            curItem.seekToTime(kCMTimeZero)
            playerQueue.advanceToNextItem()
        }
        
        var ndx = x[index]
        
        var isDownloaded = songs[ndx].valueForKey("isDownloaded") as! Bool
        
        var identifier = songs[ndx].valueForKey("identifier") as! String
        if isDownloaded {
            
            var file = identifier.stringByAppendingString(".mp4")
            var filePath = documentsDir.stringByAppendingPathComponent(file)
            
            
            
            
            let url = NSURL(fileURLWithPath: filePath)
            
            
            var playerItem = AVPlayerItem(URL: url)
            playerQueue.insertItem(playerItem, afterItem: nil)
        }
            
        else{
            println(streamURLs[identifier])
            
            
            if streamURLs[identifier] == nil {
                XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
                    if error == nil {
                        var streamURLs : NSDictionary = video.valueForKey("streamURLs") as! NSDictionary
                        
                        
                        var url = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                        
                        
                        self.streamURLs[video.identifier] = url
                        
                        var playerItem = AVPlayerItem(URL: url)
                        self.playerQueue.insertItem(playerItem, afterItem: nil)
                        
                    }
                })
                
            }
                
            else {
                var url = streamURLs[identifier]
                var playerItem = AVPlayerItem(URL: url)
                playerQueue.insertItem(playerItem, afterItem: nil)
            }
            
        }
        
    }
    
    func advance(){
        if curNdx == songs.count - 1 { curNdx = 0 }
        else{ curNdx++ }
        
        enableVidTracks()
        addSongToQueue(curNdx)
    }
    
    func retreat(){
        if curNdx == 0 { curNdx = songs.count - 1 }
        else { curNdx-- }
        
        if (songs.count == 1) { advance() }
        else{
            enableVidTracks()
            addSongToQueue(curNdx)
        }
    }
    
    func playerItemDidReachEnd(notification : NSNotification){
        enableVidTracks()
        advance()
    }
    
    func enableVidTracks(){
        videoTracks = playerQueue.currentItem.tracks as! [AVPlayerItemTrack]
        for track : AVPlayerItemTrack in videoTracks{
            track.enabled = true; // enable the track
        }
    }
    
    func enteredForeground(notification: NSNotification){
        if playerQueue.currentItem != nil{
            enableVidTracks()
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
}
