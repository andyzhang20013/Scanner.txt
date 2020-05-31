//
//  Button.swift
//  Scanner
//
//  Created by Andy Zhang on 5/31/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import Foundation
struct Button{
    var buttonPressed: Bool = true
    
    mutating func setButton(_ bool: Bool){
        buttonPressed = bool
    }
    
    func getButton() -> Bool{
        return buttonPressed
    }
}
