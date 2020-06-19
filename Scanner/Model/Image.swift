//
//  Image.swift
//  Scanner
//
//  Created by Andy Zhang on 6/7/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
struct Image{
    enum StorageType {
        case fileSystem
    }
    let realm = try! Realm()
    var imageName: Results<textData>?{
        didSet{ //every time imageKey is updated, this will be called
            imageName = realm.objects(textData.self)
            imageName = imageName!.sorted(byKeyPath: "date", ascending: false)
        }
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
                       } catch let error {
                           print("Error saving image: ", error)
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
       
       
       
    mutating func getNewKey(_ textCount: Int) -> String{ //this will create a unique key (name) for each image when we take a new scan
        let newImageData = textData()
        newImageData.imageKey = "item" + String(textCount)
        //saveImageKey(newImageData) //we will now save in the ProcessedImageViewController
        return( "item" + String(textCount))
       }
       
       //MARK: - Retreive Image
       func getExistingKey(_ cellNumber: Int) -> String{ //this will regenerate the key for a previously scanned image
        //print("ImageKey from Realm is:" + String(imageKey?[cellNumber].imageKey) ?? "")
        if let existingKey = imageName?[cellNumber-1].imageKey{ //subtract 1 to get the index
            return existingKey
        }
        return "no key found"
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
       
       
       
       
       //MARK: - Delete Image & imageKey
       func deleteImage(_ url: URL){
           do{
           let fileManager = FileManager.default
               try fileManager.removeItem(at: url)
           }
           catch{
               print("Error deleting image: \(error)")
           }
       }
       
    
    func deleteImageKey(_ cellNumber: Int){
        if let imageKeyForDeletion = self.imageName?[cellNumber - 1]{
            do{
            try self.realm.write{
                self.realm.delete(imageKeyForDeletion)
                }
            }
            
            catch{
                print("Error deleting imageKey: \(error)")
            }
        }
    }
}
