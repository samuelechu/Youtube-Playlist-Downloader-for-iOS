//
//  PlaylistsTableViewController.swift
//  Music Player
//
//  Created by 岡本拓也 on 2016/01/02.
//  Copyright © 2016年 Sem. All rights reserved.
//

import UIKit
import SwiftFilePath
import CoreData

class PlaylistsTableViewController: UITableViewController {
    
    @IBAction func didTapAddButton(sender: AnyObject) {
        showTextFieldDialog("Add playlist", message: "", placeHolder: "Name", okButtonTitle: "Add", didTapOkButton: { title in
            self.addPlaylist(title!)
            self.refreshPlaylists()
        })
    }
    
    private var context : NSManagedObjectContext!
    private var appDel : AppDelegate?
    
    var playlists: NSArray!
    var playlistNames : [String] = []
    var playlistSortDescriptor  = NSSortDescriptor(key: "playlistName", ascending: true, selector: "caseInsensitiveCompare:")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDel = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDel!.managedObjectContext
        
        tableView.dataSource = self
        tableView.delegate = self
        playlists = PlaylistManager().getPlaylists()
        
        //set background image
        tableView.backgroundColor = UIColor.clearColor()
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        refreshPlaylists()
        
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistNames.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistCell")! as UITableViewCell
        cell.textLabel?.text = playlistNames[indexPath.row]
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playlistName = playlistNames[indexPath.row]
        performSegueWithIdentifier("PlaylistsToPlaylist", sender: playlistName)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PlaylistsToPlaylist") {
            let playlistName = sender as! String
            let playlistVC = (segue.destinationViewController as? PlaylistViewController)!
            playlistVC.playlistName = playlistName
        }
    }

    
    func addPlaylist(name: String){
        let newPlaylist = NSEntityDescription.insertNewObjectForEntityForName("Playlist", inManagedObjectContext: self.context)
        newPlaylist.setValue(name, forKey: "playlistName")
        
        do{
            try self.context.save()
        }catch _ as NSError{}

    }
    
    func refreshPlaylists(){
        playlistNames = []
        let request = NSFetchRequest(entityName: "Playlist")
        request.sortDescriptors = [playlistSortDescriptor]
        
        playlists = try? context.executeFetchRequest(request)
        for playlist in playlists{
            let playlistName = playlist.valueForKey("playlistName") as! String
            playlistNames += [playlistName]
        }
        
        tableView.reloadData()
    }


}




class PlaylistManager {

    let playlistDir = Path.documentsDir["playlists"]
    
    func getPlaylists() -> [String] {
        PlaylistManager().initPlaylistDirIfNotExist()
        if let contents = playlistDir.contents {
            var playlists: [String] = []
            contents.forEach { path in
                playlists.append(path.basename as String)
            }
            return playlists
        }
        else {
            return []
        }
    }
    
    func makeNewDirectory(directoryName: String) {
        playlistDir[directoryName].mkdir()
    }
    
    func initPlaylistDirIfNotExist() {
        if !playlistDir.exists {
            playlistDir.mkdir()
            ["Favorites", "Love", "Best", "Good"].forEach { title in
                playlistDir[title].mkdir()
            }
        }
    }
}