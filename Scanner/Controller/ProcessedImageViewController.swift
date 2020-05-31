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
    var button = Button()
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    var text: Results<Data>?
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
 var selectedText : Data? //this will be set during the segue
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //print(button.buttonPressed)
        if button.buttonPressed{
            pictureButtonPressed()
            setupVision()
            textView.isEditable = false
            button.buttonPressed = false //after the button is pressed, set back to false
        }
        
        if (textView.text != nil){ //if there is text, we just display it (no other methods are called)
            textView.text = selectedText?.text
        }
        
        
        
    }
    
    func pictureButtonPressed(){
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
     func setupVision() {
        
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            print("setupVision")
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

        print("ok")
        
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
    
}
