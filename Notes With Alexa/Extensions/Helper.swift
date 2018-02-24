//
//  Helper.swift
//  Notes With Alexa
//
//  Created by Dave on 1/28/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import Foundation
import UIKit

class Helper {
    
    static func convertTimestamp(millisecondsSinceEpoch: Int64) -> String {
        // Converts milliseconds since the epoch to a human readable date
        //
        let calendar = NSCalendar.current
        let seconds = Double(millisecondsSinceEpoch / 1000)
        let date = Date(timeIntervalSince1970: seconds)
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let timeString = formatter.string(from: date)
            return "Today at \(timeString)"
        }
        else if calendar.isDateInYesterday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let timeString = formatter.string(from: date)
            return "Yesterday at \(timeString)"
        }
        else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date as Date)
        }
    }
    
    static func showAlert(vc: UIViewController, title: String, message: String) -> Void {
        // Function to show a generic alert on any viewController
        //
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(defaultAction)
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func getTitle(lines: [String]) -> String? {
        // Function that returned the first line of text that isn't a blank line
        //
        var firstLine: String?
        guard !lines.isEmpty else { return firstLine }
        
        if lines[0] != "" {
            // If first line is not a new line just return this
            //
            firstLine = lines[0]
            return firstLine
        }
        else if lines.count == 2 {
            // Find the first line in additional text that isn't \n
            // all lines start with \n since we are preserving the user entered format
            //
            let subString = lines[1].replacingOccurrences(of: "^\\n*", with: "", options: .regularExpression, range: nil)
            // Find the next occurance of \n so we can get only the first line
            //
            if let index = subString.index(of: "\n") {
                let line = subString[subString.startIndex..<index]
                firstLine = String(line)
                return firstLine
            }
            else {
                // No \n means there are no additional lines so we can just return
                //
                firstLine = String(subString)
                return firstLine
            }
        }
        return firstLine
    }
    
    static func getFirstLineOfText(note: Note) -> String? {
        // Function that returned the first line of text that isn't a blank line
        //
        var firstLine: String?
        
        if note.firstLine != "" {
            // If first line is not a new line just return this
            //
            firstLine = note.firstLine
            return firstLine
        }
        else if let additional = note.additionalText {
            // Find the first line in additional text that isn't \n
            // all lines start with \n since we are preserving the user entered format
            //
            let subString = additional.replacingOccurrences(of: "^\\n*", with: "", options: .regularExpression, range: nil)
            // Find the next occurance of \n so we can get only the first line
            //
            if let index = subString.index(of: "\n") {
                let line = subString[subString.startIndex..<index]
                firstLine = String(line)
                return firstLine
            }
            else {
                // No \n means there are no additional lines so we can just return
                //
                firstLine = String(subString)
                return firstLine
            }
        }
        return firstLine
    }
    
    static func getSecondLineOfText(note: Note) -> String? {
        var secondLine: String?
        
        // Check if first line is \n
        //
        if note.firstLine != "" {
            // We just need to get the first line from additional text
            //
            if note.additionalText == nil {
                // Nothing to return
                //
                return secondLine
            }
            if let text = note.additionalText?.replacingOccurrences(of: "^\\n*", with: "", options: .regularExpression, range: nil) {
                if let index = text.index(of: "\n") {
                    let line = text[text.startIndex..<index]
                    secondLine = String(line)
                    return secondLine
                }
                else {
                    // No \n means there are no additional lines so we can just return the whole string
                    //
                    secondLine = text
                    return secondLine
                }
            }
            else {
                // text is nil so there must have been an error
                //
                return secondLine
            }
        }
        else if let firstLine = getFirstLineOfText(note: note), let additional = note.additionalText {
            // FirstLine has \n so the title label is the first line from additional text
            // we will remove this line from additional text and return the next line
            //
            let removed = additional.replaceFirstOccurrence(target: firstLine, withString: "")
            secondLine = removed.replacingOccurrences(of: "^\\n*", with: "", options: .regularExpression, range: nil)
            return secondLine
        }
        return secondLine
    }
}
