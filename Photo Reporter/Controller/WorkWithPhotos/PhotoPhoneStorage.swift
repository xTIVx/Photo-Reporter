//
//  PhotoPhoneStorage.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/29/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import Foundation
import UIKit

class PhotoPhoneStorage {
    
    
    
// Getting document directory for save images to temporary folder in documents
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
    
    func getFilesFromDocuments () -> [URL] {
        var imagesURL = [URL]()
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let docs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            imagesURL = docs.filter{ $0.pathExtension == "jpg" }
            imagesURL.append(contentsOf: docs.filter{ $0.pathExtension == "png" })
            print(documentsURL)
           // GETTING FILE NAMES! images.map{ $0.deletingPathExtension().lastPathComponent }
        } catch {
            print(error)
        }
        return imagesURL
    }
    
    // DELETE FILE FROM DOCUMENTS!
    func deleteFromTempFolder (fileName: String) {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(documentsUrl)
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            for fileURL in fileURLs {
                if fileURL.lastPathComponent == fileName {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
    }
    
    func checkFileExists (name: String) -> String? {
        let fileNameToDelete = name
        var filePath = ""
        
        // Find documents directory on device
        let dirs : [String] = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        
        if dirs.count > 0 {
            let dir = dirs[0] //documents directory
            filePath = dir.appendingFormat("/" + fileNameToDelete)
            
        } else {
            print("Could not find local directory to store file")
        }
        
        let fileManager = FileManager.default
        
        // Check if file exists
        if fileManager.fileExists(atPath: filePath) {
            
            return filePath
        } else {
            
            return nil
        }
    }
    
    func saveToDocuments(image: UIImage, photoName: String) {
        print(photoName, "00000000000000000000")
        if let data = image.jpegData(compressionQuality: 0.7) {
            let filename = self.getDocumentsDirectory().appendingPathComponent(photoName)
            try? data.write(to: filename)
        }
    }
    
    
}


