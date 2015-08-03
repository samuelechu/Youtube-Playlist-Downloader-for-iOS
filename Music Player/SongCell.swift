//
//  SongCell.swift
//  Music Player
//
//  Created by Sem on 8/2/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {

    @IBOutlet var songLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
