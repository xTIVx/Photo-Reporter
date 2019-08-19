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
// TODO 8) Если нажал НЕТ на использование старого jobcode то удалять сохраненные фото в документах!

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import Photos
import Foundation
import GTMSessionFetcher


class PhotosViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource{
    
    
    
    @IBOutlet weak var syncWaiting: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    
    var imagePicker = UIImagePickerController()
    let defaults = UserDefaults.standard
    var appDelegate = AppDelegate.shared()
    let googleDriveService = GTLRDriveService()
    var cellTW = CustomTableViewCell()
    let settings = Settings.shared
    let workWithGoogle = WorkWithGoogle()
    let PhotoStorage = PhotoPhoneStorage()
    lazy var syncFunctional = SyncFunctional()
    var flagUpdatedInViewDidLoad = true
    var imageForTransferToImagePreview: UIImage?
    var imageTitleForTransferImagePreview: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.tableView.isHidden = true
        self.syncWaiting.isHidden = true
        self.tableView.tableFooterView = UIView()

        if let jcode = defaults.string(forKey: "jobCode"){
            let ac = UIAlertController(title: "Use last Job Code?", message: "Do you want to use \(jcode.uppercased())?", preferredStyle: .alert)
            let no = UIAlertAction(title: "No", style: .destructive) { (alert) in
                self.flagUpdatedInViewDidLoad = false
               
                for i in self.PhotoStorage.getFilesFromDocuments() {
                    self.PhotoStorage.deleteFromTempFolder(fileName: String(i.lastPathComponent))
                }
                
            }
            let yes = UIAlertAction(title: "Yes", style: .default) { (alert) in
                self.flagUpdatedInViewDidLoad = true
                self.settings.jobCode = jcode
                self.navigationItem.title = self.settings.jobCode?.uppercased()
                if let installFolderID = self.defaults.string(forKey: "Install Photos ID") {
                    self.settings.installPhotosFolderID = installFolderID
                    
                }
                
                
                self.syncWaiting.isHidden = false
                self.syncWaiting.startAnimating()
                if let installPhotosFolderID = self.settings.installPhotosFolderID {
                    self.googleDriveService.authorizer = self.appDelegate.gUser?.authentication.fetcherAuthorizer()
                    self.syncFunctional.start(folderID: installPhotosFolderID, service: self.googleDriveService, completionHandlerStart: { (ready) in
                        if ready {
                            self.syncWaiting.isHidden = true
                            self.syncWaiting.stopAnimating()
                            self.tableView.isHidden = false
                            

                            self.settings.actualPhotoListFromStorage = self.PhotoStorage.getFilesFromDocuments()
                            for i in self.settings.actualPhotoListFromStorage {
                                if !self.settings.staticPhotoList.contains(i.deletingPathExtension().lastPathComponent) {
                                    self.settings.staticPhotoList.append(i.deletingPathExtension().lastPathComponent)
                                }
                            }
                            self.tableView.reloadData()
                        }
                    })
                }
            }
            present(ac, animated: true)
            ac.addAction(no)
            ac.addAction(yes)
            
        } else {
            let ac = UIAlertController(title: "Enter Job-Code!", message: "Go to the 'Settings' and enter Job-Code!", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { (action) in
                self.flagUpdatedInViewDidLoad = false
                self.performSegue(withIdentifier: "goToSettings", sender: self)
            }
            present(ac, animated: true)
            ac.addAction(ok)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = settings.jobCode?.uppercased()
        guard !flagUpdatedInViewDidLoad else{return}
        
        self.syncWaiting.isHidden = false
        self.syncWaiting.startAnimating()
        if let installPhotosFolderID = self.settings.installPhotosFolderID {
            self.googleDriveService.authorizer = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer()
            self.syncFunctional.start(folderID: installPhotosFolderID, service: self.googleDriveService, completionHandlerStart: { (ready) in
                if ready {
                    
                    self.syncWaiting.isHidden = true
                    self.syncWaiting.stopAnimating()
                    self.tableView.isHidden = false
                    
                    self.settings.actualPhotoListFromStorage = self.PhotoStorage.getFilesFromDocuments()
                    for i in self.settings.actualPhotoListFromStorage {
                        if !self.settings.staticPhotoList.contains(i.deletingPathExtension().lastPathComponent) {
                            self.settings.staticPhotoList.append(i.deletingPathExtension().lastPathComponent)
                        }
                    }
                    
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings.staticPhotoList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "photosTW", for: indexPath) as! CustomTableViewCell
        // Reset cell
        cell.idPhoto?.isHidden = true
        cell.namePhoto?.text = nil
        cell.imagePhoto.image = nil
        cell.uploadProgress.isHidden = true
        cell.uploadActivityIndicator.isHidden = true
        cell.downloadActivityIndicator.isHidden = true
        cell.accessoryType = .none
        
        // Add gesture recognizer to the images
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(gesture:)))
        cell.imagePhoto.addGestureRecognizer(recognizer)
        cell.imagePhoto.isUserInteractionEnabled = true;
    
        cell.namePhoto.text = self.settings.staticPhotoList[indexPath.row]
        
        for i in self.settings.actualPhotoListfromGoogle.keys {
            if i.hasPrefix(cell.namePhoto.text!) {
                cell.accessoryType = .checkmark
            }
        }
        
        for i in self.settings.actualPhotoListFromStorage {
            if i.deletingPathExtension().lastPathComponent == cell.namePhoto.text {
                cell.imagePhoto.image = UIImage(url: i)
            }
        }
        
        return cell
        
    }

    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            let tapLocation = gesture.location(in: self.tableView)
            if let tapIndexPath = self.tableView.indexPathForRow(at: tapLocation) {
                if let tappedCell = self.tableView.cellForRow(at: tapIndexPath) as? CustomTableViewCell {
                    if tappedCell.imagePhoto.image != nil {
                        self.imageTitleForTransferImagePreview = tappedCell.namePhoto.text
                        self.imageForTransferToImagePreview = tappedCell.imagePhoto.image
                        self.performSegue(withIdentifier: "showPicture", sender: self)
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPicture" {
            let vc = segue.destination as! imagePreviewViewController
            vc.transferedImage = self.imageForTransferToImagePreview
            vc.transferedImageTitle = self.imageTitleForTransferImagePreview
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let iindexPath = tableView.indexPathForSelectedRow
        
        let currentCell = tableView.cellForRow(at: iindexPath!) as! CustomTableViewCell
        self.cellTW = currentCell
        
        let alertController = UIAlertController(title: "Photo Selection", message: "", preferredStyle: .actionSheet)
        DispatchQueue.main.async {
            let a1Camera = UIAlertAction(title: "Camera", style: .default) { (alert) in
                
                self.imagePicker.sourceType = .camera
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.rear) && currentCell.imagePhoto?.image == nil{
                alertController.addAction(a1Camera)
            }
            let a2Photo = UIAlertAction(title: "Select From Library", style: .default) { (alert) in
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.imagePicker.delegate = self
                self.present(self.imagePicker, animated: true, completion: nil)
                
            }
            if currentCell.imagePhoto.image == nil {
                alertController.addAction(a2Photo)
            }
            if currentCell.imagePhoto.image != nil || currentCell.accessoryType == .checkmark {
                let a3Delete = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
                    
                    let fileName = self.settings.actualPhotoListfromGoogle.keys.filter{ $0.contains(currentCell.namePhoto.text!)}
                    print(self.settings.actualPhotoListfromGoogle[fileName[0]]!)
                    self.workWithGoogle.deleteFile(fileID: self.settings.actualPhotoListfromGoogle[fileName[0]]!, service: self.googleDriveService, completionHandler: { (answer) in
                        if answer == true {
                            self.PhotoStorage.deleteFromTempFolder(fileName: fileName[0])
                            self.settings.actualPhotoListfromGoogle.removeValue(forKey: fileName[0])
                            currentCell.isSelected = false
                            currentCell.imagePhoto.image = nil
                            currentCell.accessoryType = .none
                            print(self.settings.actualPhotoListfromGoogle.keys)
                            print(self.settings.actualPhotoListfromGoogle.count)
                            
                        } else {
                            self.PhotoStorage.deleteFromTempFolder(fileName: fileName[0])
                            currentCell.imagePhoto.image = nil
                        }
                    })
                    
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
        
        var extent: String?
        // Regular
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            let regex = try! NSRegularExpression(pattern: "\\.[a-zA-Z]+")
            let matches = regex.matches(in: assetResources.first!.originalFilename, options: [], range: NSRange(location: 0, length: assetResources.first!.originalFilename.utf16.count))
            if let match = matches.first {
                let range = match.range(at:0)
                if let swiftRange = Range(range, in: assetResources.first!.originalFilename) {
                    let name = assetResources.first!.originalFilename[swiftRange]
                    extent = String(name)
                }
            }
        }
        // ******
        
        // Saving image to temporary folder in documents for upload on google and after - delete
        if let extention = extent {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.PhotoStorage.saveToDocuments(image: image, photoName: (cellTW.namePhoto.text! + extention.lowercased()))
            print("QQQQQQQQQQ")
            cellTW.isSelected = false
            cellTW.imagePhoto.image = image
            
        }
            dismiss(animated:true, completion: nil)
        } else {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                print("DDDDDDDDDD")
                self.PhotoStorage.saveToDocuments(image: image, photoName: "\(cellTW.namePhoto.text!).png")
                cellTW.isSelected = false
                cellTW.imagePhoto.image = image
            }
            dismiss(animated:true, completion: nil)
        }
        
    }
    
    
    @IBAction func syncButton(_ sender: UIBarButtonItem) {
        
        if let installPhotosFolderID = self.settings.installPhotosFolderID {
            self.syncWaiting.isHidden = false
            self.syncWaiting.startAnimating()
            self.googleDriveService.authorizer = AppDelegate.shared().gUser?.authentication.fetcherAuthorizer()
            self.syncFunctional.start(folderID: installPhotosFolderID, service: self.googleDriveService, completionHandlerStart: { (ready) in
                if ready {
                    
                    self.settings.actualPhotoListFromStorage = self.PhotoStorage.getFilesFromDocuments()
                    for i in self.settings.actualPhotoListFromStorage {
                        
                        if !self.settings.staticPhotoList.contains(i.deletingPathExtension().lastPathComponent) {
                            self.settings.staticPhotoList.append(i.deletingPathExtension().lastPathComponent)
                        }
                    }
                    self.tableView.reloadData()
                }
            })
        }else {
            let ac = UIAlertController(title: "Enter Job-Code!", message: "Go to the 'Settings' and enter Job-Code!", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default) { (action) in
                self.flagUpdatedInViewDidLoad = false
                self.performSegue(withIdentifier: "goToSettings", sender: self)
            }
            present(ac, animated: true)
            ac.addAction(ok)

        }
    }
    
    
    var counter = 1
    @IBAction func addNewPhoto(_ sender: UIBarButtonItem) {
    
    guard settings.jobCode != nil else {
            let ac = UIAlertController(title: "Enter Job Code!", message: "Go back to Settings and fill in the field \"Job Code\".", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true); return
        }
        
        if !self.settings.staticPhotoList.contains("additional photo (\(self.counter))") {
            self.settings.staticPhotoList.append("additional photo (\(self.counter))")
            
            self.tableView.reloadData()
        }
        else {
            repeat {
                self.counter += 1
            } while self.settings.staticPhotoList.contains("additional photo (\(self.counter))")
            self.settings.staticPhotoList.append("additional photo (\(self.counter))")
            self.tableView.reloadData()
            
        }
    }
    
}


















