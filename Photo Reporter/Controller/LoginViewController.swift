//
//  ViewController.swift
//  Photo Reporter
//
//  Created by Igor Chernobai on 6/1/19.
//  Copyright © 2019 Igor Chernobai. All rights reserved.
//

import UIKit
import GoogleSignIn
import GTMSessionFetcher

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        GIDSignIn.sharedInstance().scopes.append("https://www.googleapis.com/auth/plus.login")
        GIDSignIn.sharedInstance().scopes.append("https://www.googleapis.com/auth/plus.me")
        GIDSignIn.sharedInstance().scopes.append("https://www.googleapis.com/auth/drive")
        
        if GIDSignIn.sharedInstance()?.hasAuthInKeychain() == true {
            GIDSignIn.sharedInstance().signInSilently()
           
        } else {
            GIDSignIn.sharedInstance()?.signOut()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
       
        if GIDSignIn.sharedInstance()?.hasAuthInKeychain() == true {
            self.performSegue(withIdentifier: "loginSegue", sender: self)
        }
    }
    
}

