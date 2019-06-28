//
//  PhotosTableViewController.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/1/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//


// TO-DO: 2) При синхронизации проверять наличие папки Install Photos!!!!!
// TO-DO: 3) Сделать очередь на загрузку
// TO-DO: 4) Сделать кнопку "добавить ячейку"
// To-DO: 5) Serach Bar
// TODO 6) Сделать фото в большом размере ПРОСМОТР
// TODO 7) Если быстро начать удалять изображения - приложение крашится
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
    let googleDriveService = GTLRDriveService()
    var cellTW = CustomTableViewCell()
    var settings = Settings.shared
    
    
    
    @IBOutlet var photosTW: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        
        
        
        
        if let jcode = defaults.string(forKey: "jobCode"){
            let ac = UIAlertController(title: "Use last Job Code?", message: "Do you want to use \(jcode.uppercased())?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "No", style: .destructive))
            let yes = UIAlertAction(title: "Yes", style: .default) { (alert) in
                
                self.settings.installPhotosFolderID = self.defaults.string(forKey: "Install Photos ID")
                if let queue = self.defaults.array(forKey: "queue") as? [String] {
                    print("ПРОВЕРКА ПОЛЯ!!!!!\(queue)")
                    self.settings.arrayUploadQueue = queue
                    for r in self.settings.arrayUploadQueue {
                        if !self.settings.photoList.contains(r) {
                            self.settings.photoList.append(r)
                        }
                    }
                    self.tableView.reloadData()
                }
                
                self.settings.jobCode = jcode
                self.navigationItem.title = jcode.uppercased()
                if let auth = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer() {
                    self.googleDriveService.authorizer = auth
                    for i in self.tableView.visibleCells as! [CustomTableViewCell] {
                        for f in self.settings.arrayUploadQueue {
                            if i.namePhoto?.text == f {
                            self.uploadFile(cell: i, name: f, folderID: self.settings.installPhotosFolderID!, fileURL: self.getDocumentsDirectory().appendingPathComponent("\(f).png"), mimeType: "image/png", service: self.googleDriveService)
                                
                            }
                        }
                    }
                    
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
    
    // MARK: - GET ALL FILES
    func getAllFiles(folderID: String, service: GTLRDriveService) {
        
        let root = "mimeType = 'image/jpeg' and trashed=false"
        let withName = "'\(folderID)'"
        let query = GTLRDriveQuery_FilesList.query()
        
        for f in tableView.visibleCells as! [CustomTableViewCell]{
        f.accessoryType = .none
        }
        
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
                    for f in filesShow {
                        if !self.settings.photoList.contains(f.name!) {
                            self.settings.photoList.append(f.name!)
                            print(self.settings.photoList)
                        }
                    }
                    self.tableView.reloadData()
                    
                    for i in self.tableView.visibleCells as! [CustomTableViewCell] {
                       
                        
                        for name in filesShow {
                            if name.name == i.namePhoto?.text {
                                i.downloadActivityIndicator.isHidden = false
                                i.downloadActivityIndicator.startAnimating()
                                i.idPhoto?.text = name.identifier
                                i.accessoryType = .checkmark
                                self.downloadFile(fileID: name.identifier!, service: self.googleDriveService, cell: i)
                                self.tableView.reloadData()
                                continue
                            }
                        }
                    }
                    self.tableView.reloadData()
                   
                }
            }
        })
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.photoList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "photosTW", for: indexPath) as! CustomTableViewCell
        cell.idPhoto?.isHidden = true
        cell.namePhoto?.text = nil
        cell.namePhoto?.text = settings.photoList[indexPath.row]
        
        cell.uploadProgress.isHidden = true
        cell.uploadActivityIndicator.isHidden = true
        cell.downloadActivityIndicator.isHidden = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.cellTW = tableView.cellForRow(at: indexPath)! as! CustomTableViewCell
        
        let alertController = UIAlertController(title: "Photo Selection", message: "", preferredStyle: .actionSheet)
        DispatchQueue.main.async {
            let a1Camera = UIAlertAction(title: "Camera", style: .default) { (alert) in
                
                self.imagePicker.sourceType = .camera
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.rear) && self.cellTW.imagePhoto?.image == nil{
                alertController.addAction(a1Camera)
            }
            let a2Photo = UIAlertAction(title: "Select From Library", style: .default) { (alert) in
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
                
                
            }
            if self.cellTW.imagePhoto.image == nil {
            alertController.addAction(a2Photo)
            }
            if self.cellTW.imagePhoto.image != nil || self.cellTW.accessoryType == .checkmark {
                let a3Delete = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
                        
                    self.deleteFile(cell: self.cellTW, fileID: self.cellTW.idPhoto.text!, service: self.googleDriveService)
                    
                    
                }
                alertController.addAction(a3Delete)
            }
            let a4Cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
                
            }
            alertController.addAction(a4Cancel)
            
            self.present(alertController, animated: true, completion: nil)
            
        }
       
       
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Saving image to temporary folder in documents for upload on google and after - delete
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if let data = image.jpegData(compressionQuality: 0.7) {
                let filename = getDocumentsDirectory().appendingPathComponent("\(cellTW.namePhoto.text!).png")
                try? data.write(to: filename)
                print(getDocumentsDirectory())
            }
        }
        
         cellTW.imagePhoto.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            
           
        
        
        tableView.reloadData()
        dismiss(animated:true, completion: nil)
        
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
        
        let cells = self.tableView.visibleCells as! [CustomTableViewCell]
            
        // MARK: - Uploading to GOOGLE!
        
        
            for i in cells {
                
                if let label = i.namePhoto?.text {
                    
                    if checkFileExists(name: "\(label).png") && i.accessoryType != .checkmark && i.imagePhoto.image != nil && !settings.arrayUploadQueue.contains(label) {
                        
                        self.settings.arrayUploadQueue.append(label)
                        print("AAAAAAAADDD \(self.settings.arrayUploadQueue)")
                        
                        
                    }
                }
            }
        
        self.googleDriveService.authorizer = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
        for i in cells {
            if let label = i.namePhoto?.text {
                
                if checkFileExists(name: "\(label).png") && i.accessoryType != .checkmark && i.imagePhoto.image != nil && settings.arrayUploadQueue.contains(label) {
                    
                    for f in self.settings.arrayUploadQueue {
                        if f == label {
            self.uploadFile(cell: i, name: label, folderID: self.settings.installPhotosFolderID!, fileURL: self.getDocumentsDirectory().appendingPathComponent("\(label).png"), mimeType: "image/png", service: self.googleDriveService)
                            
                        }
                    }
                }
            }
        }
        if !settings.arrayUploadQueue.isEmpty {
                defaults.set(settings.arrayUploadQueue, forKey: "queue")
        }

        
            tableView.reloadData()
        
            // Checking Album, if not - create new!
            
            if let _ = PHPhotoLibrary.shared().findAlbum(albumName: settings.jobCode!) {
                
                let cells = self.tableView.visibleCells as! [CustomTableViewCell]
                
                for i in cells {
                    if i.imagePhoto.image != nil {
                        PHPhotoLibrary.shared().savePhoto(image: i.imagePhoto.image!, albumName: settings.jobCode!)
                    }
                }
                 return
            }
            else {
                PHPhotoLibrary.shared().createAlbum(albumName: settings.jobCode!) { (success) in
                    
                    if (success != nil) {
                        DispatchQueue.main.async {
                            for i in cells {
                                if i.imagePhoto.image != nil{
                                    PHPhotoLibrary.shared().savePhoto(image: i.imagePhoto.image!, albumName: self.settings.jobCode!)
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
    
    
    // Getting document directory for save images to temporary folder in documents
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - Function UPLOAD pictures on GOOGLE!
    func uploadFile(
        cell: UITableViewCell,
        name: String,
        folderID: String,
        fileURL: URL,
        mimeType: String,
        service: GTLRDriveService) {
        
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        // Optionally, GTLRUploadParameters can also be created with a Data object.
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        let cellw = cell as! CustomTableViewCell
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
       
        service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
            
            // This block is called multiple times during upload and can
            // be used to update a progress indicator visible to the user.
            let uploadProgress: Float = Float(totalBytesUploaded) / Float(totalBytesExpectedToUpload)
            cellw.uploadActivityIndicator.isHidden = false
            cellw.uploadProgress.isHidden = false
            cellw.uploadActivityIndicator.startAnimating()
            cellw.uploadProgress.progress = uploadProgress

        }
        
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                let myAlert = UIAlertController(title: "Alert!", message: error!.localizedDescription, preferredStyle: .alert)
                myAlert.show(self, sender: self)
                fatalError(error!.localizedDescription)
            }
            
            // Successful upload if no error is returned.
            
            let folderList = result as! GTLRDrive_File
            cellw.idPhoto?.text = folderList.identifier
            cellw.accessoryType = .checkmark
            self.deleteFromTempFolder(fileName: name)
            self.settings.arrayUploadQueue.removeLast()
            self.defaults.set(self.settings.arrayUploadQueue, forKey: "queue")
            self.getAllFiles(folderID: self.settings.installPhotosFolderID!, service: self.googleDriveService)
            self.tableView.reloadData()
            print("FINISH \(self.settings.arrayUploadQueue)")
        }
    }
    
 //  DOWNLOAD IMAGES FOR DISPLAY it in ImageView.image in cells!
    func downloadFile(fileID: String, service: GTLRDriveService, cell: UITableViewCell) {
        let cellw = cell as! CustomTableViewCell
        let url = "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media"
        
        let fetcher = service.fetcherService.fetcher(withURLString: url)
        
        fetcher.beginFetch { (data, error) in
            guard error == nil else {
                let myAlert = UIAlertController(title: "Alert!", message: error!.localizedDescription, preferredStyle: .alert)
                myAlert.show(self, sender: self)
                fatalError(error!.localizedDescription)
                print(error?.localizedDescription)
            }
            
            
            if let image = UIImage(data: data!, scale: 0.1) {
                cellw.downloadActivityIndicator.isHidden = true
                cellw.downloadActivityIndicator.stopAnimating()
                cellw.imagePhoto?.image = image
                self.tableView.reloadData()
            }
        }
        
    }
    
    // Delete file from GOOGLE DRIVE
    func deleteFile (
        cell: UITableViewCell,
        fileID: String,
        service: GTLRDriveService) {
       
        let cellw = cell as! CustomTableViewCell
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        
        service.executeQuery(query) { (ticket, any, error) in
            if let error = error {
                print(error.localizedDescription)
                
            }
            if let any = any {
                print(any)
                
            }
            if ticket.statusCode == 204 {
                cellw.imagePhoto?.image = nil
                cellw.accessoryType = .none
                cellw.idPhoto?.text = nil
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
            
            return true
        } else {
            
            return false
        }
    }

    var counter = 1
    @IBAction func addNewPhoto(_ sender: UIButton) {
        guard settings.jobCode != nil else {
            let ac = UIAlertController(title: "Enter Job Code!", message: "Go back to Settings and fill in the field \"Job Code\".", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true); return
        }
        
        if !settings.photoList.contains("Additional Photo (\(self.counter))") {
            settings.photoList.append("Additional Photo (\(self.counter))")
            if let auth = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer() {
                self.googleDriveService.authorizer = auth
                self.getAllFiles(folderID: self.settings.installPhotosFolderID!, service: self.googleDriveService)
            }
        } else {
            repeat {
              self.counter += 1
            } while settings.photoList.contains("Additional Photo (\(self.counter))")
            print(self.counter)
            settings.photoList.append("Additional Photo (\(self.counter))")
            if let auth = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer() {
                self.googleDriveService.authorizer = auth
                self.getAllFiles(folderID: self.settings.installPhotosFolderID!, service: self.googleDriveService)
            }
        }
        
        self.tableView.reloadData()
        print(settings.photoList)
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
