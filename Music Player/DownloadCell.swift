//
//  downloadCell.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadCell: UITableViewCell {
    
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var imageLabel: UIImageView!
    @IBOutlet var progressBar: UIProgressView!
     
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
