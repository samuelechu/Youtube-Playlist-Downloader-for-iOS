//
//  PlaylistsTableViewController.swift
//  Music Player
//
//  Created by 岡本拓也 on 2016/01/02.
//  Copyright © 2016年 Sem. All rights reserved.
//

import UIKit
import CoreData

class PlaylistsTableViewController: UITableViewController {
    
    @IBAction func didTapAddButton(_ sender: AnyObject) {
        showTextFieldDialog("Add playlist", message: "", placeHolder: "Name", okButtonTitle: "Add", didTapOkButton: { title in
            self.addPlaylist(title!)
            self.refreshPlaylists()
        })
    }
    let database = Database.shared
    var playlists: [Playlist] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //set background image
        tableView.backgroundColor = UIColor.clear
        let imgView = UIImageView(image: UIImage(named: "pastel.jpg"))
        imgView.frame = tableView.frame
        tableView.backgroundView = imgView
        
        refreshPlaylists()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistCell")! as UITableViewCell
        cell.textLabel?.text = playlists[indexPath.row].playlistName
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlistName = playlists[indexPath.row].playlistName
        performSegue(withIdentifier: "PlaylistsToPlaylist", sender: playlistName)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "PlaylistsToPlaylist") {
            let playlistName = sender as! String
            let playlistVC = segue.destination as! PlaylistPlayerViewController
            playlistVC.playlistName = playlistName
        }
    }
    
    func addPlaylist(_ name: String){
        if(!SongManager.isPlaylist(name)){
            database.createPlaylist(named: name)
            database.save()
        }
        
    }
    
    func refreshPlaylists(){
        playlists = database.playlists(sorted: true)
        tableView.reloadData()
    }
    
    //swipe to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let playlist = playlists[indexPath.row]
            deletePlaylist(playlist)
            refreshPlaylists()
        }
    }
    
    //delete playlist and all songs in it
    func deletePlaylist(_ playlist: Playlist) {
        for songObj in playlist.songs ?? [] {
            let song = songObj as! Song
            SongManager.deleteSong(song.identifier!, playlistName: playlist.playlistName!)
        }
        
        database.delete(playlist)
        database.save()
    }
    
}
