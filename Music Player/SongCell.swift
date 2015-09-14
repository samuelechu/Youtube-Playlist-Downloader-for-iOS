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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageLabel.contentMode = .ScaleAspectFit
        imageLabel.clipsToBounds = true
    }
 
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    } 

    
}
