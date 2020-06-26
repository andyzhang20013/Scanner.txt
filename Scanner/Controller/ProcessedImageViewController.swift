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
import AVFoundation
class ProcessedImageViewController: UIViewController, VNDocumentCameraViewControllerDelegate, AVSpeechSynthesizerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var speakerBarButton: UIBarButtonItem!
    let realm = try! Realm()
    //let spin = SpinnerViewController()
    let alert = UIAlertController(title: nil, message: "Scanning for Text", preferredStyle: .alert)
    let indicator = SpinningIndicator(frame: UIScreen.main.bounds)
    var buttonPressed: Bool = false
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    var cellNumber: Int? //for referring to existing cells
    var textCount: Int? //for creating new cells
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var selectedText : textData? //this will be set during the segue
    var image = Image()
    let synthesizer = AVSpeechSynthesizer()
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
        speakerBarButton.image = UIImage(named: "speaker")
        synthesizer.delegate = self
        //navigationController?.setToolbarHidden(true, animated: false)
        if buttonPressed{
            pictureButtonPressed()
            setupVision()
            
        }
        else if (textView.text != nil){ //if there is text, we just display it (no other methods are called)
            textView.text = selectedText?.text
            print("Key is:" + image.getExistingKey(cellNumber!))
            imageView.image = image.retrieveImage(forKey: image.getExistingKey(cellNumber!), inStorageType: .fileSystem)
            //imageView.image = image.retrieveImage(forKey: "item0", inStorageType: .fileSystem)
            if let imageKey = selectedText?.imageKey{
            print(imageKey)
            imageView.image = image.retrieveImage(forKey: imageKey, inStorageType: .fileSystem)
               
            }
            
            
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
                //print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                
                detectedText += topCandidate.string
                detectedText += " "
            }
            
            
            if detectedText == ""{ //if no text detected, alert the user
                let alert = UIAlertController(title: "No text found", message: "No text was scanned. Please try again", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) {(action) in
                    //delete the image and imageKey?
                    //self.performSegue(withIdentifier: "okButtonPressed", sender: Any?)
                    
                    //performSegue(withIdentifier: "okButtonPressed", sender: Any?)
                    self.performSegue(withIdentifier: "unwindToCells", sender: action)
                    
                }
                
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            
            else if detectedText != ""{
                let newTextData = textData()
                newTextData.text = detectedText
                newTextData.imageKey = self.image.getNewKey(self.textCount!)
                newTextData.date = Date()
                self.saveItems(newTextData)
            }
            DispatchQueue.main.async {
                self.textView.text = detectedText
                self.textView.flashScrollIndicators()
            }
        }
        textRecognitionRequest.recognitionLevel = .accurate
    }
    
    private func processImage(_ processedImage: UIImage) {
        image.store(image: processedImage, forKey: image.getNewKey(textCount!), withStorageType: .fileSystem) //save the image
        imageView.image = processedImage
        recognizeTextInImage(processedImage)
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
        //ac.excludedActivityTypes = ["com.tencent.xin.sharetimeline"] //can't exclude Wechat
        present(ac, animated: true)
        
    }
    
    //MARK: - Text to Speech
    
    @IBAction func speakerButtonPressed(_ sender: UIBarButtonItem){
        print(synthesizer.isSpeaking)
        let utterance = AVSpeechUtterance(string: textView.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        if sender.image == UIImage(named: "speaker"){
            synthesizer.speak(utterance)
            sender.image = UIImage(named: "speakerSlash")
        }
        else if sender.image == UIImage(named: "speakerSlash"){
            synthesizer.stopSpeaking(at: .immediate)
            sender.image = UIImage(named: "speaker")
        }
        
    }
     func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance){
        speakerBarButton.image = UIImage(named: "speaker")
    }
}
