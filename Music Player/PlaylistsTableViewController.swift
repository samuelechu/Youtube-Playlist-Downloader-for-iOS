//
//  PlaylistsTableViewController.swift
//  Music Player
//
//  Created by 岡本拓也 on 2016/01/02.
//  Copyright © 2016年 Sem. All rights reserved.
//

import UIKit
import SwiftFilePath

class PlaylistsTableViewController: UITableViewController {
    
    @IBAction func didTapAddButton(sender: AnyObject) {
        showTextFieldDialog("Add playlist", message: "please type title", placeHolder: "title", okButtonTitle: "Add", didTapOkButton: { titleOrNil in
            print("titleOrNil \(titleOrNil)")
            PlaylistManager().makeNewDirectory("muiaej")
        })
    }
    
    var playlists: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        PlaylistManager().initPlaylistDirIfNotExist()
        playlists = PlaylistManager().getPlaylists()
        
        //set background image
        tableView.backgroundColor = UIColor.clearColor()
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistCell")! as UITableViewCell
        cell.textLabel?.text = playlists[indexPath.row]
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playlistName = playlists[indexPath.row]
        performSegueWithIdentifier("PlaylistsToPlaylist", sender: playlistName)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "PlaylistsToPlaylist") {
            let playlistName = sender as! String
            let playlistVC = (segue.destinationViewController as? PlayerVC)!
            playlistVC.playlistName = playlistName
        }
    }
}



class PlaylistManager {

    let playlistDir = Path.documentsDir["playlists"]
    
    func getPlaylists() -> [String] {
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