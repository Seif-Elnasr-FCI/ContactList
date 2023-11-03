//
//  ViewController.swift
//  ContactList
//
//  Created by seif elshahet on 28/10/2023.
//

import UIKit
import SQLite3
class ViewController: UITableViewController {
    var db: OpaquePointer?
    var dataSource = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAlertController))
        db = openConnecton()
        createTable(db: db)
        //showAlertController()
        query(db: db)
        //delete(db: db)
        //query(db: db)
        //insert(id: 1, name: "seif", db: db)
        
        
    }
    
    func openConnecton() -> OpaquePointer? {
        var db: OpaquePointer?
        let fileUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("contacts.sqlite")
        if sqlite3_open(fileUrl?.path, &db) == SQLITE_OK {
            print("successfully opened connection to database")
            return db
        } else {
            print("unable to open database")
            return nil
        }
    }
    
    func createTable(db: OpaquePointer?) {
        let createTableString = """
CREATE TABLE contact(Id INT PRIMARY KEY NOT NULL, Name CHAR(255));
"""
        var createTableStatment: OpaquePointer?
        
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatment, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatment) == SQLITE_DONE {
                print("\ncontact table is created")
            }else{
                print("\ncontact table is not created")
            }
        }else{
            print("\ncreate table statment is not prepared")
        }
        
        sqlite3_finalize(createTableStatment)
    }
    
    func insert(id: Int32, name: NSString, db: OpaquePointer?){
        
        let insertStatmentString = "INSERT INTO contact (Id, Name) VALUES (?,?);"
        var insertStatment: OpaquePointer?
        if sqlite3_prepare_v2(db, insertStatmentString, -1, &insertStatment, nil) == SQLITE_OK {
            
            sqlite3_bind_int(insertStatment, 1, id)
            sqlite3_bind_text(insertStatment, 2, name.utf8String, -1, nil)
            
            if sqlite3_step(insertStatment) == SQLITE_DONE {
                print("\nsuccessfully inserted row")
            } else {
                showErrorMessage(message: "User with this ID is aleardy exists")
            }
        } else {
            print("\ninsert statment is not prepared")
        }
        sqlite3_finalize(insertStatment)
    }
    
    func query(db: OpaquePointer?) {
        dataSource.removeAll()
        
        let queryStatmentString = "SELECT * FROM contact;"
        var queryStatment: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryStatmentString, -1, &queryStatment, nil) == SQLITE_OK {
            while (sqlite3_step(queryStatment) == SQLITE_ROW) {
                let id = sqlite3_column_int(queryStatment, 0)
                guard let queryResultCol1 = sqlite3_column_text(queryStatment, 1) else { print("query result is nil")
                    return
                }
                let name = String(cString: queryResultCol1)
                print("\nQuery result:")
                print("\(id) | \(name)")
                dataSource.append("\(id) | \(name)")
            }
            self.tableView.reloadData()
        }else{
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("\nquery is not prepared \(errorMessage)")
        }
        sqlite3_finalize(queryStatment)
    }
    
    func delete(db: OpaquePointer?) {
        let deleteStatmentString = "DELETE FROM contact WHERE Id = 1;"
        var deleteStatment: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteStatmentString, -1, &deleteStatment, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatment) == SQLITE_DONE {
                print("\nsuccessfully deleted row")
            } else {
                print("\ncouldn`t delete row")
            }
        } else {
            print("\ndelete statment is not prepared")
        }
        sqlite3_finalize(deleteStatment)
    }
    
    @objc func showAlertController() {
        let ac = UIAlertController(title: "Enter Contact", message: nil, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Enter id"
        }
        ac.addTextField { tf in
            tf.placeholder = "Enter Name"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self,weak ac] action in
            guard let id = ac?.textFields?[0].text else { return }
            guard let name = ac?.textFields?[1].text else { return }
            guard let idAsInt = Int32(id) else { return }
            self?.insert(id: idAsInt, name: name as NSString, db: self?.db)
            self?.query(db: self?.db)
        }
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    func showErrorMessage(message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(ac, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell")
        cell?.textLabel?.text = dataSource[indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    
}




