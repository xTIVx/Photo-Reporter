//
//  imagePreviewViewController.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 7/9/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import UIKit

class imagePreviewViewController: UIViewController {

    var transferedImage: UIImage?
    var transferedImageTitle: String?
    
    @IBOutlet weak var image: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.image.image = transferedImage
        navigationItem.title = self.transferedImageTitle
        
    }
}
