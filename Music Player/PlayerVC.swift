//
//  PlayerVC.swift
//  Music Player
//
//  Created by Samuel Chu on 1/3/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import UIKit

class PlayerVC: UIViewController {
    
    @IBOutlet weak var container: UIView!
    var playlist: Playlist!
    var playlistName : String!
    var player : Player!
    
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        //allow swipe left to right to go back
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if( segue.identifier == "showPlaylist")
        {
            let navController = segue.destinationViewController as! UINavigationController
            playlist = navController.viewControllers[0] as! Playlist
            playlist.playlistName = playlistName
            playlist.playlistContainer = self
            
        }
            
        else if(segue.identifier == "showPlayer"){
            
            player = segue.destinationViewController as! Player
            
        }
    }
    
    func startPlayer(){
        if(player.playlistDelegate == nil){
            player.playlistDelegate = playlist
            player.player = playlist.playerQueue
        }
        player.player?.play()
        
    }
    
}
