//
//  PlayerVC.swift
//  Music Player
//
//  Created by Samuel Chu on 1/3/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import UIKit

//the View Controller that contains the Player and Playlist
class PlaylistPlayerViewController: UIViewController, PlaylistViewControllerDelegate {
    
    @IBOutlet weak var container: UIView!
    var playlist: PlaylistViewController!
    var player : Player!
    var playlistName : String!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        stopVid = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        //allow swipe left to right to go back
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    //stop video play when navigating back to playlist list
    var stopVid : Bool!
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        if(self.isMovingFromParentViewController || self.isBeingDismissed){
            stopVid = true
        }
        self.navigationController?.isNavigationBarHidden = false
    }
    
    //stop video only when view popped
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if (stopVid == true){
            player.stop()
            player.player = nil
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //initialize playlist container
        if(segue.identifier == "showPlaylist")
        {
            let navController = segue.destination as! UINavigationController
            playlist = navController.viewControllers[0] as! PlaylistViewController
            playlist.playlistName = playlistName
            playlist.playlistVCDelegate = self
            
        }
        
        //initialize avPlayer container
        else if(segue.identifier == "showPlayer"){
            player = segue.destination as! Player
        }
            
        //segue to Youtube WebView
        else if(segue.identifier == "playlistToSearchView"){
            let searchVC = (segue.destination as? SearchWebViewController)!
            if let appDel = UIApplication.shared.delegate as? AppDelegate {
                if let downloadTable = appDel.downloadTable {
                    if let playlistName = playlistName {
                        searchVC.setup(downloadTable, playlistName: playlistName)
                    }
                }
                else {
                    errorAlert("error", message: "couldn't get download table view object")
                }
            }
        }
    }
    
    //initialize avPlayer
    func startPlayer(){
        if(player.playlistDelegate == nil){
            //sets avplayercontainer's delegate as the playlist shown
            player.playlistDelegate = playlist
            player.player = playlist.playerQueue
        }
        player.becomeFirstResponder()
        player.player?.play()
    }
    
    //initialize Youtube WebView
    func pushWebView() {
        performSegue(withIdentifier: "playlistToSearchView", sender: nil)
    }
    
}
