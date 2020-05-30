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
    private var recognizedText: String?
override func viewDidLoad() {
    super.viewDidLoad()
    
    
}

func loadItems(){
    text = realm.objects(Data.self)
    tableView.reloadData()
}

    
    func saveItems(text: Data){ //should save after image is processed
        do{
            try realm.write{
                realm.add(text)
            }
        }
            catch{
                print("Error saving text: \(error)")
            }
        }

    
    
    
    @IBAction func pictureButtonPressed(_ sender: UIBarButtonItem) {
    
        processedImage.setupVision()
    performSegue(withIdentifier: "toProcessedImage", sender: self)
    
}



 





override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   let destinationVC = segue.destination as! ProcessedImageViewController
    if let indexPath = tableView.indexPathForSelectedRow{ //we use this to get the selected row
        destinationVC.selectedText = text?[indexPath.row]
    }
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

