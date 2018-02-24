//
//  FirebaseDatabase.swift
//  Notes With Alexa
//
//  Created by Dave on 1/28/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseDatabase {
    
    static func saveNoteToFirebase(note: Note) {
        DispatchQueue.global(qos: .utility).async {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let ref = Database.database().reference().child("notes")
            
            // If the note already has a key it was previously uploaded
            // we do not want to upload it again. We just want to update
            // the values stored in Firebase
            //
            let key = note.key ?? ref.child("notes").childByAutoId().key
            
            let json = ["noteTitle": note.title.lowercased(),
                        "firstLine": note.firstLine,
                        "additionalText": note.additionalText,
                        "noteId": key,
                        "timestamp": note.timestamp] as [String: Any?]
            
            let upload = ["\(key)": json]
            
            ref.child(uid).updateChildValues(upload, withCompletionBlock: { (error, success) in
                if let error = error {
                    if let topVC = UIApplication.topViewController() {
                        Helper.showAlert(vc: topVC, title: "Upload Error", message: "\(error.localizedDescription). Please try again")
                    }
                    return
                }
                // Do nothing the user doesn't need to be notified that the upload worked
                //
            })
        }
    }
    
    static func fetchNotesFromFirebase(_ completion: @escaping ([Note]) -> ()) {
        DispatchQueue.global(qos: .utility).async {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            var fetchedNotes = [Note]()

            let ref = Database.database().reference()
            ref.child("notes").child(uid).queryOrderedByKey().observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    for child in snap.children.reversed() {
                        let child = child as? DataSnapshot

                        if let note = child?.value as? [String: Any] {
                            if let title = note["noteTitle"] as? String, let first = note["firstLine"] as? String, let id = note["noteId"] as? String, let time = note["timestamp"] as? Int64 {

                                let n = Note(title: title, firstLine: first, timestamp: time, additionalText: nil)
                                n.key = id

                                if let optionalText = note["additionalText"] as? String {
                                    n.additionalText = optionalText
                                }
                                fetchedNotes.append(n)
                            }
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    completion(fetchedNotes)
                })
            })
        }
    }
    
    static func deployDatabaseUpdateListener(_ completion: @escaping (Note) -> ()) {
        DispatchQueue.global(qos: .utility).async {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let ref = Database.database().reference()
            ref.child("notes").child(uid).queryOrderedByKey().observe(.childChanged, with: { snap in
                // Should get a snap everytime a note is updated
                // so we can cast to a dictionary right away
                //
                if let note = snap.value as? [String: Any] {
                    if let title = note["noteTitle"] as? String, let first = note["firstLine"] as? String, let id = note["noteId"] as? String, let time = note["timestamp"] as? Int64 {
                        
                        let n = Note(title: title, firstLine: first, timestamp: time, additionalText: nil)
                        n.key = id
                        
                        if let optionalText = note["additionalText"] as? String {
                            n.additionalText = optionalText
                        }
                        // Return this note to the VC
                        //
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            completion(n)
                        })
                    }
                }
            })
        }
    }
    
    static func deployDatabaseNewNoteListener(_ completion: @escaping (Note) -> ()) {
        DispatchQueue.global(qos: .utility).async {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let ref = Database.database().reference()
            ref.child("notes").child(uid).queryOrderedByKey().observe(.childAdded, with: { snap in
                // Should get a snap everytime a note is updated
                // so we can cast to a dictionary right away
                //
                if let note = snap.value as? [String: Any] {
                    if let title = note["noteTitle"] as? String, let first = note["firstLine"] as? String, let id = note["noteId"] as? String, let time = note["timestamp"] as? Int64 {
                        
                        let n = Note(title: title, firstLine: first, timestamp: time, additionalText: nil)
                        n.key = id
                        
                        if let optionalText = note["additionalText"] as? String {
                            n.additionalText = optionalText
                        }
                        // Return this note to the VC
                        //
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            completion(n)
                        })
                    }
                }
            })
        }
    }
    
    static func getPostKey() -> String {
        return Database.database().reference().child("note").childByAutoId().key
    }
}
