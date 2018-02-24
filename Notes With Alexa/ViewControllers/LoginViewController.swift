//
//  ViewController.swift
//  Notes With Alexa
//
//  Created by Dave on 1/25/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import UIKit
import LoginWithAmazon
import FirebaseAuth

class LoginViewController: UIViewController, AIAuthenticationDelegate {
    
    @IBOutlet weak var loginWithAmazonButton: UIButton!
    @IBOutlet weak var mobileNotesButton: UIButton!
    
    var hasProfile: Bool = false
    var shouldRequestAmazonToken: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if there's already a Firebase user
        //
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.goToNotes()
            }
            else {
                // See if there is an Amazon token we can use
                //
                AIMobileLib.getAccessToken(forScopes: Settings.Credentials.scopes, withOverrideParams: nil, delegate: self)
            }
        }
        
        // Style button
        //
        mobileNotesButton.layer.borderColor = UIColor.black.cgColor
        mobileNotesButton.layer.borderWidth = 1
        mobileNotesButton.layer.cornerRadius = 4
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        LoginWithAmazonProxy.sharedInstance.login(delegate: self)
    }
    
    func requestDidSucceed(_ apiResult: APIResult) {
        
        if apiResult.api == API.authorizeUser {
            // User has not previously been authorized
            //
            AIMobileLib.getAccessToken(forScopes: Settings.Credentials.scopes, withOverrideParams: nil, delegate: self)
        }
        else if apiResult.api == API.clearAuthorizationState {
            // Sign User Out
            //
            print("Clearing authorization state")
        }
            
        else if apiResult.api == API.getProfile {
            // Requesting a user profile
            //
            if let userInfo = apiResult.result as? [String: Any] {
                if let name = userInfo["name"] as? String, let email = userInfo["email"] as? String,
                    let userId = userInfo["user_id"] as? String {
                    // Since Firebase won't let us use the Amazon token and we can't create
                    // a custom token in swift we need to create a user. This is completely
                    // abstracted away from the user. We also need to be able to re-authenticate
                    // this account without user input.
                    //
                    hasProfile = true
                    Auth.auth().createUser(withEmail: email, password: userId, completion: { (user, error) in
                        if let error = error {
                            let code = AuthErrorCode(rawValue: error._code)
                            if code == .emailAlreadyInUse {
                                // User already has an account sign them in
                                //
                                self.signUserIn(email: email, password: userId)
                            }
                        }
                        if let user = user {
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.displayName = name
                            // Save the users Amazon UID in the photoURL in case we need it
                            //
                            changeRequest.photoURL = URL(string: userId)
                            changeRequest.commitChanges(completion: nil)
                            self.goToNotes()
                        }
                    })
                }
            }
        }
            
        else if apiResult.api == API.getAccessToken {
            // Once we have the user signed in we get their profile information
            //
            if !hasProfile {
                AIMobileLib.getProfile(self)
            }
            else {
                print("user profile not nil in get auth token")
            }
        }
    }
    
    func requestDidFail(_ errorResponse: APIError) {
        // Error 1 is returned when the authorization token is no longer valid
        // This error is ignored because we automatically try to sign the user in
        // if that sign in fails we do not need to alert the user
        //
        if errorResponse.error.code != 1 {
            displayError(title: "Amazon Login Error", message: errorResponse.error.message)
        }
        print("Error: \(errorResponse.error.message)")
        print("Code: \(errorResponse.error.code)")
        print("Description: \(errorResponse.error.description)")
    }
    
    func signUserIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error = error {
                self.displayError(title: "Sign In Error", message: error.localizedDescription)
            }
            // Segue to notes will be handled by the addStateDidChangeListener in viewDidLoad
            //
        })
    }
    
    @IBAction func mobileNotesPressed(_ sender: Any) {
        if let url = NSURL(string: "https://www.amazon.com/dp/B079MHR4V6/?ref-suffix=ss_copy") {
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        }
    }
    
    
    func goToNotes() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toNotesList", sender: nil)
        }
    }
    
    func displayError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
