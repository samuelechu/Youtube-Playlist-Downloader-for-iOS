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
    func advance()
    func retreat()
    func updateNowPlayingInfo()
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
        
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        view.addGestureRecognizer(swipeRight)
        
        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
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
    
    //recieve input from earphone button clicks
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        let rc = event.subtype
        
        switch rc {
        case .RemoteControlNextTrack:
            playlistDelegate?.advance()
        case .RemoteControlPreviousTrack:
            playlistDelegate?.retreat()
        default:
            MiscFuncs.delay(1.2){
                playlistDelegate?.updateNowPlayingInfo()
            }
            
        }
        
    }
}
