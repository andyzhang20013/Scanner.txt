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
    var text: Results<textData>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80
        tableView.keyboardDismissMode = .onDrag
        loadItems()
        navigationItem.title = "My Scans"
    }
    func loadItems(){
        text = realm.objects(textData.self)
        text = text!.sorted(byKeyPath: "date", ascending: false)
        print(text)
        tableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) { //if we press the back button, then reload the table
        loadItems()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //always go through here
        let destinationVC = segue.destination as! ProcessedImageViewController
        self.view.window?.endEditing(true) //if searched for something, close the keyboard
        destinationVC.textCount = text!.count //for creating new images
        if let indexPath = tableView.indexPathForSelectedRow{ //we use this to get the selected row
            if (text?[indexPath.row].text != "No text scanned yet" || text?.count != 0) { //if there is actually something scanned
                destinationVC.selectedText = text?[indexPath.row]
                destinationVC.buttonPressed = false
                destinationVC.cellNumber = indexPath.row
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
                        self.image.deleteImage(imageUrl) //deletes the image
                        }
                    self.image.deleteImageKey(indexPath.row + 1)
                    }
                }
                
                catch{
                    print("Error deleting image and/or text: \(error)")
                }
                 tableView.reloadData()
                
            }
           
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
    //MARK: - Search Bar Methods
    extension ViewController: UISearchBarDelegate{
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            print("A")
            text = text?.filter("text CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "date", ascending: false)
            tableView.reloadData() //calls datasource table view methods
            print("B")
            
        }
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
            if searchBar.text?.count == 0 { //when we want to clear the serach bar
                loadItems() //reload all items to quit out of search
                DispatchQueue.main.async{ //run on mainQeue so that when we dismiss, the keyboard can go away on a background thread so that it can go away even if other items are still be loaded
                    searchBar.resignFirstResponder()//this makes the keyboard go away
                }
            }
        }
        
       
        
    }

    


