//
//  ProcessedImageViewController.swift
//  Scanner
//
//  Created by Andy Zhang on 5/28/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import UIKit
import Vision
import VisionKit
import RealmSwift
class ProcessedImageViewController: UIViewController, VNDocumentCameraViewControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    let realm = try! Realm()
    var buttonPressed: Bool = false
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    var text: Results<Data>?
    var cellNumber: Int = 0 //for referring to existing cells
    var textCount: Int? //for creating new cells
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var imageUrl: URL?
    var selectedText : Data? //this will be set during the segue
    
    enum StorageType {
        case fileSystem
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        if buttonPressed{
            pictureButtonPressed()
            setupVision()
            
        }
        if (textView.text != nil){ //if there is text, we just display it (no other methods are called)
            textView.text = selectedText?.text
            print("Key is:" + getKey(cellNumber))
            imageView.image = retrieveImage(forKey: getKey(cellNumber), inStorageType: .fileSystem) //need to find a way to display unique images, not just the last one
        }
    }
    
    func pictureButtonPressed(){
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    //MARK: - Text Recognition Function
    func setupVision() {
        
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                
                detectedText += topCandidate.string
                detectedText += "\n"
            }
            let newData = Data()
            newData.text = detectedText
            self.saveItems(text: newData)
            DispatchQueue.main.async {
                
                self.textView.text = detectedText
                
                self.textView.flashScrollIndicators()
                
                
                //need to send the text & image over to ProcessImage view controller
                
                
            }
        }
        
        textRecognitionRequest.recognitionLevel = .accurate
    }
    
    private func processImage(_ image: UIImage) {
        imageView.image = image
        recognizeTextInImage(image)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        
        
        guard let cgImage = image.cgImage else { return }
        
        textView.text = ""
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
        
        
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let newImage = compressedImage(originalImage)
        controller.dismiss(animated: true)
        let image = scan.imageOfPage(at: 0)
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
        //let newText = Data()
        //newText.imageKey = getKey()
        imageUrl = filePath(forKey: getKey()) //creates a unique image URL
        store(image: image, forKey: getKey(), withStorageType: .fileSystem) //save the image
        print("Key is:" + getKey())
        
        //saveImageKey(imageKey: newText) //save to realm for future reference to this specific image
        //print(newText.imageKey)
        processImage(image)
    }
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
    
    //MARK: - Save Image
    private func store(image: UIImage,
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
    
    private func filePath(forKey key: String) -> URL? { //gets the path
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                 in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png")
    }
    
    
    
    func getKey() -> String{ //this will create a unique key (name) for each image when we take a new scan
        /*if let itemCount = (textCount! + 1){
         let itemCountAsString = String(itemCount)
         return ( "item" + (itemCountAsString))
         }*/
        return("item" + String(textCount!))
        //return ""
    }
    
    //MARK: - Retreive Image
    func getKey(_ cellNumber: Int) -> String{ //this will regenerate the key for a previously scanned image
        return ("item" + String(cellNumber))
    }
    private func retrieveImage(forKey key: String,
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
    
    
    //MARK: - DocumentCameraViewController Delegate Methods
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
        performSegue(withIdentifier: "unwindToCells", sender: self)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
        performSegue(withIdentifier: "unwindToCells", sender: self)
    }
    
    
    
    //MARK: - Data Persistence Methods
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
    
    
    //MARK: - Share Function
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        //let imageToShare = [UIImage(named: getKey(cellNumber))]
        //find a way to share images
        let items = [selectedText?.text]
         let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
        
    }
    
    
}
