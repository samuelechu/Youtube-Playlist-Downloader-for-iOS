//
//  Player.swift
//  Music Player
//
//  Created by Sem on 7/23/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class Player: AVPlayerViewController {
    
    var playlistDelegate : PlaylistDelegate? = nil
     
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(Player.respondToSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(Player.respondToSwipeGesture(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        view.addGestureRecognizer(swipeLeft)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    //swipe left : go to next song, swipe right : go to previous song
    @objc func respondToSwipeGesture(_ gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                playlistDelegate?.retreat()
            case UISwipeGestureRecognizerDirection.left:
                playlistDelegate?.advance()
            default:
                break
            }
        }
    }
    
    //stop video
    func stop(){
        playlistDelegate?.stop()
    }
    
    //recieve input from earphone button clicks
    override func remoteControlReceived(with event: UIEvent?) {
        let rc = event!.subtype
        switch rc {
        case .remoteControlNextTrack:
            playlistDelegate?.advance()
        case .remoteControlPreviousTrack:
            playlistDelegate?.retreat()
        case .remoteControlPause:
            playlistDelegate?.togglePlayPause()
        case .remoteControlPlay:
            playlistDelegate?.togglePlayPause()
        case .remoteControlTogglePlayPause :
            playlistDelegate?.togglePlayPause()
        
        case .remoteControlBeginSeekingForward:
            playlistDelegate?.seekForward()
        case .remoteControlBeginSeekingBackward:
            playlistDelegate?.seekBackward()
        
        case .remoteControlEndSeekingBackward:
            playlistDelegate?.togglePlayPause()
            playlistDelegate?.togglePlayPause()
        case .remoteControlEndSeekingForward:
            playlistDelegate?.togglePlayPause()
            playlistDelegate?.togglePlayPause()
            
        default: break
        }
        
    }
}
