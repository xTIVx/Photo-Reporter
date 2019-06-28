//
//  CustomTableViewCell.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/24/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    
    
    
    
    @IBOutlet weak var imagePhoto: UIImageView!
    @IBOutlet weak var namePhoto: UILabel!
    @IBOutlet weak var idPhoto: UILabel!
    @IBOutlet weak var uploadProgress: UIProgressView!
    @IBOutlet weak var uploadActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadActivityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        
        imagePhoto.image = nil
        namePhoto.text = nil
        idPhoto.text = nil
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
