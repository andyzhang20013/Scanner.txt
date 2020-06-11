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
import SpinningIndicator
class ProcessedImageViewController: UIViewController, VNDocumentCameraViewControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    let realm = try! Realm()
    //let spin = SpinnerViewController()
    let alert = UIAlertController(title: nil, message: "Scanning for Text", preferredStyle: .alert)
    let indicator = SpinningIndicator(frame: UIScreen.main.bounds)
    var buttonPressed: Bool = false
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    var text: Results<Data>?
    var cellNumber: Int? //for referring to existing cells
    var textCount: Int? //for creating new cells
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var selectedText : Data? //this will be set during the segue
    let image = Image()
    private var imageUrl: URL?
    enum StorageType {
        case fileSystem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.isUserInteractionEnabled = true
        navigationItem.largeTitleDisplayMode = .never
        if buttonPressed{
            pictureButtonPressed()
            setupVision()
            
        }
        else if (textView.text != nil){ //if there is text, we just display it (no other methods are called)
            textView.text = selectedText?.text
            print("Key is:" + image.getExistingKey(cellNumber!))
            imageView.image = image.retrieveImage(forKey: image.getExistingKey(cellNumber!), inStorageType: .fileSystem)
        }
        /*view.addSubview(indicator)
        indicator.addCircle(lineColor: UIColor(red: 255/255, green: 91/255, blue: 25/255, alpha: 1), lineWidth: 2, radius: 16, angle: 0)
        indicator.addCircle(lineColor: UIColor.orange, lineWidth: 2, radius: 19, angle: CGFloat.pi)*/
    }
    
    func pictureButtonPressed(){
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
        //loading animation
        //indicator.beginAnimating()
        
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
        //dismiss(animated: false, completion: nil)
        //indicator.endAnimating()
    }
    
    
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        
       //Loading animation - need to figure out where this goes
        /*DispatchQueue.main.async {
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating()

            self.alert.view.addSubview(loadingIndicator)
            self.present(self.alert, animated: true, completion: nil)
        }*/
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        
        
        let originalImage = scan.imageOfPage(at: 0)
        let newImage = compressedImage(originalImage)
        controller.dismiss(animated: true)
        
        
        let scannedImage = scan.imageOfPage(at: 0)
        let handler = VNImageRequestHandler(cgImage: scannedImage.cgImage!, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
        //imageUrl = image.filePath(forKey: image.getKey()) //creates a unique image URL
        image.store(image: scannedImage, forKey: image.getNewKey(textCount!), withStorageType: .fileSystem) //save the image
        //print("Key is:" + image.getKey())
        
        
        
        processImage(newImage)
    }
    
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        
        return reloadedImage
    }
    
    /*func startSpinning(){ //loading animation appears while processing image
        
        // add the spinner view controller
        addChild(spin)
        spin.view.frame = view.frame
        view.addSubview(spin.view)
        spin.didMove(toParent: self)

        /*// wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // then remove the spinner view controller
            spin.willMove(toParent: nil)
            spin.view.removeFromSuperview()
            spin.removeFromParent()
        }*/
    }
    
    func stopSpinning(){
        spin.willMove(toParent: nil)
        spin.view.removeFromSuperview()
        spin.removeFromParent()
    }*/
   
    
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
    func getCellNumber() -> Int{
        return (cellNumber!)
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
    
    /*func itemDeleted(_ cellNumber: Int) -> Int{
        //if we delete something, need to find a way to also update the imges
    }*/
    
    //MARK: - Share Function
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        //let imageToShare = [UIImage(named: getKey(cellNumber))]
        //find a way to share images
        let items = [selectedText?.text]
         let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
        
    }
    
    
}
