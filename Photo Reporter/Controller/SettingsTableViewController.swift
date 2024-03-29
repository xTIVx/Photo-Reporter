//
//  SettingsTableViewController.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/1/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class SettingsTableViewController: UITableViewController {
    
    
    static var shared = SettingsTableViewController()
    let defaults = UserDefaults.standard
    var settings = Settings.shared
    var gDriveService = GTLRDriveService()
    let www : Error? = nil
    var gUser = AppDelegate.shared().gUser
    var auth = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
    
    
    
    @IBOutlet weak var jobCodeTextField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        jobCodeTextField.text = settings.jobCode
        
    }
    
    @IBAction func savePressed(_ sender: UIBarButtonItem) {
        
        guard jobCodeTextField.text != "" else {
            let ac = UIAlertController(title: "Enter Job Code!", message: "", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
            return
        }
        
        
       
        
        if let _ = GIDSignIn.sharedInstance()?.currentUser {
            
            self.gDriveService.authorizer = self.auth
            
            getParentID(name: self.jobCodeTextField.text!.trimmingCharacters(in: .whitespaces), service: self.gDriveService) { (parentID) in
                
                if let parentid = parentID {
                    self.settings.parentID = parentid
                    self.settings.jobCode = self.jobCodeTextField.text?.trimmingCharacters(in: .whitespaces)
                    self.defaults.set(self.settings.jobCode, forKey: "jobCode")
                    self.defaults.set(parentid, forKey: "parentID")
                    self.getFolderID(parent: parentid, service: self.gDriveService) { (folderID) in
                        if let folderid = folderID {
                        self.settings.installPhotosFolderID = folderid
                        self.defaults.set(folderid, forKey: "Install Photos ID")
                        self.navigationController?.popViewController(animated: true)
                            print("НАШЕЛ!! \(folderid)")
                        }
                        else {
                            self.createFolder(service: self.gDriveService, completion: { (createdFolderID) in
                                self.defaults.set(createdFolderID, forKey: "Install Photos ID")
                                self.settings.installPhotosFolderID = createdFolderID
                                self.navigationController?.popViewController(animated: true)
                                print("СОЗДАЛ!!! \(createdFolderID)")
                            })
                        }
                    }
                } else {
                    let ac = UIAlertController(title: "Wrong Job Code!", message: "We can't find the folder with your JobCode! Double check your spelling!", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
            
           
        } else {
            let ac = UIAlertController(title: "Authorization Error!", message: "Try to log in again!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            
        }
        
    }
    
    @IBAction func didTapSignOut(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    func getParentID(
        name: String,
        service: GTLRDriveService,
        completion: @escaping (String?) -> Void) {
        
        let query = GTLRDriveQuery_FilesList.query()
        
        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"
        
        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"
        
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        
        query.q = "\(withName) and \(foldersOnly)"
        
        
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                print("ParentID ERROR: \(error!.localizedDescription)")
                return
            }
            
            let folderList = result as! GTLRDrive_FileList
            
            // For brevity, assumes only one folder is returned.
            completion(folderList.files?.first?.identifier)
            
            
        }
    }
    
    func getFolderID(
        parent: String,
        service: GTLRDriveService,
        completion: @escaping (String?) -> Void) {
        
        let query = GTLRDriveQuery_FilesList.query()
        
        // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
        query.spaces = "drive"
        
        // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
        query.corpora = "user"
        
        let parent = "'\(parent)'"
        let withName = "name = 'Install Photos'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder' and trashed=false"
        
        
        query.q = "\(parent) in parents and \(withName) and \(foldersOnly)"
        service.executeQuery(query) { (_, result, error) in
            guard error == nil else {
                print("Get Folder ID ERROR: \(error!.localizedDescription)")
                return
            }
            
            let folderList = result as! GTLRDrive_FileList
            
            // For brevity, assumes only one folder is returned.
            completion(folderList.files?.first?.identifier)
            
        }
    }
    
   
    func createFolder(
        service: GTLRDriveService,
        completion: @escaping (String) -> Void) {
        let parent = [settings.parentID]
        let folder = GTLRDrive_File()
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.name = "Install Photos"
        folder.parents = parent as? [String]
        
        // Google Drive folders are files with a special MIME-type.
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        
        service.executeQuery(query) { (_, file, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            let folder = file as! GTLRDrive_File
            completion(folder.identifier!)
            
        }
    }
    
}
    

