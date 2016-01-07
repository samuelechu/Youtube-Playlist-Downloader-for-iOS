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


protocol PlaylistDelegate{
    func seekForward()
    func seekBackward()
    func togglePlayPause()
    func advance()
    func retreat()
    func updateNowPlayingInfo()
    func stop()
}

class Player: AVPlayerViewController {
    
    var playlistDelegate : PlaylistDelegate? = nil
     
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        view.addGestureRecognizer(swipeLeft)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    //swipe left : go to next song, swipe right : go to previous song
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                playlistDelegate?.retreat()
            case UISwipeGestureRecognizerDirection.Left:
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
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        let rc = event!.subtype
        switch rc {
        case .RemoteControlNextTrack:
            playlistDelegate?.advance()
        case .RemoteControlPreviousTrack:
            playlistDelegate?.retreat()
        case .RemoteControlPause:
            playlistDelegate?.togglePlayPause()
        case .RemoteControlPlay:
            playlistDelegate?.togglePlayPause()
        case .RemoteControlTogglePlayPause :
            playlistDelegate?.togglePlayPause()
        
        case .RemoteControlBeginSeekingForward:
            playlistDelegate?.seekForward()
        case .RemoteControlBeginSeekingBackward:
            playlistDelegate?.seekBackward()
        
        case .RemoteControlEndSeekingBackward:
            playlistDelegate?.togglePlayPause()
            playlistDelegate?.togglePlayPause()
        case .RemoteControlEndSeekingForward:
            playlistDelegate?.togglePlayPause()
            playlistDelegate?.togglePlayPause()
            
        default: break
        }
        
    }
}
