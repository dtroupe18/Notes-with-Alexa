//
//  NoteViewController.swift
//  Notes With Alexa
//
//  Created by Dave on 1/26/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import UIKit

class NoteViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    
    var note: Note?
    var index: Int?
    
    // Button that allows for the keyboard to be dismissed
    //
    var doneButton: UIButton?
    
    // Tap Gesture to determine when
    // to activate the textview
    //
    var tapGesture: UITapGestureRecognizer?
    
    // Min content size of textview
    //
    let minHeight: CGFloat = 1000
    
    var noteWasUpdated: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        self.navigationController?.delegate = self
        
        if let n = note {
            if let first = n.firstLine, let additional = n.additionalText {
                textView.text = "\(first)\n\(additional)"
            }
            else if let first = n.firstLine {
                textView.text = "\(first)"
            }
        }
        
        // Detect things inside a note
        //
        textView.isEditable = false
        textView.dataDetectorTypes = .all
        textView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 10.0, right: 0.0)

        // Add done button to navigation bar
        //
        doneButton = UIButton(type: .custom)
        doneButton?.setTitle("Done", for: .normal)
        doneButton?.setTitleColor(UIColor.white, for: .normal)
        doneButton?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        doneButton?.addTarget(self, action: #selector(self.donePressed), for: .touchUpInside)
        doneButton?.isHidden = true
        if doneButton != nil {
            let barButton = UIBarButtonItem(customView: doneButton!)
            self.navigationItem.setRightBarButton(barButton, animated: true)
        }
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.textViewTapped(recognizer:)))
        textView.addGestureRecognizer(tapGesture!)
        
        // Notifications for resizing the textView based on the keyboard
        //
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Adjust the content size of the textView here because it isn't loaded in viewDidLoad
        //
        var currentContentSize = textView.contentSize.height
        
        if currentContentSize < minHeight {
            currentContentSize = 1000
            textView.contentSize.height = currentContentSize
            
        }
        else {
            currentContentSize *= 2
            textView.contentSize.height = currentContentSize
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UserDefaults.standard.bool(forKey: "darkMode") {
            textView.backgroundColor = UIColor.black
            textView.textColor = UIColor.white
        }
        else {
            textView.backgroundColor = UIColor(red: 235.0, green: 235.0, blue: 235.0, alpha: 1.0)
            textView.textColor = UIColor.black
        }
        
        let textSize = UserDefaults.standard.integer(forKey: "textSize")
        // 0 is the default value or an integer in UserDefaults that hasn't been set yet
        //
        if textSize != 0 {
            textView.setFontSize(size: textSize)
        }
    }
    
    @objc func donePressed() {
        textView.resignFirstResponder()
        textView.isEditable = false
        doneButton?.isHidden = true
        tapGesture?.isEnabled = true
    }
    
    @objc func textViewTapped(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            if !textView.isEditable {
                textView.isEditable = true
                textView.becomeFirstResponder()
                
                let location = recognizer.location(in: textView)
                if let position = textView.closestPosition(to: location) {
                    let uiTextRange = textView.textRange(from: position, to: position)
                    
                    if let start = uiTextRange?.start, let end = uiTextRange?.end {
                        let loc = textView.offset(from: textView.beginningOfDocument, to: position)
                        let length = textView.offset(from: start, to: end)
                        // Move the cursor to the touched location
                        //
                        textView.selectedRange = NSMakeRange(loc, length)
                        tapGesture?.isEnabled = false
                    }
                }
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        doneButton?.isHidden = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        noteWasUpdated = true
        var currentContentSize = textView.contentSize.height
        
        if currentContentSize < minHeight {
            currentContentSize = 1000
            textView.contentSize.height = currentContentSize
        }
    }

    func getTextForNote(text: String) -> [String] {
        var array = [String]()
        
        if text.range(of: "\n") != nil {
            var lines = text.lines
            array.insert(lines[0], at: 0)
            
            if lines.count > 1 {
                // remove the first line since it was already added to array
                //
                lines.remove(at: 0)
                array.insert(lines.joined(separator: "\n"), at: 1)
                return array
            }
            else {
                // This should never happen
                //
                return array
            }
        }
        else {
            array.insert(text, at: 0)
            return array
        }
    }
    
    func createNewNote() -> Note? {
        let array = getTextForNote(text: textView.text)
        var newNote: Note?
        
        guard let title = Helper.getTitle(lines: array) else { return newNote }
        
        if array.count == 2 {
            newNote = Note(title: title, firstLine: array[0], timestamp: Date().millisecondsSinceEpoch, additionalText: array[1])
        }
        else if array.count == 1 {
            newNote = Note(title: title, firstLine: array[0], timestamp: Date().millisecondsSinceEpoch, additionalText: nil)
        }
        newNote?.key = FirebaseDatabase.getPostKey()
        return newNote
    }
    
    func getUpdatedNote() -> Note? {
        guard note != nil else { return createNewNote() }
        let array = getTextForNote(text: textView.text)
        
        if array.count == 2 {
            note?.firstLine = array[0]
            note?.additionalText = array[1]
            // Timestamp is updated to reflect the time it was last edited
            //
            note?.timestamp = Date().millisecondsSinceEpoch
        }
        else if array.count == 1 {
            note?.firstLine = array[0]
            note?.timestamp = Date().millisecondsSinceEpoch
            note?.additionalText = nil
        }
        return note
    }
    
    // Pass note back to previous viewController
    //
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let previous = viewController as? NotesListViewController {
            if let i = index, noteWasUpdated {
                // Replace the note in notes with the updated note
                //
                print("updating note...")
                if let updatedNote = getUpdatedNote() {
                    // Remove the old note and place the updated note at the top of the list
                    //
                    previous.notes.remove(at: i)
                    previous.notes.insert(updatedNote, at: 0)
                    FirebaseDatabase.saveNoteToFirebase(note: updatedNote)
                    self.note = nil
                }
            }
            else if note == nil {
                // Working with a new note
                //
                if let newNote = createNewNote() {
                    // Insert the newest note at the top
                    //
                    previous.notes.insert(newNote, at: 0)
                    FirebaseDatabase.saveNoteToFirebase(note: newNote)
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadNotesTableView"), object: nil)
        }
    }
    
    // Adjusting textview content size with keyboard
    //
    @objc func keyboardWillShow(notification: Notification) {
        if let rectValue = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue {
            let keyboardSize = rectValue.cgRectValue.size
            updateTextViewContentInset(keyboardHeight: keyboardSize.height)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        updateTextViewContentInset(keyboardHeight: 0)
    }
    
    func updateTextViewContentInset(keyboardHeight: CGFloat) {
        textView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardHeight, right: 0)
        textView.scrollIndicatorInsets = textView.contentInset
        scrollToCursorPositionIfBelowKeyboard(keyboardHeight: keyboardHeight)
    }
    
    private func scrollToCursorPositionIfBelowKeyboard(keyboardHeight: CGFloat) {
        if let selectedTextRange = textView.selectedTextRange {
            let caret = textView.caretRect(for: selectedTextRange.start)
            let keyboardTop = textView.bounds.size.height - keyboardHeight
            
            // The y-scale starts in the upper-left hand corner at "0", then gets
            // larger as you go down the screen from top-to-bottom. Therefore, the caret.origin.y
            // being larger than keyboardTopBorder indicates that the caret sits below the
            // keyboardTopBorder, and the textView needs to scroll to that position.
            //
            if caret.origin.y > keyboardTop {
                textView.scrollRectToVisible(caret, animated: true)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
