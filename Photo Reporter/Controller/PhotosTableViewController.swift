//
//  PhotosTableViewController.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/1/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

// TO-DO: 1) Когда есть загруженное и отображаемое фото и попытаться вставить новое изображение - оно тут же заменяется на синхронизированное с гугла! поправить в viewWillAppear

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import Photos
import Foundation
import GTMSessionFetcher

class PhotosTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    var imagePicker = UIImagePickerController()
    
    let defaults = UserDefaults.standard
    var appDelegate = AppDelegate.shared()
    var imageTransporter = UIImage()
    let googleDriveService = GTLRDriveService()
    var gUser = AppDelegate.shared().gUser
    var cell = UITableViewCell()
    var settings = Settings.shared
   
    
    
    @IBOutlet var photosTW: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let jcode = defaults.string(forKey: "jobCode"){
            let ac = UIAlertController(title: "Use last Job Code?", message: "Do you want to use \(jcode.uppercased())?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "No", style: .destructive))
            let yes = UIAlertAction(title: "Yes", style: .default) { (alert) in
                
                self.settings.installPhotosFolderID = self.defaults.string(forKey: "Install Photos ID")
                self.settings.jobCode = jcode
                self.navigationItem.title = jcode.uppercased()
                if let auth = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer() {
                    self.googleDriveService.authorizer = auth
                    self.getAllFiles(folderID: self.settings.installPhotosFolderID!, service: self.googleDriveService)
                    
                }
            }
            present(ac, animated: true)
            ac.addAction(yes)
        }
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = settings.jobCode?.uppercased()
        if self.settings.installPhotosFolderID != nil {
            if let auth = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer() {
            self.googleDriveService.authorizer = auth
            self.getAllFiles(folderID: self.settings.installPhotosFolderID!, service: self.googleDriveService)
            }
        }
        
    }
    
    
    func getAllFiles(folderID: String, service: GTLRDriveService) {
        
        let root = "mimeType = 'image/jpeg' and trashed=false"
        let withName = "'\(folderID)'"
        let query = GTLRDriveQuery_FilesList.query()
        
        query.corpora = "user"
        query.spaces = "drive"
        query.q = "\(withName) in parents and \(root)"
        service.executeQuery(query, completionHandler: {(ticket, files, error) in

            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let filesList : GTLRDrive_FileList = files as? GTLRDrive_FileList {
                if let filesShow : [GTLRDrive_File] = filesList.files {
                    
                    for i in self.tableView.visibleCells {
                        
                        for name in filesShow {
                            if name.name == i.textLabel?.text {
                                print(name)
                                i.detailTextLabel?.text = name.identifier
                                i.accessoryType = .checkmark
                                self.downloadFile(fileID: name.identifier!, service: self.googleDriveService, cell: i)
                                
                                continue
                            }
                            
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        })
        
    }
    
   
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell = super.tableView(tableView, cellForRowAt: indexPath) as UITableViewCell
        cell.detailTextLabel?.isHidden = true
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // customize cell "ADD MORE..."
        if tableView.cellForRow(at: indexPath)?.reuseIdentifier == "addmore" {
            return
        }
        
        let alertController = UIAlertController(title: "Photo Selection", message: "", preferredStyle: .actionSheet)
        DispatchQueue.main.async {
            let a1Camera = UIAlertAction(title: "Camera", style: .default) { (alert) in
                
                self.imagePicker.sourceType = .camera
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
                self.cell = tableView.cellForRow(at: indexPath)!
                tableView.deselectRow(at: indexPath, animated: true)
            }
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.rear) {
                alertController.addAction(a1Camera)
            }
            let a2Photo = UIAlertAction(title: "Select From Library", style: .default) { (alert) in
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
                self.cell = tableView.cellForRow(at: indexPath)!
            }
            alertController.addAction(a2Photo)
            
            if tableView.cellForRow(at: indexPath)!.imageView?.image != nil || tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark {
                let a3Delete = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
                        
                    self.deleteFile(cell: tableView.cellForRow(at: indexPath)!, fileID: tableView.cellForRow(at: indexPath)!.detailTextLabel!.text!, service: self.googleDriveService)
                    
                    
                }
                alertController.addAction(a3Delete)
            }
            let a4Cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
                
            }
            alertController.addAction(a4Cancel)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
        //self.cell = tableView.cellForRow(at: indexPath)!
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Saving image to temporary folder in documents for upload on google and after - delete
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if let data = image.jpegData(compressionQuality: 0.8) {
                let filename = getDocumentsDirectory().appendingPathComponent("\(cell.textLabel!.text!).png")
                try? data.write(to: filename)
                print(getDocumentsDirectory())
            }
        }
        cell.imageView?.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        dismiss(animated:true, completion: nil)
        tableView.reloadData()
    }
    
    @IBAction func syncButtonPressed(_ sender: UIBarButtonItem) {
        
        guard settings.jobCode != nil else {
            let ac = UIAlertController(title: "Enter Job Code!", message: "Go back to Settings and fill in the field \"Job Code\".", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true); return
        }
        
        
        if let auth = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer() {
            self.googleDriveService.authorizer = auth
            self.getAllFiles(folderID: self.settings.installPhotosFolderID!, service: self.googleDriveService)
        }
        
        let cells = self.tableView.visibleCells as Array<UITableViewCell>
            
            // Uploading to GOOGLE!
        
        
            for i in cells {
                if i.reuseIdentifier == "addmore" {
                    continue
                }
                if let label = i.textLabel?.text {
                    
                    // MARK: - PROBLEM HERE!!
                    
                    if checkFileExists(name: "\(label).png") {
                    
                    if i.accessoryType != .checkmark {
                        
                        self.googleDriveService.authorizer = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
                        
                            self.uploadFile(cell: i, name: label, folderID: self.settings.installPhotosFolderID!, fileURL: self.getDocumentsDirectory().appendingPathComponent("\(label).png"), mimeType: "image/png", cellLabel: label, service: self.googleDriveService)
                     
                    }
                    }
                    
                }
            }
            tableView.reloadData()
        
            // Checking Album, if not - create new!
            
            if let _ = PHPhotoLibrary.shared().findAlbum(albumName: settings.jobCode!) {
                
                let cells = self.tableView.visibleCells as Array<UITableViewCell>
                
                for i in cells {
                    if i.imageView?.image != nil {
                        PHPhotoLibrary.shared().savePhoto(image: i.imageView!.image!, albumName: settings.jobCode!)
                    }
                }
                 return
            }
            else {
                PHPhotoLibrary.shared().createAlbum(albumName: settings.jobCode!) { (success) in
                    
                    if (success != nil) {
                        DispatchQueue.main.async {
                            for i in cells {
                                if i.reuseIdentifier != "addmore" && i.imageView?.image != nil{
                                    PHPhotoLibrary.shared().savePhoto(image: i.imageView!.image!, albumName: self.settings.jobCode!)
                                }
                            }
                        }
                        let ac = UIAlertController(title: "Album created and photos inside!", message: "", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true); return
                    }
                }
            }
            
        
    }
    
    @IBAction func addMoreButton(_ sender: UIButton) {
        
        
        
        }
    // Getting document directory for save images to temporary folder in documents
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - Function upload pictures on google!
    func uploadFile(
        cell: UITableViewCell,
        name: String,
        folderID: String,
        fileURL: URL,
        mimeType: String,
        cellLabel: String,
        service: GTLRDriveService) {
        
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
       
        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
            // This block is called multiple times during upload and can
            // be used to update a progress indicator visible to the user.
        }
        
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            // Successful upload if no error is returned.
            
            let folderList = result as! GTLRDrive_File
            cell.detailTextLabel?.text = folderList.identifier
            self.deleteFromTempFolder(fileName: cellLabel)
            cell.accessoryType = .checkmark
            
  
        }
    }
    
 //  DOWNLOAD IMAGES FOR DISPLAY it in ImageView.image in cells!
    func downloadFile(fileID: String, service: GTLRDriveService, cell: UITableViewCell) {
    let url = "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media"
        
        let fetcher = service.fetcherService.fetcher(withURLString: url)
    
        fetcher.beginFetch { (data, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let image = UIImage(data: data!, scale: 0.1) {
            cell.imageView?.image = image
                self.tableView.reloadData()
            }
        }
        
    }
    
    // Delete file from GOOGLE DRIVE
    func deleteFile (
        cell: UITableViewCell,
        fileID: String,
        service: GTLRDriveService) {
       
        
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        
        service.executeQuery(query) { (ticket, any, error) in
            if let error = error {
                print(error.localizedDescription)
                
            }
            if let any = any {
                print(any)
                
            }
            if ticket.statusCode == 204 {
                cell.imageView?.image = nil
                cell.accessoryType = .none
                self.tableView.reloadData()
            }
        }
        
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
                if fileURL.lastPathComponent == "\(fileName).png" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
    }
    
    func checkFileExists (name: String) -> Bool {
        let fileNameToDelete = name
        var filePath = ""
        
        // Fine documents directory on device
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
            
            return true
        } else {
            
            return false
        }
    }
    
    
    
    
}




extension PHPhotoLibrary {
    // MARK: - PHPhotoLibrary+SaveImage
    
    func savePhoto(image:UIImage, albumName:String, completion:((PHAsset?)->())? = nil) {
        func save() {
            if let album = PHPhotoLibrary.shared().findAlbum(albumName: albumName) {
                PHPhotoLibrary.shared().saveImage(image: image, album: album, completion: completion)
            } else {
                PHPhotoLibrary.shared().createAlbum(albumName: albumName, completion: { (collection) in
                    if let collection = collection {
                        PHPhotoLibrary.shared().saveImage(image: image, album: collection, completion: completion)
                    } else {
                        completion?(nil)
                    }
                })
            }
        }
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            save()
        } else {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    save()
                }
            })
        }
    }
    
    // MARK: - Private
    
    fileprivate func findAlbum(albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let fetchResult : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else {
            return nil
        }
        return photoAlbum
    }
    
    fileprivate func createAlbum(albumName: String, completion: @escaping (PHAssetCollection?)->()) {
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if success {
                guard let placeholder = albumPlaceholder else {
                    completion(nil)
                    return
                }
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album = fetchResult.firstObject else {
                    completion(nil)
                    return
                }
                completion(album)
            } else {
                completion(nil)
            }
        })
    }
    
    fileprivate func saveImage(image: UIImage, album: PHAssetCollection, completion:((PHAsset?)->())? = nil) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                let photoPlaceholder = createAssetRequest.placeholderForCreatedAsset else { return }
            placeholder = photoPlaceholder
            let fastEnumeration = NSArray(array: [photoPlaceholder] as [PHObjectPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
        }, completionHandler: { success, error in
            guard let placeholder = placeholder else {
                completion?(nil)
                return
            }
            if success {
                let assets:PHFetchResult<PHAsset> =  PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                let asset:PHAsset? = assets.firstObject
                completion?(asset)
            } else {
                completion?(nil)
            }
        })
    }
}


extension UIImage {
    convenience init?(url: URL?) {
        guard let url = url else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            self.init(data: data)
        } catch {
            print("Cannot load image from url: \(url) with error: \(error)")
            return nil
        }
    }
}



// Func for add action to ImageView

//class ViewController: UIViewController {
//
//    @IBOutlet weak var imageView: UIImageView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // create tap gesture recognizer
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.imageTapped(gesture:)))
//
//        // add it to the image view;
//        imageView.addGestureRecognizer(tapGesture)
//        // make sure imageView can be interacted with by user
//        imageView.isUserInteractionEnabled = true
//    }
//
//    @objc func imageTapped(gesture: UIGestureRecognizer) {
//        // if the tapped view is a UIImageView then set it to imageview
//        if (gesture.view as? UIImageView) != nil {
//            print("Image Tapped")
//            //Here you can initiate your new ViewController
//
//        }
//    }
//}




 //let query2 = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
