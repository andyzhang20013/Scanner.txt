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
import AVFoundation
class ProcessedImageViewController: UIViewController, VNDocumentCameraViewControllerDelegate, AVSpeechSynthesizerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var speakerBarButton: UIBarButtonItem!
    let realm = try! Realm()
    let session = AVAudioSession.sharedInstance()
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
    let scanningAlert = UIAlertController(title: nil, message: "Scanning for Text", preferredStyle: .alert)
    var buttonPressed: Bool = false
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    var cellNumber: Int? //for referring to existing cells
    var textCount: Int? //for creating new cells
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var selectedText : textData? //this will be set during the segue
    var image = Image()
    let synthesizer = AVSpeechSynthesizer()
    var scanCount: Int = 0
    var detectedText = ""
    var scannedImage: UIImage?
    private var imageUrl: URL?
    enum StorageType {
        case fileSystem
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        synthesizer.stopSpeaking(at: .immediate)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.isUserInteractionEnabled = true
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.isToolbarHidden = false
        speakerBarButton.image = UIImage(named: "speaker.2")
        synthesizer.delegate = self
        imageView.isUserInteractionEnabled = true
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        if buttonPressed{
            pictureButtonPressed()
            setupVision()
        }
        else if (textView.text != nil){ //if there is text, we just display it (no other methods are called)
            textView.text = selectedText?.text
            //print("Key is:" + image.getExistingKey(cellNumber!))
            imageView.image = image.retrieveImage(forKey: image.getExistingKey(cellNumber!), inStorageType: .fileSystem)
            if let imageKey = selectedText?.imageKey{
            imageView.image = image.retrieveImage(forKey: imageKey, inStorageType: .fileSystem)
            }
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
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                //print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                self.detectedText += topCandidate.string
                self.detectedText += " "
            }
            
            DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
            }
            
            if self.detectedText == ""{ //if no text detected, alert the user
                let alert = UIAlertController(title: "No text found", message: "No text was scanned. Please try again", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) {(action) in
                    self.performSegue(withIdentifier: "unwindToCells", sender: action)
                }
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            else{
                let newTextData = textData()
                newTextData.text = self.detectedText
                newTextData.imageKey = self.image.getNewKey(self.textCount!)
                newTextData.date = Date()
                    DispatchQueue.main.async{
                        self.displayTextAndImage() //call this method to trigger all at once
                        self.saveItems(newTextData)
                    }
             
               
            }
            
        }
        textRecognitionRequest.recognitionLevel = .accurate
    }
    
    func displayTextAndImage(){
        DispatchQueue.main.async { //display all at once to prevent lagging
            self.textView.text = self.detectedText
            self.textView.flashScrollIndicators()
            self.imageView.image = self.scannedImage
        }
    }
    private func processImage(_ processedImage: UIImage) {
        
        image.store(image: processedImage, forKey: image.getNewKey(textCount!), withStorageType: .fileSystem) //save the image
        recognizeTextInImage(processedImage)
        if scanCount > 1{
            DispatchQueue.main.async {
                let pageAlert = UIAlertController(title: "Multiple images scanned", message: "Please scan only one image at a time", preferredStyle: .alert)
                let okPressed2 = UIAlertAction(title: "OK", style: .default)
                pageAlert.addAction(okPressed2)
                self.present(pageAlert, animated: true, completion: nil)
            }
            
        }
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
    }
    
    
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true)
        DispatchQueue.global(qos: .userInitiated).async { //loading animation
        DispatchQueue.main.async {
            self.loadingIndicator.startAnimating()
            self.scanningAlert.view.addSubview(self.loadingIndicator)
            self.present(self.scanningAlert, animated: true, completion: nil)
            }
        }
        scanCount = scan.pageCount
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let newImage = compressedImage(originalImage)
        self.scannedImage = newImage
        let imageToBeAnalyzed = scan.imageOfPage(at: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: imageToBeAnalyzed.cgImage!, options: [:])
            do {
                try handler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
            
            self.processImage(newImage)
        }
        
        
    }
    
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        
        return reloadedImage
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
    func saveItems(_ text: textData){ //should save after image is processed
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
        let items = [textView.text]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
        if let popOver = ac.popoverPresentationController {
          popOver.sourceView = self.view
          popOver.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
          popOver.barButtonItem = sender
        
        }
       
    }
    
    //MARK: - Text to Speech
    
    @IBAction func speakerButtonPressed(_ sender: UIBarButtonItem){
        let utterance = AVSpeechUtterance(string: textView.text)
              utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
              utterance.rate = 0.5
              //if sender.image == UIImage(named: "speaker.2"){
                  /*if speakerVolume == 0{ //if the volume is off, notify the user
                      let audioAlert = UIAlertController(title: "Increase Speaker Volume", message: "Increase speaker volume to use text-to-speech feature", preferredStyle: .alert)
                      let okPressed = UIAlertAction(title: "OK", style: .default)
                      audioAlert.addAction(okPressed)
                      self.present(audioAlert, animated: true, completion: nil)
                  }
                  else{*/
                 
                  //
               //}
                  
              //}
               if sender.image == UIImage(named: "speakerSlash"){
                  synthesizer.stopSpeaking(at: .immediate)
                  UIApplication.shared.isIdleTimerDisabled = false
               sender.image = UIImage(named: "speaker.2")
              }
              
               else{
                   synthesizer.speak(utterance)
                                      print("is speaking")
                                     UIApplication.shared.isIdleTimerDisabled = true //when speaking, won't fall asleep
                   sender.image = UIImage(named: "speakerSlash")
       }
              
          }
           func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                 didFinish utterance: AVSpeechUtterance){
               print("ok")
              speakerBarButton.image = UIImage(named: "speaker.2")
              UIApplication.shared.isIdleTimerDisabled = false
          }
}
