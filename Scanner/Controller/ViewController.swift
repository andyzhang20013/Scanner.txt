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
class ViewController: UITableViewController, VNDocumentCameraViewControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    let realm = try! Realm()
    let image = Image()
    let label = UILabel()
    var text: Results<textData>?
    private let search = UISearchController(searchResultsController: nil)
     var isSearchBarEmpty: Bool {
       return search.searchBar.text?.isEmpty ?? true
     }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 100
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        loadItems()
        navigationItem.title = "My Scans"
        navigationItem.largeTitleDisplayMode = .always
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search"
        navigationItem.searchController = search
        search.searchBar.delegate = self
        self.navigationItem.hidesSearchBarWhenScrolling = false
    }
    func loadItems(){
        text = realm.objects(textData.self)
        text = text!.sorted(byKeyPath: "date", ascending: false)
        if text?.count == 0{
            label.isHidden = false
            label.text = "Press the camera icon to scan a document"
            label.textAlignment = .center
            search.searchBar.isHidden = true
        }
        else{
            label.isHidden = true
            search.searchBar.isHidden = false
        }
        tableView.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) { //if we press the back button, then reload the table
        navigationController?.isToolbarHidden = true
        loadItems()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //always go through here
        
        if (segue.identifier == "takeNewPicture" || segue.identifier == "toProcessedImage"){
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
        
        else if (segue.identifier == "toHelp"){
            //implement a help page?
        }
        search.searchBar.text = "" //if we go back, then the search bar will clear
        
    }
    @IBAction func unwind( _ seg: UIStoryboardSegue) { //this function gets called when we press the "cancel" in camera view controller or when we press the back button in the navigation bar
    }
    
    //MARK: - Tableview Datasource Methods - This creates the cells
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Asks us for a UITableView cell to display -> This will create a new cell for each message
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SwipeTableViewCell
        if let item = text?[indexPath.row] {
            cell.textLabel?.text = item.text
        }
        
        if (text?[0].imageKey == ""){
            cell.textLabel?.text = "No text scanned yet"
        }
        cell.delegate = self
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let textCount = text?.count{
            tableView.backgroundView = label
            tableView.separatorStyle = .singleLine
            if textCount != 0{
                tableView.isScrollEnabled = true
                return textCount
            }
        else{
            tableView.isScrollEnabled = false
            return 0
        }
    }
        return 1
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
                self.loadItems()
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

    

    //MARK: - UISearchController
func updateSearchResults(for searchController: UISearchController) {
      if !isSearchBarEmpty{
      guard let textInSearchBar = searchController.searchBar.text else { return }
      text = text?.filter("text CONTAINS[cd] %@", textInSearchBar).sorted(byKeyPath: "date", ascending: false)
          if text?.count == 0{
            label.isHidden = false
            label.text = "No results found"
            label.textAlignment = .center
          }
      
          tableView.reloadData() //calls datasource table view methods
      }
      else{
          //searchController.searchBar.resignFirstResponder()
          
          searchBarCancelButtonClicked(search.searchBar)
      }
      
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
      searchBar.resignFirstResponder()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
      loadItems()
  }
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      text = realm.objects(textData.self)
      text = text!.sorted(byKeyPath: "date", ascending: false)
      label.isHidden = true
      updateSearchResults(for: search)
  }
}
