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
        imageLabel.contentMode = .scaleAspectFit
        imageLabel.clipsToBounds = true
    }
 
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @objc func redownloadVideoAction(_ sender:AnyObject?){
        UIPasteboard.general.string = "youtube.com/watch?v=\(identifier!)"
    }
    
    @objc func copyLinkAction(_ sender:AnyObject?){
        UIPasteboard.general.string = "youtube.com/watch?v=\(identifier!)"
    }
    
    @objc func saveToCameraRollAction(_ sender:AnyObject?){
        let filePath0 = MiscFuncs.grabFilePath(identifier + ".mp4")
        
        if(FileManager.default.fileExists(atPath: filePath0)){
            UISaveVideoAtPathToSavedPhotosAlbum(filePath0, nil, nil, nil)
        }
    }
}
