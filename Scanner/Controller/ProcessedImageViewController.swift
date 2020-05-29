//
//  ProcessedImageViewController.swift
//  Scanner
//
//  Created by Andy Zhang on 5/28/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import UIKit
class ProcessedImageViewController: UIViewController{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
 var selectedText : Data? //this will be set during the segue
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
        textView.text = selectedText as? String ?? "Invalid"
    }
    
}
