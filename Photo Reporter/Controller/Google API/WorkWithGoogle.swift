//
//  WorkWithGoogle.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/28/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import Foundation
import GTMSessionFetcher
import GoogleAPIClientForREST

class WorkWithGoogle: UIViewController {
    
    
    let photoStorage = PhotoPhoneStorage()
    lazy var photoVC = PhotosViewController()
    
    // MARK: - GET ALL FILES
    func getAllFiles(folderID: String, service: GTLRDriveService, completionHandler: @escaping (([String : String]) -> ())) {
        
        let root = "mimeType = 'image/jpeg' and trashed=false"
        let withName = "'\(folderID)'"
        let query = GTLRDriveQuery_FilesList.query()
        var result = [String : String]()
        query.corpora = "user"
        query.spaces = "drive"
        query.q = "\(withName) in parents and \(root)"
        service.executeQuery(query, completionHandler: {(ticket, files, error) in
            
            guard error == nil else {
                let myAlert = UIAlertController(title: "Alert!", message: error!.localizedDescription, preferredStyle: .alert)
                myAlert.show(self, sender: self)
                fatalError(error!.localizedDescription)
                
            }
            
            if let filesList : GTLRDrive_FileList = files as? GTLRDrive_FileList {
                if let filesShow : [GTLRDrive_File] = filesList.files {
                    
                    for i in filesShow {
                        result.updateValue(i.identifier!, forKey: i.name!.lowercased())
                    }
                    completionHandler(result)
                }
            }
        })
    }
    
    
    //  DOWNLOAD IMAGES FOR DISPLAY it in ImageView.image in cells!
    func downloadFile(listFileID: [String], listFileName: [String : String], downloadedFileList: [String], service: GTLRDriveService, completionHandler: @escaping ((Bool) -> ()))  {
        
        guard !listFileID.isEmpty else {completionHandler(true); return}
        
        var mutableDownloadedFileList = downloadedFileList
        var mutatedListFileID = listFileID
        
        let url = "https://www.googleapis.com/drive/v3/files/\(listFileID.last!)?alt=media"
        let fetcher = service.fetcherService.fetcher(withURLString: url)
        
        fetcher.beginFetch { (data, error) in
            guard error == nil else {
                let myAlert = UIAlertController(title: "Alert!", message: error!.localizedDescription, preferredStyle: .alert)
                myAlert.show(self, sender: self)
                fatalError(error!.localizedDescription)
            }
            
            if let image = UIImage(data: data!, scale: 0.1) {
                if let index = listFileName.values.firstIndex(of: listFileID.last!) {
                    let name = listFileName.keys[index]
                    
                    self.photoStorage.saveToDocuments(image: image, photoName: name.lowercased())
                }
                mutableDownloadedFileList.append(mutatedListFileID.removeLast())
                self.downloadFile(listFileID: mutatedListFileID, listFileName: listFileName, downloadedFileList: downloadedFileList, service: service, completionHandler: completionHandler)
                
            }
        }
    }
    
    
    // Delete file from GOOGLE DRIVE
    func deleteFile (
        fileID: String,
        service: GTLRDriveService, completionHandler: @escaping ((Bool) -> ())) {
        
        
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        
        service.executeQuery(query) { (ticket, any, error) in
            if let error = error {
                print(error.localizedDescription)
                completionHandler(false)
                
            }
            if let any = any {
                print(any)
                
            }
            if ticket.statusCode == 204 || ticket.statusCode == 200 {
                completionHandler(true)
            }
        }
        
    }
    
    
    //self.photoStorage.getDocumentsDirectory().appendingPathComponent()
    // MARK: - Function UPLOAD pictures on GOOGLE!
    func uploadFile(
        listFileNames: [String],
        folderID: String,
        filesURLs: [String],
        mimeType: String,
        service: GTLRDriveService, completionHandler: @escaping ((Bool) -> ())) {
        
        guard !listFileNames.isEmpty else {completionHandler(true); return}
        let queue = DispatchQueue.global(qos: .utility)
        var mutableListFileNames = listFileNames
        var mutableListURLs = filesURLs
        
        let file = GTLRDrive_File()
        file.name = listFileNames.last
        file.parents = [folderID]
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: self.photoStorage.getDocumentsDirectory().appendingPathComponent(mutableListURLs.last!), mimeType: mimeType)
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        //        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
        //            // This block is called multiple times during upload and can
        //            // be used to update a progress indicator visible to the user.
        //            let uploadProgress: Float = Float(totalBytesUploaded) / Float(totalBytesExpectedToUpload)
        //
        //
        //        }
        queue.async {
            
            service.executeQuery(query) { (_, result, error) in
                guard error == nil else {
                    let myAlert = UIAlertController(title: "Alert!", message: error!.localizedDescription, preferredStyle: .alert)
                    myAlert.show(self, sender: self)
                    fatalError(error!.localizedDescription)
                }
                
                // Successful upload if no error is returned.
                
                
                mutableListFileNames.removeLast()
                mutableListURLs.removeLast()
                
                self.uploadFile(listFileNames: mutableListFileNames, folderID: folderID, filesURLs: mutableListURLs, mimeType: mimeType, service: service, completionHandler: completionHandler)
                
                
                
            }
        }
    }
}



