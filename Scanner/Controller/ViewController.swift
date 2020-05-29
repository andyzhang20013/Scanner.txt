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
var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var textRecognitionRequest = VNRecognizeTextRequest()
let realm = try! Realm()
var text: Results<Data>?
    private var recognizedText: String?
override func viewDidLoad() {
    super.viewDidLoad()
    setupVision()
    textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
        if let results = request.results, !results.isEmpty {
            if let requestResults = request.results as? [VNRecognizedTextObservation] {
                self.recognizedText = ""
                for observation in requestResults {
                    guard let candidiate = observation.topCandidates(1).first else { return }
                      self.recognizedText! += candidiate.string
                    self.recognizedText! += "\n"
                }
                
            }
        }
    })
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
    
    let scannerViewController = VNDocumentCameraViewController()
    scannerViewController.delegate = self
    present(scannerViewController, animated: true)
    DispatchQueue.main.async{
        //create a new cell in the background
    }
}

private func setupVision() {
    textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        var detectedText = ""
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { return }
            print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
            
            detectedText += topCandidate.string
            detectedText += "\n"
        }
        
        DispatchQueue.main.async {
            /*
             self.textView.text = detectedText
             self.textView.flashScrollIndicators()
             
             */
            //need to send the text & image over to ProcessImage view controller
            
            
        }
    }
    
    textRecognitionRequest.recognitionLevel = .accurate
}

private func processImage(_ image: UIImage) {
    //imageView.image = image
    recognizeTextInImage(image)
}
 

private func recognizeTextInImage(_ image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    print("ok")
   textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
       if let results = request.results, !results.isEmpty {
           if let requestResults = request.results as? [VNRecognizedTextObservation] {
               self.recognizedText = ""
               for observation in requestResults {
                   guard let candidiate = observation.topCandidates(1).first else { return }
                     self.recognizedText! += candidiate.string
                   self.recognizedText! += "\n"
               }
            do{ //need to save the recognized text to realm
                let newData = Data()
                newData.text = self.recognizedText!
                self.saveItems(text: newData)
                print("text saved")
            }
            
                catch{
                    print("Error saving text: \(error)")
                }
           }
        self.tableView.reloadData()
       }
   })
    
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
    /*guard scan.pageCount >= 1 else {
        controller.dismiss(animated: true)
        return
    }
    
    let originalImage = scan.imageOfPage(at: 0)
    let newImage = compressedImage(originalImage)
    controller.dismiss(animated: true)*/
    let image = scan.imageOfPage(at: 0)
       let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
       do {
           try handler.perform([textRecognitionRequest])
       } catch {
           print(error)
       }
    
    processImage(image)
}

func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    print(error)
    controller.dismiss(animated: true)
}

func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true)
}

func compressedImage(_ originalImage: UIImage) -> UIImage {
    guard let imageData = originalImage.jpegData(compressionQuality: 1),
        let reloadedImage = UIImage(data: imageData) else {
            return originalImage
    }
    return reloadedImage
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

