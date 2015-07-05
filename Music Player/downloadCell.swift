//
//  downloadCell.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit

class downloadCell: UITableViewCell {

    @IBOutlet var initializeIndicator: UIActivityIndicatorView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var downloadLabel: UILabel!
    
    @IBOutlet var progressBar: UIProgressView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
