//
//  PlayerVC.swift
//  Music Player
//
//  Created by Samuel Chu on 1/3/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import UIKit

//the View Controller that contains the Player and Playlist
class PlaylistViewController: UIViewController, PlaylistViewControllerDelegate {
    
    @IBOutlet weak var container: UIView!
    var playlist: Playlist!
    var player : Player!
    var playlistName : String!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        stopVid = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        //allow swipe left to right to go back
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    //stop video play when navigating back to playlist list
    var stopVid : Bool!
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        if(self.isMovingFromParentViewController() || self.isBeingDismissed()){
            stopVid = true
        }
        self.navigationController?.navigationBarHidden = false
    }
    
    //stop video only when view popped
    override func viewDidDisappear(animated: Bool) {
        if (stopVid == true){
            player.stop()
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //initialize playlist container
        if(segue.identifier == "showPlaylist")
        {
            let navController = segue.destinationViewController as! UINavigationController
            playlist = navController.viewControllers[0] as! Playlist
            playlist.playlistName = playlistName
            playlist.playlistVCDelegate = self
            
        }
        
        //initialize avPlayer container
        else if(segue.identifier == "showPlayer"){
            player = segue.destinationViewController as! Player
        }
            
        //segue to Youtube WebView
        else if(segue.identifier == "playlistToSearchView"){
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
    }
    
    //initialize avPlayer
    func startPlayer(){
        if(player.playlistDelegate == nil){
            player.playlistDelegate = playlist
            player.player = playlist.playerQueue
        }
        player.becomeFirstResponder()
        player.player?.play()
    }
    
    //initialize Youtube WebView
    func pushWebView() {
        performSegueWithIdentifier("playlistToSearchView", sender: nil)
    }
    
}
