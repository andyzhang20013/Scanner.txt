//
//  ViewController.swift
//  Scanner
//
//  Created by Andy Zhang on 5/27/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import UIKit
import VisionKit
import Vision
import RealmSwift
class ViewController: UITableViewController, VNDocumentCameraViewControllerDelegate {

let processedImage = ProcessedImageViewController()
let realm = try! Realm()
var button = Button()
var text: Results<Data>?
override func viewDidLoad() {
    super.viewDidLoad()
    loadItems()
}

    
func loadItems(){
    text = realm.objects(Data.self)
    tableView.reloadData()
}
    
    @IBAction func pictureButtonPressed(_ sender: UIBarButtonItem) {
        print("abc")
        button.setButton(true)
        print(button.getButton())
        //performSegue(withIdentifier: "takeNewPicture", sender: self)
}

override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //always go through here
   let destinationVC = segue.destination as! ProcessedImageViewController
    print("ok")
    print(button.getButton())
    if let indexPath = tableView.indexPathForSelectedRow{ //we use this to get the selected row
        if text?[indexPath.row].text != "No text scanned yet" { //if there is actually something scanned
            button.setButton(false)
        destinationVC.selectedText = text?[indexPath.row]
        }
        else{ //if nothing scanned, then automatically launch camera
            button.setButton(true)
        }
    }
    else{ //if we press the camera button
        button.setButton(true)
    }
    print(button.getButton())
}


//MARK: - Tableview Datasource Methods - This creates the cells

override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //Asks us for a UITableView cell to display -> This will create a new cell for each message
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    if let item = text?[indexPath.row] {
        cell.textLabel?.text = item.text
    }
    else{
        cell.textLabel?.text = "No text scanned yet"
    }
    return cell
}
override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return text?.count ?? 1
}
}

