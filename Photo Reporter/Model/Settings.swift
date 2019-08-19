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
    
    private init() {}
    
    var jobCode: String?
    var parentID : String?
    var installPhotosFolderID: String?
    var actualPhotoListfromGoogle: [String : String] = [:]
    var actualPhotoListFromStorage = [URL]()
    var staticPhotoList = ["base", "roof", "ladder", "Rail"] /*ONLY LOWERCASE!*/
    
    var arrayUploadQueue = [""]
    
   
}
