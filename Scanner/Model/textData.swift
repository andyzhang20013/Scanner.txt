//
//  Data.swift
//  Scanner
//
//  Created by Andy Zhang on 5/28/20.
//  Copyright © 2020 Andy Zhang. All rights reserved.
//

import Foundation
import RealmSwift

class textData: Object{
    @objc dynamic var text: String = ""
    @objc dynamic var date: Date?
    @objc dynamic var imageKey: String = ""
    //let imageData = List<imageData>() //forward relationship, each textData has a imageData object
}
