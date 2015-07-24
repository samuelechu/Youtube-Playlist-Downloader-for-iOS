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

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "TEST"
        label.textColor = UIColor.whiteColor()
        label.sizeToFit()
        self.contentOverlayView.addSubview(label)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
