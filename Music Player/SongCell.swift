//
//  SongCell.swift
//  Music Player
//
//  Created by Sem on 8/2/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import QuartzCore

class SongCell: UITableViewCell {

    @IBOutlet var bgLabel: UIImageView!
    @IBOutlet var songLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var imageLabel: UIImageView!
    @IBOutlet var positionLabel: UILabel!
    var identifier : String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageLabel.contentMode = .ScaleAspectFit
        imageLabel.clipsToBounds = true
    }
 
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    } 

    func copyLinkAction(sender:AnyObject?){
        UIPasteboard.generalPasteboard().string = "youtube.com/watch?v=\(identifier)"
    }
    
    func saveToCameraRollAction(sender:AnyObject?){
        
        let filePath = MiscFuncs.grabFilePath("\(identifier).mp4")
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, nil, nil, nil)
    }
}
