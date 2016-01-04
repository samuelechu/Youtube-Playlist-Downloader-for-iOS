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
import XCDYouTubeKit

class Playlist: UITableViewController, UISearchResultsUpdating, PlaylistDelegate {
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   Initialization
    
    
    @IBOutlet var selectButton: UIBarButtonItem!
    @IBOutlet var shuffleButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    
    var playlistName: String?
    var playlistContainer : PlayerVC!
    
    var appDel : AppDelegate!
    var context : NSManagedObjectContext!
    var songSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    
    var songs : NSArray!
    var documentsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
    var identifiers : [String] = []
    
    //search control
    var filteredSongs : NSArray!
    var resultSearchController = UISearchController(searchResultsController: nil)
    
    var x : [Int] = [] //for shuffling
    var playerQueue = AVQueuePlayer()
    var curNdx = 0
    var videoTracks : [AVPlayerItemTrack]!
    var curSong : NSObject! //current song in queue
    
    var isConnected = false
    
    //reset tableView
    override func viewWillAppear(animated: Bool) {
        
        
        setEditing(false, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
        definesPresentationContext = false
        resultSearchController.active = false
        definesPresentationContext = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel!.managedObjectContext
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredBackground:", name: "enteredBackgroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enteredForeground:", name: "enteredForegroundID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePlaylist:", name: "reloadPlaylistID", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerQueue.currentItem)
        
        //set audio to play in bg
        let audio : AVAudioSession = AVAudioSession()
        do {
            try audio.setCategory(AVAudioSessionCategoryPlayback )
        } catch _ {
        }
        do {
            try audio.setActive(true)
        } catch _ {
        }
        
        //set background image
        tableView.backgroundColor = UIColor.clearColor()
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        //initialize shuffle, select, and delete buttons
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        editButtonItem().title = "Edit"
        deleteButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.grayColor()], forState: UIControlState.Disabled)
        
        shuffleButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.grayColor()], forState: UIControlState.Disabled)
        shuffleButton.tintColor = UIColor.grayColor()
        
        setEditing(false, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
        
        //self.navigationItem.hidesBackButton = true
        
        //initialize search bar
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.searchBar.sizeToFit()
        definesPresentationContext = true
        tableView.tableHeaderView = resultSearchController.searchBar
        
        //initialize playlist
        refreshPlaylist()
        resetX()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updatePlaylist(notification: NSNotification){
        updatePlaylist()
    }
    
    func updatePlaylist(){
        refreshPlaylist()
        resetX()
        shuffleButton.tintColor = UIColor.grayColor()
    }

    
    func refreshPlaylist(){
        if let playlistName = playlistName {
            let request = NSFetchRequest(entityName: "Songs")
            request.sortDescriptors = [songSortDescriptor]
            if !isConnected {//removes nonDownloaded songs from list if no connection detected
                let playlistFilter = NSPredicate(format: "playlistName = %@", playlistName)
                let downloadedFilter = NSPredicate(format: "isDownloaded = %@", true)
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [playlistFilter, downloadedFilter])
            }
            songs = try? context.executeFetchRequest(request)
            identifiers = []
            var playlistDuration = 0.0
            for song in songs{
                let identifier = song.valueForKey("identifier") as! String
                let duration = song.valueForKey("duration") as! Double
                identifiers += [identifier]
                playlistDuration += duration
            }
            
            navigationItem.title = "Duration - \(MiscFuncs.hrsAndMinutes(playlistDuration))"
            
            tableView.reloadData()
        }
    }
    func resetX(){
        x = []
        if songs.count > 0 {
            for var index = 0; index < songs.count; ++index {
                x += [index]
            }
        }
    }
    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   TableView / Editing Functions
    
    
    override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        //return action == MenuAction.Copy.selector() || action == MenuAction.Custom.selector()
        return action == MenuAction.copyLink.selector() || action == MenuAction.saveVideo.selector()
    }
    
    override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        //needs to be present for the menu to display
    }
    
    //populate tableView
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongCell", forIndexPath: indexPath) as! SongCell
        
        var songName : String!
        var duration : String!
        var identifier : String!
        var imageData : NSData!
        
        if resultSearchController.active && resultSearchController.searchBar.text != "" {
            songName = filteredSongs[indexPath.row].valueForKey("title") as! String
            duration = filteredSongs[indexPath.row].valueForKey("durationStr") as! String
            identifier = filteredSongs[indexPath.row].valueForKey("identifier") as! String
            imageData = filteredSongs[indexPath.row].valueForKey("thumbnail") as! NSData
        }
            
        else{
            let row = x[indexPath.row]
            songName = songs[row].valueForKey("title") as! String
            duration = songs[row].valueForKey("durationStr") as! String
            identifier = songs[row].valueForKey("identifier") as! String
            imageData = songs[row].valueForKey("thumbnail") as! NSData
        }
        
        cell.songLabel.text = songName
        cell.durationLabel.text = duration
        cell.identifier = identifier
        cell.imageLabel.image = UIImage(data: imageData)
        cell.positionLabel.text = "\(indexPath.row + 1)"
        cell.contentView.backgroundColor = UIColor.clearColor()
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if songs != nil{
            if resultSearchController.active && resultSearchController.searchBar.text != ""{
                return filteredSongs.count
            }
            else{
                return songs.count
            }
        }
            
        else{
            return 0
        }
    }
    
    //called when EditButtonItem() ("Select" button) pressed, disables/enables buttons and toolbars based on editing state
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
        
        if editing {
            shuffleButton.enabled = false
            deleteButton.enabled = false
            selectButton.title = "Select All"
            editButtonItem().title = "Cancel"
            navigationController!.toolbarHidden = false
            if !resultSearchController.active {
                navigationController!.hidesBarsOnSwipe = true
            }
        }
            
        else {
            editButtonItem().title = "Edit"
            shuffleButton.enabled = true
            navigationController!.hidesBarsOnSwipe = false
            navigationController!.toolbarHidden = true
        }
        
    }
    
    //called when selectButton on toolbar pressed, edits titles and state of buttons based on number of selected playlist items
    @IBAction func selectPressed() {
        
        if selectButton.title == "Select All"{
            for var row = 0; row < tableView.numberOfRowsInSection(0); ++row {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            }
            selectButton.title = "Select None"
            deleteButton.enabled = true
        }
            
        else{
            for var row = 0; row < tableView.numberOfRowsInSection(0); ++row {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
            selectButton.title = "Select All"
            deleteButton.enabled = false
        }
        
    }
    
    //disable delete button when less than one item selected
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing{
            deleteButton.enabled = true
        }
        
        else{
            setupPlayerQueue()
            playlistContainer.startPlayer()
        }
    }
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedRows = tableView.indexPathsForSelectedRows
        if selectedRows == nil {
            deleteButton.enabled = false
        }
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   Searchbar Functions
    
    
    func findNdxInFullList(ndxInSearchList : Int) -> Int{
        let identifier = filteredSongs[ndxInSearchList].valueForKey("identifier") as! String
        let ndxIdentifiers = identifiers.indexOf(identifier)!
        let ndxInFullList = x.indexOf(ndxIdentifiers)!
        return ndxInFullList
    }
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        //in editing mode
        if !shuffleButton.enabled {
            setEditing(false, animated: true)
        }
        
        let request = NSFetchRequest(entityName: "Songs")
        request.sortDescriptors = [songSortDescriptor]
        request.predicate = NSPredicate(format: "title CONTAINS[c] %@", searchController.searchBar.text!)
        filteredSongs = try? context.executeFetchRequest(request)
        tableView.reloadData()
        
        
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   Shuffle Functions
    
    @IBAction func shufflePlaylist() {
        
        if shuffleButton.tintColor != nil{
            MiscFuncs.shuffle(&x)
            shuffleButton.tintColor = nil
            
        }
            
        else{
            resetX()
            shuffleButton.tintColor = UIColor.grayColor()
        }
        tableView.reloadData()
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   Delete Functions
    
    
    //delete selected songs
    @IBAction func deletePressed() {
        
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows as [NSIndexPath]?
        {
            var selectedRows : [Int] = []
            
            //if search active, find indexes of selected rows in the full shuffled playlist
            if resultSearchController.active && resultSearchController.searchBar.text != "" {
                
                for indexPath : NSIndexPath in selectedIndexPaths {
                    
                    var selectedRow = indexPath.row
                    let id = filteredSongs[selectedRow].valueForKey("identifier") as! String
                    let ndxIdentifiers = identifiers.indexOf(id)!
                    selectedRow = x.indexOf(ndxIdentifiers)!
                    
                    selectedRows += [selectedRow]
                    let identifier = songs[ndxIdentifiers].valueForKey("identifier") as! String
                    
                    deleteSong(identifier)
                }
                
                
            }
                
            else{
                for indexPath : NSIndexPath in selectedIndexPaths {
                    selectedRows += [indexPath.row]
                    let row = x[indexPath.row]
                    let identifier = songs[row].valueForKey("identifier") as! String
                    
                    deleteSong(identifier)
                }
            }
            
            //horribly unreadable, but keeps shuffled songs in order after deletion
            let temp = x
            var selectedSongs : [Int] = []
            
            for num in selectedRows {
                selectedSongs += [x[num]]
            }
            
            for var index = 0; index < x.count; ++index {
                if var _ = selectedSongs.indexOf(x[index]) {
                    x.removeAtIndex(index)
                    index--
                }
            }
            
            var temp2 = x
            for num in temp {
                if x.indexOf(num) == nil {
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
        
        setEditing(false, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
        updateSearchResultsForSearchController(resultSearchController)
    }
    
    //disable shuffle and editbutton when swiping to delete
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        editButtonItem().enabled = false
        shuffleButton.enabled = false
    }
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        editButtonItem().enabled = true
        shuffleButton.enabled = true
    }
    
    //swipe to delete
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            var row : Int!
            
            if resultSearchController.active && resultSearchController.searchBar.text != ""{
                let selectedRow = indexPath.row
                row = x[findNdxInFullList(selectedRow)]
                x.removeAtIndex(row)
            }
                
            else{
                row = x[indexPath.row]
                x.removeAtIndex(indexPath.row)
            }
            
            let identifier = songs[row].valueForKey("identifier") as! String
            deleteSong(identifier)
            
            
            for var index = 0; index < x.count; ++index {
                if x[index] > row {
                    x[index]--
                }
            }
            
            refreshPlaylist()
            editButtonItem().enabled = true
            updateSearchResultsForSearchController(resultSearchController)
            
        }
    }
    
    func deleteSong(identifier : String){
        let songRequest = NSFetchRequest(entityName: "Songs")
        songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        let fetchedSongs : NSArray = try! context.executeFetchRequest(songRequest)
        let selectedSong = fetchedSongs[0] as! NSManagedObject
        
        //allows for redownload of deleted song
        let dict = ["identifier" : identifier]
        NSNotificationCenter.defaultCenter().postNotificationName("resetDownloadTasksID", object: nil, userInfo: dict as [NSObject : AnyObject])
        
        let fileManager = NSFileManager.defaultManager()
        
        //remove item in both documents directory and persistentData
        let isDownloaded = selectedSong.valueForKey("isDownloaded") as! Bool
        
        
        if isDownloaded {
            var file = selectedSong.valueForKey("identifier") as! String
            file = file.stringByAppendingString(".mp4")
            let filePath = (documentsDir as NSString).stringByAppendingPathComponent(file)
            do {
                try fileManager.removeItemAtPath(filePath)
            } catch _ {
            }
        }
        context.deleteObject(selectedSong)
        
        
        do {
            try context.save()
        } catch _ {
        }
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   AVPlayer Functions
    
    
    //don't segue to AVPlayer if editing
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if !tableView.editing || identifier == "PlaylistToSearchView"{
            setEditing(false, animated: true)
            return true
        }
        
        return false
    }
    
    //if playlist item selected, segue to avplayer
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "PlaylistToSearchView") {
            let searchVC = (segue.destinationViewController as? SearchWebViewController)!
            if let appDel = UIApplication.sharedApplication().delegate as? AppDelegate {
                if let dlView = appDel.downloadListView {
                    if let playlistName = playlistName {
                        searchVC.setup(downloadListView: dlView, playlistName: playlistName)
                    }
                }
                else {
                    errorAlert("error", message: "couldn't get download table view object")
                }
            }
        }
        else if segue.identifier == "showPlayer"{
            playerQueue.removeAllItems()
            
            
            if resultSearchController.active && resultSearchController.searchBar.text != ""{
                let selectedRow = (tableView.indexPathForSelectedRow?.row)!
                curNdx = findNdxInFullList(selectedRow)
                
                resultSearchController.active = false
                let path = NSIndexPath(forRow: curNdx, inSection: 0)
                tableView.selectRowAtIndexPath(path, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
            }
                
                
            else{
                
                curNdx = (tableView.indexPathForSelectedRow?.row)!
            }
            addSongToQueue(curNdx)
            
            
            
            //if download finished, initialize avplayer\
            let player : Player = segue.destinationViewController as! Player
            player.playlistDelegate = self
            player.player = playerQueue
            player.player?.play()
        }
        
        
    }
    
    func setupPlayerQueue(){
        playerQueue.removeAllItems()
        
        
        if resultSearchController.active && resultSearchController.searchBar.text != ""{
            let selectedRow = (tableView.indexPathForSelectedRow?.row)!
            curNdx = findNdxInFullList(selectedRow)
            
            resultSearchController.active = false
            let path = NSIndexPath(forRow: curNdx, inSection: 0)
            tableView.selectRowAtIndexPath(path, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        }
            
            
        else{
            
            curNdx = (tableView.indexPathForSelectedRow?.row)!
        }
        addSongToQueue(curNdx)
    }
    func addSongToQueue(index : Int) {
        if let curItem = playerQueue.currentItem{
            curItem.seekToTime(kCMTimeZero)
            playerQueue.advanceToNextItem()
        }
        
        let ndx = x[index]
        curSong = songs[ndx] as! NSObject
        let isDownloaded = songs[ndx].valueForKey("isDownloaded") as! Bool
        let identifier = songs[ndx].valueForKey("identifier") as! String
        
        if isDownloaded {
            
            let file = identifier.stringByAppendingString(".mp4")
            let filePath = (documentsDir as NSString).stringByAppendingPathComponent(file)
            let url = NSURL(fileURLWithPath: filePath)
            
            let playerItem = AVPlayerItem(URL: url)
            playerQueue.insertItem(playerItem, afterItem: nil)
        }
            
        else{
            let songRequest = NSFetchRequest(entityName: "Songs")
            songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
            let fetchedSongs : NSArray = try! context.executeFetchRequest(songRequest)
            let selectedSong = fetchedSongs[0] as! NSManagedObject
            
            let currentDate = NSDate()
            let expireDate = songs[ndx].valueForKey("expireDate") as! NSDate
            
            if currentDate.compare(expireDate) == NSComparisonResult.OrderedDescending { //update streamURL
                
                XCDYouTubeClient.defaultClient().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
                    if error == nil {
                        let streamURLs : NSDictionary = video!.valueForKey("streamURLs") as! NSDictionary
                        let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                        
                        selectedSong.setValue(video!.expirationDate, forKey: "expireDate")
                        selectedSong.setValue("\(desiredURL)", forKey: "streamURL")
                        
                       
                        do {
                            try self.context.save()
                        } catch _ as NSError{}
                        
                        let url = NSURL(string: selectedSong.valueForKey("streamURL") as! String)!
                        print(url)
                        let playerItem = AVPlayerItem(URL: url)
                        self.playerQueue.insertItem(playerItem, afterItem: nil)
                    }
                })
            }
                
            else {
                let url = NSURL(string: selectedSong.valueForKey("streamURL") as! String)!
                let playerItem = AVPlayerItem(URL: url)
                playerQueue.insertItem(playerItem, afterItem: nil)
            }
        }
    }
    
    var loopCount = 0
    var updater : NSTimer!
    func updateNowPlayingInfo(){
        loopCount++
        let curItem = playerQueue.currentItem
        let title = curSong.valueForKey("title") as! String
        let imageData = curSong.valueForKey("thumbnail") as! NSData
        let artworkImage = UIImage(data: imageData)
        let artwork = MPMediaItemArtwork(image: artworkImage!)
        
        let songInfo: Dictionary <NSObject, AnyObject> = [
            
            MPMediaItemPropertyTitle: title,
            
            MPMediaItemPropertyArtist:"",
            
            MPMediaItemPropertyArtwork: artwork,
            MPNowPlayingInfoPropertyPlaybackRate: "\(playerQueue.rate)",
            
            MPNowPlayingInfoPropertyElapsedPlaybackTime: CMTimeGetSeconds(curItem!.currentTime()),
            
            MPMediaItemPropertyPlaybackDuration: NSTimeInterval(CMTimeGetSeconds(curItem!.duration))
            
        ]
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = songInfo as? [String:AnyObject]

        
        if(loopCount > 12){
            if (updater != nil){
                updater.invalidate()
            }
            updater = nil
            loopCount = 0
        }
    }
    
      func togglePlayPause(){
        if (playerQueue.rate == 0){
            playerQueue.play()
        }
            
        else{
            playerQueue.pause()
        }
        
        
        if(updater == nil){
            updater = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateNowPlayingInfo", userInfo: nil, repeats: true)
        }
        
    }
    
    func seekForward(){
        playerQueue.rate = 3.0
    }
    
    func seekBackward(){
        playerQueue.rate = -3.0
    }
    
    func advance(){
        if curNdx == songs.count - 1 { curNdx = 0 }
        else{ curNdx++ }
        
        enableVidTracks()
        addSongToQueue(curNdx)
        
        //set lock screen info
        loopCount = 0
        if(updater == nil){
            updater = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateNowPlayingInfo", userInfo: nil, repeats: true)
        }
        togglePlayPause()
        togglePlayPause()
        
        let path = NSIndexPath(forRow: curNdx, inSection: 0)
        tableView.selectRowAtIndexPath(path, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        
        
        
        
    }
    func retreat(){
        if curNdx == 0 { curNdx = songs.count - 1 }
        else { curNdx-- }
        
        if (songs.count == 1) { advance() }
        else{
            enableVidTracks()
            addSongToQueue(curNdx)
            
            loopCount = 0
            if(updater == nil){
                updater = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateNowPlayingInfo", userInfo: nil, repeats: true)
            }
        }
        togglePlayPause()
        togglePlayPause()
        
        let path = NSIndexPath(forRow: curNdx, inSection: 0)
        tableView.selectRowAtIndexPath(path, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
    }
    
    func playerItemDidReachEnd(notification : NSNotification){
        enableVidTracks()
        
        if(playerQueue.rate > 0){
            togglePlayPause()
            togglePlayPause()
            advance()
        }
        else{
            togglePlayPause()
            togglePlayPause()
            retreat()
        }
    }
    
    //enable vidTracks
    func enteredForeground(notification: NSNotification){
        if playerQueue.currentItem != nil{
            enableVidTracks()
        }
    }
    //disable vidTracks
    func enteredBackground(notification: NSNotification){
        
        if playerQueue.currentItem != nil {
            videoTracks = playerQueue.currentItem!.tracks
            
            for track : AVPlayerItemTrack in videoTracks{
                
                if(!track.assetTrack.hasMediaCharacteristic("AVMediaCharacteristicAudible")){
                    track.enabled = false; // disable the track
                }
            }
        }
        if curSong != nil {
            loopCount = 0
            if(updater == nil){
            updater = NSTimer.scheduledTimerWithTimeInterval(0.125, target: self, selector: "updateNowPlayingInfo", userInfo: nil, repeats: true)
            }
        }
        
    }
    func enableVidTracks(){
        
        let curItem = playerQueue.currentItem
        if(curItem != nil){
        videoTracks = playerQueue.currentItem!.tracks
        for track : AVPlayerItemTrack in videoTracks{
            track.enabled = true; // enable the track
        }
        }
    }
}
