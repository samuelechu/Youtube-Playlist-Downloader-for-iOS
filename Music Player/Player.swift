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
}

class Player: AVPlayerViewController {
    
    @IBOutlet var overlay: UIView!
    @IBOutlet var button: UIButton!
    
    
    var playlistDelegate : PlaylistDelegate? = nil
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
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
    
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        let rc = event.subtype
        
        switch rc {
        case .RemoteControlNextTrack:
            playlistDelegate?.advance()
        case .RemoteControlPreviousTrack:
            playlistDelegate?.retreat()
        default:break
        }
        
    }
    
    @IBAction func buttonPressed() {
        println("hi")
    }
    func bringButtonToFront(){
        //button.hidden = false
        println("hih")
        // view.bringSubviewToFront(overlay)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //overlay.frame = view.bounds
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
