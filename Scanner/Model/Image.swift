//
//  Image.swift
//  Scanner
//
//  Created by Andy Zhang on 6/7/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import Foundation
import UIKit
struct Image{
    enum StorageType {
        case fileSystem
    }
    //MARK: - Save Image
        func store(image: UIImage,
                          forKey key: String,
                          withStorageType storageType: StorageType) {
           if let pngRepresentation = image.pngData() {
               switch storageType {
               case .fileSystem:
                   if let filePath = filePath(forKey: key) {
                       do  {
                           try pngRepresentation.write(to: filePath,
                                                       options: .atomic)
                       } catch let err {
                           print("Saving file resulted in error: ", err)
                       }
                   }
               }
           }
       }
       
        func filePath(forKey key: String) -> URL? { //gets the path
           let fileManager = FileManager.default
           guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                    in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
           
           return documentURL.appendingPathComponent(key + ".png")
       }
       
       
       
    func getNewKey(_ textCount: Int) -> String{ //this will create a unique key (name) for each image when we take a new scan
           /*if let itemCount = (textCount! + 1){
            let itemCountAsString = String(itemCount)
            return ( "item" + (itemCountAsString))
            }*/
           return("item" + String(textCount))
           //return ""
       }
       
       //MARK: - Retreive Image
       func getExistingKey(_ cellNumber: Int) -> String{ //this will regenerate the key for a previously scanned image
           return ("item" + String(cellNumber))
       }
        
        
    func retrieveImage(forKey key: String,
                                  inStorageType storageType: StorageType) -> UIImage? {
           switch storageType {
           case .fileSystem:
               if let filePath = self.filePath(forKey: key),
                   let fileData = FileManager.default.contents(atPath: filePath.path),
                   let image = UIImage(data: fileData) {
                   return image
               }
               
           }
           print("no image found")
           return nil
       }
       
       
       
       
       //MARK: - Delete Images
       func deleteImage(_ url: URL){
           do{
           let fileManager = FileManager.default
               try fileManager.removeItem(at: url)
           }
           catch{
               print("Error deleting image: \(error)")
           }
       }
       
}
