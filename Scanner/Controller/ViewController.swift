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
var text: Results<Data>?
var imageKey: Results<Data>?
override func viewDidLoad() {
    super.viewDidLoad()
    print("ok")
    loadItems()
    print(text?.count)
}

    
func loadItems(){
    text = realm.objects(Data.self)
    tableView.reloadData()
}
    override func viewWillAppear(_ animated: Bool) { //if we press the back button, then reload the table
        loadItems()
    }



    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //always go through here
   let destinationVC = segue.destination as! ProcessedImageViewController
        
        destinationVC.textCount = text!.count //for creating new images
       
    if let indexPath = tableView.indexPathForSelectedRow{ //we use this to get the selected row
        if text?[indexPath.row].text != "No text scanned yet" || text?[indexPath.row].text != nil { //if there is actually something scanned
        destinationVC.selectedText = text?[indexPath.row]
            destinationVC.buttonPressed = false
            destinationVC.cellNumber = indexPath.row
            destinationVC.imageKey = imageKey?[indexPath.row]
        }
        else{ //if nothing scanned, then automatically launch camera
            destinationVC.buttonPressed = true
        }
    }
    else{ //if we press the camera button
        destinationVC.buttonPressed = true
    }
}
    @IBAction func unwind( _ seg: UIStoryboardSegue) { //this function gets called when we press the "cancel" in camera view controller or when we press the back button in the navigation bar
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

