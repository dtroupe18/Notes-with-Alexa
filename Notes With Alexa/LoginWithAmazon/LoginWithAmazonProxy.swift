//
//  LoginWithAmazonProxy.swift
//  Notes With Alexa
//
//  Created by Dave on 1/25/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import Foundation

import LoginWithAmazon

class LoginWithAmazonProxy {
    
    static let sharedInstance = LoginWithAmazonProxy()
    
    func login(delegate: AIAuthenticationDelegate) {
        AIMobileLib.authorizeUser(forScopes: Settings.Credentials.scopes, delegate: delegate)
    }
    
}
