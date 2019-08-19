//
//  Sync.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 7/6/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import UIKit
import Photos

final class SyncFunctional {
    
    
    let workWithGoogle = WorkWithGoogle()
    var settings = Settings.shared
    let googleDriveService = GTLRDriveService()
    var downloadedFileList: [String] = []
    let photoStorage = PhotoPhoneStorage()
    let photoVC = PhotosViewController()
    
    func start(folderID: String, service: GTLRDriveService, completionHandlerStart: @escaping ((Bool) -> ())) {
        self.googleDriveService.authorizer = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer()
        self.workWithGoogle.getAllFiles(folderID: folderID, service: service){ (value) in
            // Adding to photo list all files from Google
            value.forEach { (k,v) in self.settings.actualPhotoListfromGoogle[k] = v }
           
            
            var willDownloadFileList = self.settings.actualPhotoListfromGoogle
            
            
            let actualPhotosFromStorage = self.photoStorage.getFilesFromDocuments()
            let namesFromStorage = actualPhotosFromStorage.map{ $0.lastPathComponent }
            var differenceBetweenStorages = actualPhotosFromStorage.map{ $0.lastPathComponent }
            
            for element in self.settings.actualPhotoListfromGoogle.keys {
                if namesFromStorage.contains(element) {
                    willDownloadFileList.removeValue(forKey: element)
                }
            }
            
            self.workWithGoogle.downloadFile(listFileID: Array(willDownloadFileList.values), listFileName: value, downloadedFileList: self.downloadedFileList, service: service, completionHandler: { (result) in
                
                for i in namesFromStorage {
                    if self.settings.actualPhotoListfromGoogle.keys.contains(i) {
                        if let index = differenceBetweenStorages.firstIndex(of: i) {
                            differenceBetweenStorages.remove(at: index)
                        }
                    }
                }
                result ? print("GOOD DOWNLOAD!!!") : print("FALSE DOWNLOAD!")
                
                self.workWithGoogle.uploadFile(
                    listFileNames: differenceBetweenStorages,
                    folderID: self.settings.installPhotosFolderID!,
                    filesURLs: differenceBetweenStorages,
                    mimeType: "image/png", service: self.googleDriveService,
                    completionHandler: { (result) in
                        result ? print("GOOD UPLOAD!!!") : print("FALSE UPLOAD!")
                        
                        if differenceBetweenStorages.count > 0{
                            self.start(folderID: folderID, service: service, completionHandlerStart: completionHandlerStart)
                        } else {
                            
//                            // Checking Album, if not - create new!
//                            if let _ = PHPhotoLibrary.shared().findAlbum(albumName: self.settings.jobCode!) {
//
//                                for photo in actualPhotosFromStorage {
//                                    PHPhotoLibrary.shared().savePhoto(image: UIImage(url: photo)!, albumName: self.settings.jobCode!)
//                                }
//                                return
//                            }
//                            else {
//
//                                PHPhotoLibrary.shared().createAlbum(albumName: self.settings.jobCode!) { (success) in
//
//                                    if (success != nil) {
//                                        DispatchQueue.main.async {
//                                            for photo in actualPhotosFromStorage {
//                                                PHPhotoLibrary.shared().savePhoto(image: UIImage(url: photo)!, albumName: self.settings.jobCode!)
//                                            }
//                                        }
//                                        return
//                                    }
//                                }
//                            }
                            let ac = UIAlertController(title: "Sync is Done!", message: "", preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            UIApplication.shared.delegate?.window??.rootViewController?.present(ac, animated: true, completion: nil)
                        }
                })
                
                completionHandlerStart(true)
                
            })
            
        }
        
        
        
    }
    
    
    
}

