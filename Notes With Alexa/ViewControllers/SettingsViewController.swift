//
//  SettingsViewController.swift
//  Notes With Alexa
//
//  Created by Dave on 2/4/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import UIKit
import LoginWithAmazon
import FirebaseAuth

class SettingsViewController: UIViewController, AIAuthenticationDelegate {

    @IBOutlet weak var darkModeLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var alexaSkillButton: UIButton!
    @IBOutlet weak var alexaSkillLabel: UILabel!
    @IBOutlet weak var textSizeLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
        textSizeLabel.isUserInteractionEnabled = true
        textSizeLabel.addGestureRecognizer(tapGesture)
        
        // Doesn't depend on light or dark theme
        //
        signOutButton.layer.borderWidth = 1
        signOutButton.layer.cornerRadius = 4
        alexaSkillButton.layer.borderWidth = 1
        alexaSkillButton.layer.cornerRadius = 4
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        // Display an action sheet with the choices for textSize
        //
        let actionSheet = UIAlertController(title: "Text Size", message: "", preferredStyle: .actionSheet)
        
        let small = UIAlertAction(title: "Small", style: .default) { _ in
            UserDefaults.standard.set(17, forKey: "textSize")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadNotesTableView"), object: nil)
            self.sizeLabel.text = "Small"
        }
        
        let medium = UIAlertAction(title: "Medium", style: .default) { _ in
            UserDefaults.standard.set(20, forKey: "textSize")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadNotesTableView"), object: nil)
            self.sizeLabel.text = "Medium"
        }
        
        let large = UIAlertAction(title: "Large", style: .default) { _ in
            UserDefaults.standard.set(24, forKey: "textSize")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadNotesTableView"), object: nil)
            self.sizeLabel.text = "Large"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // relate actions to controllers
        //
        actionSheet.addAction(small)
        actionSheet.addAction(medium)
        actionSheet.addAction(large)
        actionSheet.addAction(cancel)
        
        if let popover = actionSheet.popoverPresentationController {
            if let viewForSource = recognizer.view {
                popover.sourceView = viewForSource
                popover.sourceRect = viewForSource.bounds
            }
        }
        present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.bool(forKey: "darkMode") {
            toggleSwitch.isOn = true
            self.view.backgroundColor = UIColor.black
            darkModeLabel.textColor = UIColor.white
            alexaSkillLabel.textColor = UIColor.white
            alexaSkillButton.setTitleColor(UIColor.white, for: .normal)
            alexaSkillButton.layer.borderColor = UIColor.white.cgColor
            signOutButton.setTitleColor(UIColor.white, for: .normal)
            signOutButton.layer.borderColor = UIColor.white.cgColor
            textSizeLabel.textColor = UIColor.white
            sizeLabel.textColor = UIColor.white
        }
        else {
            toggleSwitch.isOn = false
            self.view.backgroundColor = UIColor.white
            darkModeLabel.textColor = UIColor.black
            alexaSkillLabel.textColor = UIColor.black
            alexaSkillButton.setTitleColor(UIColor.defaultBlue(), for: .normal)
            alexaSkillButton.layer.borderColor = UIColor.defaultBlue().cgColor
            signOutButton.setTitleColor(UIColor.defaultBlue(), for: .normal)
            signOutButton.layer.borderColor = UIColor.defaultBlue().cgColor
        }
        
        let textSize = UserDefaults.standard.integer(forKey: "textSize")
        switch textSize {
        case 17:
            sizeLabel.text = "Small"
        case 20:
            sizeLabel.text = "Medium"
        case 24:
            sizeLabel.text = "Large"
        default:
            sizeLabel.text = "Small"
        }
    }
    
    @IBAction func toggleFlipped(_ sender: UISwitch) {
        if sender.isOn {
            // Save dark mode to user defaults and change the appearance of everything
            //
            UserDefaults.standard.set(true, forKey: "darkMode")
            viewWillAppear(true)
        }
        else {
            UserDefaults.standard.set(false, forKey: "darkMode")
            viewWillAppear(true)
        }
    }
    
    @IBAction func alexaButtonTapped(_ sender: Any) {
        if let url = URL(string: "https://www.amazon.com/dp/B079MHR4V6/?ref-suffix=ss_copy") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        // SignOut of Amazon
        //
        AIMobileLib.clearAuthorizationState(self)
    }
    
    // AIAuthentication Delegate
    //
    func requestDidSucceed(_ apiResult: APIResult) {
        if apiResult.api == API.clearAuthorizationState {
            // User successfully signed out of Amazon
            //
            // Sign user out of Firebase & segue back to the login page
            //
            do {
                try Auth.auth().signOut()
                DispatchQueue.main.async {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController")
                    self.present(vc, animated: false, completion: nil)
                }
            }
            catch let error as NSError {
                if let topVC = UIApplication.topViewController() {
                    Helper.showAlert(vc: topVC, title: "Sign Out Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    func requestDidFail(_ errorResponse: APIError) {
        // Error 1 is returned when the A,azon authorization token is no longer valid
        // This error is ignored because we will sign the user out of Firebase anyway
        //
        if errorResponse.error.code != 1 {
            if let topVC = UIApplication.topViewController() {
                if let message = errorResponse.error.message {
                    Helper.showAlert(vc: topVC, title: "Sign Out Error", message: "\(message). Please try again")
                }
            }
        }
        
        print("Error: \(errorResponse.error.message)")
        print("Code: \(errorResponse.error.code)")
        print("Description: \(errorResponse.error.description)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
