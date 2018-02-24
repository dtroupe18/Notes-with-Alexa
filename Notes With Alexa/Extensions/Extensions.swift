//
//  Extensions.swift
//  Notes With Alexa
//
//  Created by Dave on 1/26/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import Foundation
import UIKit

extension Array {
    // Binary Search
    // Allows you to insert objects into an array at their sorted index
    //
    func getSortedInsertIndex(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var low: Int = 0
        var high: Int = 0
        
        while low < high {
            let middle = (low + high) / 2
            
            if isOrderedBefore(self[middle], elem) {
                low = middle + 1
            } else if isOrderedBefore(elem, self[middle]) {
                high = middle - 1
            } else {
                // Should be at the middle position
                //
                return middle
            }
        }
        // Not found so it should be inserted at low
        //
        return low
    }
}

extension UIColor {
    // Get the "default" blue that Apple likes so much
    //
    static func defaultBlue() -> UIColor {
        return UIColor.init(red: 14/255, green: 122/255, blue: 254/255, alpha: 1.0)
    }
}

extension UITextView {
    // One line to adjust the size of a textViews font
    //
    func setFontSize(size: Int) {
        self.font =  UIFont(name: (self.font?.fontName)!, size: CGFloat(size))
    }
}

extension String {
    // Used to split the text inside a textview into lines
    //
    var lines: [String] {
        var result: [String] = []
        enumerateLines {line, _ in result.append(line) }
        return result
    }
    // Used to replace the first occurance of a substring with another string
    //
    func replaceFirstOccurrence(target: String, withString replaceString: String) -> String {
        if let range = self.range(of: target) {
            return self.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
}

extension Date {
    // Get milliseconds since epoch
    //
    var millisecondsSinceEpoch: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

extension UIApplication {
    // Get the top viewController from anywhere this allows for alerts from no vc classes
    //
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
