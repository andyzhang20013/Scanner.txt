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
import SwipeCellKit
class ViewController: UITableViewController, VNDocumentCameraViewControllerDelegate {
    let realm = try! Realm()
    let image = Image()
    var cellDeletedRow: Int?
    var text: Results<Data>?
    var imageKey: Results<Data>?
    var cellNumberChanged: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80
        loadItems()
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
                
                if cellNumberChanged{ //if an item has been deleted, we have to update the reference to the image
                    if indexPath.row > cellDeletedRow!{ //if the cell is below the cell deleted, then reduce the cell number, otherwise do nothing
                        destinationVC.cellNumber! -= 1
                    }
                    cellNumberChanged = false
                }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SwipeTableViewCell
        if let item = text?[indexPath.row] {
            cell.textLabel?.text = item.text
        }
        else{
            cell.textLabel?.text = "No text scanned yet"
        }
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return text?.count ?? 1
    }
    

}

//MARK: - Swipe Cell Delegate Methods
extension ViewController: SwipeTableViewCellDelegate{
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
            if let textForDeletion = self.text?[indexPath.row]{
            do{
                try self.realm.write{
                    self.realm.delete(textForDeletion)
                    //delete image function
                    if let imageUrl = self.image.filePath(forKey: self.image.getExistingKey(indexPath.row)){
                        print(imageUrl)
                        self.image.deleteImage(imageUrl) //deletes the image
                        
                        }
                    }
                    self.cellDeletedRow = indexPath.row
                    self.cellNumberChanged = true
                    //self.processedImage.cellNumber = self.updateCellNumber(self.processedImage.getCellNumber()) //updates position of image
                }
                
                catch{
                    print("Error deleting category: \(error)")
                }
                
            }
            
                tableView.reloadData()
            }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "delete")
        
        return [deleteAction]
        }

        
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        options.transitionStyle = .border
        return options
    }
    }
    
    /*func updateCellNumber(_ cellNumber: Int)-> Int{
        return(cellNumber - 1)
    }*/

