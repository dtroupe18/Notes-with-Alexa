//
//  NotesViewController.swift
//  Notes With Alexa
//
//  Created by Dave on 1/26/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class NotesListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plusButton: UIBarButtonItem!
    @IBOutlet weak var hamburgerButton: UIBarButtonItem!
    
    var notes = [Note]()
    
    // Int passed so that we know what note to update
    //
    var selectedRow: Int?
    
    // Pull to refresh
    //
    var refreshControl: UIRefreshControl!
    
    var darkThemeLoaded: Bool?
    
    var textSize: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        // Firebase Persistence
        //
        if let uid = Auth.auth().currentUser?.uid {
            let notesRef = Database.database().reference(withPath: "notes/\(uid)")
            notesRef.keepSynced(true)
        }
        
        // Database listener that fires when a note is changed
        //
        FirebaseDatabase.deployDatabaseUpdateListener({ updatedNote in
            // Check if this note is already in our array
            //
            if let index = self.notes.index(where: {$0.key == updatedNote.key}) {
                self.notes[index] = updatedNote
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            else {
                print("index is nil")
            }
        })
        
        // Database listener that fires when a new note is created
        //
        FirebaseDatabase.deployDatabaseNewNoteListener({ newNote in
            // Add this new note to our array
            //
            self.notes.append(newNote)
            self.notes = self.notes.sorted(by: {$0.timestamp > $1.timestamp})
            self.tableView.reloadData()
        })
        
        // Notification to reload the tableview when a note is added or updated
        //
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableView), name: NSNotification.Name(rawValue: "reloadNotesTableView"), object: nil)
        
        // Setup pull to refresh
        //
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "") // no title
        refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)

        darkThemeLoaded = UserDefaults.standard.bool(forKey: "darkMode")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.bool(forKey: "darkMode") != darkThemeLoaded {
            darkThemeLoaded = UserDefaults.standard.bool(forKey: "darkMode")
            if darkThemeLoaded != nil && darkThemeLoaded! {
                self.tableView.reloadData()
            }
            else if darkThemeLoaded != nil && !darkThemeLoaded! {
                self.tableView.reloadData()
            }
        }
        
        // Set textSize
        //
        textSize = UserDefaults.standard.integer(forKey: "textSize")
        if textSize == 0 {
            textSize = 17
        }
    }
    
    @objc func refresh() {
        FirebaseDatabase.fetchNotesFromFirebase({ fetchedNotes in
            self.notes = fetchedNotes.sorted(by: {$0.timestamp > $1.timestamp})
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        })
    }
    
    // Marker: Tableview Delegate
    //
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListTableViewCell
        cell.titleLabel.font = UIFont.boldSystemFont(ofSize: CGFloat(textSize + 2))
        cell.titleLabel.text = Helper.getFirstLineOfText(note: notes[indexPath.row])
        
        cell.firstLineLabel.font = UIFont.systemFont(ofSize: CGFloat(textSize))
        cell.firstLineLabel.text = Helper.getSecondLineOfText(note: notes[indexPath.row])
        
        cell.timestampLabel.font = UIFont.systemFont(ofSize: CGFloat(textSize - 5))
        cell.timestampLabel.text = Helper.convertTimestamp(millisecondsSinceEpoch: notes[indexPath.row].timestamp)
        cell.selectionStyle = .none
        
        if darkThemeLoaded != nil && darkThemeLoaded! {
            cell.backgroundColor = UIColor.black
            tableView.backgroundColor = UIColor.black
            cell.titleLabel.textColor = UIColor.white
            cell.firstLineLabel.textColor = UIColor.white
            cell.timestampLabel.textColor = UIColor.white
        }
        
        else if darkThemeLoaded != nil && !darkThemeLoaded! {
            cell.backgroundColor = UIColor.white
            tableView.backgroundColor = UIColor.white
            cell.titleLabel.textColor = UIColor.black
            cell.firstLineLabel.textColor = UIColor.black
            cell.timestampLabel.textColor = UIColor.black
        }

        return cell
    }
    
    // Deleting notes
    //
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Alert the user and ask for confirmation
            //
            let deleteAlert = UIAlertController(title: "Delete Note", message: "Are you sure you want to delete this note? This action cannot be undone.", preferredStyle: .alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
                if let key = self.notes[indexPath.row].key, let uid = Auth.auth().currentUser?.uid {
                    let ref = Database.database().reference()
                    ref.child("notes").child(uid).child(key).removeValue(completionBlock: { (error, ref) in
                        if error == nil {
                            self.notes.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    })
                }
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
                // Do nothing
                //
            }))
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    // Row action
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toNote", sender: nil)
        }
    }
    
    @objc func reloadTableView() {
        tableView.reloadData()
    }
    
    @IBAction func plusPressed(_ sender: Any) {
        // Create a new note
        //
        performSegue(withIdentifier: "toNote", sender: nil)
    }
    
    @IBAction func hamburgerPressed(_ sender: Any) {
        performSegue(withIdentifier: "toSettings", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNote" {
            if let vc = segue.destination as? NoteViewController {
                // Used when a row or "note" is selected
                //
                if let index = selectedRow {
                    vc.note = notes[index]
                    vc.index = index
                    selectedRow = nil
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
