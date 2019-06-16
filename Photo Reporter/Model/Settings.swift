//
//  Settings.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/5/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import Foundation

final class Settings {
    
   static var shared = Settings()
    
    var jobCode: String?
    var parentID : String?
    var installPhotosFolderID: String?
    
    
    private init() {
        
    }
}
