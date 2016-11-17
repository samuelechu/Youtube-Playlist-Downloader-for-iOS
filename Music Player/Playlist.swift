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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


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
    var playlistVCDelegate : PlaylistViewControllerDelegate!
    
    var context : NSManagedObjectContext!
    var songSortDescriptor = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
    
    var songs : NSArray!
    var documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
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
    override func viewWillAppear(_ animated: Bool) {
        
        
        setEditing(false, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
        definesPresentationContext = false
        resultSearchController.isActive = false
        definesPresentationContext = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDel = UIApplication.shared.delegate as! AppDelegate
        context = appDel.managedObjectContext
        
        NotificationCenter.default.addObserver(self, selector: #selector(Playlist.enteredBackground(_:)), name: NSNotification.Name(rawValue: "enteredBackgroundID"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Playlist.enteredForeground(_:)), name: NSNotification.Name(rawValue: "enteredForegroundID"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Playlist.updatePlaylist(_:)), name: NSNotification.Name(rawValue: "reloadPlaylistID"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Playlist.playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerQueue.currentItem)
        
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
        tableView.backgroundColor = UIColor.clear
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        //initialize shuffle, select, and delete buttons
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        editButtonItem.title = "Edit"
        deleteButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.gray], for: UIControlState.disabled)
        
        shuffleButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.gray], for: UIControlState.disabled)
        shuffleButton.tintColor = UIColor.gray
        
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
    
    func updatePlaylist(_ notification: Notification){
        updatePlaylist()
    }
    
    func updatePlaylist(){
        refreshPlaylist()
        resetX()
        shuffleButton.tintColor = UIColor.gray
    }
    
    //get songs from current playlist
    func getCurSongs() -> NSArray{
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        // request.sortDescriptors = [songSortDescriptor]
        request.predicate = NSPredicate(format: "playlistName = %@", playlistName!)
        
        let playlists = try? context.fetch(request) as NSArray
        if(playlists?.count >= 1){
            let playlist = (playlists![0] as AnyObject).value(forKey: "songs") as! NSSet
            let songsUnsorted = playlist.allObjects as NSArray
            return songsUnsorted.sortedArray(using: [songSortDescriptor]) as NSArray
        }
        return []
    }
    
    func refreshPlaylist(){
        if (playlistName != nil) {
            songs = getCurSongs()
            
            identifiers = []
            var playlistDuration = 0.0
            for song in songs{
                let identifier = (song as AnyObject).value(forKey: "identifier") as! String
                let duration = (song as AnyObject).value(forKey: "duration") as! Double
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
            for index in 0 ..< songs.count {
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
    
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        //return action == MenuAction.Copy.selector() || action == MenuAction.Custom.selector()
        return action == MenuAction.copyLink.selector() || action == MenuAction.saveVideo.selector() || action == MenuAction.redownloadVideo.selector()
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        //needs to be present for the menu to display
    }
    
    //populate tableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
        
        var songName : String!
        var duration : String!
        var identifier : String!
        var imageData : Data!
        
        if resultSearchController.isActive && resultSearchController.searchBar.text != "" {
            songName = (filteredSongs[indexPath.row] as AnyObject).value(forKey: "title") as! String
            duration = (filteredSongs[indexPath.row] as AnyObject).value(forKey: "durationStr") as! String
            identifier = (filteredSongs[indexPath.row] as AnyObject).value(forKey: "identifier") as! String
            imageData = (filteredSongs[indexPath.row] as AnyObject).value(forKey: "thumbnail") as! Data
        }
            
        else{
            let row = x[indexPath.row]
            songName = (songs[row] as AnyObject).value(forKey: "title") as! String
            duration = (songs[row] as AnyObject).value(forKey: "durationStr") as! String
            identifier = (songs[row] as AnyObject).value(forKey: "identifier") as! String
            imageData = (songs[row] as AnyObject).value(forKey: "thumbnail") as! Data
        }
        
        cell.songLabel.text = songName
        cell.durationLabel.text = duration
        cell.identifier = identifier
        cell.imageLabel.image = UIImage(data: imageData)
        cell.positionLabel.text = "\(indexPath.row + 1)"
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
        return cell
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if songs != nil{
            if resultSearchController.isActive && resultSearchController.searchBar.text != ""{
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
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
        
        if editing {
            shuffleButton.isEnabled = false
            deleteButton.isEnabled = false
            selectButton.title = "Select All"
            editButtonItem.title = "Cancel"
            navigationController!.isToolbarHidden = false
            if !resultSearchController.isActive {
                navigationController!.hidesBarsOnSwipe = true
            }
        }
            
        else {
            editButtonItem.title = "Edit"
            shuffleButton.isEnabled = true
            navigationController!.hidesBarsOnSwipe = false
            navigationController!.isToolbarHidden = true
        }
        
    }
    
    //called when selectButton on toolbar pressed, edits titles and state of buttons based on number of selected playlist items
    @IBAction func selectPressed() {
        
        if selectButton.title == "Select All"{
            for row in 0 ..< tableView.numberOfRows(inSection: 0) {
                let indexPath = IndexPath(row: row, section: 0)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
            }
            selectButton.title = "Select None"
            deleteButton.isEnabled = true
        }
            
        else{
            for row in 0 ..< tableView.numberOfRows(inSection: 0) {
                let indexPath = IndexPath(row: row, section: 0)
                tableView.deselectRow(at: indexPath, animated: true)
            }
            selectButton.title = "Select All"
            deleteButton.isEnabled = false
        }
        
    }
    
    //disable delete button when less than one item selected
    //function to setup segue to start AVPlayer
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing{
            deleteButton.isEnabled = true
        }
            
        else{//playlist cell selected
            
            
            setupPlayerQueue()
            if(playlistVCDelegate != nil){
                playlistVCDelegate.startPlayer()
                
            }
        }
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        let selectedRows = tableView.indexPathsForSelectedRows
        if selectedRows == nil {
            deleteButton.isEnabled = false
        }
    }
    
    
    //push WebView from PlayerVC
    @IBAction func pushWebView() {
        if(playlistVCDelegate != nil){
            playlistVCDelegate.pushWebView()
        }
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////
    ////////
    //////////
    ////////////
    //////////////
    ////////////////   Searchbar Functions
    
    
    func findNdxInFullList(_ ndxInSearchList : Int) -> Int{
        let identifier = (filteredSongs[ndxInSearchList] as AnyObject).value(forKey: "identifier") as! String
        let ndxIdentifiers = identifiers.index(of: identifier)!
        let ndxInFullList = x.index(of: ndxIdentifiers)!
        return ndxInFullList
    }
    func updateSearchResults(for searchController: UISearchController) {
        
        //in editing mode
        if !shuffleButton.isEnabled {
            setEditing(false, animated: true)
        }
        
        let curSongs = getCurSongs()
        let predicate = NSPredicate(format: "title CONTAINS[c] %@", searchController.searchBar.text!)
        filteredSongs = curSongs.filtered(using: predicate) as NSArray!
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
            shuffleButton.tintColor = UIColor.gray
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
        
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows as [IndexPath]?
        {
            var selectedRows : [Int] = []
            
            //if search active, find indexes of selected rows in the full shuffled playlist
            if resultSearchController.isActive && resultSearchController.searchBar.text != "" {
                
                for indexPath : IndexPath in selectedIndexPaths {
                    
                    var selectedRow = indexPath.row
                    let id = (filteredSongs[selectedRow] as AnyObject).value(forKey: "identifier") as! String
                    let ndxIdentifiers = identifiers.index(of: id)!
                    selectedRow = x.index(of: ndxIdentifiers)!
                    
                    selectedRows += [selectedRow]
                    let identifier = (songs[ndxIdentifiers] as AnyObject).value(forKey: "identifier") as! String
                    
                    SongManager.deleteSong(identifier, playlistName: playlistName!)
                }
                
                
            }
                
            else{
                for indexPath : IndexPath in selectedIndexPaths {
                    selectedRows += [indexPath.row]
                    let row = x[indexPath.row]
                    let identifier = (songs[row] as AnyObject).value(forKey: "identifier") as! String
                    
                    SongManager.deleteSong(identifier, playlistName: playlistName!)
                }
            }
            
            //horribly unreadable, but keeps shuffled songs in order after deletion
            let temp = x
            var selectedSongs : [Int] = []
            
            for num in selectedRows {
                selectedSongs += [x[num]]
            }
            
            var index = 0
            while index < x.count {
                if var _ = selectedSongs.index(of: x[index]) {
                    x.remove(at: index)
                    index -= 1
                }
                index += 1
            }
            
            var temp2 = x
            for num in temp {
                if x.index(of: num) == nil {
                    for index in 0 ..< x.count {
                        if x[index] > num {
                            temp2[index] -= 1
                        }
                    }
                }
            }
            x = temp2
            
            refreshPlaylist()
        }
        
        setEditing(false, animated: true)
        navigationController!.setNavigationBarHidden(false, animated: true)
        updateSearchResults(for: resultSearchController)
    }
    
    //disable shuffle and editbutton when swiping to delete
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        editButtonItem.isEnabled = false
        shuffleButton.isEnabled = false
    }
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        editButtonItem.isEnabled = true
        shuffleButton.isEnabled = true
    }
    
    //swipe to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            var row : Int!
            
            if resultSearchController.isActive && resultSearchController.searchBar.text != ""{
                let selectedRow = indexPath.row
                row = x[findNdxInFullList(selectedRow)]
                x.remove(at: row)
            }
                
            else{
                row = x[indexPath.row]
                x.remove(at: indexPath.row)
            }
            
            let identifier = (songs[row] as AnyObject).value(forKey: "identifier") as! String
            SongManager.deleteSong(identifier, playlistName: playlistName!)
            
            for index in 0 ..< x.count {
                if x[index] > row {
                    x[index] -= 1
                }
            }
            
            refreshPlaylist()
            editButtonItem.isEnabled = true
            updateSearchResults(for: resultSearchController)
            
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
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if !tableView.isEditing{
            setEditing(false, animated: true)
            return true
        }
        
        return false
    }
    
    func setupPlayerQueue(){
        playerQueue.removeAllItems()
        
        
        if resultSearchController.isActive && resultSearchController.searchBar.text != ""{
            let selectedRow = (tableView.indexPathForSelectedRow?.row)!
            curNdx = findNdxInFullList(selectedRow)
            
            resultSearchController.isActive = false
            let path = IndexPath(row: curNdx, section: 0)
            tableView.selectRow(at: path, animated: false, scrollPosition: UITableViewScrollPosition.middle)
        }
            
            
        else{
            
            curNdx = (tableView.indexPathForSelectedRow?.row)!
        }
        addSongToQueue(curNdx)
    }
    func addSongToQueue(_ index : Int) {
        if let curItem = playerQueue.currentItem{
            curItem.seek(to: kCMTimeZero)
            playerQueue.advanceToNextItem()
        }
        
        let ndx = x[index]
        curSong = songs[ndx] as! NSObject
        let isDownloaded = (songs[ndx] as AnyObject).value(forKey: "isDownloaded") as! Bool
        let identifier = (songs[ndx] as AnyObject).value(forKey: "identifier") as! String
        
        if isDownloaded {
            
            let filePath = MiscFuncs.grabFilePath("\(identifier).mp4")
            var url = URL(fileURLWithPath: filePath)
            
            if(!FileManager.default.fileExists(atPath: filePath)){
                url = URL(fileURLWithPath: MiscFuncs.grabFilePath("\(identifier).m4a"))
            }
            
            let playerItem = AVPlayerItem(url: url)
            playerQueue.insert(playerItem, after: nil)
        }
            
        else{
            let songRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Song")
            songRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
            let fetchedSongs : NSArray = try! context.fetch(songRequest) as NSArray
            let selectedSong = fetchedSongs[0] as! NSManagedObject
            
            let currentDate = Date()
            let expireDate = (songs[ndx] as AnyObject).value(forKey: "expireDate") as! Date
            
            if currentDate.compare(expireDate) == ComparisonResult.orderedDescending { //update streamURL
                
                XCDYouTubeClient.default().getVideoWithIdentifier(identifier, completionHandler: {(video, error) -> Void in
                    if error == nil {
                    //    let streamURLs : NSDictionary = video!.value(forKey: "streamURLs") as! NSDictionary
                    //    let desiredURL = (streamURLs[22] != nil ? streamURLs[22] : (streamURLs[18] != nil ? streamURLs[18] : streamURLs[36])) as! NSURL
                        
                        selectedSong.setValue(video!.expirationDate, forKey: "expireDate")
                       /* selectedSong.setValue("\(desiredURL)", forKey: "streamURL")
                        
                        
                        do {
                            try self.context.save()
                        } catch _ as NSError{}
                        
                        let url = NSURL(string: selectedSong.value(forKey: "streamURL") as! String)!
                        print(url)
                        let playerItem = AVPlayerItem(url: url as URL)
                        self.playerQueue.insert(playerItem, after: nil)*/
                    }
                })
            }
                
            else {
                /*let url = URL(string: selectedSong.value(forKey: "streamURL") as! String)!
                let playerItem = AVPlayerItem(url: url)
                playerQueue.insert(playerItem, after: nil)*/
            }
        }
    }
    
    var loopCount = 0
    var updater : Timer!
    func updateNowPlayingInfo(){
        loopCount += 1
        let curItem = playerQueue.currentItem
        if(curItem != nil){
            let title = curSong.value(forKey: "title") as! String
            let imageData = curSong.value(forKey: "thumbnail") as! Data
            let artworkImage = UIImage(data: imageData)
            let artwork = MPMediaItemArtwork(image: artworkImage!)
            
            let songInfo: Dictionary <NSObject, AnyObject> = [
                
                MPMediaItemPropertyTitle as NSObject: title as AnyObject,
                
                MPMediaItemPropertyArtist as NSObject:"" as AnyObject,
                
                MPMediaItemPropertyArtwork as NSObject: artwork,
                MPNowPlayingInfoPropertyPlaybackRate as NSObject: "\(playerQueue.rate)" as AnyObject,
                
                MPNowPlayingInfoPropertyElapsedPlaybackTime as NSObject: CMTimeGetSeconds(curItem!.currentTime()) as AnyObject,
                
                MPMediaItemPropertyPlaybackDuration as NSObject: TimeInterval(CMTimeGetSeconds(curItem!.duration)) as AnyObject
                
            ]
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo as? [String:AnyObject]
            
        }
        
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
            updater = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Playlist.updateNowPlayingInfo), userInfo: nil, repeats: true)
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
        else{ curNdx += 1 }
        
        enableVidTracks()
        addSongToQueue(curNdx)
        
        //set lock screen info
        loopCount = 0
        if(updater == nil){
            updater = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Playlist.updateNowPlayingInfo), userInfo: nil, repeats: true)
        }
        togglePlayPause()
        togglePlayPause()
        
        let path = IndexPath(row: curNdx, section: 0)
        tableView.selectRow(at: path, animated: false, scrollPosition: UITableViewScrollPosition.middle)
        
        
        
        
    }
    func retreat(){
        if curNdx == 0 { curNdx = songs.count - 1 }
        else { curNdx -= 1 }
        
        if (songs.count == 1) { advance() }
        else{
            enableVidTracks()
            addSongToQueue(curNdx)
            
            loopCount = 0
            if(updater == nil){
                updater = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Playlist.updateNowPlayingInfo), userInfo: nil, repeats: true)
            }
        }
        togglePlayPause()
        togglePlayPause()
        
        let path = IndexPath(row: curNdx, section: 0)
        tableView.selectRow(at: path, animated: false, scrollPosition: UITableViewScrollPosition.middle)
    }
    
    func playerItemDidReachEnd(_ notification : Notification){
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
    func enteredForeground(_ notification: Notification){
        if playerQueue.currentItem != nil{
            enableVidTracks()
        }
    }
    //disable vidTracks
    func enteredBackground(_ notification: Notification){
        
        if playerQueue.currentItem != nil {
            videoTracks = playerQueue.currentItem!.tracks
            
            for track : AVPlayerItemTrack in videoTracks{
                
                if(!track.assetTrack.hasMediaCharacteristic("AVMediaCharacteristicAudible")){
                    track.isEnabled = false; // disable the track
                }
            }
            
            //playback controls only work in 'playlists' tab
            tabBarController?.selectedIndex = 0
        }
        if curSong != nil {
            loopCount = 0
            if(updater == nil){
                updater = Timer.scheduledTimer(timeInterval: 0.125, target: self, selector: #selector(Playlist.updateNowPlayingInfo), userInfo: nil, repeats: true)
            }
        }
        
    }
    func enableVidTracks(){
        
        let curItem = playerQueue.currentItem
        if(curItem != nil){
            videoTracks = playerQueue.currentItem!.tracks
            for track : AVPlayerItemTrack in videoTracks{
                track.isEnabled = true; // enable the track
            }
        }
    }
    
    func stop(){
        playerQueue.pause()
        //prevent player from playing another song when different playlist opened
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerQueue.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "reloadPlaylistID"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "enteredBackgroundID"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "enteredForegroundID"), object: nil)
        if (updater != nil){
            updater.invalidate()
        }
        updater = nil
        loopCount = 0
    }
}
