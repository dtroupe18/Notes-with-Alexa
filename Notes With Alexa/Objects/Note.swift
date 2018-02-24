//
//  Note.swift
//  Notes With Alexa
//
//  Created by Dave on 1/26/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import Foundation

class Note: NSObject {
    
    var firstLine: String!
    var timestamp: Int64
    var additionalText: String?
    var title: String!
    
    // Firebase Key if uploaded
    var key: String?
    
    init(title: String, firstLine: String, timestamp: Int64, additionalText: String?) {
        self.title = title
        self.firstLine = firstLine
        self.timestamp = timestamp
        self.additionalText = additionalText
        super.init()
    }
}
