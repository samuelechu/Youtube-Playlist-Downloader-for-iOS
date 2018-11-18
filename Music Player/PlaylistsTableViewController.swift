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
    let context = Database.shared.managedObjectContext
    
    var playlists: [NSManagedObject] = []
    var playlistNames : [String] = []
    var playlistSortDescriptor  = NSSortDescriptor(key: "playlistName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
    
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
        return playlistNames.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistCell")! as UITableViewCell
        cell.textLabel?.text = playlistNames[indexPath.row]
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlistName = playlistNames[indexPath.row]
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
            let newPlaylist = NSEntityDescription.insertNewObject(forEntityName: "Playlist", into: self.context)
            newPlaylist.setValue(name, forKey: "playlistName")
            
            do{
                try self.context.save()
            }catch _ as NSError{}
        }
        
    }
    
    func refreshPlaylists(){
        playlistNames = []
        let request = NSFetchRequest<NSManagedObject>(entityName: "Playlist")
        request.sortDescriptors = [playlistSortDescriptor]
        
        playlists = (try? context.fetch(request)) ?? []
        for playlist in playlists{
            let playlistName = (playlist as AnyObject).value(forKey: "playlistName") as! String
            playlistNames += [playlistName]
        }
        
        tableView.reloadData()
    }
    
    
    //swipe to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let row = indexPath.row
            let playlistName = (playlists[row] as AnyObject).value(forKey: "playlistName") as! String
            deletePlaylist(playlistName)
            refreshPlaylists()
        }
    }
    
    //delete playlist and all songs in it
    func deletePlaylist(_ playlistName : String){
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Playlist")
        request.predicate = NSPredicate(format: "playlistName = %@", playlistName)
        let fetchedPlaylists : NSArray = try! context.fetch(request) as NSArray
        let selectedPlaylist = fetchedPlaylists[0] as! NSManagedObject
        
        let songs = selectedPlaylist.value(forKey: "songs") as! NSSet
        
        var songIdentifiers : [String] = []
        for song in songs{
            let identifier = (song as AnyObject).value(forKey: "identifier") as! String
            songIdentifiers += [identifier]
        }
        
        for identifier in songIdentifiers{
            SongManager.deleteSong(identifier, playlistName: playlistName)
        }
        context.delete(selectedPlaylist)
        
        do {
            try context.save()
        } catch _ {
        }
    }
    
}
